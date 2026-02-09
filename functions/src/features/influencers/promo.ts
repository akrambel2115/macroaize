import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { getInfluencerCommissionRate, getInfluencerEarnForCode } from '../../remote_config_service';
import { isValidPromoCode } from '../../utils/validation';
import { checkRateLimit } from '../../utils/rate-limit';

const db = admin.firestore();

export const validatePromoCode = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const promoCode = (request.data?.promoCode as string || '').toUpperCase().trim();
    const clientIP = request.rawRequest.ip || 'unknown';

    if (!checkRateLimit(`promo_${clientIP}_${uid}`, 20, 1)) {
        throw new HttpsError('resource-exhausted', 'Too many attempts. Please try again later.');
    }

    if (!isValidPromoCode(promoCode)) {
        throw new HttpsError('invalid-argument', 'Invalid promo code format.');
    }

    try {
        const influencersQuery = await db.collection('influencers')
            .where('promoCode', '==', promoCode)
            .where('isActive', '==', true)
            .limit(1)
            .get();

        if (influencersQuery.empty) {
            throw new HttpsError('not-found', 'Invalid promo code.');
        }

        const influencerDoc = influencersQuery.docs[0];
        const influencerData = influencerDoc.data();
        const influencerId = influencerDoc.id;

        const expirationDate = influencerData.expirationDate?.toDate?.() || new Date(influencerData.expirationDate);
        if (expirationDate && expirationDate < new Date()) {
            throw new HttpsError('failed-precondition', 'This promo code has expired.');
        }

        const existingSubscription = await db.collection('subscriptions')
            .where('userId', '==', uid)
            .where('promoCodeUsed', '==', promoCode)
            .limit(1)
            .get();

        if (!existingSubscription.empty) {
            throw new HttpsError('failed-precondition', 'This promo code has already been used.');
        }

        await db.collection('influencer_audit').add({
            userId: influencerId,
            action: 'promo_validated',
            amount: 0,
            details: {
                promoCode,
                validatedBy: uid,
                clientIP
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            status: 'success'
        });

        return {
            valid: true,
            discountRate: getInfluencerCommissionRate(),
            earnAmount: getInfluencerEarnForCode(),
            influencerId
        };

    } catch (error) {
        // re throw
        if (error instanceof HttpsError) {
            throw error;
        }
        // Fallback
        throw new HttpsError('not-found', 'Invalid promo code.');
    }
});
