import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onRequest } from 'firebase-functions/v2/https';
import { Request, Response } from 'express';
import { logger } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import crypto from 'crypto';
import axios from 'axios';
import { REVENUECAT_WEBHOOK_SECRET, REVENUECAT_REST_API_KEY } from '../../config';
import { getPromoExtensionDaysMonthly, getPromoExtensionDaysYearly, getInfluencerEarnForCode } from '../../remote_config_service';

const db = admin.firestore();


const isYearlyProduct = (productId: string): boolean => {
    const p = productId.toLowerCase();
    return p.includes('year') || p.includes('annual') || p.includes('yr');
};


const extendSubscriptionForPromoCode = async (
    uid: string,
    productId: string,
    purchasedAtMs: number | null,
    apiKey: string
): Promise<void> => {
    if (!uid || !apiKey) return;

    try {

        const promoUseDoc = await db.collection('promoUses').doc(uid).get();
        
        logger.info('Checking promoUses for subscription extension', { 
            uid, 
            docExists: promoUseDoc.exists,
            docPath: `promoUses/${uid}`
        });
        
        if (!promoUseDoc.exists) {
            logger.info('No promo code linked for user', { uid });
            return;
        }
        
        const promoData = promoUseDoc.data();
        if (!promoData) return;
        
        if (promoData.extensionApplied === true) {
            logger.info('Promo extension already applied for this user', { uid, promoCode: promoData.promoCode });
            return;
        }
        
        const promoCode = promoData.promoCode;
        if (!promoCode) {
            logger.warn('Missing promoCode in promoUses doc', { uid, promoData });
            return;
        }


        const isYearly = isYearlyProduct(productId);
        const extensionDays = isYearly ? getPromoExtensionDaysYearly() : getPromoExtensionDaysMonthly();
        
        logger.info('Extending subscription for promo code', {
            uid,
            promoCode,
            productId,
            isYearly,
            extensionDays
        });

        const customerInfoUrl = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`;
        const customerResponse = await axios.get(customerInfoUrl, {
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            }
        });

        const subscriber = customerResponse.data?.subscriber;
        if (!subscriber || !subscriber.subscriptions) {
            logger.warn('No subscriber or subscriptions found', { uid });
            return;
        }

        const subscriptions = subscriber.subscriptions;
        let subscription = subscriptions[productId];
        let actualProductId = productId;
        
        // handle base ids
        if (!subscription && productId.includes(':')) {
            const baseProductId = productId.split(':')[0];
            subscription = subscriptions[baseProductId];
            if (subscription) {
                actualProductId = baseProductId;
                logger.info('Found subscription using base product ID', { 
                    uid, 
                    originalProductId: productId, 
                    baseProductId 
                });
            }
        }

        if (!subscription) {
            const subKeys = Object.keys(subscriptions);
            logger.info('Available subscriptions in RevenueCat', { uid, subscriptionKeys: subKeys });
            
            for (const key of subKeys) {
                const sub = subscriptions[key];
                const expiresDate = sub.expires_date ? new Date(sub.expires_date).getTime() : null;
                if (expiresDate && expiresDate > Date.now()) {
                    subscription = sub;
                    actualProductId = key;
                    logger.info('Found active subscription by scanning', { uid, foundProductId: key });
                    break;
                }
            }
        }
        
        if (!subscription) {
            logger.warn('No subscription found for product', { uid, productId, availableKeys: Object.keys(subscriptions) });
            return;
        }

        const store = subscription.store;
        const originalTransactionId = subscription.original_purchase_date ? 
            subscription.store_transaction_id || subscription.original_transaction_id : null;
        
        if (!originalTransactionId) {
            logger.warn('No transaction ID found for subscription', { uid, productId: actualProductId });
            return;
        }

        let extensionSuccess = false;
        let extensionSkippedReason: string | null = null;

        const isSandbox = subscription.is_sandbox === true || 
                         subscription.environment === 'SANDBOX' ||
                         subscription.sandbox === true;

        if (isSandbox) {
            // sandbox unsupported
            logger.info('SANDBOX: Promo extension would be applied in production', {
                uid,
                promoCode,
                productId: actualProductId,
                extensionDays,
                store,
                note: 'RevenueCat defer/extend API does not work in sandbox mode'
            });
            extensionSuccess = true; 
            extensionSkippedReason = 'SANDBOX_MODE';
        } else {
            if (store === 'play_store' || store === 'PLAY_STORE') {
                const deferUrl = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}/subscriptions/${encodeURIComponent(actualProductId)}/defer`;
                
                try {
                    const deferResponse = await axios.post(deferUrl, {
                        extend_by_days: extensionDays
                    }, {
                        headers: {
                            'Authorization': `Bearer ${apiKey}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    
                    logger.info('Google Play subscription deferred successfully', {
                        uid,
                        productId: actualProductId,
                        extensionDays,
                        response: deferResponse.status
                    });
                    extensionSuccess = true;
                } catch (deferError: any) {
                    logger.error('Failed to defer Google Play subscription', {
                        error: deferError.response?.data || deferError.message,
                        uid,
                        productId: actualProductId
                    });
                }
            } else if (store === 'app_store' || store === 'APP_STORE') {
                const extendDays = Math.min(extensionDays, 90); 
                const extendUrl = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}/subscriptions/${encodeURIComponent(originalTransactionId)}/extend`;
                
                try {
                    const extendResponse = await axios.post(extendUrl, {
                        extend_by_days: extendDays,
                        extend_reason_code: 1 
                    }, {
                        headers: {
                            'Authorization': `Bearer ${apiKey}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    
                    logger.info('App Store subscription extended successfully', {
                        uid,
                        originalTransactionId,
                        extensionDays: extendDays,
                        response: extendResponse.status
                    });
                    extensionSuccess = true;
                } catch (extendError: any) {
                    logger.error('Failed to extend App Store subscription', {
                        error: extendError.response?.data || extendError.message,
                        uid,
                        originalTransactionId
                    });
                }
            } else {
                logger.warn('Unsupported store for subscription extension', { uid, store });
            }
        }

        // prevent retry loops
        await db.collection('promoUses').doc(uid).update({
            extensionApplied: true,
            extensionAppliedAt: admin.firestore.FieldValue.serverTimestamp(),
            extensionDays: extensionDays,
            extensionSuccess: extensionSuccess,
            extensionSkippedReason: extensionSkippedReason,
            productId: actualProductId,
            store: store
        });

        await db.collection('subscriptions').doc(uid).set({
            promoCodeUsed: promoCode,
            promoExtensionDays: extensionDays,
            promoExtensionApplied: extensionSuccess,
            promoExtensionSkippedReason: extensionSkippedReason
        }, { merge: true });

        await db.collection('promo_audit').add({
            userId: uid,
            action: extensionSkippedReason ? 'promo_extension_simulated' : 'promo_extension_applied',
            promoCode: promoCode,
            productId: actualProductId,
            extensionDays: extensionDays,
            success: extensionSuccess,
            skippedReason: extensionSkippedReason,
            store: store,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        try {
            const influencersQuery = await db.collection('influencers')
                .where('promoCode', '==', promoCode)
                .where('isActive', '==', true)
                .limit(1)
                .get();

            if (!influencersQuery.empty) {
                const influencerDoc = influencersQuery.docs[0];
                const influencerId = influencerDoc.id;
                const influencerData = influencerDoc.data();
                
                // custom vs default earn
                const earnAmount = typeof influencerData.earnAmount === 'number' && influencerData.earnAmount > 0
                    ? influencerData.earnAmount
                    : getInfluencerEarnForCode();

                await db.runTransaction(async (tx) => {
                    const influencerRef = db.collection('influencers').doc(influencerId);
                    const currentInfluencer = await tx.get(influencerRef);
                    
                    if (currentInfluencer.exists) {
                        const data = currentInfluencer.data()!;
                        const newEarnings = Math.max(0, (data.earningsDzd || 0)) + earnAmount;
                        const newTotalEarnings = Math.max(0, (data.totalEarningsDzd || 0)) + earnAmount;
                        const newUsersCount = Math.max(0, (data.usersCount || 0)) + 1;

                        tx.update(influencerRef, {
                            earningsDzd: newEarnings,
                            totalEarningsDzd: newTotalEarnings,
                            usersCount: newUsersCount,
                            lastEarningDate: admin.firestore.FieldValue.serverTimestamp(),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });

                        logger.info('Credited influencer for promo code usage', {
                            influencerId,
                            promoCode,
                            earnAmount,
                            newUsersCount,
                            subscriberUid: uid
                        });
                    }
                });

                await db.collection('subscriptions').doc(uid).set({
                    commissionProcessed: true,
                    commissionAmount: earnAmount,
                    commissionInfluencerId: influencerId,
                    commissionProcessedAt: admin.firestore.FieldValue.serverTimestamp()
                }, { merge: true });

                await db.collection('influencer_audit').add({
                    userId: influencerId,
                    action: 'commission_earned',
                    amount: earnAmount,
                    details: {
                        promoCode,
                        subscriptionUserId: uid,
                        productId: actualProductId,
                        store: store,
                        isSandbox: isSandbox
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    status: 'completed',
                    source: 'webhook_auto'
                });

            } else {
                logger.warn('No active influencer found for promo code', { promoCode, uid });
            }
        } catch (creditError) {
            logger.error('Failed to credit influencer, but promo extension was applied', {
                error: creditError instanceof Error ? creditError.message : String(creditError),
                promoCode,
                uid
            });
            await db.collection('subscriptions').doc(uid).set({
                commissionProcessed: false,
                commissionError: creditError instanceof Error ? creditError.message : 'Unknown error'
            }, { merge: true });
        }

        logger.info('Promo extension process completed', {
            uid,
            promoCode,
            extensionDays,
            extensionSuccess,
            extensionSkippedReason
        });

    } catch (error) {
        logger.error('Error extending subscription for promo code', {
            error: error instanceof Error ? error.message : String(error),
            uid
        });
    }
};

// trust store data
const updateSubscriptionInFirestore = async (uid: string, data: {
    productId: string | null;
    purchasedAtMs: number | null;
    expirationAtMs: number | null;
    entitlements?: any;
    eventType?: string;
    store?: string;
    environment?: string;
    isTrial?: boolean;
    autoRenewStatus?: boolean;
    cancellationReason?: string;
    gracePeriodExpiresAtMs?: number | null;
    originalPurchasedAtMs?: number | null;
    priceInPurchasedCurrency?: number | null;
    currency?: string;
}) => {
    const { 
        productId, 
        purchasedAtMs, 
        expirationAtMs, 
        entitlements,
        eventType,
        store,
        environment,
        isTrial,
        autoRenewStatus,
        cancellationReason,
        gracePeriodExpiresAtMs,
        originalPurchasedAtMs,
        priceInPurchasedCurrency,
        currency
    } = data;

    const guessPlanFromProduct = (pid: string): string => {
        const p = pid.toLowerCase();
        if (p.includes('year') || p.includes('annual') || p.includes('yr')) return 'yearly';
        return 'monthly';
    };
    
    const planType = productId ? guessPlanFromProduct(productId) : 'monthly';

    const startIso = purchasedAtMs 
        ? new Date(purchasedAtMs).toISOString() 
        : (originalPurchasedAtMs ? new Date(originalPurchasedAtMs).toISOString() : null);
    
    const endIso = expirationAtMs 
        ? new Date(expirationAtMs).toISOString() 
        : null;

    const gracePeriodEndIso = gracePeriodExpiresAtMs 
        ? new Date(gracePeriodExpiresAtMs).toISOString() 
        : null;

    const originalPurchaseIso = originalPurchasedAtMs 
        ? new Date(originalPurchasedAtMs).toISOString() 
        : startIso;

    const now = Date.now();
    let isActive = false;
    
    if (expirationAtMs) {
        isActive = expirationAtMs > now;
    }
    
    if (!isActive && gracePeriodExpiresAtMs && gracePeriodExpiresAtMs > now) {
        isActive = true;
    }

    // entitlements priority
    if (entitlements) {
        const all = Object.values(entitlements);
        const active: any = all.find((e: any) => {
            const exp = e.expires_date ? new Date(e.expires_date).getTime() : null;
            return !exp || exp > now;
        });
        if (active) {
            isActive = true;
        }
    }

    let status: string = isActive ? 'active' : 'expired';
    
    if (eventType) {
        switch (eventType.toUpperCase()) {
            case 'INITIAL_PURCHASE':
            case 'RENEWAL':
            case 'PRODUCT_CHANGE':
            case 'UNCANCELLATION':
                status = 'active';
                break;
            case 'CANCELLATION':
                status = isActive ? 'canceled' : 'expired';
                break;
            case 'BILLING_ISSUE':
                status = 'past_due';
                break;
            case 'SUBSCRIPTION_PAUSED':
                status = 'paused';
                break;
            case 'EXPIRATION':
                status = 'expired';
                isActive = false;
                break;
            case 'SUBSCRIBER_ALIAS':
                // ignore alias
                break;
        }
    }

    const subscriptionData: Record<string, any> = {
        userId: uid,
        isPremium: isActive,
        planType,
        provider: 'revenuecat',
        status,
        productId: productId || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (startIso) {
        subscriptionData.startDate = startIso;
    }
    if (endIso) {
        subscriptionData.endDate = endIso;
    }
    if (originalPurchaseIso) {
        subscriptionData.originalPurchaseDate = originalPurchaseIso;
    }
    if (gracePeriodEndIso) {
        subscriptionData.gracePeriodEndDate = gracePeriodEndIso;
    }

    if (store) {
        subscriptionData.store = store; 
    }
    if (environment) {
        subscriptionData.environment = environment; 
    }
    if (typeof isTrial === 'boolean') {
        subscriptionData.isTrial = isTrial;
    }
    if (typeof autoRenewStatus === 'boolean') {
        subscriptionData.autoRenewStatus = autoRenewStatus;
    }
    if (cancellationReason) {
        subscriptionData.cancellationReason = cancellationReason;
    }
    if (priceInPurchasedCurrency !== null && priceInPurchasedCurrency !== undefined) {
        subscriptionData.price = priceInPurchasedCurrency;
    }
    if (currency) {
        subscriptionData.currency = currency;
    }
    if (eventType) {
        subscriptionData.lastEventType = eventType.toUpperCase();
        subscriptionData.lastEventAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await db.collection('subscriptions').doc(uid).set(subscriptionData, { merge: true });

    logger.info('Updated subscription for user (full sync)', { 
        uid, 
        isActive, 
        planType, 
        status,
        eventType,
        store,
        environment,
        isTrial,
        autoRenewStatus,
        endDate: endIso,
        expirationAtMs,
    });
    
    return isActive;
};

export const refreshSubscription = onCall(
    {
        region: 'europe-west1',
        secrets: [REVENUECAT_REST_API_KEY],
        maxInstances: 10,
    },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'User must be logged in');
        }

        const uid = request.auth.uid;
        logger.info('Manual subscription refresh requested', { uid });

        try {
            const apiKey = REVENUECAT_REST_API_KEY.value();
            const response = await axios.get(
                `https://api.revenuecat.com/v1/subscribers/${uid}`,
                {
                    headers: {
                        'Authorization': `Bearer ${apiKey}`,
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    }
                }
            );

            const subscriber = response.data?.subscriber;
            if (!subscriber) {
                logger.warn('No subscriber data found in RevenueCat', { uid });
                return { success: false, isPremium: false };
            }

            // find active sub
            const subscriptions = subscriber.subscriptions || {};
            const entitlements = subscriber.entitlements || {};
            const activeEntitlementIds = Object.keys(entitlements).filter(id => {
                const e = entitlements[id];
                const exp = e.expires_date ? new Date(e.expires_date).getTime() : null;
                return !exp || exp > Date.now();
            });

            let targetSubKey = null;
            let targetSub = null;

            for (const entId of activeEntitlementIds) {
                const ent = entitlements[entId];
                const prodId = ent.product_identifier;
                if (subscriptions[prodId]) {
                    targetSubKey = prodId;
                    targetSub = subscriptions[prodId];
                    break;
                }
            }

            if (!targetSub) {
                const subKeys = Object.keys(subscriptions);
                const sortedSubs = subKeys
                    .map(k => ({ key: k, value: subscriptions[k] }))
                    .sort((a, b) => {
                        const dateA = new Date(a.value.expires_date || 0).getTime();
                        const dateB = new Date(b.value.expires_date || 0).getTime();
                        return dateB - dateA;
                    });

                if (sortedSubs.length > 0) {
                    targetSubKey = sortedSubs[0].key;
                    targetSub = sortedSubs[0].value;
                }
            }

            if (!targetSub) {
                logger.info('No active subscriptions found for user in RevenueCat', { uid });
                await db.collection('subscriptions').doc(uid).set({
                    userId: uid,
                    isPremium: false,
                    status: 'expired',
                    provider: 'revenuecat',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    lastEventType: 'MANUAL_REFRESH_NO_SUB',
                    lastEventAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                return { success: true, isPremium: false };
            }

            const purchasedAtMs = targetSub.purchase_date ? new Date(targetSub.purchase_date).getTime() : null;
            const expirationAtMs = targetSub.expires_date ? new Date(targetSub.expires_date).getTime() : null;
            const originalPurchasedAtMs = targetSub.original_purchase_date ? new Date(targetSub.original_purchase_date).getTime() : null;
            const gracePeriodExpiresAtMs = targetSub.grace_period_expires_date ? new Date(targetSub.grace_period_expires_date).getTime() : null;
            
            const store = targetSub.store || null;
            const isTrial = targetSub.is_sandbox === false && targetSub.period_type === 'trial';
            const autoRenewStatus = targetSub.auto_renew_status === true;
            const cancellationReason = targetSub.unsubscribe_detected_at ? 'USER_CANCELLED' : null;
            
            const environment = targetSub.is_sandbox ? 'SANDBOX' : 'PRODUCTION';

            logger.info('Refreshing subscription with full data', {
                uid,
                productId: targetSubKey,
                store,
                environment,
                isTrial,
                autoRenewStatus,
                purchasedAtMs,
                expirationAtMs,
                gracePeriodExpiresAtMs,
            });

            await updateSubscriptionInFirestore(uid, {
                productId: targetSubKey,
                purchasedAtMs,
                expirationAtMs,
                entitlements,
                eventType: 'MANUAL_REFRESH',
                store: store || undefined,
                environment: environment || undefined,
                isTrial,
                autoRenewStatus,
                cancellationReason: cancellationReason || undefined,
                gracePeriodExpiresAtMs,
                originalPurchasedAtMs,
            });

            const isActive = expirationAtMs ? expirationAtMs > Date.now() : false;

            return { success: true, isPremium: isActive };

        } catch (error: any) {
            if (axios.isAxiosError(error)) {
                const status = error.response?.status;
                const data = error.response?.data;
                logger.error('RevenueCat API Error', {
                    status,
                    data,
                    headers: error.response?.headers,
                    message: error.message
                });
                if (status === 401) {
                    throw new HttpsError('permission-denied', 'Invalid RevenueCat API configuration');
                }
                if (status === 404) {
                    // handle new users
                    logger.info('User not found in RevenueCat', { uid });
                    return { success: true, isPremium: false };
                }
            } else {
                logger.error('Failed to refresh subscription from RevenueCat', error);
            }
            throw new HttpsError('internal', `Failed to sync with RevenueCat provider: ${error.message}`);
        }
    }
);

export const revenuecatWebhook = onRequest(
    {
        region: 'europe-west1',
        secrets: [REVENUECAT_WEBHOOK_SECRET, REVENUECAT_REST_API_KEY],
        maxInstances: 10,
        memory: '256MiB',
    },
    async (req: Request, res: Response) => {
        if (req.method !== 'POST') {
            res.status(405).send('Method Not Allowed');
            return;
        }

        const authHeader = req.get('Authorization') || req.headers['authorization'];
        const expected = `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`;

        logger.info('Received RevenueCat event', {
            method: req.method,
            hasAuth: !!authHeader,
            ua: req.get('user-agent')
        });

        if (authHeader !== expected) {
            logger.warn('RevenueCat invalid authorization', {
                received: authHeader ? `${authHeader.substring(0, 15)}...` : 'none',
                expectedPrefix: 'Bearer ...'
            });
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
                    receivedAt: admin.firestore.FieldValue.serverTimestamp(),
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

            logger.info('Processing RevenueCat payload', {
                type: typeRaw,
                uid: uid,
                eventId: eventId,
                productId: ev?.product_id || ev?.productIdentifier,
            });

            if (!uid || uid.startsWith('$RCAnonymousID')) {
                logger.warn('RevenueCat ignored event for anonymous/missing user', {
                    uid: uid,
                    type: typeRaw,
                    productId: ev?.product_id
                });
                res.status(200).send('ignored');
                return;
            }

            const productId: string = String(
                ev?.product_id ||
                ev?.productIdentifier ||
                ev?.transaction?.product_id ||
                ''
            );

            // schema compatibility
            const rawPurchasedAtMs =
                ev?.purchased_at_ms ??
                ev?.purchase_date_ms ??
                event?.event?.purchased_at_ms ??
                event?.event?.purchase_date_ms ??
                null;
            
            const rawExpirationAtMs =
                ev?.expiration_at_ms ??
                ev?.expires_at_ms ??
                event?.event?.expiration_at_ms ??
                event?.event?.expires_at_ms ??
                null;

            const purchasedAtMs: number | null = 
                typeof rawPurchasedAtMs === 'number' && rawPurchasedAtMs > 0 
                    ? rawPurchasedAtMs 
                    : null;
            
            const expirationAtMs: number | null = 
                typeof rawExpirationAtMs === 'number' && rawExpirationAtMs > 0 
                    ? rawExpirationAtMs 
                    : null;

            const store = ev?.store || ev?.platform || null;
            const environment = ev?.environment || (ev?.is_sandbox ? 'SANDBOX' : 'PRODUCTION');
            
            const isTrial = ev?.is_trial_period === true || 
                            ev?.is_trial_period === 'true' ||
                            ev?.period_type === 'TRIAL';

            const autoRenewStatus = ev?.auto_renew_status === true || 
                                    ev?.auto_renew_status === 'true' ||
                                    ev?.subscriber_attributes?.auto_renew_status?.value === 'true';

            const cancellationReason = ev?.cancel_reason || ev?.cancellation_reason || null;

            const rawGracePeriodExpiresAtMs = ev?.grace_period_expires_at_ms ?? ev?.grace_period_expiration_at_ms ?? null;
            const gracePeriodExpiresAtMs: number | null = 
                typeof rawGracePeriodExpiresAtMs === 'number' && rawGracePeriodExpiresAtMs > 0 
                    ? rawGracePeriodExpiresAtMs 
                    : null;

            const rawOriginalPurchasedAtMs = ev?.original_purchased_at_ms ?? ev?.original_purchase_date_ms ?? null;
            const originalPurchasedAtMs: number | null = 
                typeof rawOriginalPurchasedAtMs === 'number' && rawOriginalPurchasedAtMs > 0 
                    ? rawOriginalPurchasedAtMs 
                    : null;

            const priceInPurchasedCurrency = ev?.price_in_purchased_currency ?? ev?.price ?? null;
            const currency = ev?.currency ?? ev?.price_currency_code ?? null;

            logger.info('RevenueCat webhook full event data', {
                uid,
                eventType: typeRaw,
                productId,
                store,
                environment,
                isTrial,
                autoRenewStatus,
                cancellationReason,
                purchasedAtMs,
                expirationAtMs,
                gracePeriodExpiresAtMs,
                priceInPurchasedCurrency,
                currency,
            });

            await updateSubscriptionInFirestore(uid, {
                productId,
                purchasedAtMs,
                expirationAtMs,
                eventType: typeRaw,
                store,
                environment,
                isTrial,
                autoRenewStatus,
                cancellationReason,
                gracePeriodExpiresAtMs,
                originalPurchasedAtMs,
                priceInPurchasedCurrency,
                currency,
            });

            logger.info('RevenueCat webhook event details for promo check', {
                uid,
                eventType: typeRaw,
                isTrial,
                is_trial_period: ev?.is_trial_period,
                period_type: ev?.period_type,
                productId
            });
            
            const realPurchaseEvents = ['INITIAL_PURCHASE', 'TRIAL_CONVERTED', 'NON_RENEWING_PURCHASE', 'RENEWAL'];
            
            if (realPurchaseEvents.includes(typeRaw) && !isTrial) {
                try {
                    const apiKey = REVENUECAT_REST_API_KEY.value();
                    
                    logger.info('Processing promo code extension for real purchase', {
                        uid,
                        eventType: typeRaw,
                        productId
                    });
                    
                    await extendSubscriptionForPromoCode(
                        uid,
                        productId,
                        purchasedAtMs,
                        apiKey
                    );
                } catch (promoError) {
                    logger.error('Failed to apply promo extension, but continuing', {
                        error: promoError instanceof Error ? promoError.message : String(promoError),
                        uid,
                        eventType: typeRaw
                    });
                }
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

export const storePromoCodeForPurchase = onCall(
    { region: 'europe-west1' },
    async (request) => {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError('unauthenticated', 'User must be authenticated');
        }

        const { promoCode } = request.data;
        if (!promoCode || typeof promoCode !== 'string') {
            throw new HttpsError('invalid-argument', 'promoCode is required');
        }

        const normalizedCode = promoCode.toUpperCase().trim();

        try {
            const existingPromo = await db.collection('promoUses').doc(uid).get();
            if (existingPromo.exists) {
                const data = existingPromo.data();
                logger.info('User already has promo code linked', {
                    uid,
                    existingCode: data?.promoCode
                });
                return { 
                    success: true, 
                    alreadyLinked: true,
                    promoCode: data?.promoCode 
                };
            }

            const influencersQuery = await db.collection('influencers')
                .where('promoCode', '==', normalizedCode)
                .limit(1)
                .get();

            if (influencersQuery.empty) {
                throw new HttpsError('not-found', 'Invalid promo code');
            }

            await db.collection('promoUses').doc(uid).set({
                promoCode: normalizedCode,
                linkedAt: admin.firestore.FieldValue.serverTimestamp(),
                extensionApplied: false
            });

            logger.info('Linked promo code to user', {
                uid,
                promoCode: normalizedCode
            });

            return { success: true, alreadyLinked: false };
        } catch (error) {
            if (error instanceof HttpsError) throw error;
            
            logger.error('Failed to store promo code', {
                error: error instanceof Error ? error.message : String(error),
                uid,
                promoCode: normalizedCode
            });
            throw new HttpsError('internal', 'Failed to store promo code');
        }
    }
);