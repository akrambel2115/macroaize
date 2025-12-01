import { logger } from 'firebase-functions/v2';

export function validateRequestSize(data: any, maxSizeKB: number = 10): boolean {
    try {
        const serialized = JSON.stringify(data);
        const sizeKB = serialized.length / 1024;
        return sizeKB <= maxSizeKB;
    } catch {
        return false;
    }
}

export function isValidPromoCode(code: string): boolean {
    if (!code || typeof code !== 'string') return false;
    if (code.length < 6 || code.length > 12) return false;
    return /^[A-Z0-9]+$/.test(code);
}

export function validateAiJsonResponse(jsonString: string, schema: 'nutrition' | 'mealItems'): any {
    try {
        // Basic sanitization
        let cleaned = jsonString.trim();
        if (cleaned.includes('```')) {
            const start = cleaned.indexOf('```');
            const end = cleaned.lastIndexOf('```');
            if (end > start) {
                cleaned = cleaned.substring(start + 3, end).trim();
                if (cleaned.startsWith('json')) {
                    cleaned = cleaned.substring(4).trimLeft();
                }
            }
        }

        const parsed = JSON.parse(cleaned);

        if (schema === 'nutrition') {
            return validateNutritionSchema(parsed);
        } else if (schema === 'mealItems') {
            return validateMealItemsSchema(parsed);
        }

        throw new Error('Unknown schema type');
    } catch (error) {
        logger.warn('AI JSON validation failed', {
            error: error instanceof Error ? error.message : String(error),
            schema,
            input: jsonString.substring(0, 200) // Log first 200 chars
        });

        // Return safe fallback
        if (schema === 'nutrition') {
            return {
                food_name: 'Unknown Food',
                food_name_english: 'Unknown Food',
                calories: 0,
                protein_g: 0,
                carbohydrates_g: 0,
                fats_g: 0
            };
        } else {
            return { mealItems: [] };
        }
    }
}

function validateNutritionSchema(data: any): any {
    if (!data || typeof data !== 'object') {
        throw new Error('Invalid nutrition data structure');
    }

    const clampNumber = (value: any, min: number = 0, max: number = 10000): number => {
        const num = Number(value) || 0;
        return Math.max(min, Math.min(max, Math.round(num)));
    };

    const sanitizeString = (value: any, maxLength: number = 100): string => {
        const str = String(value || '').trim();
        return str.substring(0, maxLength);
    };

    return {
        food_name: sanitizeString(data.food_name, 200),
        food_name_english: sanitizeString(data.food_name_english, 200),
        calories: clampNumber(data.calories),
        protein_g: clampNumber(data.protein_g),
        carbohydrates_g: clampNumber(data.carbohydrates_g),
        fats_g: clampNumber(data.fats_g)
    };
}

function validateMealItemsSchema(data: any): any {
    if (!data || typeof data !== 'object') {
        throw new Error('Invalid meal items data structure');
    }

    const mealItems = Array.isArray(data.mealItems) ? data.mealItems : [];
    const validatedItems = mealItems.slice(0, 20).map((item: any) => { // Limit to 20 items
        if (!item || typeof item !== 'object') return null;

        const clampNumber = (value: any, min: number = 0, max: number = 10000): number => {
            const num = Number(value) || 0;
            return Math.max(min, Math.min(max, Math.round(num)));
        };

        const sanitizeString = (value: any, maxLength: number = 100): string => {
            const str = String(value || '').trim();
            return str.substring(0, maxLength);
        };

        const portionType = String(item.portionType || '').toLowerCase();
        const validPortionTypes = ['pieces', 'grams'];
        const safePortionType = validPortionTypes.includes(portionType) ? portionType : 'grams';

        return {
            name: sanitizeString(item.name, 200),
            english_name: sanitizeString(item.english_name, 200),
            portionType: safePortionType,
            count: safePortionType === 'pieces' ? clampNumber(item.count, 1, 100) : undefined,
            estimatedWeight: clampNumber(item.estimatedWeight, 1, 5000) // Max 5kg
        };
    }).filter((item: any) => item !== null);

    return {
        mealItems: validatedItems
    };
}

export function sanitizeUsdaResponse(rawResponse: any): any {
    try {
        if (!rawResponse || typeof rawResponse !== 'object') {
            return { foods: [] };
        }

        const foods = Array.isArray(rawResponse.foods) ? rawResponse.foods : [];
        const sanitizedFoods = foods.map((food: any) => {
            if (!food || typeof food !== 'object') return null;

            const sanitizedFood: any = {
                fdcId: Number(food.fdcId) || 0,
                description: String(food.description || '').trim().substring(0, 200),
                foodNutrients: []
            };

            if (Array.isArray(food.foodNutrients)) {
                sanitizedFood.foodNutrients = food.foodNutrients.map((nutrient: any) => {
                    if (!nutrient || typeof nutrient !== 'object') return null;

                    const value = nutrient.value;
                    const sanitizedValue = (typeof value === 'number' && !isNaN(value) && isFinite(value))
                        ? Math.max(0, Math.min(10000, value))
                        : 0;

                    return {
                        nutrientName: String(nutrient.nutrientName || '').trim().substring(0, 100),
                        value: sanitizedValue,
                        unitName: String(nutrient.unitName || '').trim().substring(0, 20)
                    };
                }).filter((nutrient: any) => nutrient !== null);
            }

            return sanitizedFood;
        }).filter((food: any) => food !== null);

        return {
            foods: sanitizedFoods.slice(0, 10), // Limit to 10
            totalHits: Number(rawResponse.totalHits) || 0,
            currentPage: Number(rawResponse.currentPage) || 1,
            totalPages: Number(rawResponse.totalPages) || 1
        };
    } catch (error) {
        logger.warn('Failed to sanitize USDA response', { error: error instanceof Error ? error.message : String(error) });
        return { foods: [] };
    }
}
