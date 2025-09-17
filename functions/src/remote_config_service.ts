import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';

// Type definitions for Remote Config cache
type RcCache = {
  params: Record<string, string>;
  fetchedAt: number;
  ttlMs: number;
};

/**
 * Remote Config service for managing notification content and timing
 * Provides secure, centralized configuration management
 * All notification messages and schedules come from Remote Config
 */
export class RemoteConfigService {
  private static instance: RemoteConfigService;
  private remoteConfig: admin.remoteConfig.RemoteConfig | null = null;
  private cache: Map<string, any> = new Map();
  private cacheExpiry: number = 0;
  private readonly CACHE_DURATION = 5 * 60 * 1000; // 5 minutes cache

  // Simple Remote Config parameter cache (separate from notification cache)
  private static rcCache: RcCache | null = null;

  private constructor() {
    // Initialize services lazily when first accessed
  }

  public static getInstance(): RemoteConfigService {
    if (!RemoteConfigService.instance) {
      RemoteConfigService.instance = new RemoteConfigService();
    }
    return RemoteConfigService.instance;
  }

  /**
   * Lazy initialization of Firebase Remote Config
   */
  private initializeService(): void {
    if (!this.remoteConfig) {
      this.remoteConfig = admin.remoteConfig();
    }
  }

  /**
   * Get Remote Config template with caching
   * Reduces API calls and improves performance
   */
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

  /**
   * Fetch Remote Config template parameters (static method for config functions)
   */
  private static async fetchRcTemplateParams(): Promise<Record<string, string>> {
    try {
      // If admin is not initialized yet, skip RC fetch (index.ts will initialize)
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

  /**
   * Ensure Remote Config parameter cache is up to date
   */
  private static async ensureRcCache(): Promise<void> {
    const now = Date.now();
    const needsFetch = !RemoteConfigService.rcCache || (now - RemoteConfigService.rcCache.fetchedAt) > (RemoteConfigService.rcCache.ttlMs);
    if (needsFetch) {
      const params = await RemoteConfigService.fetchRcTemplateParams();
      RemoteConfigService.rcCache = { params, fetchedAt: now, ttlMs: 5 * 60 * 1000 }; // 5 minutes TTL
    }
  }

  /**
   * Get cached Remote Config parameter
   */
  private static getCachedRcParam(key: string): string | undefined {
    if (!RemoteConfigService.rcCache) return undefined;
    return RemoteConfigService.rcCache.params[key];
  }

  /**
   * Get Remote Config string parameter (static method for config functions)
   */
  public static async getRcString(key: string, fallback?: string): Promise<string> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (typeof val === 'string' && val.length > 0) return val;
    return fallback ?? '';
  }

  /**
   * Get Remote Config number parameter (static method for config functions)
   */
  public static async getRcNumber(key: string, fallback: number = 0): Promise<number> {
    await RemoteConfigService.ensureRcCache();
    const val = RemoteConfigService.getCachedRcParam(key);
    if (val == null) return fallback;
    const n = Number(val);
    return Number.isFinite(n) ? n : fallback;
  }

  /**
   * Get a Remote Config parameter value with fallback
   * 
   * @param key - Parameter key
   * @param fallback - Fallback value if parameter not found
   * @returns Parameter value or fallback
   */
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

      // Return the default value
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

  /**
   * Get notification message with parameter substitution
   * 
   * @param messageKey - Remote Config key for the message
   * @param fallbackMessage - Fallback message if key not found
   * @param params - Parameters to substitute in message (e.g., {code: "PROMO123"})
   * @returns Formatted message
   */
  async getNotificationMessage(
    messageKey: string, 
    fallbackMessage: string,
    params: Record<string, string> = {}
  ): Promise<string> {
    let message = await this.getParameter(messageKey, fallbackMessage);
    
    // Ensure message is a string
    if (typeof message !== 'string') {
      logger.warn('Remote Config message is not a string, using fallback', {
        messageKey,
        messageType: typeof message,
        fallbackMessage
      });
      message = fallbackMessage;
    }

    // Substitute parameters
    for (const [key, value] of Object.entries(params)) {
      const placeholder = `{${key}}`;
      message = message.replace(new RegExp(placeholder, 'g'), value);
    }

    return message;
  }

  /**
   * Get notification time in Algeria Time (UTC+1)
   * 
   * @param timeKey - Remote Config key for the time
   * @param fallbackTime - Fallback time in HH:mm format
   * @returns Time object with hour and minute
   */
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

  /**
   * Parse time string into hour and minute
   * Validates format and ensures valid time values
   * 
   * @param timeString - Time in HH:mm format
   * @returns Time object with hour and minute
   */
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
    
    // Validate time values
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

  /**
   * Check if current Algeria time matches the target time
   * Used to prevent early/late notification sends due to function delays
   * 
   * @param targetTime - Target time object
   * @param toleranceMinutes - Tolerance in minutes (default: 5)
   * @returns True if current time matches target time within tolerance
   */
  isCurrentTimeMatch(targetTime: { hour: number; minute: number }, toleranceMinutes: number = 5): boolean {
    const now = new Date();
    // Convert to Algeria Time (UTC+1)
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

  /**
   * Clear cache - useful for testing or forced refresh
   */
  clearCache(): void {
    this.cache.clear();
    this.cacheExpiry = 0;
    logger.info('Remote Config cache cleared');
  }

  /**
   * Clear parameter cache - useful for testing or forced refresh
   */
  static clearRcCache(): void {
    RemoteConfigService.rcCache = null;
    logger.info('Remote Config parameter cache cleared');
  }
}

/**
 * Default Remote Config values for notifications
 * Used as fallbacks when Remote Config is not available
 */
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

/**
 * Factory function to get Remote Config service instance
 */
export function getRemoteConfigService(): RemoteConfigService {
  return RemoteConfigService.getInstance();
}

// =============================================================================
// SYNCHRONOUS CONFIG FUNCTIONS - For backward compatibility
// =============================================================================

// Simple Remote Config parameter cache (moved from config.ts)
let rcCache: RcCache | null = null;

async function fetchRcTemplateParams(): Promise<Record<string, string>> {
  try {
    // If admin is not initialized yet, skip RC fetch (index.ts will initialize)
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
// CONFIG FUNCTIONS - Remote Config related configuration getters
// =============================================================================

/**
 * Get premium monthly price in DZD from Remote Config
 */
export function getPremiumMonthlyDzd(): number {
  return getRcNumber('premium_monthly_price_dzd', Number(process.env.PREMIUM_MONTHLY_PRICE_DZD) || 450);
}

/**
 * Get premium yearly price in DZD from Remote Config
 */
export function getPremiumYearlyDzd(): number {
  return getRcNumber('premium_yearly_price_dzd', Number(process.env.PREMIUM_YEARLY_PRICE_DZD) || 4500);
}

/**
 * Get influencer commission rate from Remote Config
 */
export function getInfluencerCommissionRate(): number {
  return getRcNumber('influencer_commission_rate', Number(process.env.INFLUENCER_COMMISSION_RATE) || 0.15);
}

/**
 * Get influencer earn amount for code from Remote Config
 */
export function getInfluencerEarnForCode(): number {
  return getRcNumber('influencer_earn_for_code', Number(process.env.INFLUENCER_EARN_FOR_CODE) || 100);
}

/**
 * Get influencer withdrawal processing days from Remote Config
 */
export function getInfluencerWithdrawalProcessingDays(): number {
  return getRcNumber('influencer_withdrawal_processing_days', Number(process.env.INFLUENCER_WITHDRAWAL_PROCESSING_DAYS) || 3);
}

/**
 * Get success URL from Remote Config
 */
export function getSuccessUrl(): string {
  return getRcString('success_url', process.env.SUCCESS_URL || "https://macroaize.com/success");
}

/**
 * Get failure URL from Remote Config
 */
export function getFailureUrl(): string {
  return getRcString('failure_url', process.env.FAILURE_URL || "https://macroaize.com/failure");
}

/**
 * Get terms link from Remote Config
 */
export function getTermsLink(): string {
  return getRcString('terms_link', process.env.TERMS_LINK || 'https://macroaize.com/terms');
}

/**
 * Get privacy link from Remote Config
 */
export function getPrivacyLink(): string {
  return getRcString('privacy_link', process.env.PRIVACY_LINK || 'https://macroaize.com/privacy');
}

/**
 * Get Android share URL (Play Store) from Remote Config
 */
export function getShareUrlAndroid(): string {
  // Backward compat: prefer new RC key play_store_url
  const rc = getRcString('play_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_ANDROID || '';
}

/**
 * Get iOS share URL (App Store) from Remote Config
 */
export function getShareUrlIos(): string {
  // Backward compat: prefer new RC key app_store_url
  const rc = getRcString('app_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_IOS || '';
}

/**
 * Get scan limit from Remote Config
 */
export function getScanLimit(): number {
  return getRcNumber('scan_limit', Number(process.env.SCAN_LIMIT) || 1);
}

/**
 * Get chat limit from Remote Config
 */
export function getChatLimit(): number {
  return getRcNumber('chat_limit', Number(process.env.CHAT_LIMIT) || 3);
}

/**
 * Get minimum required app version from Remote Config
 */
export function getMinRequiredAppVersion(): string {
  return getRcString('min_required_app_version');
}

/**
 * Get update message from Remote Config
 */
export function getUpdateMessage(): string {
  return getRcString('update_message', 'A new version is required to continue using MacroAize.');
}

// =============================================================================
// SYNCHRONOUS WRAPPERS (for backward compatibility where needed)
// =============================================================================

/**
 * Get scan limit (synchronous version for existing code)
 */
export function getScanLimitCfg(): number {
  return getScanLimit();
}

/**
 * Get chat limit (synchronous version for existing code)
 */
export function getChatLimitCfg(): number {
  return getChatLimit();
}
