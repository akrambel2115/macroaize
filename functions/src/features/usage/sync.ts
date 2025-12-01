import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import dayjs from 'dayjs';
import { getScanLimitCfg, getChatLimitCfg } from '../../remote_config_service';
import { safeNow, toDate, toDayjs } from '../../utils/date';
import { UsageData, SubscriptionData } from '../../types';

const db = admin.firestore();

export const syncUsage = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new Error('unauthenticated');
    }

    const clientScan = Math.max(0, parseInt(String(request.data?.scanCount ?? 0), 10) || 0);
    const clientChat = Math.max(0, parseInt(String(request.data?.chatCount ?? 0), 10) || 0);

    const SCAN_LIMIT = getScanLimitCfg();
    const CHAT_LIMIT = getChatLimitCfg();

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
        // fall through
    }

    const usageRef = db.collection('user_usage').doc(uid);

    const result = await db.runTransaction(async (tx) => {
        const snap = await tx.get(usageRef);
        const todayStart = safeNow().startOf('day');

        let serverScan = 0;
        let serverChat = 0;
        if (snap.exists) {
            const d = snap.data() as UsageData;
            const last = d?.lastUsageDate;
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

        const mergedScan = Math.min(Math.max(serverScan, clientScan), SCAN_LIMIT);
        const mergedChat = Math.min(Math.max(serverChat, clientChat), CHAT_LIMIT);

        tx.set(usageRef, {
            scanCount: mergedScan,
            chatCount: mergedChat,
            lastUsageDate: admin.firestore.FieldValue.serverTimestamp(),
            userId: uid,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
