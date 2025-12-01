import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import { getMinRequiredAppVersion, getUpdateMessage, getShareUrlIos, getShareUrlAndroid } from '../../remote_config_service';
import { validateRequestSize } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';

const db = admin.firestore();

export const validateAppVersion = onCall({ region: 'europe-west1' }, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    if (!validateRequestSize(request.data, 1)) {
        throw createStructuredError('invalid-argument', 'Request too large', correlationId);
    }

    const clientVersion = String(request.data?.version || '').trim();
    const platform = String(request.data?.platform || '').toLowerCase().trim();

    if (!clientVersion) {
        throw new Error('invalid-argument');
    }

    logger.info('App version validation request', {
        correlationId,
        clientVersion,
        platform,
        userId: request.auth?.uid || 'anonymous'
    });

    const requiredVersion = getMinRequiredAppVersion();
    const updateMessage = getUpdateMessage();

    try {
        const isOutdated = _isVersionOutdated(clientVersion, requiredVersion);

        await db.collection('version_checks').add({
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            clientVersion,
            requiredVersion,
            platform,
            isOutdated,
            userId: request.auth?.uid || null,
            correlationId,
            userAgent: request.rawRequest.headers['user-agent'] || 'unknown',
            ip: request.rawRequest.ip || 'unknown'
        });

        if (isOutdated) {
            const storeUrl = platform === 'ios'
                ? getShareUrlIos()
                : getShareUrlAndroid();

            return {
                updateRequired: true,
                currentVersion: clientVersion,
                requiredVersion,
                updateMessage,
                storeUrl,
                severity: 'blocking'
            };
        }

        return {
            updateRequired: false,
            currentVersion: clientVersion,
            requiredVersion,
            severity: 'none'
        };

    } catch (error) {
        logger.error('Version validation error', {
            correlationId,
            error: error instanceof Error ? error.message : String(error),
            clientVersion,
            requiredVersion
        });

        return {
            updateRequired: true,
            currentVersion: clientVersion,
            requiredVersion,
            updateMessage: 'Unable to verify app version. Please update to continue.',
            severity: 'blocking',
            errorCode: 'validation_failed'
        };
    }
});

export function _isVersionOutdated(current: string, required: string): boolean {
    const parse = (v: string): number[] => {
        const core = v.split('+')[0].split('-')[0].trim();
        return core
            .split('.')
            .map((part) => {
                const match = /^(\d+)/.exec(part);
                return match ? parseInt(match[1], 10) : 0;
            });
    };

    const c = parse(current);
    const r = parse(required);
    const len = Math.max(c.length, r.length);

    for (let i = 0; i < len; i++) {
        const cv = i < c.length ? c[i] : 0;
        const rv = i < r.length ? r[i] : 0;
        if (cv < rv) return true;
        if (cv > rv) return false;
    }
    return false;
}
