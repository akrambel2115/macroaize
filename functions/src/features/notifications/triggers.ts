import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import { getRemoteConfigService, DEFAULT_NOTIFICATION_CONFIG } from '../../remote_config_service';
import { getNotificationService, NotificationPayload } from '../../notification_service';

const db = admin.firestore();

export const notifyInfluencerOnPromoUse = onDocumentCreated({
    region: 'europe-west1',
    document: 'promoUses/{docId}'
}, async (event) => {
    const correlationId = `promo_use_${Date.now()}`;
    try {
        const promoUseData = event.data?.data();
        if (!promoUseData) return;

        const promoCodeId = promoUseData.promoCodeId;
        const userId = promoUseData.userId;
        if (!promoCodeId) return;

        const promoCodeDoc = await db.collection('promoCodes').doc(promoCodeId).get();
        if (!promoCodeDoc.exists) return;

        const promoCodeData = promoCodeDoc.data();
        const ownerUid = promoCodeData?.ownerUid;
        if (!ownerUid) return;

        const remoteConfig = getRemoteConfigService();
        const message = await remoteConfig.getNotificationMessage(
            'notification_promo_used_msg',
            DEFAULT_NOTIFICATION_CONFIG.notification_promo_used_msg
        );

        const notificationService = getNotificationService();
        const payload: NotificationPayload = {
            title: 'Promo Code Used! 🎉',
            body: message,
            data: {
                type: 'promo_used',
                promoCode: promoCodeId,
                userId: userId || 'unknown'
            }
        };

        await notificationService.sendNotificationToUser(ownerUid, payload);
    } catch (error) {
        logger.error('Error sending promo code use notification', { correlationId, error });
    }
});

export const notifyNewInfluencer = onDocumentCreated({
    region: 'europe-west1',
    document: 'promoCodes/{code}'
}, async (event) => {
    const correlationId = `new_influencer_${Date.now()}`;
    try {
        const promoCodeData = event.data?.data();
        if (!promoCodeData) return;

        const ownerUid = promoCodeData.ownerUid;
        const promoCode = event.params.code;
        if (!ownerUid) return;

        const remoteConfig = getRemoteConfigService();
        const message = await remoteConfig.getNotificationMessage(
            'notification_influencer_welcome_msg',
            DEFAULT_NOTIFICATION_CONFIG.notification_influencer_welcome_msg,
            { code: promoCode }
        );

        const notificationService = getNotificationService();
        const payload: NotificationPayload = {
            title: 'Welcome to the Influencer Program! 🌟',
            body: message,
            data: {
                type: 'influencer_welcome',
                promoCode: promoCode
            }
        };

        await notificationService.sendNotificationToUser(ownerUid, payload);
    } catch (error) {
        logger.error('Error sending new influencer notification', { correlationId, error });
    }
});

export const notifyGoalProgress = onDocumentWritten({
    region: 'europe-west1',
    document: 'calorie_history/{date}'
}, async (event) => {
    const correlationId = `goal_progress_${Date.now()}`;
    try {
        const afterData = event.data?.after?.data();
        if (!afterData) return;

        const userId = afterData.userId;
        const totalCalories = afterData.totalCalories || 0;
        const targetCalories = afterData.targetCalories || 2000;
        const notified50 = afterData.notified50 || false;
        const notified100 = afterData.notified100 || false;

        if (!userId) return;

        const progress = totalCalories / targetCalories;
        const progressPercent = Math.round(progress * 100);

        const remoteConfig = getRemoteConfigService();
        const notificationService = getNotificationService();

        if (progress >= 0.5 && !notified50) {
            const message = await remoteConfig.getNotificationMessage(
                'notification_goal_50pct_msg',
                DEFAULT_NOTIFICATION_CONFIG.notification_goal_50pct_msg
            );

            const payload: NotificationPayload = {
                title: 'Halfway There!',
                body: message,
                data: {
                    type: 'goal_progress',
                    milestone: '50',
                    progress: progressPercent.toString()
                }
            };

            const success = await notificationService.sendNotificationToUser(userId, payload);
            if (success) {
                await event.data?.after?.ref.update({ notified50: true });
            }
        }

        if (progress >= 1.0 && !notified100) {
            const message = await remoteConfig.getNotificationMessage(
                'notification_goal_100pct_msg',
                DEFAULT_NOTIFICATION_CONFIG.notification_goal_100pct_msg
            );

            const payload: NotificationPayload = {
                title: 'Goal Achieved! 🏆',
                body: message,
                data: {
                    type: 'goal_check',
                    milestone: '100',
                    progress: progressPercent.toString()
                }
            };

            const success = await notificationService.sendNotificationToUser(userId, payload);
            if (success) {
                await event.data?.after?.ref.update({ notified100: true });
            }
        }
    } catch (error) {
        logger.error('Error sending goal progress notification', { correlationId, error });
    }
});
