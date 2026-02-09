import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import crypto from 'crypto';
import { RIP_ENCRYPTION_KEY_V1 } from '../../config';
import { getInfluencerMinWithdrawal, getInfluencerWithdrawalProcessingDays } from '../../remote_config_service';
import { getEmailToAddress, getEmailFromAddress } from '../../config';
import { validateRequestSize } from '../../utils/validation';
import { maskRip, encryptRip, isValidRip } from '../../crypto_rip';
import { safeNow } from '../../utils/date';
import { WithdrawalRecord } from '../../types';
import { logger } from 'firebase-functions/v2';

const db = admin.firestore();

export const processWithdrawal = onCall({
    region: 'europe-west1',
    secrets: [RIP_ENCRYPTION_KEY_V1]
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    try {
        const uid = request.auth?.uid;
        if (!uid) {
            throw new HttpsError('unauthenticated', 'Authentication required');
        }

        if (!request.auth?.token?.email_verified) {
            throw new HttpsError('permission-denied', 'Email verification required');
        }

        if (!validateRequestSize(request.data, 2)) {
            throw new HttpsError('invalid-argument', 'Request too large');
        }

        const amount = request.data?.amount as number;
        const rip = (request.data?.rip as string || '').trim();

        if (!amount || amount <= 0) {
            throw new HttpsError('invalid-argument', 'Invalid withdrawal amount');
        }
        
        if (!isValidRip(rip)) {
            throw new HttpsError('invalid-argument', 'RIP must be exactly 20 digits');
        }

        const encryptionKey = RIP_ENCRYPTION_KEY_V1.value();
        if (!encryptionKey || encryptionKey.length < 16) {
            logger.error('RIP encryption key not configured or invalid', { correlationId });
            throw new HttpsError('internal', 'Service configuration error');
        }

        const ripMasked = maskRip(rip);
        const ripEncrypted = encryptRip(rip, encryptionKey);

        const influencerDoc = await db.collection('influencers').doc(uid).get();
        if (!influencerDoc.exists) {
            throw new HttpsError('permission-denied', 'Not an influencer');
        }

        const influencerData = influencerDoc.data()!;
        if (!influencerData.isActive) {
            throw new HttpsError('permission-denied', 'Account is not active');
        }

        const minWithdrawal = influencerData.minWithdrawal ?? getInfluencerMinWithdrawal();
        if (amount < minWithdrawal) {
            throw new HttpsError('invalid-argument', `Minimum withdrawal is ${minWithdrawal} DZD`);
        }

        const withdrawalId = `WD_${Date.now()}_${uid.slice(-6)}`;

        await db.runTransaction(async (transaction) => {
            const currentInfluencer = await transaction.get(db.collection('influencers').doc(uid));
            if (!currentInfluencer.exists) {
                throw new HttpsError('not-found', 'Influencer not found');
            }

            const data = currentInfluencer.data()!;
            const currentBalance = data.earningsDzd || 0;

            if (currentBalance < amount) {
                throw new HttpsError('failed-precondition', 'Insufficient balance');
            }

            const newBalance = currentBalance - amount;
            const now = new Date();
            const withdrawalRecord: WithdrawalRecord = {
                id: withdrawalId,
                amount,
                ripMasked,
                requestedAt: now,
                status: 'processing',
                estimatedProcessingDate: safeNow().add(getInfluencerWithdrawalProcessingDays(), 'days').toISOString()
            };

            transaction.update(db.collection('influencers').doc(uid), {
                earningsDzd: newBalance,
                withdrawHistory: admin.firestore.FieldValue.arrayUnion(withdrawalRecord),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

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
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                status: 'processing'
            });

            transaction.set(db.collection('withdrawals_secure').doc(withdrawalId), {
                userId: uid,
                amount,
                ripEncrypted,
                keyVersion: 1,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'processing'
            });

            transaction.create(db.collection('mail').doc(), {
                to: [getEmailToAddress()],
                from: getEmailFromAddress(),
                message: {
                    subject: ` Withdrawal Request #${withdrawalId}`,
                    text: `New withdrawal request received: ${withdrawalId} - ${amount} DZD`,
                    html: `<div>New withdrawal request received: ${withdrawalId} - ${amount} DZD</div>`
                }
            });
        });

        logger.info('Withdrawal processed successfully', { correlationId, withdrawalId, userId: uid, amount });

        return {
            success: true,
            withdrawalId,
            message: `Withdrawal request submitted. Processing time: ${getInfluencerWithdrawalProcessingDays()} business days.`
        };

    } catch (error) {

        if (error instanceof HttpsError) {
            logger.warn('Withdrawal failed with HttpsError', { 
                correlationId, 
                code: error.code, 
                message: error.message 
            });
            throw error;
        }

        // Log 
        logger.error('Unexpected error processing withdrawal', { 
            correlationId, 
            error: error instanceof Error ? error.message : 'Unknown error',
            stack: error instanceof Error ? error.stack : undefined
        });

        throw new HttpsError('internal', 'Failed to process withdrawal request');
    }
});
