import { onRequest } from 'firebase-functions/v2/https';
import { Request, Response } from 'express';
import { logger } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import dayjs from 'dayjs';
import crypto from 'crypto';
import { REVENUECAT_WEBHOOK_SECRET } from '../../config';
import { safeNow, addDuration } from '../../utils/date';

const db = admin.firestore();

export const revenuecatWebhook = onRequest(
    {
        region: 'europe-west1',
        secrets: [REVENUECAT_WEBHOOK_SECRET],
    },
    async (req: Request, res: Response) => {
        if (req.method !== 'POST') {
            res.status(405).send('Method Not Allowed');
            return;
        }

        const authHeader = req.get('Authorization') || req.headers['authorization'];
        const expected = `Bearer ${REVENUECAT_WEBHOOK_SECRET.value()}`;

        if (authHeader !== expected) {
            logger.warn('RevenueCat invalid authorization');
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
            if (!uid || uid.startsWith('$RCAnonymousID')) {
                res.status(200).send('ignored');
                return;
            }

            const productId: string = String(
                ev?.product_id ||
                ev?.productIdentifier ||
                ev?.transaction?.product_id ||
                ''
            );
            const purchasedAtMs: number | null =
                Number(
                    ev?.purchased_at_ms ||
                    ev?.purchase_date_ms ||
                    event?.event_timestamp_ms ||
                    event?.sent_at_ms ||
                    0
                ) || null;
            const expirationAtMs: number | null =
                Number(
                    ev?.expiration_at_ms ||
                    ev?.expires_at_ms ||
                    ev?.expiration_ms ||
                    0
                ) || null;

            const startIso = purchasedAtMs
                ? new Date(purchasedAtMs).toISOString()
                : new Date().toISOString();
            let endIso: string | null = expirationAtMs
                ? new Date(expirationAtMs).toISOString()
                : null;

            const guessPlanFromProduct = (pid: string): string => {
                const p = pid.toLowerCase();
                if (p.includes('year') || p.includes('annual') || p.includes('yr'))
                    return 'yearly';
                return 'monthly';
            };
            const guessPlanFromDuration = (
                startMs: number | null,
                endMs: number | null
            ): string => {
                if (!startMs || !endMs) return 'monthly';
                const days = Math.max(
                    0,
                    Math.round((endMs - startMs) / (1000 * 60 * 60 * 24))
                );
                if (days >= 300) return 'yearly';
                if (days >= 27) return 'monthly';
                return 'monthly';
            };

            const planType = endIso
                ? guessPlanFromDuration(purchasedAtMs, expirationAtMs)
                : guessPlanFromProduct(productId);

            if (!endIso) {
                const start = purchasedAtMs ? dayjs(purchasedAtMs).utc() : safeNow();
                endIso = addDuration(start, planType).toISOString();
            }

            const now = safeNow();
            const end = dayjs(endIso).utc();
            const isActiveNow = end.isAfter(now);

            const subRef = db.collection('subscriptions').doc(uid);

            const writeActive = async (status: string) => {
                await subRef.set(
                    {
                        userId: uid,
                        isPremium: isActiveNow,
                        planType,
                        startDate: startIso,
                        endDate: endIso,
                        provider: 'revenuecat',
                        status,
                        productId: productId || null,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true }
                );
            };

            const writeStatusOnly = async (status: string) => {
                await subRef.set(
                    {
                        provider: 'revenuecat',
                        status,
                        isPremium: isActiveNow,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                    { merge: true }
                );
            };

            switch (typeRaw) {
                case 'INITIAL_PURCHASE':
                case 'RENEWAL':
                case 'PRODUCT_CHANGE':
                case 'UNCANCELLATION':
                case 'NON_RENEWING_PURCHASE':
                    await writeActive('active');
                    break;
                case 'CANCELLATION':
                    await writeStatusOnly('canceled');
                    break;
                case 'EXPIRATION':
                    await subRef.set(
                        {
                            provider: 'revenuecat',
                            status: 'expired',
                            isPremium: false,
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        },
                        { merge: true }
                    );
                    break;
                case 'BILLING_ISSUE':
                case 'SUBSCRIPTION_PAUSED':
                    await writeStatusOnly('past_due');
                    break;
                case 'REFUND':
                case 'UNCANCELLATION_FAILURE':
                default:
                    await writeStatusOnly('updated');
                    break;
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
