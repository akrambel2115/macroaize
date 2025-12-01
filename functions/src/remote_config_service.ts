import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';

// Cache types
type RcCache = {
  params: Record<string, string>;
  fetchedAt: number;
  ttlMs: number;
};

// Remote Config service
export class RemoteConfigService {
  private static instance: RemoteConfigService;
  private remoteConfig: admin.remoteConfig.RemoteConfig | null = null;
  private cache: Map<string, any> = new Map();
  private cacheExpiry: number = 0;
  private readonly CACHE_DURATION = 5 * 60 * 1000; // 5 minutes cache

  // Parameter cache
  private static rcCache: RcCache | null = null;

  private constructor() {
    // Lazy init
  }

  public static getInstance(): RemoteConfigService {
    if (!RemoteConfigService.instance) {
      RemoteConfigService.instance = new RemoteConfigService();
    }
    return RemoteConfigService.instance;
  }

  // Lazy init
  private initializeService(): void {
    if (!this.remoteConfig) {
      this.remoteConfig = admin.remoteConfig();
    }
  }

  // Get cached template
  private async getTemplate(): Promise<admin.remoteConfig.RemoteConfigTemplate> {
    const now = Date.now();

    if (this.cacheExpiry > now && this.cache.has('template')) {
      return this.cache.get('template');
    }

    try {
      // Initialize service if needed
      this.initializeService();

      const template = await this.remoteConfig!.getTemplate();
      this.cache.set('template', template);
      this.cacheExpiry = now + this.CACHE_DURATION;

      logger.info('Remote Config template fetched and cached', {
        cacheExpiry: new Date(this.cacheExpiry).toISOString()
      });

      return template;
    } catch (error) {
      logger.error('Failed to fetch Remote Config template', {
        error: error instanceof Error ? error.message : String(error)
      });
      throw error;
    }
  }

  // Fetch params
  private static async fetchRcTemplateParams(): Promise<Record<string, string>> {
    try {
      // Skip if uninitialized
      if (!admin.apps.length) {
        return {};
      }
      const rc = admin.remoteConfig();
      const template = await rc.getTemplate();
      const out: Record<string, string> = {};
      const params = template.parameters || {} as any;
      for (const [key, p] of Object.entries<any>(params)) {
        const dv = p?.defaultValue?.value;
        if (typeof dv === 'string') out[key] = dv;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  // Ensure cache
  private static async ensureRcCache(): Promise<void> {
    const now = Date.now();
    const needsFetch = !RemoteConfigService.rcCache || (now - RemoteConfigService.rcCache.fetchedAt) > (RemoteConfigService.rcCache.ttlMs);
    if (needsFetch) {
      const params = await RemoteConfigService.fetchRcTemplateParams();
      RemoteConfigService.rcCache = { params, fetchedAt: now, ttlMs: 5 * 60 * 1000 }; // 5 minutes TTL
    }
  }

  // Get cached param
  private static getCachedRcParam(key: string): string | undefined {
    if (!RemoteConfigService.rcCache) return undefined;
    return RemoteConfigService.rcCache.params[key];
  }

  // Get string param
  public static async getRcString(key: string, fallback?: string): Promise<string> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (typeof val === 'string' && val.length > 0) return val;
    return fallback ?? '';
  }

  // Get number param
  public static async getRcNumber(key: string, fallback: number = 0): Promise<number> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (val == null) return fallback;
    const n = Number(val);
    return Number.isFinite(n) ? n : fallback;
  }

  // Get param value
  async getParameter(key: string, fallback: any = null): Promise<any> {
    try {
      const template = await this.getTemplate();
      const parameter = template.parameters[key];

      if (!parameter) {
        logger.warn('Remote Config parameter not found, using fallback', {
          key,
          fallback
        });
        return fallback;
      }

      // Return default
      const defaultValue = parameter.defaultValue;
      if (defaultValue && 'value' in defaultValue) {
        return defaultValue.value;
      }

      logger.warn('Remote Config parameter has no default value, using fallback', {
        key,
        fallback
      });
      return fallback;

    } catch (error) {
      logger.error('Error fetching Remote Config parameter, using fallback', {
        key,
        fallback,
        error: error instanceof Error ? error.message : String(error)
      });
      return fallback;
    }
  }

  // Get message
  async getNotificationMessage(
    messageKey: string,
    fallbackMessage: string,
    params: Record<string, string> = {}
  ): Promise<string> {
    let message = await this.getParameter(messageKey, fallbackMessage);

    // Validate string
    if (typeof message !== 'string') {
      logger.warn('Remote Config message is not a string, using fallback', {
        messageKey,
        messageType: typeof message,
        fallbackMessage
      });
      message = fallbackMessage;
    }

    // Substitute params
    for (const [key, value] of Object.entries(params)) {
      const placeholder = `{${key}}`;
      message = message.replace(new RegExp(placeholder, 'g'), value);
    }

    return message;
  }

  // Get time
  async getNotificationTime(timeKey: string, fallbackTime: string): Promise<{ hour: number; minute: number }> {
    const timeString = await this.getParameter(timeKey, fallbackTime);

    if (typeof timeString !== 'string') {
      logger.warn('Remote Config time is not a string, using fallback', {
        timeKey,
        fallbackTime
      });
      return this.parseTime(fallbackTime);
    }

    return this.parseTime(timeString);
  }

  // Parse time
  private parseTime(timeString: string): { hour: number; minute: number } {
    const timeRegex = /^(\d{1,2}):(\d{2})$/;
    const match = timeString.match(timeRegex);

    if (!match) {
      logger.error('Invalid time format, using default', {
        timeString,
        expectedFormat: 'HH:mm'
      });
      return { hour: 12, minute: 0 }; // Default to noon
    }

    const hour = parseInt(match[1], 10);
    const minute = parseInt(match[2], 10);

    // Validate time
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      logger.error('Invalid time values, using default', {
        timeString,
        hour,
        minute
      });
      return { hour: 12, minute: 0 }; // Default to noon
    }

    return { hour, minute };
  }

  // Check time match
  isCurrentTimeMatch(targetTime: { hour: number; minute: number }, toleranceMinutes: number = 5): boolean {
    const now = new Date();
    // Convert timezone
    const algeriaTime = new Date(now.getTime() + (1 * 60 * 60 * 1000));

    const currentHour = algeriaTime.getUTCHours();
    const currentMinute = algeriaTime.getUTCMinutes();

    const targetTotalMinutes = targetTime.hour * 60 + targetTime.minute;
    const currentTotalMinutes = currentHour * 60 + currentMinute;

    const diff = Math.abs(currentTotalMinutes - targetTotalMinutes);

    logger.info('Time match check', {
      algeriaTime: algeriaTime.toISOString(),
      currentTime: `${currentHour.toString().padStart(2, '0')}:${currentMinute.toString().padStart(2, '0')}`,
      targetTime: `${targetTime.hour.toString().padStart(2, '0')}:${targetTime.minute.toString().padStart(2, '0')}`,
      diff,
      toleranceMinutes,
      isMatch: diff <= toleranceMinutes
    });

    return diff <= toleranceMinutes;
  }

  // Clear cache
  clearCache(): void {
    this.cache.clear();
    this.cacheExpiry = 0;
    logger.info('Remote Config cache cleared');
  }

  // Clear param cache
  static clearRcCache(): void {
    RemoteConfigService.rcCache = null;
    logger.info('Remote Config parameter cache cleared');
  }
}

// Default config
export const DEFAULT_NOTIFICATION_CONFIG = {
  // Timing
  notification_lunch_time: "13:00",
  notification_dinner_time: "20:30",

  // Messages
  notification_lunch_msg: "Don't forget to log your lunch!",
  notification_dinner_msg: "Time to log your dinner! Don't skip your last meal.",
  notification_end_of_day_msg: "Only a few hours left to reach your goal!",
  notification_goal_50pct_msg: "You're halfway to your goal! Keep going!",
  notification_goal_100pct_msg: "Goal achieved! Great job today!",
  notification_daily_reset_msg: "Your daily scan & chat limits have been reset!",
  notification_promo_used_msg: "One of your promo codes was used by a new user!",
  notification_influencer_welcome_msg: "Congratulations! You're now an influencer. Share your code: {code}"
};

// Get service instance
export function getRemoteConfigService(): RemoteConfigService {
  return RemoteConfigService.getInstance();
}

// =============================================================================
// Sync functions
// =============================================================================

// Param cache
let rcCache: RcCache | null = null;

async function fetchRcTemplateParams(): Promise<Record<string, string>> {
  try {
    // Skip if uninitialized
    if (!admin.apps.length) {
      return {};
    }
    const rc = admin.remoteConfig();
    const template = await rc.getTemplate();
    const out: Record<string, string> = {};
    const params = template.parameters || {} as any;
    for (const [key, p] of Object.entries<any>(params)) {
      const dv = p?.defaultValue?.value;
      if (typeof dv === 'string') out[key] = dv;
    }
    return out;
  } catch (_) {
    return {};
  }
}

async function ensureRcCache(): Promise<void> {
  const now = Date.now();
  const needsFetch = !rcCache || (now - rcCache.fetchedAt) > (rcCache.ttlMs);
  if (needsFetch) {
    const params = await fetchRcTemplateParams();
    rcCache = { params, fetchedAt: now, ttlMs: 5 * 60 * 1000 }; // 5 minutes TTL
  }
}

function getCachedRcParam(key: string): string | undefined {
  if (!rcCache) return undefined;
  return rcCache.params[key];
}

export function getRcString(key: string, fallback?: string): string {
  if (!rcCache) {
    ensureRcCache();
  }
  const val = getCachedRcParam(key);
  if (typeof val === 'string' && val.length > 0) return val;
  return fallback ?? '';
}

export function getRcNumber(key: string, fallback: number = 0): number {
  if (!rcCache) {
    ensureRcCache();
  }
  const val = getCachedRcParam(key);
  if (val == null) return fallback;
  const n = Number(val);
  return Number.isFinite(n) ? n : fallback;
}

// =============================================================================
// Config getters
// =============================================================================

// Premium monthly price
export function getPremiumMonthlyDzd(): number {
  return getRcNumber('premium_monthly_price_dzd', Number(process.env.PREMIUM_MONTHLY_PRICE_DZD) || 450);
}

// Premium yearly price
export function getPremiumYearlyDzd(): number {
  return getRcNumber('premium_yearly_price_dzd', Number(process.env.PREMIUM_YEARLY_PRICE_DZD) || 4500);
}

// Influencer commission
export function getInfluencerCommissionRate(): number {
  return getRcNumber('influencer_commission_rate', Number(process.env.INFLUENCER_COMMISSION_RATE) || 0.15);
}

// Influencer earn amount
export function getInfluencerEarnForCode(): number {
  return getRcNumber('influencer_earn_for_code', Number(process.env.INFLUENCER_EARN_FOR_CODE) || 25);
}

// Withdrawal processing days
export function getInfluencerWithdrawalProcessingDays(): number {
  return getRcNumber('influencer_withdrawal_processing_days', Number(process.env.INFLUENCER_WITHDRAWAL_PROCESSING_DAYS) || 3);
}

// Min withdrawal amount
export function getInfluencerMinWithdrawal(): number {
  return getRcNumber('influencer_min_withdrawal', Number(process.env.INFLUENCER_MIN_WITHDRAWAL) || 2500);
}

// Success URL
export function getSuccessUrl(): string {
  return getRcString('success_url', process.env.SUCCESS_URL || "https://macroaize.com/success");
}

// Failure URL
export function getFailureUrl(): string {
  return getRcString('failure_url', process.env.FAILURE_URL || "https://macroaize.com/failure");
}

// Terms link
export function getTermsLink(): string {
  return getRcString('terms_link', process.env.TERMS_LINK || 'https://macroaize.com/terms');
}

// Privacy link
export function getPrivacyLink(): string {
  return getRcString('privacy_link', process.env.PRIVACY_LINK || 'https://macroaize.com/privacy');
}

// Android share URL
export function getShareUrlAndroid(): string {
  // Backward compat: prefer new RC key play_store_url
  const rc = getRcString('play_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_ANDROID || '';
}

// iOS share URL
export function getShareUrlIos(): string {
  // Backward compat: prefer new RC key app_store_url
  const rc = getRcString('app_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_IOS || '';
}

// Scan limit
export function getScanLimit(): number {
  return getRcNumber('scan_limit', Number(process.env.SCAN_LIMIT) || 1);
}

// Chat limit
export function getChatLimit(): number {
  return getRcNumber('chat_limit', Number(process.env.CHAT_LIMIT) || 3);
}

// Min app version
export function getMinRequiredAppVersion(): string {
  return getRcString('min_required_app_version');
}

// Update message
export function getUpdateMessage(): string {
  return getRcString('update_message', 'A new version is required to continue using MacroAize.');
}

// =============================================================================
// Sync wrappers
// =============================================================================

// Scan limit (sync)
export function getScanLimitCfg(): number {
  return getScanLimit();
}

// Chat limit (sync)
export function getChatLimitCfg(): number {
  return getChatLimit();
}

// Subscriptions enabled
export function getSubscriptionsEnabled(): boolean {
  // default false if not set
  const val = getRcString('subscriptions_enabled', process.env.SUBSCRIPTIONS_ENABLED || 'false');
  return String(val).toLowerCase() === 'true';
}
