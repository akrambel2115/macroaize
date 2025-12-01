import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import { getRemoteConfigService, DEFAULT_NOTIFICATION_CONFIG } from '../../remote_config_service';
import { getNotificationService, NotificationPayload } from '../../notification_service';

const db = admin.firestore();

export const notifyLunchReminder = onSchedule({
    region: 'europe-west1',
    schedule: '0 12 * * *',
    timeZone: 'UTC'
}, async () => {
    const correlationId = `lunch_reminder_${Date.now()}`;
    try {
        const remoteConfig = getRemoteConfigService();
        const lunchTime = await remoteConfig.getNotificationTime(
            'notification_lunch_time',
            DEFAULT_NOTIFICATION_CONFIG.notification_lunch_time
        );

        if (!remoteConfig.isCurrentTimeMatch(lunchTime, 5)) return;

        const message = await remoteConfig.getNotificationMessage(
            'notification_lunch_msg',
            DEFAULT_NOTIFICATION_CONFIG.notification_lunch_msg
        );

        const elevenAM = new Date();
        elevenAM.setUTCHours(10, 0, 0, 0);

        const usersQuery = await db.collection('users')
            .where('lastMealLog', '<', elevenAM)
            .limit(1000)
            .get();

        if (usersQuery.empty) return;

        const userIds = usersQuery.docs.map(doc => doc.id);
        const notificationService = getNotificationService();
        const payload: NotificationPayload = {
            title: 'Lunch Time! 🍽️',
            body: message,
            data: { type: 'meal_reminder', mealType: 'lunch' }
        };

        await notificationService.sendNotificationToUsers(userIds, payload);
    } catch (error) {
        logger.error('Error in lunch reminder notification job', { correlationId, error });
    }
});

export const notifyEveningCheckin = onSchedule({
    region: 'europe-west1',
    schedule: '30 20 * * *',
    timeZone: 'UTC'
}, async () => {
    const correlationId = `evening_checkin_${Date.now()}`;
    try {
        const remoteConfig = getRemoteConfigService();
        const notificationService = getNotificationService();

        const dinnerTime = await remoteConfig.getNotificationTime(
            'notification_dinner_time',
            DEFAULT_NOTIFICATION_CONFIG.notification_dinner_time
        );

        if (!remoteConfig.isCurrentTimeMatch(dinnerTime, 5)) return;

        const usersQuery = await db.collection('users').limit(1000).get();
        if (usersQuery.empty) return;

        for (const userDoc of usersQuery.docs) {
            const userId = userDoc.id;
            const userData = userDoc.data();

            try {
                const sevenPM = new Date();
                sevenPM.setUTCHours(18, 0, 0, 0);

                if (!userData.lastDinnerLog || userData.lastDinnerLog < sevenPM) {
                    const dinnerMessage = await remoteConfig.getNotificationMessage(
                        'notification_dinner_msg',
                        DEFAULT_NOTIFICATION_CONFIG.notification_dinner_msg
                    );

                    const dinnerPayload: NotificationPayload = {
                        title: 'Dinner Time! 🌙',
                        body: dinnerMessage,
                        data: { type: 'meal_reminder', mealType: 'dinner' }
                    };

                    await notificationService.sendNotificationToUser(userId, dinnerPayload);
                }

                const today = new Date().toISOString().split('T')[0];
                const calorieHistoryDoc = await db.collection('calorie_history').doc(`${userId}_${today}`).get();

                if (calorieHistoryDoc.exists) {
                    const historyData = calorieHistoryDoc.data();
                    const totalCalories = historyData?.totalCalories || 0;
                    const targetCalories = historyData?.targetCalories || 2000;
                    const progress = totalCalories / targetCalories;

                    if (progress < 0.9) {
                        const goalMessage = await remoteConfig.getNotificationMessage(
                            'notification_end_of_day_msg',
                            DEFAULT_NOTIFICATION_CONFIG.notification_end_of_day_msg
                        );

                        const goalPayload: NotificationPayload = {
                            title: 'Almost There! 🎯',
                            body: goalMessage,
                            data: { type: 'goal_check', progress: Math.round(progress * 100).toString() }
                        };

                        await notificationService.sendNotificationToUser(userId, goalPayload);
                    }
                }
                await new Promise(resolve => setTimeout(resolve, 100));
            } catch (userError) {
                logger.warn('Error processing evening notifications for user', { userId, error: userError });
            }
        }
    } catch (error) {
        logger.error('Error in evening check-in notification job', { correlationId, error });
    }
});
