import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import { getRemoteConfigService, DEFAULT_NOTIFICATION_CONFIG } from '../../remote_config_service';
import { getNotificationService, NotificationPayload } from '../../notification_service';
import { toDayjs, safeNow } from '../../utils/date';
import { SubscriptionData } from '../../types';

const db = admin.firestore();

export const dailyMaintenance = onSchedule({
    region: 'europe-west1',
    schedule: '0 0 * * *',
    timeZone: 'Africa/Algiers'
}, async () => {
    const jobStart = Date.now();
    const correlationId = crypto.randomUUID();
    logger.info('Starting dailyMaintenance job', { correlationId });

    // Phase 1: Reset daily usage
    try {
        const collectionRef = db.collection('user_usage');

        let processed = 0;
        let page = 0;
        let lastDoc: admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData> | null = null;
        const maxPages = 1000;

        while (page < maxPages) {
            const query: admin.firestore.Query<admin.firestore.DocumentData> = lastDoc
                ? collectionRef.orderBy(admin.firestore.FieldPath.documentId()).startAfter(lastDoc.id).limit(500)
                : collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(500);

            const snapshot: admin.firestore.QuerySnapshot<admin.firestore.DocumentData> = await query.get();
            if (snapshot.empty) break;

            const batch = db.batch();
            snapshot.docs.forEach((doc) => {
                batch.update(doc.ref, {
                    scanCount: 0,
                    chatCount: 0,
                    lastUsageDate: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                processed++;
            });

            await batch.commit();
            page++;
            lastDoc = snapshot.docs[snapshot.docs.length - 1];
        }
        logger.info('Completed dailyMaintenance phase: resetAllDailyUsage', { correlationId, totalProcessed: processed });
    } catch (error) {
        console.error('Error in dailyMaintenance resetAllDailyUsage phase:', error);
    }

    // Phase 2: Expire invalid subscriptions
    try {
        const collectionRef = db.collection('subscriptions');
        const now = safeNow();

        let processed = 0;
        let updated = 0;
        let page = 0;
        let lastDoc: admin.firestore.QueryDocumentSnapshot<admin.firestore.DocumentData> | null = null;
        const maxPages = 1000;

        while (page < maxPages) {
            const query: admin.firestore.Query<admin.firestore.DocumentData> = lastDoc
                ? collectionRef.orderBy(admin.firestore.FieldPath.documentId()).startAfter(lastDoc.id).limit(500)
                : collectionRef.orderBy(admin.firestore.FieldPath.documentId()).limit(500);

            const snapshot: admin.firestore.QuerySnapshot<admin.firestore.DocumentData> = await query.get();
            if (snapshot.empty) break;

            const batch = db.batch();
            let writesInBatch = 0;

            snapshot.docs.forEach((doc) => {
                const data = doc.data() as SubscriptionData;
                const isPremium: boolean = data?.isPremium === true;
                if (!isPremium) { processed++; return; }

                const start = data?.startDate ? toDayjs(data.startDate) : null;
                const end = data?.endDate ? toDayjs(data.endDate) : null;

                let shouldExpire = false;
                if (!end) {
                    shouldExpire = true;
                } else {
                    if (start && (start.isAfter(end) || start.isSame(end))) {
                        shouldExpire = true;
                    }
                    if (!shouldExpire && end.isBefore(now)) {
                        shouldExpire = true;
                    }
                }

                if (shouldExpire) {
                    batch.set(doc.ref, {
                        isPremium: false,
                        status: 'expired',
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });
                    updated++;
                    writesInBatch++;
                }
                processed++;
            });

            if (writesInBatch > 0) {
                await batch.commit();
            }
            page++;
            lastDoc = snapshot.docs[snapshot.docs.length - 1];
        }
        logger.info('Completed dailyMaintenance phase: expireInvalidSubscriptions', { correlationId, totalProcessed: processed, totalUpdated: updated });
    } catch (error) {
        console.error('Error in dailyMaintenance expireInvalidSubscriptions phase:', error);
    }

    // Phase 3: Send daily reset notification
    try {
        const usersQuery = await db.collection('users').limit(1000).get();

        if (!usersQuery.empty) {
            const remoteConfig = getRemoteConfigService();
            const notificationService = getNotificationService();

            const resetMessage = await remoteConfig.getNotificationMessage(
                'notification_daily_reset_msg',
                DEFAULT_NOTIFICATION_CONFIG.notification_daily_reset_msg
            );

            const resetPayload: NotificationPayload = {
                title: 'Daily Limits Reset! ✨',
                body: resetMessage,
                data: { type: 'daily_reset' }
            };

            const userIds = usersQuery.docs.map(doc => doc.id);
            await notificationService.sendNotificationToUsers(userIds, resetPayload);

            logger.info('Completed dailyMaintenance phase: sendDailyResetNotification', { correlationId, totalUsers: userIds.length });
        }
    } catch (error) {
        console.error('Error in dailyMaintenance sendDailyResetNotification phase:', error);
    }

    logger.info('Finished dailyMaintenance job', { correlationId, totalDuration: Date.now() - jobStart });
});
