import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';

// Define secret for Firebase service account (using Secret Manager)
export const FIREBASE_SERVICE_ACCOUNT = defineSecret('FIREBASE_SERVICE_ACCOUNT');

/**
 * Interface for notification payload
 */
export interface NotificationPayload {
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}

/**
 * Interface for FCM token document
 */
interface FCMTokenDoc {
  token: string;
  platform: string;
  isActive: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  lastUsed: FirebaseFirestore.Timestamp;
}

/**
 * Secure notification service for sending FCM messages
 * Uses Firebase Admin SDK with service account authentication
 * Implements token cleanup and error handling best practices
 */
export class NotificationService {
  private static instance: NotificationService;
  private messaging: admin.messaging.Messaging | null = null;
  private db: admin.firestore.Firestore | null = null;
  
  private constructor() {
    // Initialize services lazily when first accessed
  }
  
  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * Lazy initialization of Firebase services
   * Ensures Firebase Admin is properly initialized before use
   */
  private initializeServices(): void {
    if (!this.messaging) {
      this.messaging = getMessaging();
    }
    if (!this.db) {
      this.db = getFirestore();
    }
  }

  /**
   * Send notification to a specific user
   * Fetches all active FCM tokens for the user and sends to all devices
   * Handles invalid tokens and cleans them up automatically
   * 
   * @param uid - User ID to send notification to
   * @param payload - Notification payload with title, body, and optional data
   * @returns Promise<boolean> - True if at least one message was sent successfully
   */
  async sendNotificationToUser(uid: string, payload: NotificationPayload): Promise<boolean> {
    const correlationId = `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    try {
      // Initialize Firebase services
      this.initializeServices();
      
      logger.info('Sending notification to user', {
        correlationId,
        uid,
        title: payload.title,
        hasData: !!payload.data
      });

      // Fetch all active FCM tokens for the user
      const tokensSnapshot = await this.db!
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .where('isActive', '==', true)
        .get();

      if (tokensSnapshot.empty) {
        logger.warn('No active FCM tokens found for user', {
          correlationId,
          uid
        });
        return false;
      }

      const tokens = tokensSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => {
        const data = doc.data() as FCMTokenDoc;
        return {
          token: data.token,
          docId: doc.id,
          platform: data.platform
        };
      });

      logger.info('Found FCM tokens for user', {
        correlationId,
        uid,
        tokenCount: tokens.length
      });

      // Prepare FCM message
      const message = {
        notification: {
          title: payload.title,
          body: payload.body,
          ...(payload.imageUrl && { imageUrl: payload.imageUrl })
        },
        data: {
          correlationId,
          timestamp: new Date().toISOString(),
          ...(payload.data || {})
        },
        android: {
          priority: 'high' as const,
          notification: {
            sound: 'default',
            channelId: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      // Send to multiple tokens using sendMulticast
      const tokenValues = tokens.map((t: any) => t.token);
      const multicastMessage = {
        ...message,
        tokens: tokenValues
      };

      const response = await this.messaging!.sendEachForMulticast(multicastMessage);
      
      logger.info('FCM multicast response', {
        correlationId,
        uid,
        successCount: response.successCount,
        failureCount: response.failureCount
      });

      // Handle invalid tokens - mark them as inactive
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error) {
          const errorCode = resp.error.code;
          // Token is invalid, unregistered, or app was uninstalled
          if (errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered') {
            invalidTokens.push(tokens[idx].docId);
            logger.warn('Invalid FCM token detected', {
              correlationId,
              uid,
              tokenDocId: tokens[idx].docId,
              platform: tokens[idx].platform,
              errorCode
            });
          }
        }
      });

      // Clean up invalid tokens in batch
      if (invalidTokens.length > 0) {
        await this.cleanupInvalidTokens(uid, invalidTokens, correlationId);
      }

      // Update lastUsed timestamp for valid tokens
      if (response.successCount > 0) {
        await this.updateTokenUsage(uid, tokens, correlationId);
      }

      // Log notification audit
      await this.logNotificationAudit(uid, payload, response.successCount, response.failureCount, correlationId);

      return response.successCount > 0;

    } catch (error) {
      logger.error('Failed to send notification to user', {
        correlationId,
        uid,
        error: error instanceof Error ? error.message : String(error)
      });
      
      // Log failed notification audit
      await this.logNotificationAudit(uid, payload, 0, 1, correlationId, error);
      
      return false;
    }
  }

  /**
   * Send notification to multiple users
   * Efficiently handles bulk notifications
   * 
   * @param userIds - Array of user IDs
   * @param payload - Notification payload
   * @returns Promise<number> - Number of users successfully notified
   */
  async sendNotificationToUsers(userIds: string[], payload: NotificationPayload): Promise<number> {
    const correlationId = `bulk_notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    logger.info('Sending bulk notifications', {
      correlationId,
      userCount: userIds.length,
      title: payload.title
    });

    let successCount = 0;
    
    // Process in batches to avoid overwhelming the system
    const batchSize = 10;
    for (let i = 0; i < userIds.length; i += batchSize) {
      const batch = userIds.slice(i, i + batchSize);
      
      const promises = batch.map(uid => 
        this.sendNotificationToUser(uid, payload)
          .then(success => success ? 1 : 0)
          .catch(() => 0)
      );
      
      const results = await Promise.all(promises);
      successCount += results.reduce((sum, result) => sum + result, 0);
    }

    logger.info('Bulk notifications completed', {
      correlationId,
      totalUsers: userIds.length,
      successCount,
      failureCount: userIds.length - successCount
    });

    return successCount;
  }

  /**
   * Send notification to a topic (for broadcast notifications)
   * 
   * @param topic - Topic name
   * @param payload - Notification payload
   * @returns Promise<boolean> - True if message was sent successfully
   */
  async sendNotificationToTopic(topic: string, payload: NotificationPayload): Promise<boolean> {
    const correlationId = `topic_notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    try {
      // Initialize Firebase services
      this.initializeServices();
      
      logger.info('Sending notification to topic', {
        correlationId,
        topic,
        title: payload.title
      });

      const message = {
        topic,
        notification: {
          title: payload.title,
          body: payload.body,
          ...(payload.imageUrl && { imageUrl: payload.imageUrl })
        },
        data: {
          correlationId,
          timestamp: new Date().toISOString(),
          ...(payload.data || {})
        },
        android: {
          priority: 'high' as const,
          notification: {
            sound: 'default',
            channelId: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await this.messaging!.send(message);
      
      logger.info('Topic notification sent successfully', {
        correlationId,
        topic,
        messageId: response
      });

      return true;

    } catch (error) {
      logger.error('Failed to send notification to topic', {
        correlationId,
        topic,
        error: error instanceof Error ? error.message : String(error)
      });
      
      return false;
    }
  }

  /**
   * Clean up invalid FCM tokens
   * Marks tokens as inactive instead of deleting for audit purposes
   */
  private async cleanupInvalidTokens(uid: string, tokenDocIds: string[], correlationId: string): Promise<void> {
    try {
      const batch = this.db!.batch();
      
      for (const tokenDocId of tokenDocIds) {
        const tokenRef = this.db!
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(tokenDocId);
        
        batch.update(tokenRef, {
          isActive: false,
          invalidatedAt: FieldValue.serverTimestamp(),
          invalidationReason: 'FCM error - token invalid'
        });
      }
      
      await batch.commit();
      
      logger.info('Cleaned up invalid FCM tokens', {
        correlationId,
        uid,
        invalidatedCount: tokenDocIds.length
      });
      
    } catch (error) {
      logger.error('Failed to cleanup invalid tokens', {
        correlationId,
        uid,
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }

  /**
   * Update lastUsed timestamp for successful tokens
   */
  private async updateTokenUsage(uid: string, tokens: any[], correlationId: string): Promise<void> {
    try {
      const batch = this.db!.batch();
      
      for (const token of tokens) {
        const tokenRef = this.db!
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token.docId);
        
        batch.update(tokenRef, {
          lastUsed: FieldValue.serverTimestamp()
        });
      }
      
      await batch.commit();
      
    } catch (error) {
      logger.warn('Failed to update token usage timestamps', {
        correlationId,
        uid,
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }

  /**
   * Log notification audit for monitoring and debugging
   */
  private async logNotificationAudit(
    uid: string, 
    payload: NotificationPayload, 
    successCount: number, 
    failureCount: number, 
    correlationId: string,
    error?: any
  ): Promise<void> {
    try {
      await this.db!.collection('notification_audit').add({
        timestamp: FieldValue.serverTimestamp(),
        correlationId,
        userId: uid,
        title: payload.title,
        body: payload.body.substring(0, 200), // Truncate for storage
        hasData: !!payload.data,
        dataKeys: payload.data ? Object.keys(payload.data) : [],
        successCount,
        failureCount,
        ...(error && {
          error: error instanceof Error ? error.message : String(error)
        }),
        region: 'europe-west1'
      });
    } catch (auditError) {
      // Don't fail the notification if audit logging fails
      logger.warn('Failed to log notification audit', {
        correlationId,
        auditError: auditError instanceof Error ? auditError.message : String(auditError)
      });
    }
  }
}

/**
 * Factory function to get notification service instance
 * Ensures proper initialization of Firebase Admin SDK
 */
export function getNotificationService(): NotificationService {
  return NotificationService.getInstance();
}
