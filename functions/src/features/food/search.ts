import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import axios from 'axios';
import { USDA_API_KEY, USDA_URL } from '../../config';
import { getScanLimitCfg } from '../../remote_config_service';
import { validateRequestSize, sanitizeUsdaResponse } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { safeNow, toDayjs } from '../../utils/date';
import { SubscriptionData, UsageData } from '../../types';

const db = admin.firestore();

export const searchUsdaFoods = onCall({
    region: 'europe-west1',
    secrets: [USDA_API_KEY]
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    const uid = request.auth?.uid;
    if (!uid) throw new Error('unauthenticated');

    if (!validateRequestSize(request.data, 5)) {
        throw createStructuredError('invalid-argument', 'Request too large', correlationId);
    }

    const query = String(request.data?.query || '').trim();
    const limit = Math.max(1, Math.min(10, Number(request.data?.limit || 3)));
    if (!query) throw new Error('invalid-argument');

    let isPremium = false;
    try {
        const subSnap = await db.collection('subscriptions').doc(uid).get();
        if (subSnap.exists) {
            const s = subSnap.data() as SubscriptionData;
            const end = s?.endDate ? toDayjs(s.endDate) : null;
            isPremium = s?.isPremium === true && !!(end && end.isAfter(safeNow()));
        }
    } catch (e) {
        isPremium = false;
    }

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
                throw new Error('Daily scan limit reached. Upgrade to Premium for unlimited access.');
            }

            await db.collection('user_usage').doc(uid).set({
                scanCount: scanCount + 1,
                lastUsageDate: admin.firestore.FieldValue.serverTimestamp(),
                userId: uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        } catch (e) {
            if (e instanceof Error && e.message.includes('Daily scan limit reached')) {
                throw e;
            }
            logger.error('Error checking/updating usage for USDA request', { uid, error: e });
        }
    }

    const key = USDA_API_KEY.value();
    if (!key) throw new Error('internal');

    try {
        const url = USDA_URL;
        const res = await axios.get(url, {
            params: { query, api_key: key, pageSize: String(limit) },
            timeout: 10000,
        });

        return sanitizeUsdaResponse(res.data);
    } catch (e: any) {
        const status = e?.response?.status;
        const msg = e?.response?.data?.message || e?.message || 'USDA error';
        if (status === 429) throw new Error('Rate limited by USDA');
        throw new Error(msg);
    }
});
