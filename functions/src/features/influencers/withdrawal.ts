import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import crypto from 'crypto';
import { RIP_ENCRYPTION_KEY_V1 } from '../../config';
import { getInfluencerMinWithdrawal, getInfluencerWithdrawalProcessingDays } from '../../remote_config_service';
import { getEmailToAddress, getEmailFromAddress } from '../../config';
import { validateRequestSize } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { maskRip, encryptRip, isValidRip } from '../../crypto_rip';
import { safeNow } from '../../utils/date';
import { WithdrawalRecord } from '../../types';

const db = admin.firestore();

export const processWithdrawal = onCall({
    region: 'europe-west1',
    secrets: [RIP_ENCRYPTION_KEY_V1]
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    const uid = request.auth?.uid;
    if (!uid) {
        throw createStructuredError('unauthenticated', 'No authenticated user', correlationId);
    }

    if (!request.auth?.token?.email_verified) {
        throw createStructuredError('permission-denied', 'Email verification required', correlationId);
    }

    if (!validateRequestSize(request.data, 2)) {
        throw createStructuredError('invalid-argument', 'Request too large', correlationId);
    }

    const amount = request.data?.amount as number;
    const rip = (request.data?.rip as string || '').trim();

    if (!amount || amount <= 0 || !isValidRip(rip)) {
        throw new Error('invalid-argument');
    }

    const minWithdrawal = getInfluencerMinWithdrawal();
    if (amount < minWithdrawal) {
        throw new Error(`Minimum withdrawal amount is ${minWithdrawal} DZD`);
    }

    const ripMasked = maskRip(rip);
    const ripEncrypted = encryptRip(rip, RIP_ENCRYPTION_KEY_V1.value());

    try {
        const influencerDoc = await db.collection('influencers').doc(uid).get();
        if (!influencerDoc.exists) {
            throw new Error('permission-denied');
        }

        const influencerData = influencerDoc.data()!;
        if (!influencerData.isActive) {
            throw new Error('Account is not active');
        }

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

        return {
            success: true,
            withdrawalId,
            message: `Withdrawal request submitted. Processing time: ${getInfluencerWithdrawalProcessingDays()} business days.`
        };

    } catch (error) {
        console.error('Error processing withdrawal:', error);
        if (error instanceof Error) {
            if (error.message === 'insufficient-funds') throw new Error('Insufficient balance.');
            if (error.message === 'Account is not active') throw new Error('Account not active.');
        }
        throw new Error('Failed to process withdrawal request.');
    }
});
