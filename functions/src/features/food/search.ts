import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import axios from 'axios';
import { USDA_API_KEY, USDA_URL } from '../../config';
import { validateRequestSize, sanitizeUsdaResponse } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { safeNow, toDayjs } from '../../utils/date';
import { SubscriptionData } from '../../types';

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

    // Usage tracking is handled by the dedicated incrementUsage Cloud Function
    // called from the client before reaching this point.
    // Removing the duplicate scan counter increment here avoids multi-item scans
    // consuming N scan credits (one per USDA lookup) instead of 1.
    if (!isPremium) {
        logger.info('Free user USDA search - usage tracked by client incrementUsage', { uid, correlationId });
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
