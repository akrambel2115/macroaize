// Add CallableRequest to this import
import { onCall, onRequest, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { defineString } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import axios from 'axios';
import crypto from 'crypto';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import { CHARGILY_SECRET_KEY, getChargilyApiUrl, getPremiumMonthlyDzd, getPremiumYearlyDzd, getWebhookToleranceSeconds, getInfluencerMinWithdrawal, getInfluencerCommissionRate, getInfluencerFinanceEmail, getInfluencerWithdrawalProcessingDays } from './config';

dayjs.extend(utc);
dayjs.extend(timezone);

admin.initializeApp();

const db = getFirestore();

// Define limits as parameters so they can be changed without redeploying
const SCAN_LIMIT_PARAM = defineString('SCAN_LIMIT', { default: '2' });
const CHAT_LIMIT_PARAM = defineString('CHAT_LIMIT', { default: '5' });

// Helpers and other functions remain the same...
function planAmountDzd(planType: string): number {
  if (planType === 'yearly') return getPremiumYearlyDzd();
  return getPremiumMonthlyDzd();
}
export function addDuration(start: dayjs.Dayjs, planType: string): dayjs.Dayjs {
  return planType === 'yearly' ? start.add(1, 'year') : start.add(1, 'month');
}
function safeNow(): dayjs.Dayjs {
  return dayjs().utc();
}
function verifyHmac(signatureHeader: string | undefined, payload: string, secret: string): boolean {
  if (!signatureHeader) return false;
  try {
    const expected = crypto.createHmac('sha256', secret).update(payload, 'utf8').digest('hex');
    const sigBuf = Buffer.from(signatureHeader, 'hex');
    const expBuf = Buffer.from(expected, 'hex');
    if (sigBuf.length !== expBuf.length) return false;
    return crypto.timingSafeEqual(sigBuf, expBuf);
  } catch (e) {
    return false;
  }
}

// =================================================================
// ===== TEST FUNCTION (NO CHANGES) ================================
// =================================================================
export const testAuth = onCall({ region: 'europe-west1' }, (request: CallableRequest) => {
  console.log(`--- testAuth running in project: ${process.env.GCLOUD_PROJECT} ---`);
  if (!request.auth) {
    console.error('Authentication context is NULL!');
    throw new Error('authentication-failed');
  }
  console.log(`Authentication successful for UID: ${request.auth.uid}`);
  return {
    status: 'Success!',
    message: `Authenticated successfully as UID: ${request.auth.uid}`,
  };
});

// =================================================================
// ===== FINAL CORRECTED CODE ======================================
// =================================================================

export const createChargilyPayment = onCall({
  region: 'europe-west1',
  secrets: [CHARGILY_SECRET_KEY]
}, async (request: CallableRequest) => {
  const authedUid = request.auth?.uid;
  if (!authedUid) {
    throw new Error('unauthenticated');
  }

  const userId = request.data?.userId as string | undefined;
  const planType = (request.data?.planType as string | undefined)?.toLowerCase();
  const clientTimestamp = request.data?.timestamp;
  const promoCode = (request.data?.promoCode as string || '').toUpperCase().trim();

  // Audit log entry
  const auditLogData = {
    timestamp: FieldValue.serverTimestamp(),
    action: 'payment_attempt',
    userId: authedUid,
    requestedUserId: userId,
    planType,
    clientTimestamp,
    ip: request.rawRequest.ip || 'unknown',
    userAgent: request.rawRequest.headers['user-agent'] || 'unknown'
  };

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
    success_url: 'https://example.com/success',
    failure_url: 'https://example.com/failed'
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
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'success',
      amount: amountDzd,
      checkoutCreated: true
    });

    return { checkoutUrl };
  } catch (err: any) {
    await db.collection('audit_logs').add({
      ...auditLogData,
      result: 'chargily_error',
      reason: 'API request failed',
      error: err?.response?.data || err?.message || String(err)
    });
    
    console.error('Chargily create checkout failed', err?.response?.data || err?.message);
    throw new Error('internal');
  }
});


// =================================================================
// ===== USAGE TRACKING FUNCTIONS ==================================
// =================================================================

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

  // Check if user is premium - if so, allow unlimited usage
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

  // Non-premium user - check and increment usage
  const usageRef = db.collection('user_usage').doc(authedUid);
  const todayStart = safeNow().startOf('day');
  
  // Parse limits from params (available outside the transaction scope)
  const SCAN_LIMIT = parseInt(SCAN_LIMIT_PARAM.value() || '2', 10) || 2;
  const CHAT_LIMIT = parseInt(CHAT_LIMIT_PARAM.value() || '5', 10) || 5;

  try {
    const result = await db.runTransaction(async (transaction) => {
      const usageDoc = await transaction.get(usageRef);
      const usageData = usageDoc.exists ? usageDoc.data() : null;
      
      let scanCount = 0;
      let chatCount = 0;
      
      if (usageData) {
        const lastUsageRaw: any = (usageData as any).lastUsageDate;
        const lastUsageDate: Date | null = lastUsageRaw
          ? (typeof lastUsageRaw.toDate === 'function' ? lastUsageRaw.toDate() : new Date(lastUsageRaw))
          : null;
        const lastUsageDayStart = lastUsageDate ? dayjs(lastUsageDate).startOf('day') : null;

        if (lastUsageDayStart && lastUsageDayStart.isSame(todayStart)) {
          // Same day - use existing counts
          scanCount = (usageData as any).scanCount || 0;
          chatCount = (usageData as any).chatCount || 0;
        }
        // If different day, counts remain 0 (reset)
      }
      
  // Limits already parsed from params above
      
      // Check limits before incrementing
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

export const resetAllDailyUsage = onSchedule({
  region: 'europe-west1',
  schedule: '0 0 * * *', // Daily at 00:00 UTC
  timeZone: 'UTC'
}, async (event) => {
  // Scheduled function: not callable by users
  console.log('Starting scheduled resetAllDailyUsage job');
  try {
    const collectionRef = db.collection('user_usage');

    let processed = 0;
    let page = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;

    while (true) {
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
      console.log(`resetAllDailyUsage: committed page ${page}, total processed ${processed}`);
    }

    console.log(`Completed resetAllDailyUsage. Total documents updated: ${processed}`);
  } catch (error) {
    console.error('Error in scheduled resetAllDailyUsage:', error);
    // Let function succeed to avoid retries storm; consider alerting here
  }
});

// =================================================================
// ===== DAILY SUBSCRIPTION EXPIRY ENFORCER =========================
// =================================================================
// Flips isPremium to false when:
// - endDate has passed, or
// - startDate >= endDate (invalid/degenerate subscription)
// Runs once per day.
export const expireInvalidSubscriptions = onSchedule({
  region: 'europe-west1',
  schedule: '0 0 * * *', // Daily at 00:00 Africa/Algiers
  timeZone: 'Africa/Algiers'
}, async () => {
  console.log('Starting expireInvalidSubscriptions job');
  const now = safeNow();
  try {
    const collectionRef = db.collection('subscriptions');

    let processed = 0;
    let updated = 0;
    let page = 0;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;

    while (true) {
      const query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = lastDoc
        ? collectionRef.orderBy(admin.firestore.FieldPath.documentId()).startAfter(lastDoc.id).limit(500)
        : collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(500);

      const snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData> = await query.get();
      if (snapshot.empty) break;

      const batch = db.batch();

      snapshot.docs.forEach((doc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>) => {
        const data = doc.data() as any;
        const isPremium: boolean = data?.isPremium === true;
        if (!isPremium) { processed++; return; }

        const start = data?.startDate ? dayjs(data.startDate) : null;
        const end = data?.endDate ? dayjs(data.endDate) : null;

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
        }
        processed++;
      });

      if (updated > 0) {
        await batch.commit();
      }
      page++;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      console.log(`expireInvalidSubscriptions: page ${page} done, processed=${processed}, updated=${updated}`);
    }

    console.log(`Completed expireInvalidSubscriptions. Total processed: ${processed}, updated: ${updated}`);
  } catch (error) {
    console.error('Error in expireInvalidSubscriptions:', error);
    // Allow function to succeed to avoid repeated retries; consider alerting.
  }
});

export const chargilyWebhook = onRequest({
  region: 'europe-west1',
  secrets: [CHARGILY_SECRET_KEY]
}, async (req: any, res: any) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  // Use rawBody for HMAC integrity; available in Firebase Functions
  const hasRaw = (req as any).rawBody;
  const rawBodyBuffer: Buffer = hasRaw ? (req as any).rawBody as Buffer : Buffer.from(typeof req.body === 'string' ? req.body : JSON.stringify(req.body), 'utf8');
  const rawBody = rawBodyBuffer.toString('utf8');
  const signature = req.get?.('x-chargily-signature') || req.get?.('signature') || req.headers['x-chargily-signature'] || req.headers['signature'] || '';

  // Optional replay protection if Chargily provides a timestamp header
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

  if (!verifyHmac(signature, rawBody, secret)) {
    console.warn('Invalid webhook signature');
    res.status(403).send('Invalid signature');
    return;
  }

  let event: any;
  try {
    event = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    console.error('Invalid JSON body');
    res.status(400).send('Bad Request');
    return;
  }
  try {
    // Example Chargily event: { type, data: { status, metadata, ... } }
    const type = event?.type || event?.event || 'unknown';
    const data = event?.data || event?.payload || {};
    const status = data?.status || data?.payment?.status;
    const metadata = data?.metadata || {};
    const eventId: string | undefined = event?.id || data?.id || data?.payment_id || data?.checkout_id;

    // Idempotency: if we have an identifiable event id, ensure single processing
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

      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(subRef);
          const existing = snap.exists ? snap.data() as any : null;
          const prevEnd = existing?.endDate ? dayjs(existing.endDate) : null;
          // Renewals: extend remaining time if subscription still active
          const start = prevEnd && prevEnd.isAfter(now) ? prevEnd : now;
          const end = addDuration(start, planType);

          // Idempotent-ish: if existing endDate is same or after desired end, skip write
          if (prevEnd && (prevEnd.isSame(end) || prevEnd.isAfter(end))) return;

          const subscriptionData: any = {
            userId,
            isPremium: true,
            planType,
            startDate: start.toISOString(),
            endDate: end.toISOString(),
            provider: 'chargily',
            status: 'active',
            updatedAt: FieldValue.serverTimestamp()
          };

          // Add promo code to subscription if used
          if (promoCode) {
            subscriptionData.promoCodeUsed = promoCode;
          }

          tx.set(subRef, subscriptionData, { merge: true });

          // Track promo code usage if applicable
          if (promoCode && originalAmount) {
            try {
              // Find the influencer
              const influencersQuery = await db.collection('influencers')
                .where('promoCode', '==', promoCode)
                .where('isActive', '==', true)
                .limit(1)
                .get();

              if (!influencersQuery.empty) {
                const influencerDoc = influencersQuery.docs[0];
                const influencerId = influencerDoc.id;

                // Calculate commission based on original amount
                const commissionRate = getInfluencerCommissionRate();
                const commission = Math.round(originalAmount * commissionRate);

                // Update influencer earnings
                const influencerRef = db.collection('influencers').doc(influencerId);
                const currentInfluencer = await tx.get(influencerRef);
                
                if (currentInfluencer.exists) {
                  const data = currentInfluencer.data()!;
                  const newEarnings = (data.earningsDzd || 0) + commission;
                  const newTotalEarnings = (data.totalEarningsDzd || 0) + commission;
                  const newUsersCount = (data.usersCount || 0) + 1;

                  tx.update(influencerRef, {
                    earningsDzd: newEarnings,
                    totalEarningsDzd: newTotalEarnings,
                    usersCount: newUsersCount,
                    updatedAt: FieldValue.serverTimestamp()
                  });

                  // Create audit log
                  tx.create(db.collection('influencer_audit').doc(), {
                    userId: influencerId,
                    action: 'commission_earned',
                    amount: commission,
                    details: {
                      promoCode,
                      subscriptionUserId: userId,
                      subscriptionAmount: originalAmount,
                      commissionRate,
                      paymentProcessedAt: FieldValue.serverTimestamp()
                    },
                    timestamp: FieldValue.serverTimestamp(),
                    status: 'completed'
                  });
                }
              }
            } catch (promoError) {
              console.error('Error processing promo code commission:', promoError);
              // Continue with subscription creation even if promo tracking fails
            }
          }
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

// =================================================================
// ===== USAGE HYDRATION AND SYNC ==================================
// =================================================================

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
      const s = subSnap.data() as any;
      const end = s?.endDate ? dayjs(s.endDate) : null;
      if (s?.isPremium === true && end && end.isAfter(safeNow())) {
        isPremium = true;
      }
    }
  } catch (e) {
    // Treat errors as non-premium (fail closed)
    isPremium = false;
  }

  // Limits from params (server-of-record values)
  const SCAN_LIMIT = parseInt(SCAN_LIMIT_PARAM.value() || '2', 10) || 2;
  const CHAT_LIMIT = parseInt(CHAT_LIMIT_PARAM.value() || '5', 10) || 5;

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
    const d = snap.data() as any;
    const last: any = d?.lastUsageDate;
    let lastDate: dayjs.Dayjs | null = null;
    if (last?.toDate) {
      lastDate = dayjs(last.toDate()).utc();
    } else if (typeof last === 'string') {
      const parsed = dayjs(last);
      lastDate = parsed.isValid() ? parsed.utc() : null;
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

export const syncUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  // Parse client-reported counts safely
  const clientScan = Math.max(0, parseInt(String(request.data?.scanCount ?? 0), 10) || 0);
  const clientChat = Math.max(0, parseInt(String(request.data?.chatCount ?? 0), 10) || 0);

  // Limits from params
  const SCAN_LIMIT = parseInt(SCAN_LIMIT_PARAM.value() || '2', 10) || 2;
  const CHAT_LIMIT = parseInt(CHAT_LIMIT_PARAM.value() || '5', 10) || 5;

  // If premium, we simply acknowledge — we do not need to persist counts
  try {
    const subSnap = await db.collection('subscriptions').doc(uid).get();
    if (subSnap.exists) {
      const s = subSnap.data() as any;
      const end = s?.endDate ? dayjs(s.endDate) : null;
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
    let last: any = null;
    if (snap.exists) {
      const d = snap.data() as any;
      last = d?.lastUsageDate;
      let lastDate: dayjs.Dayjs | null = null;
      if (last?.toDate) {
        lastDate = dayjs(last.toDate()).utc();
      } else if (typeof last === 'string') {
        const parsed = dayjs(last);
        lastDate = parsed.isValid() ? parsed.utc() : null;
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

// =================================================================
// ===== INFLUENCER PROMO CODE FUNCTIONS ==========================
// =================================================================

// Rate limiting helper for promo code validation
const promoCodeAttempts = new Map<string, { count: number; lastAttempt: number }>();

function isValidPromoCode(code: string): boolean {
  if (!code || typeof code !== 'string') return false;
  if (code.length < 6 || code.length > 12) return false;
  return /^[A-Z0-9]+$/.test(code);
}

function isValidRIP(rip: string): boolean {
  if (!rip || typeof rip !== 'string') return false;
  // Algerian bank account format validation (simplified)
  return /^\d{20,24}$/.test(rip.replace(/\s/g, ''));
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

export const trackPromoUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  // Verify this is being called from a trusted context (backend function)
  // In a real implementation, you'd use Firebase Auth custom claims
  const isBackendCall = request.auth?.token?.admin === true;
  if (!isBackendCall) {
    throw new Error('permission-denied');
  }

  const promoCode = (request.data?.promoCode as string || '').toUpperCase().trim();
  const subscriptionUserId = request.data?.userId as string;
  const subscriptionAmount = request.data?.amount as number;

  if (!isValidPromoCode(promoCode) || !subscriptionUserId || !subscriptionAmount || subscriptionAmount <= 0) {
    throw new Error('invalid-argument');
  }

  try {
    // Find the influencer
    const influencersQuery = await db.collection('influencers')
      .where('promoCode', '==', promoCode)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (influencersQuery.empty) {
      throw new Error('invalid-code');
    }

    const influencerDoc = influencersQuery.docs[0];
    const influencerId = influencerDoc.id;

    // Calculate commission
    const commissionRate = getInfluencerCommissionRate();
    const commission = Math.round(subscriptionAmount * commissionRate);

    // Update influencer earnings in transaction
    await db.runTransaction(async (transaction) => {
      const influencerRef = db.collection('influencers').doc(influencerId);
      const currentData = await transaction.get(influencerRef);
      
      if (!currentData.exists) {
        throw new Error('Influencer not found');
      }

      const data = currentData.data()!;
      const newEarnings = (data.earningsDzd || 0) + commission;
      const newTotalEarnings = (data.totalEarningsDzd || 0) + commission;
      const newUsersCount = (data.usersCount || 0) + 1;

      transaction.update(influencerRef, {
        earningsDzd: newEarnings,
        totalEarningsDzd: newTotalEarnings,
        usersCount: newUsersCount,
        updatedAt: FieldValue.serverTimestamp()
      });

      // Create audit log
      transaction.create(db.collection('influencer_audit').doc(), {
        userId: influencerId,
        action: 'commission_earned',
        amount: commission,
        details: {
          promoCode,
          subscriptionUserId,
          subscriptionAmount,
          commissionRate
        },
        timestamp: FieldValue.serverTimestamp(),
        status: 'completed'
      });
    });

    return {
      success: true,
      commission,
      influencerId
    };

  } catch (error) {
    console.error('Error tracking promo usage:', error);
    throw new Error('internal');
  }
});

export const processWithdrawal = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new Error('unauthenticated');
  }

  const amount = request.data?.amount as number;
  const rip = (request.data?.rip as string || '').trim();

  if (!amount || amount <= 0 || !isValidRIP(rip)) {
    throw new Error('invalid-argument');
  }

  const minWithdrawal = getInfluencerMinWithdrawal();
  if (amount < minWithdrawal) {
    throw new Error(`Minimum withdrawal amount is ${minWithdrawal} DZD`);
  }

  try {
    // Check if user is an influencer
    const influencerDoc = await db.collection('influencers').doc(uid).get();
    if (!influencerDoc.exists) {
      throw new Error('permission-denied');
    }

    const influencerData = influencerDoc.data()!;
    if (!influencerData.isActive) {
      throw new Error('Account is not active');
    }

    // Check recent withdrawal attempts (one per week limit)
    const oneWeekAgo = safeNow().subtract(7, 'days').toDate();
    const recentWithdrawals = await db.collection('influencer_audit')
      .where('userId', '==', uid)
      .where('action', '==', 'withdrawal_requested')
      .where('timestamp', '>', oneWeekAgo)
      .limit(1)
      .get();

    if (!recentWithdrawals.empty) {
      throw new Error('withdrawal-too-frequent');
    }

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
      const withdrawalRecord = {
        id: withdrawalId,
        amount,
        ripLast4: rip.slice(-4), // Store only last 4 digits for security
        requestedAt: FieldValue.serverTimestamp(),
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
          ripLast4: rip.slice(-4),
          previousBalance: currentBalance,
          newBalance
        },
        timestamp: FieldValue.serverTimestamp(),
        status: 'processing'
      });

      // Create email notification
      transaction.create(db.collection('mail').doc(), {
        to: [getInfluencerFinanceEmail()],
        message: {
          subject: `Withdrawal Request - ${withdrawalId}`,
          text: `
New withdrawal request received:

Withdrawal ID: ${withdrawalId}
Influencer ID: ${uid}
Amount: ${amount} DZD
Bank Account (RIP): ${rip}
Requested At: ${new Date().toISOString()}

Please process this withdrawal within ${getInfluencerWithdrawalProcessingDays()} business days.
          `.trim(),
          html: `
<h2>New Withdrawal Request</h2>
<p><strong>Withdrawal ID:</strong> ${withdrawalId}</p>
<p><strong>Influencer ID:</strong> ${uid}</p>
<p><strong>Amount:</strong> ${amount} DZD</p>
<p><strong>Bank Account (RIP):</strong> ${rip}</p>
<p><strong>Requested At:</strong> ${new Date().toISOString()}</p>
<p>Please process this withdrawal within ${getInfluencerWithdrawalProcessingDays()} business days.</p>
          `.trim()
        }
      });
    });

    return {
      success: true,
      withdrawalId,
      message: `Withdrawal request submitted. Processing time: ${getInfluencerWithdrawalProcessingDays()} business days.`
    };

  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'withdrawal-too-frequent') {
        throw new Error('You can only request one withdrawal per week.');
      }
      if (error.message === 'insufficient-funds') {
        throw new Error('Insufficient balance for this withdrawal amount.');
      }
    }
    console.error('Error processing withdrawal:', error);
    throw new Error('internal');
  }
});