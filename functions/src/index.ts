import { onCall, onRequest, CallableRequest } from 'firebase-functions/v2/https';
import { Request, Response } from 'express';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';

import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import axios from 'axios';
import crypto from 'crypto';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import { OPENROUTER_API_KEY, USDA_API_KEY, getEmailToAddress, getEmailFromAddress, getAiModel, getAndroidIapIds, getIosIapIds, REVENUECAT_WEBHOOK_SECRET } from './config';
import { encryptRip, decryptRip, maskRip, isValidRip } from './crypto_rip';
import { getNotificationService, NotificationPayload } from './notification_service';
import { getRemoteConfigService, DEFAULT_NOTIFICATION_CONFIG, getPremiumMonthlyDzd, getPremiumYearlyDzd, getInfluencerCommissionRate, getInfluencerEarnForCode, getInfluencerWithdrawalProcessingDays, getInfluencerMinWithdrawal, getSuccessUrl, getFailureUrl, getScanLimitCfg, getChatLimitCfg, getTermsLink, getPrivacyLink, getShareUrlAndroid, getShareUrlIos, getMinRequiredAppVersion, getUpdateMessage, getSubscriptionsEnabled } from './remote_config_service';

dayjs.extend(utc);
dayjs.extend(timezone);

admin.initializeApp();

const db = getFirestore();

// Remote config manages usage limits.

export const RIP_ENCRYPTION_KEY_V1 = defineSecret('RIP_ENCRYPTION_KEY_V1');

interface UsageData {
  scanCount?: number;
  chatCount?: number;
  lastUsageDate?: FirebaseFirestore.Timestamp | string | null;
}

interface SubscriptionData {
  isPremium?: boolean;
  endDate?: FirebaseFirestore.Timestamp | string;
  userId?: string;
  promoCodeUsed?: string;
  startDate?: FirebaseFirestore.Timestamp | string;
  planType?: string;
  commissionProcessed?: boolean;
  commissionError?: string;
  provider?: string;
  status?: string;
  updatedAt?: FirebaseFirestore.FieldValue;
}

export interface InfluencerData {
  promoCode?: string;
  isActive?: boolean;
  earningsDzd?: number;
  usersCount?: number;
  expirationDate?: FirebaseFirestore.Timestamp | string;
}

// Unused interface - keeping for potential future use
// interface WebhookEvent {
//   id?: string;
//   type?: string;
//   event?: string;
//   payload?: any;
//   data?: {
//     id?: string;
//     amount?: number;
//     currency?: string;
//     status?: string;
//     metadata?: {
//       userId?: string;
//       planType?: string;
//       promoCode?: string;
//       originalAmount?: number;
//     };
//   };
// }

interface WithdrawalRecord {
  id: string;
  amount: number;
  ripMasked: string;
  requestedAt: Date | string;
  status: string;
  estimatedProcessingDate?: string;
  completedAt?: Date | string;
}

// Type-safe helpers for Firestore Timestamp handling
function toDate(dateValue: FirebaseFirestore.Timestamp | string | Date | null | undefined): Date | null {
  if (!dateValue) return null;
  if (dateValue instanceof Date) return dateValue;
  if (typeof dateValue === 'string') return new Date(dateValue);
  if (typeof dateValue === 'object' && 'toDate' in dateValue && typeof dateValue.toDate === 'function') {
    return dateValue.toDate();
  }
  return null;
}

function toDayjs(dateValue: FirebaseFirestore.Timestamp | string | Date | null | undefined): dayjs.Dayjs | null {
  const date = toDate(dateValue);
  return date ? dayjs(date) : null;
}

// Helpers and other functions remain the same...
// Unused function - keeping for potential future use
// function planAmountDzd(planType: string): number {
//   if (planType === 'yearly') return getPremiumYearlyDzd();
//   return getPremiumMonthlyDzd();
// }
export function addDuration(start: dayjs.Dayjs, planType: string): dayjs.Dayjs {
  return planType === 'yearly' ? start.add(1, 'year') : start.add(1, 'month');
}
function safeNow(): dayjs.Dayjs {
  return dayjs().utc();
}
// Unused function - keeping for potential future use
// function verifyHmac(signatureHeader: string | undefined, payload: string, secret: string): boolean {
//   if (!signatureHeader) return false;
//   try {
//     const expected = crypto.createHmac('sha256', secret).update(payload, 'utf8').digest('hex');
//     const sigBuf = Buffer.from(signatureHeader, 'hex');
//     const expBuf = Buffer.from(expected, 'hex');
//     if (sigBuf.length !== expBuf.length) return false;
//     return crypto.timingSafeEqual(sigBuf, expBuf);
//   } catch (e) {
//     return false;
//   }
// }

/**
 * Validates that the request is from an authenticated admin user
 * @param request - The callable request
 * @throws Error if not authenticated or not an admin
 */
function requireAdmin(request: CallableRequest): void {
  const uid = request.auth?.uid;
  const isAdmin = request.auth?.token?.admin === true || request.auth?.token?.role === 'admin';
  
  if (!uid) {
    throw new Error('unauthenticated');
  }
  
  if (!isAdmin) {
    throw new Error('permission-denied');
  }
}

/**
 * Creates a structured error with logging
 * @param message - User-safe error message
 * @param details - Internal error details for logging
 * @param correlationId - Request correlation ID
 */
function createStructuredError(message: string, details: any, correlationId?: string): Error {
  logger.error('Structured error occurred', {
    userMessage: message,
    details,
    correlationId,
    timestamp: new Date().toISOString()
  });
  return new Error(message);
}

/**
 * Validates request size to prevent DoS attacks
 * @param data - Request data to validate
 * @param maxSizeKB - Maximum size in KB (default 10KB)
 */
function validateRequestSize(data: any, maxSizeKB: number = 10): boolean {
  try {
    const serialized = JSON.stringify(data);
    const sizeKB = serialized.length / 1024;
    return sizeKB <= maxSizeKB;
  } catch {
    return false;
  }
}

/**
 * Validates and sanitizes AI-generated JSON responses to prevent data poisoning
 * @param jsonString - Raw JSON string from AI
 * @param schema - Expected schema type ('nutrition' | 'mealItems')
 * @returns Validated and sanitized object
 */
function validateAiJsonResponse(jsonString: string, schema: 'nutrition' | 'mealItems'): any {
  try {
    // Basic sanitization - remove code fences and trim
    let cleaned = jsonString.trim();
    if (cleaned.includes('```')) {
      const start = cleaned.indexOf('```');
      const end = cleaned.lastIndexOf('```');
      if (end > start) {
        cleaned = cleaned.substring(start + 3, end).trim();
        if (cleaned.startsWith('json')) {
          cleaned = cleaned.substring(4).trimLeft();
        }
      }
    }

    const parsed = JSON.parse(cleaned);
    
    if (schema === 'nutrition') {
      return validateNutritionSchema(parsed);
    } else if (schema === 'mealItems') {
      return validateMealItemsSchema(parsed);
    }
    
    throw new Error('Unknown schema type');
  } catch (error) {
    logger.warn('AI JSON validation failed', {
      error: error instanceof Error ? error.message : String(error),
      schema,
      input: jsonString.substring(0, 200) // Log first 200 chars for debugging
    });
    
    // Return safe fallback based on schema
    if (schema === 'nutrition') {
      return {
        food_name: 'Unknown Food',
        food_name_english: 'Unknown Food',
        calories: 0,
        protein_g: 0,
        carbohydrates_g: 0,
        fats_g: 0
      };
    } else {
      return { mealItems: [] };
    }
  }
}

/**
 * Validates nutrition analysis response schema
 */
function validateNutritionSchema(data: any): any {
  if (!data || typeof data !== 'object') {
    throw new Error('Invalid nutrition data structure');
  }

  // Clamp numeric values to reasonable ranges
  const clampNumber = (value: any, min: number = 0, max: number = 10000): number => {
    const num = Number(value) || 0;
    return Math.max(min, Math.min(max, Math.round(num)));
  };

  // Sanitize string values
  const sanitizeString = (value: any, maxLength: number = 100): string => {
    const str = String(value || '').trim();
    return str.substring(0, maxLength);
  };

  return {
    food_name: sanitizeString(data.food_name, 200),
    food_name_english: sanitizeString(data.food_name_english, 200),
    calories: clampNumber(data.calories),
    protein_g: clampNumber(data.protein_g),
    carbohydrates_g: clampNumber(data.carbohydrates_g),
    fats_g: clampNumber(data.fats_g)
  };
}

/**
 * Validates meal items breakdown response schema
 */
function validateMealItemsSchema(data: any): any {
  if (!data || typeof data !== 'object') {
    throw new Error('Invalid meal items data structure');
  }

  const mealItems = Array.isArray(data.mealItems) ? data.mealItems : [];
  const validatedItems = mealItems.slice(0, 20).map((item: any) => { // Limit to 20 items max
    if (!item || typeof item !== 'object') return null;

    const clampNumber = (value: any, min: number = 0, max: number = 10000): number => {
      const num = Number(value) || 0;
      return Math.max(min, Math.min(max, Math.round(num)));
    };

    const sanitizeString = (value: any, maxLength: number = 100): string => {
      const str = String(value || '').trim();
      return str.substring(0, maxLength);
    };

    const portionType = String(item.portionType || '').toLowerCase();
    const validPortionTypes = ['pieces', 'grams'];
    const safePortionType = validPortionTypes.includes(portionType) ? portionType : 'grams';

    return {
      name: sanitizeString(item.name, 200),
      english_name: sanitizeString(item.english_name, 200),
      portionType: safePortionType,
      count: safePortionType === 'pieces' ? clampNumber(item.count, 1, 100) : undefined,
      estimatedWeight: clampNumber(item.estimatedWeight, 1, 5000) // Max 5kg per item
    };
  }).filter((item: any) => item !== null);

  return {
    mealItems: validatedItems
  };
}

// Unused function - keeping for potential future use
// /**
//  * Creates enhanced audit log with performance metrics
//  */
// function createAuditLog(baseData: any, correlationId: string, duration?: number) {
//   return {
//     ...baseData,
//     timestamp: FieldValue.serverTimestamp(),
//     correlationId,
//     duration,
//     region: 'europe-west1'
//   };
// }

// testAuth function removed to reduce CPU quota usage

/*
// CHARGILY PAYMENT CREATION - COMMENTED OUT FOR REVENUECAT-ONLY IMPLEMENTATION
export const createChargilyPayment = onCall({
  region: 'europe-west1',
  secrets: [CHARGILY_SECRET_KEY]
}, async (request: CallableRequest) => {
  const startTime = Date.now();
  const correlationId = crypto.randomUUID();
  
  const authedUid = request.auth?.uid;
  if (!authedUid) {
    throw createStructuredError('unauthenticated', 'No authenticated user', correlationId);
  }

  // Request validation
  if (!validateRequestSize(request.data, 5)) {
    throw createStructuredError('invalid-argument', 'Request too large', correlationId);
  }

  const userId = request.data?.userId as string | undefined;
  const planType = (request.data?.planType as string | undefined)?.toLowerCase();
  const clientTimestamp = request.data?.timestamp;
  const promoCode = (request.data?.promoCode as string || '').toUpperCase().trim();

  logger.info('Processing payment request', {
    correlationId,
    userId: authedUid,
    planType,
    hasPromoCode: !!promoCode
  });

  // Enhanced audit log entry
  const auditLogData = createAuditLog({
    action: 'payment_attempt',
    userId: authedUid,
    requestedUserId: userId,
    planType,
    clientTimestamp,
    ip: request.rawRequest.ip || 'unknown',
    userAgent: request.rawRequest.headers['user-agent'] || 'unknown',
    requestSize: JSON.stringify(request.data).length
  }, correlationId);

  if (!userId || userId !== authedUid) {
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'permission_denied',
      reason: 'userId mismatch'
    });
    throw new Error('permission-denied');
  }
  if (planType !== 'monthly' && planType !== 'yearly') {
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'invalid_argument',
      reason: 'invalid plan type'
    });
    throw new Error('invalid-argument');
  }

  // SECURITY CHECK: Verify user doesn't already have an active subscription
  try {
    const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();
    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      if (subscriptionData) {
        const now = safeNow();
        const endDate = subscriptionData.endDate ? dayjs(subscriptionData.endDate) : null;
        const isActive = subscriptionData.isPremium === true && endDate && endDate.isAfter(now);
        
        if (isActive) {
          console.warn(`User ${userId} attempted to purchase while having active subscription until ${endDate.toISOString()}`);
          
          await db.collection('audit_logs').add({
            ...auditLogData,
            result: 'already_subscribed',
            existingEndDate: endDate.toISOString(),
            reason: 'active subscription exists'
          });
          
          throw new Error('already-subscribed');
        }
      }
    }
  } catch (error) {
    if (error instanceof Error && error.message === 'already-subscribed') {
      throw error;
    }
    
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'internal_error',
      reason: 'subscription check failed',
      error: error instanceof Error ? error.message : String(error)
    });
    
    console.error('Error checking existing subscription:', error);
    throw new Error('internal');
  }

  let amountDzd = planAmountDzd(planType);
  let discountApplied = false;

  // Apply promo code discount if provided
  if (promoCode && isValidPromoCode(promoCode)) {
    try {
      // Validate promo code
      const influencersQuery = await db.collection('influencers')
        .where('promoCode', '==', promoCode)
        .where('isActive', '==', true)
        .limit(1)
        .get();

      if (!influencersQuery.empty) {
        const influencerDoc = influencersQuery.docs[0];
        const influencerData = influencerDoc.data();

        // Check expiration
        const expirationDate = influencerData.expirationDate?.toDate?.() || new Date(influencerData.expirationDate);
        if (!expirationDate || expirationDate > new Date()) {
          // Check if user has already used this promo code
          const existingSubscription = await db.collection('subscriptions')
            .where('userId', '==', userId)
            .where('promoCodeUsed', '==', promoCode)
            .limit(1)
            .get();

          if (existingSubscription.empty) {
            // Apply discount
            const discountRate = getInfluencerCommissionRate();
            amountDzd = Math.round(amountDzd * (1 - discountRate));
            discountApplied = true;
          }
        }
      }
    } catch (error) {
      // Continue without discount if promo code validation fails
      console.warn('Promo code validation failed during payment creation:', error);
    }
  }

  const secret = CHARGILY_SECRET_KEY.value();
  if (!secret) {
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'internal_error',
      reason: 'missing secret key'
    });
    throw new Error('internal: missing secret');
  }

  const apiUrl = getChargilyApiUrl();
  const body = {
    amount: amountDzd,
    currency: 'dzd',
    metadata: { 
      userId, 
      planType,
      ...(promoCode && discountApplied ? { promoCode, originalAmount: planAmountDzd(planType) } : {})
    },
  success_url: getSuccessUrl(),
  failure_url: getFailureUrl()
  };

  try {
    const res = await axios.post(`${apiUrl}/checkouts`, body, {
      headers: {
        'Authorization': `Bearer ${secret}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    const checkoutUrl = res.data?.checkout_url || res.data?.checkout_url_mobile || res.data?.link;
    if (!checkoutUrl) {
      await db.collection('audit_logs').add({
        ...auditLogData,
        result: 'chargily_error',
        reason: 'no checkout URL returned',
        chargilyResponse: JSON.stringify(res.data)
      });
      throw new Error('No checkout URL returned by Chargily');
    }

    // Log successful payment creation
    const duration = Date.now() - startTime;
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'success',
      amount: amountDzd,
      checkoutCreated: true,
      duration
    });

    logger.info('Payment checkout created successfully', {
      correlationId,
      userId: authedUid,
      duration,
      amount: amountDzd
    });

    return { checkoutUrl };
  } catch (err: unknown) {
    const error = err instanceof Error ? err : new Error(String(err));
    const errorInfo = error.message || 'Unknown error';
    
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'chargily_error',
      reason: 'API request failed',
      error: errorInfo
    });
    
    console.error('Chargily create checkout failed', errorInfo);
    throw new Error('internal');
  }
});
*/


// Usage tracking
export const incrementUsage = onCall({
  region: 'europe-west1'
}, async (request: CallableRequest) => {
  const authedUid = request.auth?.uid;
  if (!authedUid) {
    throw new Error('unauthenticated');
  }

  const actionType = request.data?.actionType as string | undefined;
  
  if (!actionType || !['scan', 'chat'].includes(actionType)) {
    throw new Error('invalid-argument');
  }

  // If user is premium allow unlimited usage
  try {
    const subscriptionDoc = await db.collection('subscriptions').doc(authedUid).get();
    if (subscriptionDoc.exists) {
      const subscriptionData = subscriptionDoc.data();
      if (subscriptionData) {
        const now = safeNow();
        const endDate = subscriptionData.endDate ? dayjs(subscriptionData.endDate) : null;
        const isActive = subscriptionData.isPremium === true && endDate && endDate.isAfter(now);
        
        if (isActive) {
          // Premium user - no limits
          return { success: true, isPremium: true, message: 'Premium user - unlimited access' };
        }
      }
    }
  } catch (error) {
    console.error('Error checking subscription status:', error);
    throw new Error('internal');
  }

  // Non-premium: check and increment usage
  const usageRef = db.collection('user_usage').doc(authedUid);
  const todayStart = safeNow().startOf('day');
  
  // Limits from Remote Config (server-of-record values)
  const SCAN_LIMIT = getScanLimitCfg();
  const CHAT_LIMIT = getChatLimitCfg();

  try {
    const result = await db.runTransaction(async (transaction) => {
      const usageDoc = await transaction.get(usageRef);
      const usageData = usageDoc.exists ? usageDoc.data() : null;
      
      let scanCount = 0;
      let chatCount = 0;
      
      if (usageData) {
        const typedUsageData = usageData as UsageData;
        const lastUsageRaw = typedUsageData.lastUsageDate;
        const lastUsageDate: Date | null = lastUsageRaw
          ? (typeof lastUsageRaw === 'object' && lastUsageRaw !== null && 'toDate' in lastUsageRaw 
              ? (lastUsageRaw as FirebaseFirestore.Timestamp).toDate() 
              : new Date(lastUsageRaw as string))
          : null;
        const lastUsageDayStart = lastUsageDate ? dayjs(lastUsageDate).startOf('day') : null;

        if (lastUsageDayStart && lastUsageDayStart.isSame(todayStart)) {
          // Same day - use existing counts
          scanCount = typedUsageData.scanCount ?? 0;
          chatCount = typedUsageData.chatCount ?? 0;
        }
        // If different day, counts remain 0 (reset)
      }
      
  // Check and increment usage counts
      if (actionType === 'scan') {
        if (scanCount >= SCAN_LIMIT) {
          throw new Error('permission-denied');
        }
        scanCount++;
      } else if (actionType === 'chat') {
        if (chatCount >= CHAT_LIMIT) {
          throw new Error('permission-denied');
        }
        chatCount++;
      }
      
      // Update usage
      transaction.set(usageRef, {
        scanCount,
        chatCount,
        lastUsageDate: FieldValue.serverTimestamp(),
        userId: authedUid,
        updatedAt: FieldValue.serverTimestamp()
      }, { merge: true });
      
      return { scanCount, chatCount, actionType };
    });
    
    return { 
      success: true, 
      isPremium: false,
      currentUsage: {
        scanCount: result.scanCount,
        chatCount: result.chatCount,
        scanLimit: SCAN_LIMIT,
        chatLimit: CHAT_LIMIT
      },
      message: `${actionType} allowed. Usage incremented.`
    };
    
  } catch (error) {
    if (error instanceof Error && error.message === 'permission-denied') {
      const limitType = actionType === 'scan' ? 'scan' : 'chat';
  const limit = actionType === 'scan' ? SCAN_LIMIT : CHAT_LIMIT;
  throw new Error(`Daily ${limitType} limit reached (${limit}/${limit}). Upgrade to Premium for unlimited access.`);
    }
    
    console.error('Error in incrementUsage transaction:', error);
    throw new Error('internal');
  }
});

// Combined daily maintenance job: resets daily usage and expires invalid subscriptions
export const dailyMaintenance = onSchedule({
  region: 'europe-west1',
  schedule: '0 0 * * *', // Daily at 00:00 Africa/Algiers
  timeZone: 'Africa/Algiers'
}, async () => {
  const jobStart = Date.now();
  const correlationId = crypto.randomUUID();
  logger.info('Starting dailyMaintenance job', { correlationId });

  // Phase 1: Reset all daily usage
  try {
    const startTime = Date.now();
    const collectionRef = db.collection('user_usage');

    let processed = 0;
    let page = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;
    const maxPages = 1000;

    while (page < maxPages) {
      const query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = lastDoc
        ? collectionRef.orderBy(admin.firestore.FieldPath.documentId()).startAfter(lastDoc.id).limit(500)
        : collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(500);

      const snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData> = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      snapshot.docs.forEach((doc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>) => {
        batch.update(doc.ref, {
          scanCount: 0,
          chatCount: 0,
          lastUsageDate: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp()
        });
        processed++;
      });

      await batch.commit();
      page++;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    const duration = Date.now() - startTime;
    logger.info('Completed dailyMaintenance phase: resetAllDailyUsage', { correlationId, totalProcessed: processed, totalPages: page, duration });
  } catch (error) {
    console.error('Error in dailyMaintenance resetAllDailyUsage phase:', error);
  }

  // Phase 2: Expire invalid subscriptions
  try {
    const startTime = Date.now();
    const collectionRef = db.collection('subscriptions');
    const now = safeNow();

    let processed = 0;
    let updated = 0;
    let page = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;
    const maxPages = 1000; // Safety limit

    while (page < maxPages) {
      const query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = lastDoc
        ? collectionRef.orderBy(admin.firestore.FieldPath.documentId()).startAfter(lastDoc.id).limit(500)
        : collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(500);

      const snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData> = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();
      let writesInBatch = 0;

      snapshot.docs.forEach((doc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>) => {
        const data = doc.data() as SubscriptionData;
        const isPremium: boolean = data?.isPremium === true;
        if (!isPremium) { processed++; return; }

        const start = data?.startDate ? toDayjs(data.startDate) : null;
        const end = data?.endDate ? toDayjs(data.endDate) : null;

        let shouldExpire = false;
        if (!end) {
          // No end date but marked premium -> expire defensively
          shouldExpire = true;
        } else {
          // Invalid range: start >= end
          if (start && (start.isAfter(end) || start.isSame(end))) {
            shouldExpire = true;
          }
          // End date passed
          if (!shouldExpire && end.isBefore(now)) {
            shouldExpire = true;
          }
        }

        if (shouldExpire) {
          batch.set(doc.ref, {
            isPremium: false,
            status: 'expired',
            updatedAt: FieldValue.serverTimestamp()
          }, { merge: true });
          updated++;
          writesInBatch++;
        }
        processed++;
      });

      if (writesInBatch > 0) {
        await batch.commit();
      }
      page++;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      logger.info('Expiry batch completed', { correlationId, page, batchSize: snapshot.docs.length, totalProcessed: processed, totalUpdated: updated });
    }

    const duration = Date.now() - startTime;
    logger.info('Completed dailyMaintenance phase: expireInvalidSubscriptions', { correlationId, totalProcessed: processed, totalUpdated: updated, totalPages: page, duration });
  } catch (error) {
    console.error('Error in dailyMaintenance expireInvalidSubscriptions phase:', error);
    // Allow function to succeed to avoid repeated retries of the whole job
  }

  // Phase 3: Send daily reset notification to all users
  try {
    const startTime = Date.now();
    
    // Get all users for daily reset notification
    const usersQuery = await db.collection('users')
      .limit(1000) // Process in batches
      .get();

    if (!usersQuery.empty) {
      const remoteConfig = getRemoteConfigService();
      const notificationService = getNotificationService();
      
      // Get daily reset message from Remote Config
      const resetMessage = await remoteConfig.getNotificationMessage(
        'notification_daily_reset_msg',
        DEFAULT_NOTIFICATION_CONFIG.notification_daily_reset_msg
      );

      const resetPayload: NotificationPayload = {
        title: 'Daily Limits Reset! ✨',
        body: resetMessage,
        data: {
          type: 'daily_reset'
        }
      };

      const userIds = usersQuery.docs.map(doc => doc.id);
      const successCount = await notificationService.sendNotificationToUsers(userIds, resetPayload);
      
      const duration = Date.now() - startTime;
      logger.info('Completed dailyMaintenance phase: sendDailyResetNotification', { 
        correlationId, 
        totalUsers: userIds.length, 
        successCount, 
        duration 
      });
    } else {
      logger.info('No users found for daily reset notification', { correlationId });
    }
  } catch (error) {
    console.error('Error in dailyMaintenance sendDailyResetNotification phase:', error);
    // Allow function to succeed to avoid repeated retries of the whole job
  }

  logger.info('Finished dailyMaintenance job', { correlationId, totalDuration: Date.now() - jobStart });
});
 
// Promo code tracking helpers

// Unused function - keeping for potential future use
// // Helper for promo code validation
// function validatePromoCodeForTracking(promoCode: string, influencerData: InfluencerData): boolean {
//   // Validate promo code format
//   if (!isValidPromoCode(promoCode)) {
//     console.warn(`Invalid promo code format: ${promoCode}`);
//     return false;
//   }
// 
//   // Check expiration
//   const expirationDate = toDate(influencerData.expirationDate);
//   if (expirationDate && expirationDate < new Date()) {
//     console.warn(`Expired promo code: ${promoCode}`);
//     return false;
//   }
// 
//   return true;
// }

/*
// CHARGILY WEBHOOK - COMMENTED OUT FOR REVENUECAT-ONLY IMPLEMENTATION
// Chargily webhook

export const chargilyWebhook = onRequest({
  region: 'europe-west1',
  secrets: [CHARGILY_SECRET_KEY]
}, async (req: Request, res: Response) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  // Use rawBody for HMAC integrity
  const hasRaw = 'rawBody' in req;
  const rawBodyBuffer: Buffer = hasRaw ? (req as any).rawBody as Buffer : Buffer.from(typeof req.body === 'string' ? req.body : JSON.stringify(req.body), 'utf8');
  const rawBody = rawBodyBuffer.toString('utf8');
  const signature = req.get?.('x-chargily-signature') || req.get?.('signature') || req.headers['x-chargily-signature'] || req.headers['signature'] || '';
  
  // Ensure signature is a string
  const signatureString = Array.isArray(signature) ? signature[0] : (signature || '');

  // Optional replay protection using timestamp header
  const tsHeader = (req.get?.('x-chargily-timestamp') || req.headers['x-chargily-timestamp'] || req.get?.('date') || req.headers['date']) as string | undefined;
  if (tsHeader) {
    const tolerance = getWebhookToleranceSeconds();
    let tsSeconds: number | null = null;
    // Support unix seconds or ISO date
    if (/^\d+$/.test(tsHeader)) {
      tsSeconds = parseInt(tsHeader, 10);
    } else {
      const parsed = Date.parse(tsHeader);
      if (!Number.isNaN(parsed)) tsSeconds = Math.floor(parsed / 1000);
    }
    if (tsSeconds != null) {
      const nowSec = Math.floor(Date.now() / 1000);
      if (Math.abs(nowSec - tsSeconds) > tolerance) {
        res.status(400).send('stale');
        return;
      }
    }
  }

  const secret = CHARGILY_SECRET_KEY.value() || '';

  if (!verifyHmac(signatureString, rawBody, secret)) {
    console.warn('Invalid webhook signature');
    res.status(403).send('Invalid signature');
    return;
  }

  let event: WebhookEvent;
  try {
    event = typeof req.body === 'string' ? JSON.parse(req.body) : req.body as WebhookEvent;
  } catch (e) {
    console.error('Invalid JSON body');
    res.status(400).send('Bad Request');
    return;
  }
  try {
  const type = event?.type || event?.event || 'unknown';
    const data = event?.data || event?.payload || {};
    const status = data?.status || data?.payment?.status;
    const metadata = data?.metadata || {};
    const eventId: string | undefined = event?.id || data?.id || data?.payment_id || data?.checkout_id;

  // Idempotency: ensure single processing per eventId
    if (eventId) {
      const processedRef = db.collection('webhook_events').doc(eventId);
      const processedSnap = await processedRef.get();
      if (processedSnap.exists) {
        res.status(200).send('duplicate');
        return;
      }
      await processedRef.set({ receivedAt: FieldValue.serverTimestamp(), type, status }, { merge: true });
    }

    if (status === 'paid') {
      const userId = metadata.userId as string | undefined;
      const planType = (metadata.planType as string | undefined)?.toLowerCase() || 'monthly';
      const promoCode = metadata.promoCode as string | undefined;
      const originalAmount = metadata.originalAmount as number | undefined;
      
      if (!userId) {
        console.error('Missing userId in metadata');
        res.status(400).send('Bad Request');
        return;
      }

      const now = safeNow();
      const subRef = db.collection('subscriptions').doc(userId);

  // Pre-fetch influencer data if promo code provided
      let influencerData: { id: string; data: InfluencerData } | null = null;
      if (promoCode && originalAmount) {
        try {
          // Find influencer
          const influencersQuery = await db.collection('influencers')
            .where('promoCode', '==', promoCode)
            .where('isActive', '==', true)
            .limit(1)
            .get();

          if (!influencersQuery.empty) {
            const influencerDoc = influencersQuery.docs[0];
            const data = influencerDoc.data();
            
            // Validate promo code
            if (validatePromoCodeForTracking(promoCode, data)) {
              // Check for duplicate usage
              const existingUsage = await db.collection('influencer_audit')
                .where('details.promoCode', '==', promoCode)
                .where('details.subscriptionUserId', '==', userId)
                .where('action', '==', 'commission_earned')
                .limit(1)
                .get();

              if (existingUsage.empty) {
                influencerData = { id: influencerDoc.id, data };
                console.log(`Found valid influencer for promo code: ${promoCode} -> ${influencerDoc.id}`);
              } else {
                console.warn(`Duplicate promo usage detected: ${promoCode} by user ${userId}`);
              }
            }
          } else {
            console.warn(`No active influencer found for promo code: ${promoCode}`);
          }
        } catch (error) {
          console.error('Error pre-fetching influencer data:', error);
        }
      }

      try {
        await db.runTransaction(async (tx) => {
          // ALL READS MUST HAPPEN FIRST
          const snap = await tx.get(subRef);
          
          // Read influencer data if needed
          let currentInfluencer: FirebaseFirestore.DocumentSnapshot | null = null;
          if (influencerData && promoCode && originalAmount) {
            const influencerRef = db.collection('influencers').doc(influencerData.id);
            currentInfluencer = await tx.get(influencerRef);
          }
          
          // Process subscription
          const existing = snap.exists ? snap.data() as SubscriptionData : null;
          const prevEnd = existing?.endDate ? toDayjs(existing.endDate) : null;
          // Renewals: extend remaining time if subscription still active
          const start = prevEnd && prevEnd.isAfter(now) ? prevEnd : now;
          const end = addDuration(start, planType);

          // Idempotent-ish: if existing endDate is same or after desired end, skip write
          if (prevEnd && (prevEnd.isSame(end) || prevEnd.isAfter(end))) return;

          const subscriptionData: SubscriptionData = {
            userId,
            isPremium: true,
            planType,
            startDate: start.toISOString(),
            endDate: end.toISOString(),
            provider: 'chargily',
            status: 'active',
            updatedAt: FieldValue.serverTimestamp()
          };

          // Add promo code to subscription
          if (promoCode) {
            subscriptionData.promoCodeUsed = promoCode;
            subscriptionData.commissionProcessed = false; // Will be updated if successful
          }

          // Track promo code commission
          if (influencerData && promoCode && originalAmount && currentInfluencer?.exists) {
            try {
              const earnAmount = getInfluencerEarnForCode();
              
              if (earnAmount > 0) {
                const data = currentInfluencer.data()!;
                const newEarnings = Math.max(0, (data.earningsDzd || 0)) + earnAmount;
                const newTotalEarnings = Math.max(0, (data.totalEarningsDzd || 0)) + earnAmount;
                const newUsersCount = Math.max(0, (data.usersCount || 0)) + 1;

                // Update influencer data
                const influencerRef = db.collection('influencers').doc(influencerData.id);
                tx.update(influencerRef, {
                  earningsDzd: newEarnings,
                  totalEarningsDzd: newTotalEarnings,
                  usersCount: newUsersCount,
                  lastEarningDate: FieldValue.serverTimestamp(),
                  updatedAt: FieldValue.serverTimestamp()
                });

                // Create audit log
                tx.create(db.collection('influencer_audit').doc(), {
                  userId: influencerData.id,
                  action: 'commission_earned',
                  amount: earnAmount,
                  details: {
                    promoCode,
                    subscriptionUserId: userId,
                    subscriptionAmount: originalAmount,
                    earnAmount,
                    previousEarnings: data.earningsDzd || 0,
                    newEarnings,
                    previousUsersCount: data.usersCount || 0,
                    newUsersCount,
                    paymentProcessedAt: FieldValue.serverTimestamp(),
                    webhookEventId: eventId || 'unknown'
                  },
                  timestamp: FieldValue.serverTimestamp(),
                  status: 'completed',
                  source: 'webhook'
                });

                subscriptionData.commissionProcessed = true;
                
                console.log(`Successfully tracked promo usage: ${promoCode} -> ${influencerData.id} earned ${earnAmount} DZD`);
              }
            } catch (promoError) {
              console.error('Error processing promo code commission:', {
                error: promoError instanceof Error ? promoError.message : String(promoError),
                promoCode,
                userId,
                eventId
              });
              
              // Log the failure for investigation
              tx.create(db.collection('influencer_audit').doc(), {
                userId: 'system',
                action: 'commission_failed',
                amount: 0,
                details: {
                  promoCode,
                  subscriptionUserId: userId,
                  error: promoError instanceof Error ? promoError.message : String(promoError),
                  webhookEventId: eventId || 'unknown'
                },
                timestamp: FieldValue.serverTimestamp(),
                status: 'failed',
                source: 'webhook'
              });
              
              // Update subscription to reflect failed commission processing
              subscriptionData.commissionProcessed = false;
              subscriptionData.commissionError = promoError instanceof Error ? promoError.message : String(promoError);
            }
          }

          // Persist subscription data
          tx.set(subRef, subscriptionData, { merge: true });
        });
      } catch (e) {
        console.error('Firestore transaction failed', e);
        res.status(500).send('error');
        return;
      }

      res.status(200).send('ok');
      return;
    }

    // Handle cancellations/refunds/failed payments by marking subscription inactive
    if (status === 'refunded' || status === 'canceled' || status === 'cancelled' || status === 'failed') {
      const userId = (event?.data?.metadata?.userId) || (event?.payload?.metadata?.userId);
      if (userId) {
        const subRef = db.collection('subscriptions').doc(String(userId));
        await subRef.set({
          status: 'canceled',
          isPremium: false,
          updatedAt: FieldValue.serverTimestamp(),
          provider: 'chargily'
        }, { merge: true });
      }
      res.status(200).send('ok');
      return;
    }

    // For failed or pending or other statuses, optionally log
    res.status(200).send('ignored');
  } catch (e) {
    console.error('Webhook processing error', e);
    res.status(500).send('error');
  }
});
*/
// END CHARGILY WEBHOOK COMMENT BLOCK

// RevenueCat webhook (Phase 3 skeleton): validates signature and records event
export const revenuecatWebhook = onRequest(
  {
    region: 'europe-west1',
    secrets: [REVENUECAT_WEBHOOK_SECRET],
  },
  async (req: Request, res: Response) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const authHeader = req.get('Authorization') || req.headers['authorization'];
    const expected = `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`;

    if (authHeader !== expected) {
      logger.warn('RevenueCat invalid authorization');
      res.status(403).send('Forbidden');
      return;
    }

    let event: any;
    try {
      event = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    } catch (e) {
      res.status(400).send('Bad Request');
      return;
    }

    const eventId: string = String(
      event?.event_timestamp_ms ||
        event?.event?.id ||
        event?.id ||
        crypto.randomUUID()
    );

    try {
      const processedRef = db.collection('webhook_events').doc(`rc_${eventId}`);
      const processedSnap = await processedRef.get();
      if (processedSnap.exists) {
        res.status(200).send('duplicate');
        return;
      }
      await processedRef.set(
        {
          receivedAt: FieldValue.serverTimestamp(),
          provider: 'revenuecat',
          type: (event?.event?.type || event?.type || 'unknown').toString(),
        },
        { merge: true }
      );
    } catch (e) {
      logger.error('Failed to store RevenueCat event', e as any);
      res.status(500).send('error');
      return;
    }

    try {
      const ev = event?.event || event || {};
      const typeRaw = String(ev?.type || event?.type || 'unknown').toUpperCase();
      const uidRaw: string | undefined =
        ev?.app_user_id || event?.app_user_id || ev?.appUserId || event?.appUserId;
      const uid = uidRaw && typeof uidRaw === 'string' ? uidRaw : undefined;
      if (!uid || uid.startsWith('$RCAnonymousID')) {
        res.status(200).send('ignored');
        return;
      }

      const productId: string = String(
        ev?.product_id ||
          ev?.productIdentifier ||
          ev?.transaction?.product_id ||
          ''
      );
      const purchasedAtMs: number | null =
        Number(
          ev?.purchased_at_ms ||
            ev?.purchase_date_ms ||
            event?.event_timestamp_ms ||
            event?.sent_at_ms ||
            0
        ) || null;
      const expirationAtMs: number | null =
        Number(
          ev?.expiration_at_ms ||
            ev?.expires_at_ms ||
            ev?.expiration_ms ||
            0
        ) || null;

      const startIso = purchasedAtMs
        ? new Date(purchasedAtMs).toISOString()
        : new Date().toISOString();
      let endIso: string | null = expirationAtMs
        ? new Date(expirationAtMs).toISOString()
        : null;

      const guessPlanFromProduct = (pid: string): string => {
        const p = pid.toLowerCase();
        if (p.includes('year') || p.includes('annual') || p.includes('yr'))
          return 'yearly';
        return 'monthly';
      };
      const guessPlanFromDuration = (
        startMs: number | null,
        endMs: number | null
      ): string => {
        if (!startMs || !endMs) return 'monthly';
        const days = Math.max(
          0,
          Math.round((endMs - startMs) / (1000 * 60 * 60 * 24))
        );
        if (days >= 300) return 'yearly';
        if (days >= 27) return 'monthly';
        return 'monthly';
      };

      const planType = endIso
        ? guessPlanFromDuration(purchasedAtMs, expirationAtMs)
        : guessPlanFromProduct(productId);

      if (!endIso) {
        const start = purchasedAtMs ? dayjs(purchasedAtMs).utc() : safeNow();
        endIso = addDuration(start, planType).toISOString();
      }

      const now = safeNow();
      const end = dayjs(endIso).utc();
      const isActiveNow = end.isAfter(now);

      const subRef = db.collection('subscriptions').doc(uid);

      const writeActive = async (status: string) => {
        await subRef.set(
          {
            userId: uid,
            isPremium: isActiveNow,
            planType,
            startDate: startIso,
            endDate: endIso,
            provider: 'revenuecat',
            status,
            productId: productId || null,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      };

      const writeStatusOnly = async (status: string) => {
        await subRef.set(
          {
            provider: 'revenuecat',
            status,
            isPremium: isActiveNow,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      };

      switch (typeRaw) {
        case 'INITIAL_PURCHASE':
        case 'RENEWAL':
        case 'PRODUCT_CHANGE':
        case 'UNCANCELLATION':
        case 'NON_RENEWING_PURCHASE':
          await writeActive('active');
          break;
        case 'CANCELLATION':
          await writeStatusOnly('canceled');
          break;
        case 'EXPIRATION':
          await subRef.set(
            {
              provider: 'revenuecat',
              status: 'expired',
              isPremium: false,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
          break;
        case 'BILLING_ISSUE':
        case 'SUBSCRIPTION_PAUSED':
          await writeStatusOnly('past_due');
          break;
        case 'REFUND':
        case 'UNCANCELLATION_FAILURE':
        default:
          await writeStatusOnly('updated');
          break;
      }

      res.status(200).send('ok');
    } catch (e) {
      logger.error('RevenueCat mapping failed', {
        error: e instanceof Error ? e.message : String(e),
      });
      res.status(500).send('error');
    }
  }
);

// Usage hydration and sync

export const getUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  // Determine premium status
  let isPremium = false;
  try {
    const subSnap = await db.collection('subscriptions').doc(uid).get();
    if (subSnap.exists) {
      const s = subSnap.data() as SubscriptionData;
      const end = s?.endDate ? toDayjs(s.endDate) : null;
      if (s?.isPremium === true && end && end.isAfter(safeNow())) {
        isPremium = true;
      }
    }
  } catch (e) {
    // Treat errors as non-premium (fail closed)
    isPremium = false;
  }

  // Limits from Remote Config (server-of-record values)
  const SCAN_LIMIT = getScanLimitCfg();
  const CHAT_LIMIT = getChatLimitCfg();

  // Premium users are effectively unlimited, but we still return counts
  // for UI awareness. Client should gate using isPremium flag.
  if (isPremium) {
    return {
      isPremium: true,
      scanCount: 0,
      chatCount: 0,
      scanLimit: SCAN_LIMIT,
      chatLimit: CHAT_LIMIT,
      serverTimestampMs: Date.now(),
    };
  }

  // Non-premium: read today's counts from user_usage, reset across day boundary
  const usageRef = db.collection('user_usage').doc(uid);
  const snap = await usageRef.get();

  let scanCount = 0;
  let chatCount = 0;

  if (snap.exists) {
    const d = snap.data() as UsageData;
    const last = d?.lastUsageDate;
    let lastDate: dayjs.Dayjs | null = null;
    const lastAsDate = toDate(last);
    if (lastAsDate) {
      lastDate = dayjs(lastAsDate).utc();
    }
    const todayStart = safeNow().startOf('day');
    if (lastDate && lastDate.startOf('day').isSame(todayStart)) {
      scanCount = (d?.scanCount as number) || 0;
      chatCount = (d?.chatCount as number) || 0;
    }
  }

  return {
    isPremium: false,
    scanCount,
    chatCount,
    scanLimit: SCAN_LIMIT,
    chatLimit: CHAT_LIMIT,
    serverTimestampMs: Date.now(),
  };
});

// Public non-sensitive app configuration
export const getAppConfig = onCall({ region: 'europe-west1' }, async (_request: CallableRequest) => {
  // SECURITY: This endpoint returns only non-sensitive configuration values that are safe for client consumption.
  // Never return API keys, secrets, private endpoints, or other sensitive data here.
  const config = {
    aiModel: getAiModel(),
    limits: {
      scan: getScanLimitCfg(),
      chat: getChatLimitCfg()
    },
    features: {
      subscriptionsEnabled: getSubscriptionsEnabled()
    },
    // IAP IDs are public identifiers, safe to expose
    iap: {
      android: getAndroidIapIds(),
      ios: getIosIapIds()
    },
    links: {
      terms: getTermsLink(),
      privacy: getPrivacyLink(),
      shareAndroid: getShareUrlAndroid(),
      shareIos: getShareUrlIos(),
      playStoreUrl: getShareUrlAndroid(),
      appStoreUrl: getShareUrlIos()
    },
    pricing: {
      monthlyDzd: getPremiumMonthlyDzd(),
      yearlyDzd: getPremiumYearlyDzd()
    },
    payments: {
      successUrl: getSuccessUrl(),
      failureUrl: getFailureUrl()
    },
    app: {
      minRequiredVersion: getMinRequiredAppVersion(),
      updateMessage: getUpdateMessage()
    }
  };

  return { 
    config, 
    updatedAt: Date.now(),
    // Add a signature for basic integrity verification
    configVersion: '1.0',
    serverTimestamp: admin.firestore.Timestamp.now()
  };
});

/// SECURITY: Server-side app version validation with fail-closed enforcement
export const validateAppVersion = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const correlationId = crypto.randomUUID();
  
  // Validate request
  if (!validateRequestSize(request.data, 1)) {
    throw createStructuredError('invalid-argument', 'Request too large', correlationId);
  }

  const clientVersion = String(request.data?.version || '').trim();
  const platform = String(request.data?.platform || '').toLowerCase().trim();
  
  if (!clientVersion) {
    throw new Error('invalid-argument');
  }

  logger.info('App version validation request', {
    correlationId,
    clientVersion,
    platform,
    userId: request.auth?.uid || 'anonymous'
  });

  const requiredVersion = getMinRequiredAppVersion();
  const updateMessage = getUpdateMessage();
  
  try {
    const isOutdated = _isVersionOutdated(clientVersion, requiredVersion);
    
    // Log version check for monitoring
    await db.collection('version_checks').add({
      timestamp: FieldValue.serverTimestamp(),
      clientVersion,
      requiredVersion,
      platform,
      isOutdated,
      userId: request.auth?.uid || null,
      correlationId,
      userAgent: request.rawRequest.headers['user-agent'] || 'unknown',
      ip: request.rawRequest.ip || 'unknown'
    });

    if (isOutdated) {
      const storeUrl = platform === 'ios' 
        ? getShareUrlIos() 
        : getShareUrlAndroid();

      return {
        updateRequired: true,
        currentVersion: clientVersion,
        requiredVersion,
        updateMessage,
        storeUrl,
        severity: 'blocking'
      };
    }

    return {
      updateRequired: false,
      currentVersion: clientVersion,
      requiredVersion,
      severity: 'none'
    };

  } catch (error) {
    logger.error('Version validation error', {
      correlationId,
      error: error instanceof Error ? error.message : String(error),
      clientVersion,
      requiredVersion
    });
    
    // SECURITY: Fail closed - if validation fails, require update
    return {
      updateRequired: true,
      currentVersion: clientVersion,
      requiredVersion,
      updateMessage: 'Unable to verify app version. Please update to continue.',
      severity: 'blocking',
      errorCode: 'validation_failed'
    };
  }
});

/// Helper function to compare version strings
function _isVersionOutdated(current: string, required: string): boolean {
  const parse = (v: string): number[] => {
    // Keep only numeric components, ignore pre-release labels
    const core = v.split('+')[0].split('-')[0].trim();
    return core
      .split('.')
      .map((part) => {
        const match = /^(\d+)/.exec(part);
        return match ? parseInt(match[1], 10) : 0;
      });
  };

  const c = parse(current);
  const r = parse(required);
  const len = Math.max(c.length, r.length);
  
  for (let i = 0; i < len; i++) {
    const cv = i < c.length ? c[i] : 0;
    const rv = i < r.length ? r[i] : 0;
    if (cv < rv) return true;  // current < required -> outdated
    if (cv > rv) return false; // current > required -> ok
  }
  return false; // equal
}

export const syncUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  // Parse client-reported counts safely
  const clientScan = Math.max(0, parseInt(String(request.data?.scanCount ?? 0), 10) || 0);
  const clientChat = Math.max(0, parseInt(String(request.data?.chatCount ?? 0), 10) || 0);

  // Limits from Remote Config
  const SCAN_LIMIT = getScanLimitCfg();
  const CHAT_LIMIT = getChatLimitCfg();

  // If premium, we simply acknowledge — we do not need to persist counts
  try {
    const subSnap = await db.collection('subscriptions').doc(uid).get();
    if (subSnap.exists) {
      const s = subSnap.data() as SubscriptionData;
      const end = s?.endDate ? toDayjs(s.endDate) : null;
      const premium = s?.isPremium === true && end && end.isAfter(safeNow());
      if (premium) {
        return {
          success: true,
          isPremium: true,
          currentUsage: { scanCount: 0, chatCount: 0, scanLimit: SCAN_LIMIT, chatLimit: CHAT_LIMIT },
        };
      }
    }
  } catch (_) {
    // fall through as non-premium
  }

  const usageRef = db.collection('user_usage').doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(usageRef);
    const todayStart = safeNow().startOf('day');

    let serverScan = 0;
    let serverChat = 0;
    let last = null;
    if (snap.exists) {
      const d = snap.data() as UsageData;
      last = d?.lastUsageDate;
      let lastDate: dayjs.Dayjs | null = null;
      const lastAsDate = toDate(last);
      if (lastAsDate) {
        lastDate = dayjs(lastAsDate).utc();
      }
      if (lastDate && lastDate.startOf('day').isSame(todayStart)) {
        serverScan = (d?.scanCount as number) || 0;
        serverChat = (d?.chatCount as number) || 0;
      }
    }

    // Monotonic merge and cap at limits
    const mergedScan = Math.min(Math.max(serverScan, clientScan), SCAN_LIMIT);
    const mergedChat = Math.min(Math.max(serverChat, clientChat), CHAT_LIMIT);

    tx.set(usageRef, {
      scanCount: mergedScan,
      chatCount: mergedChat,
      lastUsageDate: FieldValue.serverTimestamp(),
      userId: uid,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return { scanCount: mergedScan, chatCount: mergedChat };
  });

  return {
    success: true,
    isPremium: false,
    currentUsage: {
      scanCount: result.scanCount,
      chatCount: result.chatCount,
      scanLimit: SCAN_LIMIT,
      chatLimit: CHAT_LIMIT,
    },
  };
});

// Secure proxy for OpenRouter chat completions
export const chatWithOpenRouter = onCall({
  region: 'europe-west1',
  secrets: [OPENROUTER_API_KEY]
}, async (request: CallableRequest) => {
  const startTime = Date.now();
  const correlationId = crypto.randomUUID();
  
  const uid = request.auth?.uid;
  if (!uid) throw new Error('unauthenticated');

  // SECURITY: Request size validation to prevent DoS and cost attacks
  if (!validateRequestSize(request.data, 1024)) { // 1MB limit for images
    logger.warn('Request size too large for chatWithOpenRouter', {
      correlationId,
      userId: uid,
      dataSize: JSON.stringify(request.data).length
    });
    throw createStructuredError('invalid-argument', 'Request payload too large', correlationId);
  }

  const model = String(request.data?.model || getAiModel());
  const messages = request.data?.messages;
  const maxTokens = Number(request.data?.max_tokens || 500);

  if (!Array.isArray(messages) || messages.length === 0) {
    throw new Error('invalid-argument');
  }

  // SECURITY: Validate image payload sizes in messages
  for (const message of messages) {
    if (message?.content && Array.isArray(message.content)) {
      for (const content of message.content) {
        if (content?.type === 'image_url' && content?.image_url?.url) {
          const imageUrl = content.image_url.url;
          if (imageUrl.startsWith('data:image/')) {
            // Extract base64 data and validate size
            const base64Data = imageUrl.split(',')[1];
            if (base64Data) {
              const imageSize = base64Data.length * 0.75; // Approximate decoded size
              const maxImageSize = 5 * 1024 * 1024; // 5MB limit
              if (imageSize > maxImageSize) {
                logger.warn('Image payload too large', {
                  correlationId,
                  userId: uid,
                  imageSize,
                  maxImageSize
                });
                throw createStructuredError('invalid-argument', 'Image size exceeds limit', correlationId);
              }
            }
          }
        }
      }
    }
  }

  // Check subscription status for premium access
  let isPremium = false;
  try {
    const subSnap = await db.collection('subscriptions').doc(uid).get();
    if (subSnap.exists) {
      const s = subSnap.data() as SubscriptionData;
      const end = s?.endDate ? toDayjs(s.endDate) : null;
      isPremium = s?.isPremium === true && !!(end && end.isAfter(safeNow()));
    }
  } catch (_) {
    // If we can't verify subscription status, treat as non-premium
    isPremium = false;
  }

  // Premium users get unlimited access - skip rate limiting entirely
  if (isPremium) {
    logger.info('Premium user accessing chat - unlimited access granted', { 
      uid, 
      correlationId,
      duration: Date.now() - startTime 
    });
  } else {
    // Non-premium users: enforce rate limits
    try {
      const usageDoc = await db.collection('user_usage').doc(uid).get();
      const d = usageDoc.data() as UsageData | undefined;
      const last = d?.lastUsageDate;
      const todayStart = safeNow().startOf('day');
      let chatCount = 0;
      if (last) {
        const lastDate = toDayjs(last);
        if (lastDate && lastDate.startOf('day').isSame(todayStart)) {
          chatCount = (d?.chatCount as number) || 0;
        }
      }
      const CHAT_LIMIT = getChatLimitCfg();
      if (chatCount >= CHAT_LIMIT) {
        throw new Error('Daily chat limit reached. Upgrade to Premium for unlimited access.');
      }
      // Increment usage for non-premium users
      await db.collection('user_usage').doc(uid).set({
        chatCount: chatCount + 1,
        lastUsageDate: FieldValue.serverTimestamp(),
        userId: uid,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      
      logger.info('Non-premium user chat usage incremented', { 
        uid, 
        chatCount: chatCount + 1, 
        limit: CHAT_LIMIT 
      });
    } catch (e) {
      if (e instanceof Error && e.message.includes('Daily chat limit reached')) {
        throw e;
      }
      // Log other errors but don't block the request
      logger.error('Error checking/updating usage for non-premium user', { uid, error: e });
    }
  }

  const key = OPENROUTER_API_KEY.value();
  if (!key) {
    logger.error('OpenRouter API key not configured', { correlationId, userId: uid });
    throw new Error('AI service temporarily unavailable');
  }

  // Retry configuration for handling rate limits and temporary failures
  const maxRetries = 3;
  let lastError: any = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      logger.info(`AI request attempt ${attempt}/${maxRetries}`, {
        correlationId,
        userId: uid,
        attempt,
        model
      });

      const resp = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
        model,
        messages,
        max_tokens: maxTokens,
      }, {
        headers: {
          'Authorization': `Bearer ${key}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://macroaize.com',
          'X-Title': 'Food Calorie Tracker',
        },
        timeout: 30000, // Increased timeout for better reliability
      });

      // SECURITY: Validate AI response for common response formats
      const responseData = resp.data;
      if (responseData?.choices?.[0]?.message?.content) {
        const content = responseData.choices[0].message.content;
        
        // Attempt basic validation if response looks like nutrition or meal items JSON
        if (content.includes('food_name') || content.includes('calories')) {
          try {
            validateAiJsonResponse(content, 'nutrition');
          } catch (validationError) {
            logger.warn('AI response validation failed for nutrition', {
              correlationId,
              userId: uid,
              validationError: validationError instanceof Error ? validationError.message : String(validationError)
            });
          }
        } else if (content.includes('mealItems')) {
          try {
            validateAiJsonResponse(content, 'mealItems');
          } catch (validationError) {
            logger.warn('AI response validation failed for meal items', {
              correlationId,
              userId: uid,
              validationError: validationError instanceof Error ? validationError.message : String(validationError)
            });
          }
        }
      }

      const duration = Date.now() - startTime;
      logger.info('AI request completed successfully', {
        correlationId,
        userId: uid,
        duration,
        isPremium,
        attempt
      });

      return responseData;
    } catch (e: any) {
      lastError = e;
      const status = e?.response?.status;
      const errorMessage = e?.response?.data?.error?.message || e?.message || 'Unknown error';
      
      logger.warn(`AI request attempt ${attempt} failed`, {
        correlationId,
        userId: uid,
        attempt,
        status,
        errorMessage,
        willRetry: attempt < maxRetries
      });

      // Handle specific error cases
      if (status === 429) {
        // Rate limit - wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000); // Max 5s delay
          logger.info(`Rate limited, waiting ${delay}ms before retry`, {
            correlationId,
            userId: uid,
            attempt,
            delay
          });
          await new Promise(resolve => setTimeout(resolve, delay));
          continue; // Retry
        } else {
          // Final attempt failed with rate limit
          throw new Error('ai_rate_limit_exceeded');
        }
      } else if (status === 400) {
        // Bad request - don't retry
        logger.error('Bad request to AI service', {
          correlationId,
          userId: uid,
          status,
          errorMessage
        });
        throw new Error('ai_invalid_request');
      } else if (status === 401 || status === 403) {
        // Authentication error - don't retry
        logger.error('AI service authentication failed', {
          correlationId,
          userId: uid,
          status
        });
        throw new Error('ai_service_unavailable');
      } else if (status >= 500 || !status) {
        // Server error or network error - retry
        if (attempt < maxRetries) {
          const delay = Math.min(1000 * attempt, 3000); // Progressive delay up to 3s
          await new Promise(resolve => setTimeout(resolve, delay));
          continue; // Retry
        }
      }
      
      // If we reach here, either non-retryable error or max retries exceeded
      break;
    }
  }

  // All retries failed
  const finalStatus = lastError?.response?.status;
  const finalMessage = lastError?.response?.data?.error?.message || lastError?.message || 'Unknown error';
  
  logger.error('AI request failed after all retries', {
    correlationId,
    userId: uid,
    maxRetries,
    finalStatus,
    finalMessage,
    duration: Date.now() - startTime
  });

  // Return appropriate error messages based on the final error
  if (finalStatus === 429) {
    throw new Error('ai_rate_limit_exceeded');
  } else if (finalStatus >= 500 || !finalStatus) {
    throw new Error('ai_service_unavailable');
  } else {
    throw new Error('ai_request_failed');
  }
});

// Secure proxy for USDA FoodData Central search
export const searchUsdaFoods = onCall({
  region: 'europe-west1',
  secrets: [USDA_API_KEY]
}, async (request: CallableRequest) => {
  const startTime = Date.now();
  const correlationId = crypto.randomUUID();
  
  const uid = request.auth?.uid;
  if (!uid) throw new Error('unauthenticated');

  // SECURITY: Request size validation
  if (!validateRequestSize(request.data, 5)) { // 5KB limit for search queries
    logger.warn('Request size too large for searchUsdaFoods', {
      correlationId,
      userId: uid
    });
    throw createStructuredError('invalid-argument', 'Request too large', correlationId);
  }

  const query = String(request.data?.query || '').trim();
  const limit = Math.max(1, Math.min(10, Number(request.data?.limit || 3)));
  if (!query) throw new Error('invalid-argument');

  // SECURITY: Server-side usage enforcement (defense-in-depth)
  let isPremium = false;
  try {
    const subSnap = await db.collection('subscriptions').doc(uid).get();
    if (subSnap.exists) {
      const s = subSnap.data() as SubscriptionData;
      const end = s?.endDate ? toDayjs(s.endDate) : null;
      isPremium = s?.isPremium === true && !!(end && end.isAfter(safeNow()));
    }
  } catch (e) {
    // If we can't verify subscription status, treat as non-premium
    logger.warn('Failed to check subscription status for USDA request', {
      correlationId,
      userId: uid,
      error: e instanceof Error ? e.message : String(e)
    });
    isPremium = false;
  }

  // Non-premium users: enforce scan limits
  if (!isPremium) {
    try {
      const usageDoc = await db.collection('user_usage').doc(uid).get();
      const d = usageDoc.data() as UsageData | undefined;
      const last = d?.lastUsageDate;
      const todayStart = safeNow().startOf('day');
      let scanCount = 0;
      
      if (last) {
        const lastDate = toDayjs(last);
        if (lastDate && lastDate.startOf('day').isSame(todayStart)) {
          scanCount = (d?.scanCount as number) || 0;
        }
      }
      
      const SCAN_LIMIT = getScanLimitCfg();
      if (scanCount >= SCAN_LIMIT) {
        logger.warn('USDA request blocked - scan limit reached', {
          correlationId,
          userId: uid,
          scanCount,
          scanLimit: SCAN_LIMIT
        });
        throw new Error('Daily scan limit reached. Upgrade to Premium for unlimited access.');
      }

      // Increment usage count for non-premium users
      await db.collection('user_usage').doc(uid).set({
        scanCount: scanCount + 1,
        lastUsageDate: FieldValue.serverTimestamp(),
        userId: uid,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      
      logger.info('USDA request usage incremented', {
        correlationId,
        userId: uid,
        scanCount: scanCount + 1,
        limit: SCAN_LIMIT
      });
    } catch (e) {
      if (e instanceof Error && e.message.includes('Daily scan limit reached')) {
        throw e;
      }
      // Log other errors but don't block the request completely for premium users
      logger.error('Error checking/updating usage for USDA request', {
        correlationId,
        userId: uid,
        error: e instanceof Error ? e.message : String(e)
      });
    }
  } else {
    logger.info('Premium user accessing USDA - unlimited access granted', {
      correlationId,
      userId: uid
    });
  }

  const key = USDA_API_KEY.value();
  if (!key) throw new Error('internal');

  try {
    const url = 'https://api.nal.usda.gov/fdc/v1/foods/search';
    const res = await axios.get(url, {
      params: { query, api_key: key, pageSize: String(limit) },
      timeout: 10000,
    });

    // SECURITY: Validate and sanitize USDA response
    const sanitizedResponse = sanitizeUsdaResponse(res.data);
    
    const duration = Date.now() - startTime;
    logger.info('USDA request completed successfully', {
      correlationId,
      userId: uid,
      query,
      resultCount: sanitizedResponse?.foods?.length || 0,
      duration,
      isPremium
    });
    
    return sanitizedResponse;
  } catch (e: any) {
    const duration = Date.now() - startTime;
    logger.error('USDA API request failed', {
      correlationId,
      userId: uid,
      query,
      duration,
      error: e?.response?.data?.message || e?.message || 'USDA error'
    });
    
    const status = e?.response?.status;
    const msg = e?.response?.data?.message || e?.message || 'USDA error';
    if (status === 429) throw new Error('Rate limited by USDA');
    throw new Error(msg);
  }
});

/**
 * Sanitizes and validates USDA API response to prevent malformed data
 */
function sanitizeUsdaResponse(rawResponse: any): any {
  try {
    if (!rawResponse || typeof rawResponse !== 'object') {
      return { foods: [] };
    }

    const foods = Array.isArray(rawResponse.foods) ? rawResponse.foods : [];
    const sanitizedFoods = foods.map((food: any) => {
      if (!food || typeof food !== 'object') return null;
      
      const sanitizedFood: any = {
        fdcId: Number(food.fdcId) || 0,
        description: String(food.description || '').trim().substring(0, 200), // Limit description length
        foodNutrients: []
      };
      
      // Sanitize nutrients
      if (Array.isArray(food.foodNutrients)) {
        sanitizedFood.foodNutrients = food.foodNutrients.map((nutrient: any) => {
          if (!nutrient || typeof nutrient !== 'object') return null;
          
          const value = nutrient.value;
          const sanitizedValue = (typeof value === 'number' && !isNaN(value) && isFinite(value)) 
            ? Math.max(0, Math.min(10000, value)) // Clamp values to reasonable range
            : 0;
          
          return {
            nutrientName: String(nutrient.nutrientName || '').trim().substring(0, 100),
            value: sanitizedValue,
            unitName: String(nutrient.unitName || '').trim().substring(0, 20)
          };
        }).filter((nutrient: any) => nutrient !== null);
      }
      
      return sanitizedFood;
    }).filter((food: any) => food !== null);

    return {
      foods: sanitizedFoods.slice(0, 10), // Limit to max 10 results
      totalHits: Number(rawResponse.totalHits) || 0,
      currentPage: Number(rawResponse.currentPage) || 1,
      totalPages: Number(rawResponse.totalPages) || 1
    };
  } catch (error) {
    logger.warn('Failed to sanitize USDA response', { error: error instanceof Error ? error.message : String(error) });
    return { foods: [] };
  }
}

// Influencer promo code functions

// Manual function to fix failed commission processing
export const fixPromoCommission = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  // Only allow admin users to call this function
  const isAdmin = request.auth?.token?.admin === true;
  if (!isAdmin) {
    throw new Error('permission-denied');
  }

  const subscriptionUserId = request.data?.subscriptionUserId as string;
  const promoCode = request.data?.promoCode as string;

  if (!subscriptionUserId || !promoCode) {
    throw new Error('invalid-argument');
  }

  try {
    // Get the subscription
    const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionUserId).get();
    if (!subscriptionDoc.exists) {
      throw new Error('Subscription not found');
    }

    const subscriptionData = subscriptionDoc.data()!;
    
    // Verify the promo code matches
    if (subscriptionData.promoCodeUsed !== promoCode) {
      throw new Error('Promo code mismatch');
    }

    // Check if commission was already processed successfully
    if (subscriptionData.commissionProcessed === true && !subscriptionData.commissionError) {
      throw new Error('Commission already processed successfully');
    }

    // Find the influencer
    const influencersQuery = await db.collection('influencers')
      .where('promoCode', '==', promoCode)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (influencersQuery.empty) {
      throw new Error(`No active influencer found for promo code: ${promoCode}`);
    }

    const influencerDoc = influencersQuery.docs[0];
    const influencerId = influencerDoc.id;

    // Check for existing commission
    const existingCommission = await db.collection('influencer_audit')
      .where('details.promoCode', '==', promoCode)
      .where('details.subscriptionUserId', '==', subscriptionUserId)
      .where('action', '==', 'commission_earned')
      .where('status', '==', 'completed')
      .limit(1)
      .get();

    if (!existingCommission.empty) {
      throw new Error('Commission already recorded');
    }

    const earnAmount = getInfluencerEarnForCode();
    if (!earnAmount || earnAmount <= 0) {
      throw new Error(`Invalid INFLUENCER_EARN_FOR_CODE value: ${earnAmount}`);
    }

    // Process the commission in a transaction
    await db.runTransaction(async (tx) => {
      const influencerRef = db.collection('influencers').doc(influencerId);
      const subscriptionRef = db.collection('subscriptions').doc(subscriptionUserId);
      
      const currentInfluencer = await tx.get(influencerRef);
      
      if (!currentInfluencer.exists) {
        throw new Error(`Influencer document not found: ${influencerId}`);
      }

      const data = currentInfluencer.data()!;
      const newEarnings = Math.max(0, (data.earningsDzd || 0)) + earnAmount;
      const newTotalEarnings = Math.max(0, (data.totalEarningsDzd || 0)) + earnAmount;
      const newUsersCount = Math.max(0, (data.usersCount || 0)) + 1;

      // Update influencer data
      tx.update(influencerRef, {
        earningsDzd: newEarnings,
        totalEarningsDzd: newTotalEarnings,
        usersCount: newUsersCount,
        lastEarningDate: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });

      // Update subscription to mark commission as processed
      tx.update(subscriptionRef, {
        commissionProcessed: true,
        commissionFixedAt: FieldValue.serverTimestamp(),
        commissionFixedBy: uid,
        updatedAt: FieldValue.serverTimestamp()
      });

      // Create audit log
      tx.create(db.collection('influencer_audit').doc(), {
        userId: influencerId,
        action: 'commission_earned',
        amount: earnAmount,
        details: {
          promoCode,
          subscriptionUserId,
          earnAmount,
          previousEarnings: data.earningsDzd || 0,
          newEarnings,
          previousUsersCount: data.usersCount || 0,
          newUsersCount,
          fixedAt: FieldValue.serverTimestamp(),
          fixedBy: uid,
          note: 'Manually fixed failed commission processing'
        },
        timestamp: FieldValue.serverTimestamp(),
        status: 'completed',
        source: 'manual_fix'
      });
    });

    return {
      success: true,
      message: `Commission fixed for promo code ${promoCode}. Influencer ${influencerId} earned ${earnAmount} DZD.`,
      earnAmount,
      influencerId
    };

  } catch (error) {
    console.error('Error fixing promo commission:', error);
    throw new Error(error instanceof Error ? error.message : 'internal');
  }
});

// Rate limiting helper with memory cleanup
const promoCodeAttempts = new Map<string, { count: number; lastAttempt: number }>();

// Clean up old rate limiting entries to prevent memory leaks
function cleanupRateLimitMap(): void {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  
  for (const [key, attempt] of promoCodeAttempts) {
    if (now - attempt.lastAttempt > oneHour) {
      promoCodeAttempts.delete(key);
    }
  }
}

// Run cleanup every 10 minutes
setInterval(cleanupRateLimitMap, 10 * 60 * 1000);

function isValidPromoCode(code: string): boolean {
  if (!code || typeof code !== 'string') return false;
  if (code.length < 6 || code.length > 12) return false;
  return /^[A-Z0-9]+$/.test(code);
}



function checkRateLimit(key: string, maxAttempts: number = 5, windowHours: number = 1): boolean {
  const now = Date.now();
  const windowMs = windowHours * 60 * 60 * 1000;
  
  const attempt = promoCodeAttempts.get(key);
  if (!attempt) {
    promoCodeAttempts.set(key, { count: 1, lastAttempt: now });
    return true;
  }
  
  if (now - attempt.lastAttempt > windowMs) {
    promoCodeAttempts.set(key, { count: 1, lastAttempt: now });
    return true;
  }
  
  if (attempt.count >= maxAttempts) {
    return false;
  }
  
  attempt.count++;
  attempt.lastAttempt = now;
  return true;
}

export const validatePromoCode = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  const promoCode = (request.data?.promoCode as string || '').toUpperCase().trim();
  const clientIP = request.rawRequest.ip || 'unknown';

  // Rate limiting
  if (!checkRateLimit(`promo_${clientIP}_${uid}`, 5, 1)) {
    throw new Error('rate-limited');
  }

  if (!isValidPromoCode(promoCode)) {
    throw new Error('invalid-code');
  }

  try {
    // Check if promo code exists and is valid
    const influencersQuery = await db.collection('influencers')
      .where('promoCode', '==', promoCode)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (influencersQuery.empty) {
      throw new Error('invalid-code');
    }

    const influencerDoc = influencersQuery.docs[0];
    const influencerData = influencerDoc.data();
    const influencerId = influencerDoc.id;

    // Check expiration
    const expirationDate = influencerData.expirationDate?.toDate?.() || new Date(influencerData.expirationDate);
    if (expirationDate && expirationDate < new Date()) {
      throw new Error('invalid-code');
    }

    // Check if user has already used this promo code
    const existingSubscription = await db.collection('subscriptions')
      .where('userId', '==', uid)
      .where('promoCodeUsed', '==', promoCode)
      .limit(1)
      .get();

    if (!existingSubscription.empty) {
      throw new Error('already-used');
    }

    // Log validation attempt
    await db.collection('influencer_audit').add({
      userId: influencerId,
      action: 'promo_validated',
      amount: 0,
      details: {
        promoCode,
        validatedBy: uid,
        clientIP
      },
      timestamp: FieldValue.serverTimestamp(),
      status: 'success'
    });

    return {
      valid: true,
      discountRate: getInfluencerCommissionRate(),
      earnAmount: getInfluencerEarnForCode(),
      influencerId
    };

  } catch (error) {
    // Generic error message for security
    if (error instanceof Error) {
      if (error.message === 'rate-limited') {
        throw new Error('Too many attempts. Please try again later.');
      }
      if (error.message === 'already-used') {
        throw new Error('This promo code has already been used.');
      }
    }
    throw new Error('Invalid promo code.');
  }
});

// trackPromoUsage function removed - redundant with automatic webhook tracking

export const processWithdrawal = onCall({ 
  region: 'europe-west1',
  secrets: [RIP_ENCRYPTION_KEY_V1]
}, async (request: CallableRequest) => {
  const startTime = Date.now();
  const correlationId = crypto.randomUUID();
  
  const uid = request.auth?.uid;
  if (!uid) {
    throw createStructuredError('unauthenticated', 'No authenticated user', correlationId);
  }

  // Check email verification
  if (!request.auth?.token?.email_verified) {
    throw createStructuredError('permission-denied', 'Email verification required for withdrawal requests', correlationId);
  }

  // Request validation
  if (!validateRequestSize(request.data, 2)) {
    throw createStructuredError('invalid-argument', 'Request too large', correlationId);
  }

  const amount = request.data?.amount as number;
  const rip = (request.data?.rip as string || '').trim();

  logger.info('Processing withdrawal request', {
    correlationId,
    userId: uid,
    amount,
    ripMasked: maskRip(rip)
  });

  if (!amount || amount <= 0 || !isValidRip(rip)) {
    throw new Error('invalid-argument');
  }

  const minWithdrawal = getInfluencerMinWithdrawal();
  if (amount < minWithdrawal) {
    throw new Error(`Minimum withdrawal amount is ${minWithdrawal} DZD`);
  }

  // Prepare encrypted and masked RIP data
  const ripMasked = maskRip(rip);
  const ripEncrypted = encryptRip(rip, RIP_ENCRYPTION_KEY_V1.value());

  try {
    // Check if user is an influencer (using admin SDK, bypasses security rules)
    const influencerDoc = await db.collection('influencers').doc(uid).get();
    if (!influencerDoc.exists) {
      throw new Error('permission-denied');
    }

    const influencerData = influencerDoc.data()!;
    if (!influencerData.isActive) {
      throw new Error('Account is not active');
    }

    // (Optional) recent-withdrawal checks intentionally omitted for now

    // Process withdrawal in transaction
    const withdrawalId = `WD_${Date.now()}_${uid.slice(-6)}`;
    
    await db.runTransaction(async (transaction) => {
      const currentInfluencer = await transaction.get(db.collection('influencers').doc(uid));
      if (!currentInfluencer.exists) {
        throw new Error('Influencer not found');
      }

      const data = currentInfluencer.data()!;
      const currentBalance = data.earningsDzd || 0;

      if (currentBalance < amount) {
        throw new Error('insufficient-funds');
      }

      const newBalance = currentBalance - amount;
      const now = new Date();
      const withdrawalRecord = {
        id: withdrawalId,
        amount,
        ripMasked,
        requestedAt: now,
        status: 'processing',
        estimatedProcessingDate: safeNow().add(getInfluencerWithdrawalProcessingDays(), 'days').toISOString()
      };

      // Update influencer balance and withdrawal history
      transaction.update(db.collection('influencers').doc(uid), {
        earningsDzd: newBalance,
        withdrawHistory: FieldValue.arrayUnion(withdrawalRecord),
        updatedAt: FieldValue.serverTimestamp()
      });

      // Create audit log
      transaction.create(db.collection('influencer_audit').doc(), {
        userId: uid,
        action: 'withdrawal_requested',
        amount,
        details: {
          withdrawalId,
          ripMasked,
          previousBalance: currentBalance,
          newBalance
        },
        timestamp: FieldValue.serverTimestamp(),
        status: 'processing'
      });

      // Store encrypted RIP in secure admin-only collection
      transaction.set(db.collection('withdrawals_secure').doc(withdrawalId), {
        userId: uid,
        amount,
        ripEncrypted,
        keyVersion: 1,
        createdAt: FieldValue.serverTimestamp(),
        status: 'processing'
      });

      // Create email notification
      transaction.create(db.collection('mail').doc(), {
        to: [getEmailToAddress()],
        from: getEmailFromAddress(),
        message: {
          subject: ` Withdrawal Request #${withdrawalId}`,
          text: `
New withdrawal request received:

REQUEST DETAILS:
- Request ID: ${withdrawalId}
- Amount: ${amount} DZD
- Bank Account (RIP): ${ripMasked}
- Requested At: ${new Date().toISOString()}
- Processing Deadline: ${safeNow().add(getInfluencerWithdrawalProcessingDays(), 'days').format('YYYY-MM-DD')}

INFLUENCER INFORMATION:
- Influencer ID: ${uid}
- Promo Code: ${data.promoCode || 'N/A'}
- Total Referrals: ${data.usersCount || 0}
- Balance Before: ${currentBalance} DZD
- Balance After: ${newBalance} DZD

          `.trim(),
          html: `
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2 style="color: #ff6b35;">🏦 New Withdrawal Request</h2>
  
  <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
    <h3>Request Details</h3>
    <p><strong>Request ID:</strong> ${withdrawalId}</p>
    <p><strong>Amount:</strong> ${amount} DZD</p>
    <p><strong>Bank Account (RIP):</strong> ${ripMasked}</p>
    <p><strong>Requested At:</strong> ${new Date().toLocaleDateString()} ${new Date().toLocaleTimeString()}</p>
    <p><strong>Processing Deadline:</strong> ${safeNow().add(getInfluencerWithdrawalProcessingDays(), 'days').format('YYYY-MM-DD')}</p>
  </div>
  
  <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
    <h3>Influencer Information</h3>
    <p><strong>Influencer ID:</strong> ${uid}</p>
    <p><strong>Promo Code:</strong> ${data.promoCode || 'N/A'}</p>
    <p><strong>Total Referrals:</strong> ${data.usersCount || 0}</p>
    <p><strong>Balance Before:</strong> ${currentBalance} DZD</p>
    <p><strong>Balance After:</strong> ${newBalance} DZD</p>
  </div>
  
  <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
    <h3>⚠️ Action Required</h3>
    <p>Please process this withdrawal within <strong>${getInfluencerWithdrawalProcessingDays()} business days</strong>.</p>
    <p>Update the status in the admin panel once processed.</p>
  </div>
</div>
          `.trim()
        }
      });
    });

    const duration = Date.now() - startTime;
    logger.info('Withdrawal processed successfully', {
      correlationId,
      userId: uid,
      withdrawalId,
      amount,
      duration
    });

    return {
      success: true,
      withdrawalId,
      message: `Withdrawal request submitted. Processing time: ${getInfluencerWithdrawalProcessingDays()} business days.`
    };

  } catch (error) {
    console.error('Error processing withdrawal:', error);
    
    if (error instanceof Error) {
      // Handle specific error cases with user-friendly messages
      if (error.message === 'withdrawal-too-frequent') {
        throw new Error('You can only request one withdrawal per week. Please try again later.');
      }
      if (error.message === 'insufficient-funds') {
        throw new Error('Insufficient balance for this withdrawal amount. Please check your available balance.');
      }
      if (error.message === 'Account is not active') {
        throw new Error('Your influencer account is not active. Please contact support.');
      }
      if (error.message === 'Influencer not found') {
        throw new Error('Influencer account not found. Please contact support.');
      }
      if (error.message.includes('permission-denied')) {
        throw new Error('You are not authorized to make withdrawal requests.');
      }
      if (error.message.includes('unauthenticated')) {
        throw new Error('Please sign in to request a withdrawal.');
      }
      if (error.message.includes('invalid-argument')) {
        throw new Error('Invalid withdrawal details. Please check the amount and RIP number.');
      }
      if (error.message.includes('Email verification required')) {
        throw new Error('Please verify your email address to request withdrawals.');
      }
    }
    
    throw new Error('Failed to process withdrawal request. Please try again or contact support.');
  }
});

/**
 * Admin-only function to decrypt RIP for withdrawal processing
 * Requires admin role in custom claims
 */
export const adminGetWithdrawalRip = onCall({
  region: 'europe-west1',
  secrets: [RIP_ENCRYPTION_KEY_V1]
}, async (request: CallableRequest) => {
  // Validate admin permissions
  requireAdmin(request);

  const withdrawalId = String(request.data?.withdrawalId || '').trim();
  if (!withdrawalId) {
    throw new Error('invalid-argument');
  }

  try {
    // Get encrypted RIP from secure collection
    const secureDoc = await db.collection('withdrawals_secure').doc(withdrawalId).get();
    if (!secureDoc.exists) {
      throw new Error('not-found');
    }

    const secureData = secureDoc.data()!;
    
    // Validate key version
    if (secureData.keyVersion !== 1) {
      throw new Error('unsupported-key-version');
    }

    // Decrypt the RIP
    const decryptedRip = decryptRip(secureData.ripEncrypted, RIP_ENCRYPTION_KEY_V1.value());
    const ripMasked = maskRip(decryptedRip);

    // Create audit log for RIP access
    await db.collection('influencer_audit').add({
      userId: secureData.userId,
      action: 'rip_decrypted_access',
      details: {
        withdrawalId,
        ripMasked,
        accessedBy: request.auth!.uid,
        accessedAt: new Date().toISOString()
      },
      timestamp: FieldValue.serverTimestamp(),
      adminAccess: true
    });

    return {
      success: true,
      withdrawalId,
      rip: decryptedRip,
      userId: secureData.userId,
      amount: secureData.amount,
      status: secureData.status
    };

  } catch (error) {
    console.error('Error decrypting withdrawal RIP:', error);
    
    if (error instanceof Error) {
      if (error.message === 'not-found') {
        throw new Error('Withdrawal record not found or has been processed');
      }
      if (error.message === 'unsupported-key-version') {
        throw new Error('Unsupported encryption version. Please contact technical support.');
      }
      if (error.message.includes('decryption failed')) {
        throw new Error('Failed to decrypt RIP. Data may be corrupted.');
      }
    }
    
    throw new Error('Failed to retrieve withdrawal details. Please try again or contact support.');
  }
});

/**
 * Admin-only function to mark withdrawal as completed and clean up sensitive data
 */
export const adminCompleteWithdrawal = onCall({
  region: 'europe-west1'
}, async (request: CallableRequest) => {
  requireAdmin(request);

  const withdrawalId = String(request.data?.withdrawalId || '').trim();
  const status = String(request.data?.status || '').trim();
  
  if (!withdrawalId || !['completed', 'failed'].includes(status)) {
    throw new Error('invalid-argument');
  }

  try {
    await db.runTransaction(async (transaction) => {
      // Update status in secure collection
      const secureRef = db.collection('withdrawals_secure').doc(withdrawalId);
      const secureDoc = await transaction.get(secureRef);
      
      if (!secureDoc.exists) {
        throw new Error('not-found');
      }

      const secureData = secureDoc.data()!;

      // Update withdrawal history in influencer document
      const influencerRef = db.collection('influencers').doc(secureData.userId);
      const influencerDoc = await transaction.get(influencerRef);
      
      if (influencerDoc.exists) {
        const influencerData = influencerDoc.data()!;
        const withdrawHistory = influencerData.withdrawHistory || [];
        
        // Update the specific withdrawal record
        const updatedHistory = withdrawHistory.map((withdrawal: WithdrawalRecord) => {
          if (withdrawal.id === withdrawalId) {
            return { ...withdrawal, status, completedAt: new Date().toISOString() };
          }
          return withdrawal;
        });

        transaction.update(influencerRef, {
          withdrawHistory: updatedHistory,
          updatedAt: FieldValue.serverTimestamp()
        });
      }

      // Create completion audit log
      transaction.create(db.collection('influencer_audit').doc(), {
        userId: secureData.userId,
        action: 'withdrawal_completed',
        details: {
          withdrawalId,
          status,
          completedBy: request.auth!.uid,
          amount: secureData.amount
        },
        timestamp: FieldValue.serverTimestamp(),
        adminAction: true
      });

      // If completed successfully, delete the encrypted RIP for security
      if (status === 'completed') {
        transaction.delete(secureRef);
      } else {
        // If failed, just update status but keep record for investigation
        transaction.update(secureRef, {
          status,
          completedAt: FieldValue.serverTimestamp(),
          completedBy: request.auth!.uid
        });
      }
    });

    return {
      success: true,
      message: status === 'completed' ? 'Withdrawal marked as completed and sensitive data removed' : 'Withdrawal marked as failed'
    };

  } catch (error) {
    console.error('Error completing withdrawal:', error);
    
    if (error instanceof Error && error.message === 'not-found') {
      throw new Error('Withdrawal record not found');
    }
    
    throw new Error('Failed to complete withdrawal. Please try again.');
  }
});

// =============================================================================
// NOTIFICATION SYSTEM - PHASE 2 & 3: Auto-Triggered Notifications
// =============================================================================

/**
 * Auto-triggered notification: Promo Code Used → Notify Influencer
 * Trigger: onCreate in promoUses/{docId}
 * Sends notification to influencer when their promo code is used
 */
export const notifyInfluencerOnPromoUse = onDocumentCreated({
  region: 'europe-west1',
  document: 'promoUses/{docId}'
}, async (event) => {
  const correlationId = `promo_use_${Date.now()}`;
  
  try {
    const promoUseData = event.data?.data();
    if (!promoUseData) {
      logger.warn('No promo use data found', { correlationId });
      return;
    }

    const promoCodeId = promoUseData.promoCodeId;
    const userId = promoUseData.userId;

    if (!promoCodeId) {
      logger.warn('No promo code ID in promo use document', { correlationId });
      return;
    }

    logger.info('Processing promo code use notification', {
      correlationId,
      promoCodeId,
      userId
    });

    // Get promo code document to find the owner
    const promoCodeDoc = await db.collection('promoCodes').doc(promoCodeId).get();
    if (!promoCodeDoc.exists) {
      logger.warn('Promo code document not found', { correlationId, promoCodeId });
      return;
    }

    const promoCodeData = promoCodeDoc.data();
    const ownerUid = promoCodeData?.ownerUid;

    if (!ownerUid) {
      logger.warn('No owner UID in promo code document', { correlationId, promoCodeId });
      return;
    }

    // Get notification message from Remote Config
    const remoteConfig = getRemoteConfigService();
    const message = await remoteConfig.getNotificationMessage(
      'notification_promo_used_msg',
      DEFAULT_NOTIFICATION_CONFIG.notification_promo_used_msg
    );

    // Send notification to influencer
    const notificationService = getNotificationService();
    const payload: NotificationPayload = {
      title: 'Promo Code Used! 🎉',
      body: message,
      data: {
        type: 'promo_used',
        promoCode: promoCodeId,
        userId: userId || 'unknown'
      }
    };

    const success = await notificationService.sendNotificationToUser(ownerUid, payload);
    
    logger.info('Promo code use notification sent', {
      correlationId,
      ownerUid,
      success
    });

  } catch (error) {
    logger.error('Error sending promo code use notification', {
      correlationId,
      error: error instanceof Error ? error.message : String(error)
    });
  }
});

/**
 * Auto-triggered notification: User Becomes Influencer → Get Personal Promo Code
 * Trigger: onCreate in promoCodes/{code} with ownerUid
 * Sends welcome notification when user becomes an influencer
 */
export const notifyNewInfluencer = onDocumentCreated({
  region: 'europe-west1',
  document: 'promoCodes/{code}'
}, async (event) => {
  const correlationId = `new_influencer_${Date.now()}`;
  
  try {
    const promoCodeData = event.data?.data();
    if (!promoCodeData) {
      logger.warn('No promo code data found', { correlationId });
      return;
    }

    const ownerUid = promoCodeData.ownerUid;
    const promoCode = event.params.code;

    if (!ownerUid) {
      logger.warn('No owner UID in new promo code document', { correlationId, promoCode });
      return;
    }

    logger.info('Processing new influencer notification', {
      correlationId,
      ownerUid,
      promoCode
    });

    // Get notification message from Remote Config with code substitution
    const remoteConfig = getRemoteConfigService();
    const message = await remoteConfig.getNotificationMessage(
      'notification_influencer_welcome_msg',
      DEFAULT_NOTIFICATION_CONFIG.notification_influencer_welcome_msg,
      { code: promoCode }
    );

    // Send notification to new influencer
    const notificationService = getNotificationService();
    const payload: NotificationPayload = {
      title: 'Welcome to the Influencer Program! 🌟',
      body: message,
      data: {
        type: 'influencer_welcome',
        promoCode: promoCode
      }
    };

    const success = await notificationService.sendNotificationToUser(ownerUid, payload);
    
    logger.info('New influencer notification sent', {
      correlationId,
      ownerUid,
      promoCode,
      success
    });

  } catch (error) {
    logger.error('Error sending new influencer notification', {
      correlationId,
      error: error instanceof Error ? error.message : String(error)
    });
  }
});

/**
 * Auto-triggered notification: User Reaches 50% or 100% of Daily Target
 * Trigger: onWrite to calorie_history/{date}
 * Sends progress notifications based on goal achievement
 */
export const notifyGoalProgress = onDocumentWritten({
  region: 'europe-west1',
  document: 'calorie_history/{date}'
}, async (event) => {
  const correlationId = `goal_progress_${Date.now()}`;
  
  try {
    const afterData = event.data?.after?.data();
    
    if (!afterData) {
      logger.warn('No calorie history data found', { correlationId });
      return;
    }

    const userId = afterData.userId;
    const totalCalories = afterData.totalCalories || 0;
    const targetCalories = afterData.targetCalories || 2000;
    const notified50 = afterData.notified50 || false;
    const notified100 = afterData.notified100 || false;

    if (!userId) {
      logger.warn('No user ID in calorie history document', { correlationId });
      return;
    }

    const progress = totalCalories / targetCalories;
    const progressPercent = Math.round(progress * 100);

    logger.info('Processing goal progress notification', {
      correlationId,
      userId,
      totalCalories,
      targetCalories,
      progressPercent,
      notified50,
      notified100
    });

    const remoteConfig = getRemoteConfigService();
    const notificationService = getNotificationService();
    
    // Check for 50% milestone
    if (progress >= 0.5 && !notified50) {
      const message = await remoteConfig.getNotificationMessage(
        'notification_goal_50pct_msg',
        DEFAULT_NOTIFICATION_CONFIG.notification_goal_50pct_msg
      );

      const payload: NotificationPayload = {
        title: 'Halfway There!',
        body: message,
        data: {
          type: 'goal_progress',
          milestone: '50',
          progress: progressPercent.toString()
        }
      };

      const success = await notificationService.sendNotificationToUser(userId, payload);
      
      if (success) {
        // Update document to mark 50% notification as sent
        await event.data?.after?.ref.update({
          notified50: true
        });
      }
      
      logger.info('50% goal progress notification sent', {
        correlationId,
        userId,
        progressPercent,
        success
      });
    }

    // Check for 100% milestone
    if (progress >= 1.0 && !notified100) {
      const message = await remoteConfig.getNotificationMessage(
        'notification_goal_100pct_msg',
        DEFAULT_NOTIFICATION_CONFIG.notification_goal_100pct_msg
      );

      const payload: NotificationPayload = {
        title: 'Goal Achieved! 🏆',
        body: message,
        data: {
          type: 'goal_progress',
          milestone: '100',
          progress: progressPercent.toString()
        }
      };

      const success = await notificationService.sendNotificationToUser(userId, payload);
      
      if (success) {
        // Update document to mark 100% notification as sent
        await event.data?.after?.ref.update({
          notified100: true
        });
      }
      
      logger.info('100% goal progress notification sent', {
        correlationId,
        userId,
        progressPercent,
        success
      });
    }

  } catch (error) {
    logger.error('Error sending goal progress notification', {
      correlationId,
      error: error instanceof Error ? error.message : String(error)
    });
  }
});

// =============================================================================
// NOTIFICATION SYSTEM - PHASE 4: Scheduled Notifications
// =============================================================================

/**
 * Scheduled notification: Lunch reminder
 * Schedule: Daily at 12:00 UTC (13:00 Algeria Time)
 * Uses Remote Config for timing and message content
 */
export const notifyLunchReminder = onSchedule({
  region: 'europe-west1',
  schedule: '0 12 * * *', // Daily at 12:00 UTC
  timeZone: 'UTC'
}, async () => {
  const correlationId = `lunch_reminder_${Date.now()}`;
  
  try {
    logger.info('Starting lunch reminder notification job', { correlationId });

    const remoteConfig = getRemoteConfigService();
    
    // Get lunch time from Remote Config
    const lunchTime = await remoteConfig.getNotificationTime(
      'notification_lunch_time',
      DEFAULT_NOTIFICATION_CONFIG.notification_lunch_time
    );

    // Check if current time matches lunch time (within tolerance)
    if (!remoteConfig.isCurrentTimeMatch(lunchTime, 5)) {
      logger.info('Current time does not match lunch time, skipping', {
        correlationId,
        lunchTime
      });
      return;
    }

    // Get lunch message from Remote Config
    const message = await remoteConfig.getNotificationMessage(
      'notification_lunch_msg',
      DEFAULT_NOTIFICATION_CONFIG.notification_lunch_msg
    );

    // Get all users who haven't logged a meal since 11:00 AM Algeria time
    const elevenAM = new Date();
    elevenAM.setUTCHours(10, 0, 0, 0); // 11:00 Algeria time = 10:00 UTC
    
    const usersQuery = await db.collection('users')
      .where('lastMealLog', '<', elevenAM)
      .limit(1000) // Process in batches
      .get();

    if (usersQuery.empty) {
      logger.info('No users found for lunch reminder', { correlationId });
      return;
    }

    const userIds = usersQuery.docs.map(doc => doc.id);
    
    // Send notification to all eligible users
    const notificationService = getNotificationService();
    const payload: NotificationPayload = {
      title: 'Lunch Time! 🍽️',
      body: message,
      data: {
        type: 'meal_reminder',
        mealType: 'lunch'
      }
    };

    const successCount = await notificationService.sendNotificationToUsers(userIds, payload);
    
    logger.info('Lunch reminder notifications completed', {
      correlationId,
      totalUsers: userIds.length,
      successCount
    });

  } catch (error) {
    logger.error('Error in lunch reminder notification job', {
      correlationId,
      error: error instanceof Error ? error.message : String(error)
    });
  }
});

/**
 * Scheduled notification: Evening check-in 
 * Schedule: Daily at 20:30 UTC (21:30 Algeria Time)
 * Handles dinner reminder and goal check only
 */
export const notifyEveningCheckin = onSchedule({
  region: 'europe-west1',
  schedule: '30 20 * * *', // Daily at 20:30 UTC
  timeZone: 'UTC'
}, async () => {
  const correlationId = `evening_checkin_${Date.now()}`;
  
  try {
    logger.info('Starting evening check-in notification job', { correlationId });

    const remoteConfig = getRemoteConfigService();
    const notificationService = getNotificationService();
    
    // Get dinner time from Remote Config
    const dinnerTime = await remoteConfig.getNotificationTime(
      'notification_dinner_time',
      DEFAULT_NOTIFICATION_CONFIG.notification_dinner_time
    );

    // Check if current time matches dinner time (within tolerance)
    if (!remoteConfig.isCurrentTimeMatch(dinnerTime, 5)) {
      logger.info('Current time does not match dinner time, skipping', {
        correlationId,
        dinnerTime
      });
      return;
    }

    // Get all users for evening notifications
    const usersQuery = await db.collection('users')
      .limit(1000) // Process in batches
      .get();

    if (usersQuery.empty) {
      logger.info('No users found for evening check-in', { correlationId });
      return;
    }

    let dinnerReminderCount = 0;
    let goalCheckCount = 0;

    // Process each user
    for (const userDoc of usersQuery.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      
      try {
        // 1. Dinner Reminder (if not logged after 19:00)
        const sevenPM = new Date();
        sevenPM.setUTCHours(18, 0, 0, 0); // 19:00 Algeria time = 18:00 UTC
        
        if (!userData.lastDinnerLog || userData.lastDinnerLog < sevenPM) {
          const dinnerMessage = await remoteConfig.getNotificationMessage(
            'notification_dinner_msg',
            DEFAULT_NOTIFICATION_CONFIG.notification_dinner_msg
          );

          const dinnerPayload: NotificationPayload = {
            title: 'Dinner Time! 🌙',
            body: dinnerMessage,
            data: {
              type: 'meal_reminder',
              mealType: 'dinner'
            }
          };

          const dinnerSuccess = await notificationService.sendNotificationToUser(userId, dinnerPayload);
          if (dinnerSuccess) dinnerReminderCount++;
        }

        // 2. End-of-Day Goal Check
        const today = new Date().toISOString().split('T')[0];
        const calorieHistoryDoc = await db
          .collection('calorie_history')
          .doc(`${userId}_${today}`)
          .get();

        if (calorieHistoryDoc.exists) {
          const historyData = calorieHistoryDoc.data();
          const totalCalories = historyData?.totalCalories || 0;
          const targetCalories = historyData?.targetCalories || 2000;
          const progress = totalCalories / targetCalories;

          if (progress < 0.9) { // Less than 90% of goal
            const goalMessage = await remoteConfig.getNotificationMessage(
              'notification_end_of_day_msg',
              DEFAULT_NOTIFICATION_CONFIG.notification_end_of_day_msg
            );

            const goalPayload: NotificationPayload = {
              title: 'Almost There! 🎯',
              body: goalMessage,
              data: {
                type: 'goal_check',
                progress: Math.round(progress * 100).toString()
              }
            };

            const goalSuccess = await notificationService.sendNotificationToUser(userId, goalPayload);
            if (goalSuccess) goalCheckCount++;
          }
        }

        // Small delay to avoid overwhelming the system
        await new Promise(resolve => setTimeout(resolve, 100));

      } catch (userError) {
        logger.warn('Error processing evening notifications for user', {
          correlationId,
          userId,
          error: userError instanceof Error ? userError.message : String(userError)
        });
      }
    }

    logger.info('Evening check-in notifications completed', {
      correlationId,
      totalUsers: usersQuery.docs.length,
      dinnerReminderCount,
      goalCheckCount
    });

  } catch (error) {
    logger.error('Error in evening check-in notification job', {
      correlationId,
      error: error instanceof Error ? error.message : String(error)
    });
  }
});
