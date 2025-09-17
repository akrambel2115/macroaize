import { defineSecret } from 'firebase-functions/params';

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

/**
 * Get Chargily API URL from environment
 */
export function getChargilyApiUrl(): string {
  return process.env.CHARGILY_API_URL || "https://pay.chargily.net/test/api/v2";
}

/**
 * Get webhook tolerance in seconds from environment
 */
export function getWebhookToleranceSeconds(): number {
  return Number(process.env.WEBHOOK_TOLERANCE_SECONDS) || 300;
}

/**
 * Get minimum withdrawal amount for influencers from environment
 */
export function getInfluencerMinWithdrawal(): number {
  return Number(process.env.INFLUENCER_MIN_WITHDRAWAL) || 0;
}

/**
 * Get email address to send notifications to
 */
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

/**
 * Get email address to send notifications from
 */
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

/**
 * Get AI model identifier from environment
 */
export function getAiModel(): string {
  return process.env.AI_MODEL || 'mistralai/mistral-small-3.2-24b-instruct:free';
}

/**
 * Get Android In-App Purchase product IDs
 */
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

/**
 * Get iOS In-App Purchase product IDs
 */
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