import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';

export const CHARGILY_SECRET_KEY = defineSecret('CHARGILY_SECRET_KEY');
export const CHARGILY_PUBLIC_KEY = defineSecret('CHARGILY_PUBLIC_KEY');

export const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
export const USDA_API_KEY = defineSecret('USDA_API_KEY');

export const RIP_ENCRYPTION_KEY_V1 = defineSecret('RIP_ENCRYPTION_KEY_V1');

// Shared runtime configuration for Cloud Functions (Gen 2)
export const REGION = 'europe-west1';

// Low-CPU profile to keep total vCPU within Cloud Run regional quota
// Adjust memory/concurrency as needed per function load.
export const LOW_CPU_OPTS = {
  region: REGION,
  cpu: 0.25 as const,
  memory: '256MiB' as const,
  concurrency: 20,
  maxInstances: 3,
  minInstances: 0,
  timeoutSeconds: 60,
};

export function getChargilyApiUrl(): string {
  return process.env.CHARGILY_API_URL || "https://pay.chargily.net/test/api/v2";
}

export function getWebhookToleranceSeconds(): number {
  return Number(process.env.WEBHOOK_TOLERANCE_SECONDS) || 300;
}

export function getPremiumMonthlyDzd(): number {
  return getRcNumber('premium_monthly_price_dzd', Number(process.env.PREMIUM_MONTHLY_PRICE_DZD) || 450);
}

export function getPremiumYearlyDzd(): number {
  return getRcNumber('premium_yearly_price_dzd', Number(process.env.PREMIUM_YEARLY_PRICE_DZD) || 4500);
}

export function getInfluencerMinWithdrawal(): number {
  return Number(process.env.INFLUENCER_MIN_WITHDRAWAL) || 0;
}

export function getInfluencerCommissionRate(): number {
  return getRcNumber('influencer_commission_rate', Number(process.env.INFLUENCER_COMMISSION_RATE) || 0.15);
}

export function getInfluencerEarnForCode(): number {
  return getRcNumber('influencer_earn_for_code', Number(process.env.INFLUENCER_EARN_FOR_CODE) || 100);
}

export function getEmailToAddress(): string {
  const email = process.env.EMAIL_TO_ADDRESS;
  if (!email || email.trim() === '') {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('CRITICAL: EMAIL_TO_ADDRESS is required in production but not configured');
    }
    return "belbakhoucheakram2115@gmail.com"; // Development fallback
  }
  return email;
}

export function getEmailFromAddress(): string {
  const email = process.env.EMAIL_FROM_ADDRESS;
  if (!email || email.trim() === '') {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('CRITICAL: EMAIL_FROM_ADDRESS is required in production but not configured');
    }
    return "belbakhoucheakram2115@gmail.com"; // Development fallback
  }
  return email;
}

export function getInfluencerWithdrawalProcessingDays(): number {
  return getRcNumber('influencer_withdrawal_processing_days', Number(process.env.INFLUENCER_WITHDRAWAL_PROCESSING_DAYS) || 3);
}

export function getSuccessUrl(): string {
  return getRcString('success_url', process.env.SUCCESS_URL || "https://macroaize.com/success");
}

export function getFailureUrl(): string {
  return getRcString('failure_url', process.env.FAILURE_URL || "https://macroaize.com/failure");
}

export function getAiModel(): string {
  return process.env.AI_MODEL || 'mistralai/mistral-small-3.2-24b-instruct:free';
}

export function getTermsLink(): string {
  return getRcString('terms_link', process.env.TERMS_LINK || 'https://macroaize.com/terms');
}

export function getPrivacyLink(): string {
  return getRcString('privacy_link', process.env.PRIVACY_LINK || 'https://macroaize.com/privacy');
}

export function getShareUrlAndroid(): string {
  // Backward compat: prefer new RC key play_store_url
  const rc = getRcString('play_store_url');
  if (rc) return rc;
  return process.env.SHARE_URL_ANDROID || '';
}

export function getShareUrlIos(): string {
  // Backward compat: prefer new RC key app_store_url
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

export function getAndroidIapIds() {
  const monthly = process.env.ANDROID_IAP_MONTHLY;
  const yearly = process.env.ANDROID_IAP_YEARLY;
  
  if (process.env.NODE_ENV === 'production' && (!monthly || !yearly)) {
    throw new Error('CRITICAL: Android IAP IDs are required in production but not configured');
  }
  
  return {
    monthly: monthly || '',
    yearly: yearly || ''
  };
}

export function getIosIapIds() {
  const monthly = process.env.IOS_IAP_MONTHLY;
  const yearly = process.env.IOS_IAP_YEARLY;
  
  if (process.env.NODE_ENV === 'production' && (!monthly || !yearly)) {
    throw new Error('CRITICAL: iOS IAP IDs are required in production but not configured');
  }
  
  return {
    monthly: monthly || '',
    yearly: yearly || ''
  };
}

export function getMinRequiredAppVersion(): string {
  return getRcString('min_required_app_version');
}

export function getUpdateMessage(): string {
  return getRcString('update_message', 'A new version is required to continue using MacroAize.');
}

type RcCache = {
  params: Record<string, string>;
  fetchedAt: number;
  ttlMs: number;
};

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