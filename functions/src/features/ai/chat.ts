import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import axios from 'axios';
import { OPENROUTER_API_KEY, getAiModel } from '../../config';
import { getChatLimitCfg } from '../../remote_config_service';
import { validateRequestSize, validateAiJsonResponse } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { safeNow, toDayjs } from '../../utils/date';
import { SubscriptionData, UsageData } from '../../types';

const db = admin.firestore();

export const chatWithOpenRouter = onCall({
    region: 'europe-west1',
    secrets: [OPENROUTER_API_KEY]
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    const uid = request.auth?.uid;
    if (!uid) throw new Error('unauthenticated');

    if (!validateRequestSize(request.data, 1024)) {
        throw createStructuredError('invalid-argument', 'Request payload too large', correlationId);
    }

    const model = String(request.data?.model || getAiModel());
    const messages = request.data?.messages;
    const maxTokens = Number(request.data?.max_tokens || 500);

    if (!Array.isArray(messages) || messages.length === 0) {
        throw new Error('invalid-argument');
    }

    // Validate images
    for (const message of messages) {
        if (message?.content && Array.isArray(message.content)) {
            for (const content of message.content) {
                if (content?.type === 'image_url' && content?.image_url?.url) {
                    const imageUrl = content.image_url.url;
                    if (imageUrl.startsWith('data:image/')) {
                        const base64Data = imageUrl.split(',')[1];
                        if (base64Data) {
                            const imageSize = base64Data.length * 0.75;
                            const maxImageSize = 5 * 1024 * 1024;
                            if (imageSize > maxImageSize) {
                                throw createStructuredError('invalid-argument', 'Image size exceeds limit', correlationId);
                            }
                        }
                    }
                }
            }
        }
    }

    let isPremium = false;
    try {
        const subSnap = await db.collection('subscriptions').doc(uid).get();
        if (subSnap.exists) {
            const s = subSnap.data() as SubscriptionData;
            const end = s?.endDate ? toDayjs(s.endDate) : null;
            isPremium = s?.isPremium === true && !!(end && end.isAfter(safeNow()));
        }
    } catch (_) {
        isPremium = false;
    }

    if (isPremium) {
        logger.info('Premium user accessing chat - unlimited access granted', { uid, correlationId });
    } else {
        try {
            const usageDoc = await db.collection('user_usage').doc(uid).get();
            const d = usageDoc.data() as UsageData | undefined;
            const last = d?.lastUsageDate;
            const todayStart = safeNow().startOf('day');
            let chatCount = 0;
            if (last) {
                const lastDate = toDayjs(last);
                if (lastDate && lastDate.startOf('day').isSame(todayStart)) {
                    chatCount = (d?.chatCount as number) || 0;
                }
            }
            const CHAT_LIMIT = getChatLimitCfg();
            if (chatCount >= CHAT_LIMIT) {
                throw new Error('Daily chat limit reached. Upgrade to Premium for unlimited access.');
            }
            await db.collection('user_usage').doc(uid).set({
                chatCount: chatCount + 1,
                lastUsageDate: admin.firestore.FieldValue.serverTimestamp(),
                userId: uid,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
        } catch (e) {
            if (e instanceof Error && e.message.includes('Daily chat limit reached')) {
                throw e;
            }
            logger.error('Error checking/updating usage for non-premium user', { uid, error: e });
        }
    }

    const key = OPENROUTER_API_KEY.value();
    if (!key) {
        throw new Error('AI service temporarily unavailable');
    }

    const maxRetries = 3;
    let lastError: any = null;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const resp = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
                model,
                messages,
                max_tokens: maxTokens,
            }, {
                headers: {
                    'Authorization': `Bearer ${key}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'https://macroaize.com',
                    'X-Title': 'Food Calorie Tracker',
                },
                timeout: 30000,
            });

            const responseData = resp.data;
            if (responseData?.choices?.[0]?.message?.content) {
                const content = responseData.choices[0].message.content;
                if (content.includes('food_name') || content.includes('calories')) {
                    try { validateAiJsonResponse(content, 'nutrition'); } catch (_) { }
                } else if (content.includes('mealItems')) {
                    try { validateAiJsonResponse(content, 'mealItems'); } catch (_) { }
                }
            }

            return responseData;
        } catch (e: any) {
            lastError = e;
            const status = e?.response?.status;

            if (status === 429) {
                if (attempt < maxRetries) {
                    const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    continue;
                } else {
                    throw new Error('ai_rate_limit_exceeded');
                }
            } else if (status === 400 || status === 401 || status === 403) {
                throw new Error('ai_request_failed');
            } else if (status >= 500 || !status) {
                if (attempt < maxRetries) {
                    const delay = Math.min(1000 * attempt, 3000);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    continue;
                }
            }
            break;
        }
    }

    const finalStatus = lastError?.response?.status;
    if (finalStatus === 429) throw new Error('ai_rate_limit_exceeded');
    if (finalStatus >= 500 || !finalStatus) throw new Error('ai_service_unavailable');
    throw new Error('ai_request_failed');
});
