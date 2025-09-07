import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../Model/openAIModel.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';

class OpenAiCalling {
  // New: request a meal breakdown as list of items
  static Future<String> analyzeMealItems(File image) async {
    try {
      final currentLang = _getLanguageName();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant with advanced portion estimation capabilities. Given a food photo, you MUST return ONLY compact JSON listing all distinct items with detailed portion analysis. No commentary, no markdown.\n\nJSON shape:\n{\n  \"mealItems\": [\n    {\n      \"name\": <string in $currentLang>,\n      \"english_name\": <string in English>,\n      \"portionType\": \"pieces\" | \"grams\",\n      \"count\": <number, only if portionType is pieces>,\n      \"estimatedWeight\": <number in grams>\n    }\n  ]\n}\n\nCRITICAL: Be conservative with portion estimates. Common food weights:\n- Medium egg ≈ 50g (NOT 65g+)\n- Large egg ≈ 60g maximum\n- Thin bread slice ≈ 25g\n- Thick bread slice ≈ 35g\n- Medium apple ≈ 150g\n- Banana ≈ 120g\n\nFor piece-based items: carefully examine visual size and compare to standard references. Avoid overestimating weights. Always provide count AND realistic total weight in grams.\n\nFor weight-based items: estimate total grams conservatively based on visual portion size.",
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze all foods in this image with enhanced portion estimation. For piece-based items, estimate both count and realistic gram weight based on visual size cues. Output only the structured JSON with portionType, count (if pieces), and estimatedWeight fields.',
              },
              {
                'type': 'image_url',
                'image_url': {'url': "data:image/jpeg;base64,$base64Image"},
              },
            ],
          },
        ],
        'temperature': 0,
        'max_tokens': 500,
      };
  final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final callable = functions.httpsCallable('chatWithOpenRouter');
  final result = await callable.call(parameters);
  // Normalize to Map<String, dynamic> deeply to avoid nested Map<Object?, Object?> types
  final decodedJson = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      return data.choices!.first.message!.content.toString();
    } catch (e) {
      if (kDebugMode) {
        print("error analyzeMealItems====> $e");
      }
      return "Something Went Wrong";
    }
  }

  static Future<String> sentImageApi(File image) async {
    try {
      // Get current app language for response localization
      final currentLang = _getLanguageName();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. Given a food photo you MUST return ONLY compact JSON with integer values in kcal/grams. No commentary, no markdown. If multiple foods are present, estimate TOTAL combined values. JSON shape: {\\n  \"food_name\": <string>,\\n  \"food_name_english\": <string>,\\n  \"calories\": <int>,\\n  \"protein_g\": <int>,\\n  \"carbohydrates_g\": <int>,\\n  \"fats_g\": <int>\\n}. The food_name should be short, human-friendly, and written in $currentLang (e.g., 'Grilled chicken with salad'). The food_name_english should be the same food name but always in English (e.g., 'Apple', 'Grilled chicken with salad'). If unsure, provide your best reasonable estimate; never output 0 unless clearly no food.",
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze this image and output ONLY the JSON described. Make sure the food_name is in $currentLang and food_name_english is always in English.',
              },
              {
                'type': 'image_url',
                'image_url': {'url': "data:image/jpeg;base64,$base64Image"},
              },
            ],
          },
        ],
        'temperature': 0,
        'max_tokens': 300,
      };
  final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final callable = functions.httpsCallable('chatWithOpenRouter');
  final result = await callable.call(parameters);
  // Normalize to Map<String, dynamic> deeply to avoid nested Map<Object?, Object?> types
  final decodedJson = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      return data.choices!.first.message!.content.toString();
    } catch (e) {
      if (kDebugMode) {
        print("error is====> $e");
      }
      return "Something Went Wrong";
    }
  }

  // Helper method to get readable language name for AI prompts
  static String _getLanguageName() {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';

    // Map language codes to full language names for better AI understanding
    final languageMap = {
      'en': 'English',
      'ar': 'Arabic',
      'fr': 'French',
      'es': 'Spanish',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'hi': 'Hindi',
      'ur': 'Urdu',
      'tr': 'Turkish',
      'nl': 'Dutch',
    };

    return languageMap[currentLang] ?? 'English';
  }
}
