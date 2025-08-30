import { defineSecret } from 'firebase-functions/params';

export const CHARGILY_SECRET_KEY = defineSecret('CHARGILY_SECRET_KEY');
export const CHARGILY_PUBLIC_KEY = defineSecret('CHARGILY_PUBLIC_KEY');


function envString(name: string, fallback: string): string {
  const v = process.env[name];
  return v != null && v !== "" ? v : fallback;
}

function envInt(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw == null || raw === "") return fallback;
  const n = Number(raw);
  return Number.isFinite(n) ? n : fallback;
}


export function getChargilyApiUrl(): string {
  return envString("CHARGILY_API_URL", "https://pay.chargily.net/test/api/v2");
}

export function getWebhookToleranceSeconds(): number {
  return envInt("WEBHOOK_TOLERANCE_SECONDS", 300); // default: 5 minutes
}

export function getPremiumMonthlyDzd(): number {
  return envInt("PREMIUM_MONTHLY_PRICE_DZD", 450); // default: 450 DZD
}

export function getPremiumYearlyDzd(): number {
  return envInt("PREMIUM_YEARLY_PRICE_DZD", 4500); // default: 4500 DZD
}

// Influencer program configuration
export function getInfluencerMinWithdrawal(): number {
  return envInt("INFLUENCER_MIN_WITHDRAWAL", 0); // default: 0 DZD
}

export function getInfluencerCommissionRate(): number {
  return parseFloat(process.env.INFLUENCER_COMMISSION_RATE || "0.15"); // 15%
}

export function getInfluencerFinanceEmail(): string {
  return envString("INFLUENCER_FINANCE_EMAIL", "belbakhoucheakram2115@gmail.com");
}

export function getInfluencerWithdrawalProcessingDays(): number {
  return envInt("INFLUENCER_WITHDRAWAL_PROCESSING_DAYS", 3);
}