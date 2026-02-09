import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import { getNotificationService, NotificationPayload } from '../../notification_service';

const db = admin.firestore();
const remoteConfig = admin.remoteConfig();

type NotificationType = 'breakfast' | 'lunch' | 'dinner' | 'streak';

interface UserNotificationPrefs {
    enabled: boolean;
    mealReminders: boolean;
    streakReminders: boolean;
    breakfastHour: number;
    lunchHour: number;
    dinnerHour: number;
    timezone: string;
}

interface NotificationContent {
    title: string;
    body: string;
}

// fallback content if rc fails
const DEFAULT_CONTENT: Record<NotificationType, NotificationContent> = {
    breakfast: { title: 'Breakfast Reminder 🌅', body: 'Good morning! Start your day right by logging your breakfast.' },
    lunch: { title: 'Lunch Reminder 🍽️', body: 'Lunchtime! Don\'t forget to log your meal.' },
    dinner: { title: 'Dinner Reminder 🌙', body: 'Evening reminder: Log your dinner before the day ends.' },
    streak: { title: 'Streak at Risk! 🔥', body: 'Don\'t lose your streak! Log a meal before midnight.' }
};

async function getNotificationContent(): Promise<Record<NotificationType, NotificationContent>> {
    try {
        const template = await remoteConfig.getTemplate();
        const params = template.parameters;
        
        const getValue = (key: string, fallback: string): string => {
            const param = params[key];
            if (!param?.defaultValue) return fallback;
            const defaultVal = param.defaultValue as { value?: string };
            return defaultVal.value || fallback;
        };
        
        return {
            breakfast: {
                title: getValue('breakfast_reminder_title', DEFAULT_CONTENT.breakfast.title),
                body: getValue('breakfast_reminder_msg', DEFAULT_CONTENT.breakfast.body)
            },
            lunch: {
                title: getValue('lunch_reminder_title', DEFAULT_CONTENT.lunch.title),
                body: getValue('lunch_reminder_msg', DEFAULT_CONTENT.lunch.body)
            },
            dinner: {
                title: getValue('dinner_reminder_title', DEFAULT_CONTENT.dinner.title),
                body: getValue('dinner_reminder_msg', DEFAULT_CONTENT.dinner.body)
            },
            streak: {
                title: getValue('streak_at_risk_title', DEFAULT_CONTENT.streak.title),
                body: getValue('streak_at_risk_msg', DEFAULT_CONTENT.streak.body)
            }
        };
    } catch (e) {
        logger.warn('Failed to fetch Remote Config, using defaults', { error: e });
        return DEFAULT_CONTENT;
    }
}


export const sendScheduledNotifications = onSchedule({
    region: 'europe-west1',
    schedule: '0 * * * *',
    timeZone: 'UTC',
    retryCount: 3,
}, async (_event) => {
    const startTime = Date.now();
    const correlationId = `scheduled_notif_${startTime}`;
    
    logger.info('Starting scheduled notification job', { correlationId });
    

    const notificationContent = await getNotificationContent();
    
    try {
        const now = new Date();
        const utcHour = now.getUTCHours();
        

        const usersSnapshot = await db.collection('users')
            .where('notificationPrefs.enabled', '==', true)
            .get();
        
        if (usersSnapshot.empty) {
            logger.info('No users with notifications enabled', { correlationId });
            return;
        }
        
        const notificationService = getNotificationService();
        let sentCount = 0;
        let errorCount = 0;
        
        for (const userDoc of usersSnapshot.docs) {
            try {
                const userId = userDoc.id;
                const userData = userDoc.data();
                const prefs = userData.notificationPrefs as UserNotificationPrefs | undefined;
                
                if (!prefs || !prefs.enabled) continue;
                
                const userTimezone = prefs.timezone || 'Africa/Algiers';
                const userLocalHour = getLocalHour(utcHour, userTimezone);
                
                // check which notifications to send
                const notificationsToSend: NotificationType[] = [];
                
                // Meal reminders
                if (prefs.mealReminders !== false) {
                    if (prefs.breakfastHour === userLocalHour) {
                        notificationsToSend.push('breakfast');
                    }
                    if (prefs.lunchHour === userLocalHour) {
                        notificationsToSend.push('lunch');
                    }
                    if (prefs.dinnerHour === userLocalHour) {
                        notificationsToSend.push('dinner');
                    }
                }
                
                // Streak reminder
                if (prefs.streakReminders !== false && userLocalHour === 21) {
                    const hasLoggedToday = await checkIfLoggedToday(userId);
                    if (!hasLoggedToday) {
                        notificationsToSend.push('streak');
                    }
                }
                

                for (const notifType of notificationsToSend) {
                    const content = notificationContent[notifType];
                    const payload: NotificationPayload = {
                        title: content.title,
                        body: content.body,
                        data: {
                            type: notifType,
                            timestamp: Date.now().toString()
                        }
                    };
                    
                    await notificationService.sendNotificationToUser(userId, payload);
                    sentCount++;
                    
                    logger.info('Sent notification', { 
                        correlationId, 
                        userId, 
                        type: notifType,
                        userLocalHour 
                    });
                }
                
            } catch (userError) {
                errorCount++;
                logger.error('Error processing user notifications', { 
                    correlationId, 
                    userId: userDoc.id,
                    error: userError 
                });
            }
        }
        
        const duration = Date.now() - startTime;
        logger.info('Scheduled notification job completed', {
            correlationId,
            usersProcessed: usersSnapshot.size,
            notificationsSent: sentCount,
            errors: errorCount,
            durationMs: duration
        });
        
    } catch (error) {
        logger.error('Scheduled notification job failed', { correlationId, error });
        throw error; // Rethrow to trigger retry
    }
});


function getLocalHour(utcHour: number, timezone: string): number {
    try {
        const now = new Date();
        now.setUTCHours(utcHour, 0, 0, 0);
        
        const formatter = new Intl.DateTimeFormat('en-US', {
            hour: 'numeric',
            hour12: false,
            timeZone: timezone
        });
        
        const localHour = parseInt(formatter.format(now), 10);
        return localHour;
    } catch {
        // default to alg
        return (utcHour + 1) % 24;
    }
}


async function checkIfLoggedToday(userId: string): Promise<boolean> {
    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const mealsSnapshot = await db.collection('users')
            .doc(userId)
            .collection('meals')
            .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(today))
            .limit(1)
            .get();
        
        return !mealsSnapshot.empty;
    } catch {
        return true; // assume logged to avoid false streak alerts
    }
}