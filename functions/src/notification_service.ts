import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';


export const FIREBASE_SERVICE_ACCOUNT = defineSecret('FIREBASE_SERVICE_ACCOUNT');


export interface NotificationPayload {
  title: string;
  body: string;
  data?: { [key: string]: string };
  imageUrl?: string;
}


interface FCMTokenDoc {
  token: string;
  platform: string;
  isActive: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  lastUsed: FirebaseFirestore.Timestamp;
}


export class NotificationService {
  private static instance: NotificationService;
  private messaging: admin.messaging.Messaging | null = null;
  private db: admin.firestore.Firestore | null = null;

  private constructor() {
    // Lazy init
  }

  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }


  private initializeServices(): void {
    if (!this.messaging) {
      this.messaging = getMessaging();
    }
    if (!this.db) {
      this.db = getFirestore();
    }
  }


  async sendNotificationToUser(uid: string, payload: NotificationPayload): Promise<boolean> {
    const correlationId = `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    try {

      this.initializeServices();

      logger.info('Sending notification to user', {
        correlationId,
        uid,
        title: payload.title,
        hasData: !!payload.data
      });


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

      const rawTokens = tokensSnapshot.docs.map((doc: admin.firestore.QueryDocumentSnapshot) => {
        const data = doc.data() as FCMTokenDoc;
        return {
          token: data.token,
          docId: doc.id,
          platform: data.platform
        };
      });

      // --- Defense-in-depth: ownership validation ---
      // The client-side transaction ensures a device token is owned by exactly
      // one user, but we verify here too in case of races or stale data.
      // Fetch all deviceTokens/{token} docs in a single batch read.
      const ownershipRefs = rawTokens.map((t) =>
        this.db!.collection('deviceTokens').doc(t.token)
      );
      const ownershipSnaps = ownershipRefs.length > 0
        ? await this.db!.getAll(...ownershipRefs)
        : [];

      const tokens = rawTokens.filter((t, idx) => {
        const ownerData = ownershipSnaps[idx]?.data();
        // Accept token if: (a) ownership record confirms this uid, OR
        // (b) ownership record doesn't exist yet (legacy / offline write).
        return !ownerData || ownerData['ownerUid'] === uid;
      });

      const staleDocIds = rawTokens
        .filter((t, idx) => {
          const ownerData = ownershipSnaps[idx]?.data();
          return ownerData && ownerData['ownerUid'] !== uid;
        })
        .map((t) => t.docId);

      if (staleDocIds.length > 0) {
        logger.warn('Filtered tokens owned by a different user (stale)', {
          correlationId,
          uid,
          staleCount: staleDocIds.length
        });
        // Deactivate stale entries in the background — do not await.
        this.cleanupInvalidTokens(uid, staleDocIds, correlationId).catch(() => {});
      }

      logger.info('Found FCM tokens for user', {
        correlationId,
        uid,
        rawCount: rawTokens.length,
        validCount: tokens.length
      });

      if (tokens.length === 0) {
        logger.warn('No valid (owned) FCM tokens remain for user after ownership check', {
          correlationId,
          uid
        });
        return false;
      }

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

      // Send multicast
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


      if (invalidTokens.length > 0) {
        await this.cleanupInvalidTokens(uid, invalidTokens, correlationId);
      }


      if (response.successCount > 0) {
        await this.updateTokenUsage(uid, tokens, correlationId);
      }


      await this.logNotificationAudit(uid, payload, response.successCount, response.failureCount, correlationId);

      return response.successCount > 0;

    } catch (error) {
      logger.error('Failed to send notification to user', {
        correlationId,
        uid,
        error: error instanceof Error ? error.message : String(error)
      });


      await this.logNotificationAudit(uid, payload, 0, 1, correlationId, error);

      return false;
    }
  }


  async sendNotificationToUsers(userIds: string[], payload: NotificationPayload): Promise<number> {
    const correlationId = `bulk_notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    logger.info('Sending bulk notifications', {
      correlationId,
      userCount: userIds.length,
      title: payload.title
    });

    let successCount = 0;


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


  async sendNotificationToTopic(topic: string, payload: NotificationPayload): Promise<boolean> {
    const correlationId = `topic_notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    try {

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
      // Ignore audit errors
      logger.warn('Failed to log notification audit', {
        correlationId,
        auditError: auditError instanceof Error ? auditError.message : String(auditError)
      });
    }
  }
}

export function getNotificationService(): NotificationService {
  return NotificationService.getInstance();
}
