import { defineSecret } from 'firebase-functions/params';

export const CHARGILY_SECRET_KEY = defineSecret('CHARGILY_SECRET_KEY');
export const CHARGILY_PUBLIC_KEY = defineSecret('CHARGILY_PUBLIC_KEY');

export const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
export const USDA_API_KEY = defineSecret('USDA_API_KEY');

// RevenueCat secrets
export const REVENUECAT_REST_API_KEY = defineSecret('REVENUECAT_REST_API_KEY');
export const REVENUECAT_WEBHOOK_SECRET = defineSecret('REVENUECAT_WEBHOOK_SECRET');

export const RIP_ENCRYPTION_KEY_V1 = defineSecret('RIP_ENCRYPTION_KEY_V1');

// Runtime config
export const REGION = 'europe-west1';

// Low CPU profile
export const LOW_CPU_OPTS = {
  region: REGION,
  cpu: 0.25 as const,
  memory: '256MiB' as const,
  concurrency: 20,
  maxInstances: 3,
  minInstances: 0,
  timeoutSeconds: 60,
};


// Notification recipient
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

// Notification sender
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

// AI model ID
export function getAiModel(): string {
  return process.env.AI_MODEL || 'mistralai/mistral-small-3.2-24b-instruct:free';
}

// Android IAP IDs
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

// iOS IAP IDs
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