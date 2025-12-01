import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import dayjs from 'dayjs';
import { getScanLimitCfg, getChatLimitCfg } from '../../remote_config_service';
import { safeNow, toDayjs, toDate } from '../../utils/date';
import { UsageData, SubscriptionData } from '../../types';

const db = admin.firestore();

// Increment usage
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

    // Check premium status
    try {
        const subscriptionDoc = await db.collection('subscriptions').doc(authedUid).get();
        if (subscriptionDoc.exists) {
            const subscriptionData = subscriptionDoc.data();
            if (subscriptionData) {
                const now = safeNow();
                const endDate = subscriptionData.endDate ? dayjs(subscriptionData.endDate) : null;
                const isActive = subscriptionData.isPremium === true && endDate && endDate.isAfter(now);

                if (isActive) {
                    return { success: true, isPremium: true, message: 'Premium user - unlimited access' };
                }
            }
        }
    } catch (error) {
        console.error('Error checking subscription status:', error);
        throw new Error('internal');
    }

    // Non-premium: check and increment
    const usageRef = db.collection('user_usage').doc(authedUid);
    const todayStart = safeNow().startOf('day');

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
                        ? (lastUsageRaw as admin.firestore.Timestamp).toDate()
                        : new Date(lastUsageRaw as string))
                    : null;
                const lastUsageDayStart = lastUsageDate ? dayjs(lastUsageDate).startOf('day') : null;

                if (lastUsageDayStart && lastUsageDayStart.isSame(todayStart)) {
                    scanCount = typedUsageData.scanCount ?? 0;
                    chatCount = typedUsageData.chatCount ?? 0;
                }
            }

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

            transaction.set(usageRef, {
                scanCount,
                chatCount,
                lastUsageDate: admin.firestore.FieldValue.serverTimestamp(),
                userId: authedUid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
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

// Get usage
export const getUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new Error('unauthenticated');
    }

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
        isPremium = false;
    }

    const SCAN_LIMIT = getScanLimitCfg();
    const CHAT_LIMIT = getChatLimitCfg();

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
