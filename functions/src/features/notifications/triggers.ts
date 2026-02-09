import { onDocumentCreated } from 'firebase-functions/v2/firestore';
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
            title: 'Promo Code Used!',
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

/**
 * Influencer notification: Welcome message when they create a promo code
 * This must stay server-side to ensure delivery
 */
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
            title: 'Welcome to the Influencer Program!',
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

/**
 * NOTE: Goal progress notifications (50%/100%) have been moved to local notifications
 * for better user experience and battery efficiency. 
 * See lib/shared/services/local_notification_service.dart
 */
