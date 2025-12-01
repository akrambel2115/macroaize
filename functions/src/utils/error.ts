import { logger } from 'firebase-functions/v2';

export function createStructuredError(message: string, details: any, correlationId?: string): Error {
    logger.error('Structured error occurred', {
        userMessage: message,
        details,
        correlationId,
        timestamp: new Date().toISOString()
    });
    return new Error(message);
}
