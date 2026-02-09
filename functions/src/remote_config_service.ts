import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';

type RcCache = {
  params: Record<string, string>;
  fetchedAt: number;
  ttlMs: number;
};

export class RemoteConfigService {
  private static instance: RemoteConfigService;
  private remoteConfig: admin.remoteConfig.RemoteConfig | null = null;
  private cache: Map<string, any> = new Map();
  private cacheExpiry: number = 0;
  private readonly CACHE_DURATION = 5 * 60 * 1000;

  private static rcCache: RcCache | null = null;

  private constructor() {
    // lazy init
  }

  public static getInstance(): RemoteConfigService {
    if (!RemoteConfigService.instance) {
      RemoteConfigService.instance = new RemoteConfigService();
    }
    return RemoteConfigService.instance;
  }

  private initializeService(): void {
    if (!this.remoteConfig) {
      this.remoteConfig = admin.remoteConfig();
    }
  }

  private async getTemplate(): Promise<admin.remoteConfig.RemoteConfigTemplate> {
    const now = Date.now();

    if (this.cacheExpiry > now && this.cache.has('template')) {
      return this.cache.get('template');
    }

    try {
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

  private static async fetchRcTemplateParams(): Promise<Record<string, string>> {
    try {
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

  private static async ensureRcCache(): Promise<void> {
    const now = Date.now();
    const needsFetch = !RemoteConfigService.rcCache || (now - RemoteConfigService.rcCache.fetchedAt) > (RemoteConfigService.rcCache.ttlMs);
    if (needsFetch) {
      const params = await RemoteConfigService.fetchRcTemplateParams();
      RemoteConfigService.rcCache = { params, fetchedAt: now, ttlMs: 5 * 60 * 1000 };
    }
  }

  private static getCachedRcParam(key: string): string | undefined {
    if (!RemoteConfigService.rcCache) return undefined;
    return RemoteConfigService.rcCache.params[key];
  }

  public static async getRcString(key: string, fallback?: string): Promise<string> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (typeof val === 'string' && val.length > 0) return val;
    return fallback ?? '';
  }

  public static async getRcNumber(key: string, fallback: number = 0): Promise<number> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (val == null) return fallback;
    const n = Number(val);
    return Number.isFinite(n) ? n : fallback;
  }

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

  async getNotificationMessage(
    messageKey: string,
    fallbackMessage: string,
    params: Record<string, string> = {}
  ): Promise<string> {
    let message = await this.getParameter(messageKey, fallbackMessage);

    if (typeof message !== 'string') {
      logger.warn('Remote Config message is not a string, using fallback', {
        messageKey,
        messageType: typeof message,
        fallbackMessage
      });
      message = fallbackMessage;
    }

    for (const [key, value] of Object.entries(params)) {
      const placeholder = `{${key}}`;
      message = message.replace(new RegExp(placeholder, 'g'), value);
    }

    return message;
  }

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

  private parseTime(timeString: string): { hour: number; minute: number } {
    const timeRegex = /^(\d{1,2}):(\d{2})$/;
    const match = timeString.match(timeRegex);

    if (!match) {
      logger.error('Invalid time format, using default', {
        timeString,
        expectedFormat: 'HH:mm'
      });
      return { hour: 12, minute: 0 };
    }

    const hour = parseInt(match[1], 10);
    const minute = parseInt(match[2], 10);

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      logger.error('Invalid time values, using default', {
        timeString,
        hour,
        minute
      });
      return { hour: 12, minute: 0 };
    }

    return { hour, minute };
  }

  isCurrentTimeMatch(targetTime: { hour: number; minute: number }, toleranceMinutes: number = 5): boolean {
    const now = new Date();
    // algeria timezone offset
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

  clearCache(): void {
    this.cache.clear();
    this.cacheExpiry = 0;
    logger.info('Remote Config cache cleared');
  }

  static clearRcCache(): void {
    RemoteConfigService.rcCache = null;
    logger.info('Remote Config parameter cache cleared');
  }
}

export const DEFAULT_NOTIFICATION_CONFIG = {
  notification_promo_used_msg: "One of your promo codes was used by a new user!",
  notification_influencer_welcome_msg: "Congratulations! You're now an influencer. Share your code: {code}"
};

export function getRemoteConfigService(): RemoteConfigService {
  return RemoteConfigService.getInstance();
}

// sync logic
let rcCache: RcCache | null = null;

async function fetchRcTemplateParams(): Promise<Record<string, string>> {
  try {
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
    rcCache = { params, fetchedAt: now, ttlMs: 5 * 60 * 1000 };
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

export function getPremiumMonthlyDzd(): number {
  return getRcNumber('premium_monthly_price_dzd', Number(process.env.PREMIUM_MONTHLY_PRICE_DZD) || 450);
}

export function getPremiumYearlyDzd(): number {
  return getRcNumber('premium_yearly_price_dzd', Number(process.env.PREMIUM_YEARLY_PRICE_DZD) || 4500);
}

export function getInfluencerCommissionRate(): number {
  return getRcNumber('influencer_commission_rate', Number(process.env.INFLUENCER_COMMISSION_RATE) || 0.15);
}

export function getInfluencerEarnForCode(): number {
  return getRcNumber('influencer_earn_for_code', Number(process.env.INFLUENCER_EARN_FOR_CODE) || 100);
}

export function getInfluencerWithdrawalProcessingDays(): number {
  return getRcNumber('influencer_withdrawal_processing_days', Number(process.env.INFLUENCER_WITHDRAWAL_PROCESSING_DAYS) || 3);
}

export function getInfluencerMinWithdrawal(): number {
  return getRcNumber('influencer_min_withdrawal', Number(process.env.INFLUENCER_MIN_WITHDRAWAL) || 2500);
}

export function getSuccessUrl(): string {
  return getRcString('success_url', process.env.SUCCESS_URL || "https://macroaize.com/success");
}

export function getFailureUrl(): string {
  return getRcString('failure_url', process.env.FAILURE_URL || "https://macroaize.com/failure");
}

export function getTermsLink(): string {
  return getRcString('terms_link', process.env.TERMS_LINK || 'https://macroaize.com/terms');
}

export function getPrivacyLink(): string {
  return getRcString('privacy_link', process.env.PRIVACY_LINK || 'https://macroaize.com/privacy');
}

export function getShareUrlAndroid(): string {
  const rc = getRcString('play_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_ANDROID || '';
}

export function getShareUrlIos(): string {
  const rc = getRcString('app_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_IOS || '';
}

export function getScanLimit(): number {
  return getRcNumber('scan_limit', Number(process.env.SCAN_LIMIT) || 1);
}

export function getChatLimit(): number {
  return getRcNumber('chat_limit', Number(process.env.CHAT_LIMIT) || 3);
}

export function getMinRequiredAppVersion(): string {
  return getRcString('min_required_app_version');
}

export function getUpdateMessage(): string {
  return getRcString('update_message', 'A new version is required to continue using MacroAize.');
}

export function getScanLimitCfg(): number {
  return getScanLimit();
}

export function getChatLimitCfg(): number {
  return getChatLimit();
}

export function getSubscriptionsEnabled(): boolean {
  const val = getRcString('subscriptions_enabled', process.env.SUBSCRIPTIONS_ENABLED || 'false');
  return String(val).toLowerCase() === 'true';
}

export function getPromoExtensionDaysMonthly(): number {
  return getRcNumber('promo_extension_days_monthly', Number(process.env.PROMO_EXTENSION_DAYS_MONTHLY) || 3);
}

export function getPromoExtensionDaysYearly(): number {
  return getRcNumber('promo_extension_days_yearly', Number(process.env.PROMO_EXTENSION_DAYS_YEARLY) || 30);
}