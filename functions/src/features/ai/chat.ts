import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import { GoogleGenerativeAI, Content, Part } from "@google/generative-ai";
import { GEMINI_API_KEY, getAiModel } from '../../config';
import { validateRequestSize, validateAiJsonResponse } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { safeNow, toDayjs } from '../../utils/date';
import { SubscriptionData } from '../../types';

const db = admin.firestore();

export const chatWithOpenRouter = onCall({
    region: 'europe-west1',
    secrets: [GEMINI_API_KEY],
    maxInstances: 10,
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();

    const uid = request.auth?.uid;
    if (!uid) throw new Error('unauthenticated');

    if (!validateRequestSize(request.data, 10240)) {
        throw createStructuredError('invalid-argument', 'Request payload too large', correlationId);
    }

    const model = String(request.data?.model || getAiModel());
    const messages = request.data?.messages;
    const maxTokens = Number(request.data?.max_tokens || 500);
    const requestedTemperature = Number(request.data?.temperature);
    const context = request.data?.context; // 'scan' | 'chat'
    const temperature = Number.isFinite(requestedTemperature)
        ? Math.min(1, Math.max(0, requestedTemperature))
        : (context === 'scan' ? 0 : 0.4);

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

    // Usage tracking is handled by the dedicated incrementUsage Cloud Function
    // called from the client before reaching this point.
    // We only log access level here — no duplicate counter increment.
    if (isPremium) {
        logger.info('Premium user accessing chat - unlimited access granted', { uid, correlationId });
    } else if (context === 'scan') {
        logger.info('Scan request - usage tracked by scan flow', { uid, correlationId });
    } else {
        logger.info('Free user chat request - usage tracked by client incrementUsage', { uid, correlationId });
    }

    const key = GEMINI_API_KEY.value();
    if (!key) {
        throw new Error('AI service temporarily unavailable');
    }

    const genAI = new GoogleGenerativeAI(key);

    // Extract explicit system instructions so they remain highest priority.
    const systemInstructions: string[] = [];
    for (const msg of messages) {
        if (msg?.role !== 'system') continue;
        if (typeof msg.content === 'string') {
            systemInstructions.push(msg.content);
            continue;
        }
        if (Array.isArray(msg.content)) {
            for (const item of msg.content) {
                if (item?.type === 'text' && typeof item.text === 'string') {
                    systemInstructions.push(item.text);
                }
            }
        }
    }

    const genModel = genAI.getGenerativeModel({
        model,
        ...(systemInstructions.length > 0
            ? { systemInstruction: systemInstructions.join('\n\n') }
            : {}),
    });

    // Convert OpenAI messages to Gemini contents
    const contents: Content[] = [];
    for (const msg of messages) {
        if (msg?.role === 'system') continue;

        const role = msg?.role === 'assistant' ? 'model' : 'user';
        const parts: Part[] = [];

        if (typeof msg.content === 'string') {
            parts.push({ text: msg.content });
        } else if (Array.isArray(msg.content)) {
            for (const item of msg.content) {
                if (item?.type === 'text' && typeof item.text === 'string') {
                    parts.push({ text: item.text });
                } else if (item?.type === 'image_url' && item.image_url?.url) {
                    const url = item.image_url.url;
                    if (url.startsWith('data:image/')) {
                        const [header, data] = url.split(',');
                        const mimeType = header.match(/:(.*?);/)?.[1] || 'image/jpeg';
                        parts.push({
                            inlineData: {
                                mimeType,
                                data
                            }
                        });
                    }
                }
            }
        }
        if (parts.length > 0) {
            contents.push({ role, parts });
        }
    }

    if (contents.length === 0) {
        throw createStructuredError('invalid-argument', 'No valid message content', correlationId);
    }

    try {
        const result = await genModel.generateContent({
            contents,
            generationConfig: {
                maxOutputTokens: maxTokens,
                temperature,
            }
        });

        const response = result.response;
        const text = response.text();

        // Enforce structured output for scan requests to reduce malformed JSON.
        const lowerPrompt = JSON.stringify(messages).toLowerCase();
        let normalizedText = text;

        if (context === 'scan') {
            if (lowerPrompt.includes('mealitems')) {
                const validated = validateAiJsonResponse(text, 'mealItems');
                normalizedText = JSON.stringify(validated);
            } else if (
                lowerPrompt.includes('food_name') ||
                lowerPrompt.includes('calories')
            ) {
                const validated = validateAiJsonResponse(text, 'nutrition');
                normalizedText = JSON.stringify(validated);
            }
        }

        return {
            choices: [
                {
                    message: {
                        content: normalizedText
                    }
                }
            ]
        };
    } catch (e: any) {
        logger.error('GEMINI_API_ERROR', { uid, error: e, correlationId });
        const msg = e?.message || '';
        if (msg.includes('429')) throw new Error('ai_rate_limit_exceeded');
        if (msg.includes('500')) throw new Error('ai_service_unavailable');
        throw new Error('ai_request_failed');
    }
});
