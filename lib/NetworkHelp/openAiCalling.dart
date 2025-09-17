import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../Model/openAIModel.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';

class OpenAiCalling {
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
                "You are a nutrition analysis assistant with advanced portion estimation capabilities. Given a food photo, return ONLY compact JSON listing distinct items with portion analysis. No commentary or markdown.\n\nJSON shape:\n{\n  \"mealItems\": [\n    {\n      \"name\": <string in $currentLang>,\n      \"english_name\": <string in English>,\n      \"portionType\": \"pieces\" | \"grams\",\n      \"count\": <number, only if portionType is pieces>,\n      \"estimatedWeight\": <number in grams>\n    }\n  ]\n}\n\nBe conservative with portion estimates. Common references:\n- Medium egg ≈ 50g\n- Large egg ≤ 60g\n- Thin bread slice ≈ 25g\n- Thick bread slice ≈ 35g\n- Medium apple ≈ 150g\n- Banana ≈ 120g\n\nProvide count AND realistic total weight for piece-based items. For weight-based items, estimate total grams conservatively.",
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
  // normalize to Map<String, dynamic>
  final decodedJson = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      return data.choices!.first.message!.content.toString();
    } catch (e) {
      if (kDebugMode) print("error analyzeMealItems====> $e");
      return "Something Went Wrong";
    }
  }

  static Future<String> sentImageApi(File image) async {
    try {
  // get current app language for localization
  final currentLang = _getLanguageName();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. Given a food photo return ONLY compact JSON with integer kcal/gram values. No commentary or markdown. If multiple foods are present, estimate TOTAL combined values. JSON shape: {\\n  \"food_name\": <string>,\\n  \"food_name_english\": <string>,\\n  \"calories\": <int>,\\n  \"protein_g\": <int>,\\n  \"carbohydrates_g\": <int>,\\n  \"fats_g\": <int>\\n}. food_name should be in $currentLang, food_name_english always in English. If unsure, give best estimate; avoid 0 unless clearly no food.",
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
  // normalize to Map<String, dynamic>
  final decodedJson = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      return data.choices!.first.message!.content.toString();
    } catch (e) {
      if (kDebugMode) print("error is====> $e");
      return "Something Went Wrong";
    }
  }

  // helper to map language code to name for AI prompts
  static String _getLanguageName() {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';

    // map language codes to readable names
    final languageMap = {
      'en': 'English',
      'ar': 'Arabic',
      'fr': 'French',
    };

    return languageMap[currentLang] ?? 'English';
  }
}
