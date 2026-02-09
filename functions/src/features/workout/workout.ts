import { onCall, CallableRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions/v2';
import crypto from 'crypto';
import { GoogleGenerativeAI } from "@google/generative-ai";
import { GEMINI_API_KEY, getAiModel } from '../../config';
import { validateRequestSize } from '../../utils/validation';
import { createStructuredError } from '../../utils/error';
import { safeNow, toDayjs } from '../../utils/date';
import { SubscriptionData } from '../../types';

const db = admin.firestore();

// gemini schema typing

const WORKOUT_PARSE_PROMPT = `
You are a fitness expert AI. Parse the user's workout description into the structured JSON schema provided below.

Output JSON Schema:
{
  "exercises": [
    {
      "name": "string",
      "type": "bodybuilding" | "cardio" | "calisthenics" | "other",
      "muscleGroup": "string (optional)",
      "sets": "number (optional)",
      "reps": "number (optional)",
      "weight": "number (optional)",
      "weightUnit": "kg" | "lbs" (optional),
      "duration": "number (minutes, optional)",
      "distance": "number (km, optional)",
      "caloriesBurned": "number (optional)"
    }
  ],
  "totalDuration": "number (minutes)",
  "totalCaloriesBurned": "number",
  "summary": "string"
}

Guidelines:
- Estimate calories conservatively based on exercise type/intensity.
- Default to "kg" for weight unless "lbs" is specified or locale implies Imperial.
- If duration is missing, estimate: Bodybuilding (~3m/set), generic exercise (~5m).
- Return ONLY valid JSON.
`;

export const logWorkoutWithAI = onCall({
    region: 'europe-west1',
    secrets: [GEMINI_API_KEY],
    maxInstances: 10,
    timeoutSeconds: 60, 
}, async (request: CallableRequest) => {
    const correlationId = crypto.randomUUID();
    const uid = request.auth?.uid;
    
    if (!uid) {
        throw new HttpsError('unauthenticated', 'User must be logged in');
    }

    // validation
    if (!validateRequestSize(request.data, 2048)) {
        throw createStructuredError('invalid-argument', 'Request payload too large', correlationId);
    }

    const description = String(request.data?.description || '').trim();
    const locale = String(request.data?.locale || 'en');

    if (description.length < 5 || description.length > 1000) {
        throw new HttpsError('invalid-argument', 'Description must be between 5 and 1000 characters');
    }

    // premium check 
    let isPremium = false;
    try {
        const subSnap = await db.collection('subscriptions').doc(uid).get();
        if (subSnap.exists) {
            const s = subSnap.data() as SubscriptionData;
            const end = s?.endDate ? toDayjs(s.endDate) : null;
            isPremium = s?.isPremium === true && !!(end && end.isAfter(safeNow()));
        }
    } catch (e) {
        logger.error('Failed to check premium status', { uid, error: e });
        throw new HttpsError('internal', 'Unable to verify subscription status');
    }

    if (!isPremium) {
        throw new HttpsError('permission-denied', 'Upgrade required for AI logging.');
    }

    // ai execution
    const apiKey = GEMINI_API_KEY.value();
    if (!apiKey) throw new HttpsError('internal', 'AI configuration error');

    try {
        const genAI = new GoogleGenerativeAI(apiKey);
        
        const model = genAI.getGenerativeModel({ 
            model: getAiModel(), 
            generationConfig: {
                temperature: 0.2, 
                maxOutputTokens: 500,
            }
        });

        const userPrompt = `Locale: ${locale}\nDescription: "${description}"`;

        const result = await model.generateContent([
            { text: WORKOUT_PARSE_PROMPT },
            { text: userPrompt }
        ]);

        const responseText = result.response.text();
        logger.debug('AI Response', { responseText: responseText.substring(0, 500) });
        
        let parsed: any;
        try {
            // strip markdown fences
            let cleanJson = responseText.replace(/```json|```/g, '').trim();
            
            // find json object
            const firstBrace = cleanJson.indexOf('{');
            const lastBrace = cleanJson.lastIndexOf('}');
            if (firstBrace !== -1 && lastBrace !== -1) {
                cleanJson = cleanJson.substring(firstBrace, lastBrace + 1);
            }

            parsed = JSON.parse(cleanJson);
        } catch (parseError) {
            logger.error('JSON Parse Error', { responseText, error: parseError });
            throw new HttpsError('internal', 'AI returned invalid format');
        }

        // post process
        const exercises = (parsed.exercises || []).map((ex: any) => ({
            name: ex.name || 'Unknown',
            type: ex.type || 'other',
            muscleGroup: ex.muscleGroup || null,
            sets: ex.sets || null,
            reps: ex.reps || null,
            weight: ex.weight || null,
            weightUnit: ex.weightUnit || 'kg',
            duration: ex.duration || 0,
            distance: ex.distance || 0,
            caloriesBurned: ex.caloriesBurned || 0,
        }));

        // recalculate totals
        const calculatedCalories = exercises.reduce((sum: number, ex: any) => sum + ex.caloriesBurned, 0);
        const calculatedDuration = exercises.reduce((sum: number, ex: any) => sum + ex.duration, 0);

        const response = {
            success: true,
            workout: {
                exercises,
                totalDuration: parsed.totalDuration || calculatedDuration,
                totalCaloriesBurned: parsed.totalCaloriesBurned || calculatedCalories,
                summary: parsed.summary
            }
        };
        
        logger.debug('Returning workout response', { exerciseCount: exercises.length, summary: parsed.summary });
        return response;

    } catch (error: any) {
        logger.error('AI Processing Error', { uid, correlationId, error: error.message });
        
        if (error instanceof HttpsError) throw error;
        
        // hide internal errors
        throw new HttpsError('internal', 'We encountered an issue analyzing your workout.');
    }
});