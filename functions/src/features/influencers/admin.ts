import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { RIP_ENCRYPTION_KEY_V1 } from '../../config';
import { getInfluencerEarnForCode, getInfluencerMinWithdrawal } from '../../remote_config_service';
import { decryptRip } from '../../crypto_rip';
import { WithdrawalRecord } from '../../types';
import { isValidPromoCode, sanitizeDocumentId } from '../../utils/validation';

const db = admin.firestore();

function requireAdmin(request: CallableRequest): void {
    const uid = request.auth?.uid;
    const isAdmin = request.auth?.token?.admin === true || request.auth?.token?.role === 'admin';
    if (!uid) throw new Error('unauthenticated');
    if (!isAdmin) throw new Error('permission-denied');
}

export const createInfluencer = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    requireAdmin(request);

    const userId = String(request.data?.userId || '').trim();
    const promoCode = String(request.data?.promoCode || '').toUpperCase().trim();
    const expirationDays = Number(request.data?.expirationDays) || 365;
    const customEarnAmount = request.data?.earnAmount;
    const customMinWithdrawal = request.data?.minWithdrawal;

    // Validate inputs
    if (!userId) {
        throw new Error('userId is required');
    }

    if (!isValidPromoCode(promoCode)) {
        throw new Error('Invalid promo code format. Must be 6-12 uppercase alphanumeric characters.');
    }

    try {
        await admin.auth().getUser(userId);
    } catch {
        throw new Error('User not found in Firebase Auth');
    }

    const existingInfluencer = await db.collection('influencers').doc(userId).get();
    if (existingInfluencer.exists) {
        throw new Error('User is already an influencer');
    }

    // if promo code is already taken
    const existingPromoCode = await db.collection('influencers')
        .where('promoCode', '==', promoCode)
        .limit(1)
        .get();

    if (!existingPromoCode.empty) {
        throw new Error('Promo code is already in use by another influencer');
    }

    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + expirationDays);

    const influencerData: Record<string, any> = {
        promoCode,
        isActive: true,
        earningsDzd: 0,
        totalEarningsDzd: 0,
        usersCount: 0,
        minWithdrawal: customMinWithdrawal ?? getInfluencerMinWithdrawal(),
        expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
        withdrawHistory: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: request.auth!.uid
    };

    // custom earn amount if provided
    if (typeof customEarnAmount === 'number' && customEarnAmount > 0) {
        influencerData.earnAmount = customEarnAmount;
    }

    await db.runTransaction(async (transaction) => {

        transaction.set(db.collection('influencers').doc(userId), influencerData);


        transaction.set(db.collection('promoCodes').doc(promoCode), {
            ownerUid: userId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // log
        transaction.create(db.collection('influencer_audit').doc(), {
            userId,
            action: 'influencer_created',
            amount: 0,
            details: {
                promoCode,
                expirationDate: expirationDate.toISOString(),
                customEarnAmount: customEarnAmount ?? null,
                customMinWithdrawal: customMinWithdrawal ?? null,
                createdBy: request.auth!.uid
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            status: 'completed',
            adminAction: true
        });
    });

    return {
        success: true,
        message: `Influencer created successfully`,
        influencer: {
            userId,
            promoCode,
            expirationDate: expirationDate.toISOString(),
            earnAmount: customEarnAmount ?? getInfluencerEarnForCode(),
            minWithdrawal: customMinWithdrawal ?? getInfluencerMinWithdrawal()
        }
    };
});

export const fixPromoCommission = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    const uid = request.auth?.uid;
    if (!uid) throw new Error('unauthenticated');
    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin) throw new Error('permission-denied');

    const subscriptionUserId = sanitizeDocumentId(String(request.data?.subscriptionUserId || ''));
    const promoCode = String(request.data?.promoCode || '').toUpperCase().trim();

    if (!subscriptionUserId || !promoCode) throw new Error('invalid-argument');
    if (!isValidPromoCode(promoCode)) throw new Error('Invalid promo code format');

    try {
        const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionUserId).get();
        if (!subscriptionDoc.exists) throw new Error('Subscription not found');

        const subscriptionData = subscriptionDoc.data()!;
        if (subscriptionData.promoCodeUsed !== promoCode) throw new Error('Promo code mismatch');
        if (subscriptionData.commissionProcessed === true && !subscriptionData.commissionError) {
            throw new Error('Commission already processed successfully');
        }

        const influencersQuery = await db.collection('influencers')
            .where('promoCode', '==', promoCode)
            .where('isActive', '==', true)
            .limit(1)
            .get();

        if (influencersQuery.empty) throw new Error(`No active influencer found for promo code: ${promoCode}`);

        const influencerDoc = influencersQuery.docs[0];
        const influencerId = influencerDoc.id;
        const influencerData = influencerDoc.data();


        const earnAmount = typeof influencerData.earnAmount === 'number' && influencerData.earnAmount > 0
            ? influencerData.earnAmount
            : getInfluencerEarnForCode();

        await db.runTransaction(async (tx) => {
            const influencerRef = db.collection('influencers').doc(influencerId);
            const subscriptionRef = db.collection('subscriptions').doc(subscriptionUserId);

            const currentInfluencer = await tx.get(influencerRef);
            if (!currentInfluencer.exists) throw new Error(`Influencer not found`);

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

            tx.update(subscriptionRef, {
                commissionProcessed: true,
                commissionFixedAt: admin.firestore.FieldValue.serverTimestamp(),
                commissionFixedBy: uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            tx.create(db.collection('influencer_audit').doc(), {
                userId: influencerId,
                action: 'commission_earned',
                amount: earnAmount,
                details: {
                    promoCode,
                    subscriptionUserId,
                    earnAmount,
                    fixedAt: admin.firestore.FieldValue.serverTimestamp(),
                    fixedBy: uid,
                    note: 'Manually fixed failed commission processing'
                },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                status: 'completed',
                source: 'manual_fix'
            });
        });

        return {
            success: true,
            message: `Commission fixed for promo code ${promoCode}.`,
            earnAmount,
            influencerId
        };

    } catch (error) {
        throw new Error(error instanceof Error ? error.message : 'internal');
    }
});

export const adminGetWithdrawalRip = onCall({
    region: 'europe-west1',
    secrets: [RIP_ENCRYPTION_KEY_V1]
}, async (request: CallableRequest) => {
    requireAdmin(request);

    const withdrawalId = sanitizeDocumentId(String(request.data?.withdrawalId || ''));
    if (!withdrawalId) throw new Error('invalid-argument');

    try {
        const secureDoc = await db.collection('withdrawals_secure').doc(withdrawalId).get();
        if (!secureDoc.exists) throw new Error('not-found');

        const secureData = secureDoc.data()!;
        if (secureData.keyVersion !== 1) throw new Error('unsupported-key-version');

        const decryptedRip = decryptRip(secureData.ripEncrypted, RIP_ENCRYPTION_KEY_V1.value());

        await db.collection('influencer_audit').add({
            userId: secureData.userId,
            action: 'rip_decrypted_access',
            details: {
                withdrawalId,
                accessedBy: request.auth!.uid,
                accessedAt: new Date().toISOString()
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
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
        throw new Error('Failed to retrieve withdrawal details.');
    }
});

export const adminCompleteWithdrawal = onCall({
    region: 'europe-west1'
}, async (request: CallableRequest) => {
    requireAdmin(request);

    const withdrawalId = sanitizeDocumentId(String(request.data?.withdrawalId || ''));
    const status = String(request.data?.status || '').trim();

    if (!withdrawalId || !['completed', 'failed'].includes(status)) {
        throw new Error('invalid-argument');
    }

    try {
        await db.runTransaction(async (transaction) => {
            const secureRef = db.collection('withdrawals_secure').doc(withdrawalId);
            const secureDoc = await transaction.get(secureRef);

            if (!secureDoc.exists) throw new Error('not-found');

            const secureData = secureDoc.data()!;
            const influencerRef = db.collection('influencers').doc(secureData.userId);
            const influencerDoc = await transaction.get(influencerRef);

            if (influencerDoc.exists) {
                const influencerData = influencerDoc.data()!;
                const withdrawHistory = influencerData.withdrawHistory || [];

                const updatedHistory = withdrawHistory.map((withdrawal: WithdrawalRecord) => {
                    if (withdrawal.id === withdrawalId) {
                        return { ...withdrawal, status, completedAt: new Date().toISOString() };
                    }
                    return withdrawal;
                });

                transaction.update(influencerRef, {
                    withdrawHistory: updatedHistory,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            transaction.create(db.collection('influencer_audit').doc(), {
                userId: secureData.userId,
                action: 'withdrawal_completed',
                details: {
                    withdrawalId,
                    status,
                    completedBy: request.auth!.uid,
                    amount: secureData.amount
                },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                adminAction: true
            });

            if (status === 'completed') {
                transaction.delete(secureRef);
            } else {
                transaction.update(secureRef, {
                    status,
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                    completedBy: request.auth!.uid
                });
            }
        });

        return {
            success: true,
            message: status === 'completed' ? 'Withdrawal marked as completed' : 'Withdrawal marked as failed'
        };

    } catch (error) {
        throw new Error('Failed to complete withdrawal.');
    }
});
