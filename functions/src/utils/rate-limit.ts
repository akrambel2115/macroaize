// Rate limiting map
export const promoCodeAttempts = new Map<string, { count: number; lastAttempt: number }>();

// Cleanup old entries
export function cleanupRateLimitMap(): void {
    const now = Date.now();
    const oneHour = 60 * 60 * 1000;

    for (const [key, attempt] of promoCodeAttempts) {
        if (now - attempt.lastAttempt > oneHour) {
            promoCodeAttempts.delete(key);
        }
    }
}

// Run cleanup every 10 mins
setInterval(cleanupRateLimitMap, 10 * 60 * 1000);

// Check rate limit
export function checkRateLimit(key: string, maxAttempts: number = 5, windowHours: number = 1): boolean {
    const now = Date.now();
    const windowMs = windowHours * 60 * 60 * 1000;

    const attempt = promoCodeAttempts.get(key);
    if (!attempt) {
        promoCodeAttempts.set(key, { count: 1, lastAttempt: now });
        return true;
    }

    if (now - attempt.lastAttempt > windowMs) {
        promoCodeAttempts.set(key, { count: 1, lastAttempt: now });
        return true;
    }

    if (attempt.count >= maxAttempts) {
        return false;
    }

    attempt.count++;
    attempt.lastAttempt = now;
    return true;
}
