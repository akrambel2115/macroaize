import * as admin from 'firebase-admin';

export interface UsageData {
    scanCount?: number;
    chatCount?: number;
    lastUsageDate?: admin.firestore.Timestamp | string | null;
}

export interface SubscriptionData {
    isPremium?: boolean;
    endDate?: admin.firestore.Timestamp | string;
    userId?: string;
    promoCodeUsed?: string;
    startDate?: admin.firestore.Timestamp | string;
    planType?: string;
    commissionProcessed?: boolean;
    commissionError?: string;
    provider?: string;
    status?: string;
    updatedAt?: admin.firestore.FieldValue;
}

export interface InfluencerData {
    promoCode?: string;
    isActive?: boolean;
    earningsDzd?: number;
    usersCount?: number;
    expirationDate?: admin.firestore.Timestamp | string;
}

export interface WithdrawalRecord {
    id: string;
    amount: number;
    ripMasked: string;
    requestedAt: Date | string;
    status: string;
    estimatedProcessingDate?: string;
    completedAt?: Date | string;
}
