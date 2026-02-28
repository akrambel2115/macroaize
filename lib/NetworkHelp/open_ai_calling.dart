import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;
import '../Model/ai_model.dart';
import 'package:macroaize/shared/services/app_config_service.dart';

class OpenAiCalling {

  static const int _maxImageDimension = 768;

  static const int _compressQuality = 70;

  static const int _maxImageBytes = 3 * 1024 * 1024;

  static Future<Uint8List> compressImage(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();

    if (rawBytes.length <= 2 * 1024 * 1024) {
      return rawBytes;
    }

    final decoded = await compute(_decodeAndResize, rawBytes);
    if (decoded == null) {

      return rawBytes;
    }
    return decoded;
  }

  static Uint8List? _decodeAndResize(Uint8List rawBytes) {
    try {
      var decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      decoded = img.bakeOrientation(decoded);

      if (decoded.width > _maxImageDimension ||
          decoded.height > _maxImageDimension) {
        if (decoded.width >= decoded.height) {
          decoded = img.copyResize(decoded, width: _maxImageDimension);
        } else {
          decoded = img.copyResize(decoded, height: _maxImageDimension);
        }
      }

      var quality = _compressQuality;
      var encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

      while (encoded.length > _maxImageBytes && quality > 30) {
        quality -= 10;
        encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      }

      return encoded;
    } catch (e) {
      return null;
    }
  }

  static Future<String> analyzeMealItems(File image) async {
    try {
      final currentLang = _getLanguageName();
      final bytes = await compressImage(image);
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant with advanced portion estimation capabilities. Given a photo, first determine whether the image contains food or a beverage. If the image does NOT contain any food or drink, return ONLY: {\"is_food\": false}. Do NOT invent nutritional values for non-food images.\n\nIf the image DOES contain food, return ONLY compact JSON listing distinct items with portion analysis. No commentary or markdown.\n\nJSON shape:\n{\n  \"is_food\": true,\n  \"mealItems\": [\n    {\n      \"name\": <string in $currentLang>,\n      \"english_name\": <string in English>,\n      \"portionType\": \"pieces\" | \"grams\" | \"ml\",\n      \"count\": <number, only if portionType is pieces>,\n      \"estimatedWeight\": <number in grams or ml>\n    }\n  ]\n}\n\nBe conservative with portion estimates. Common references:\n- Medium egg ≈ 50g\n- Large egg ≤ 60g\n- Thin bread slice ≈ 25g\n- Thick bread slice ≈ 35g\n- Medium apple ≈ 150g\n- Banana ≈ 120g\n\nProvide count AND realistic total weight for piece-based items. For weight-based items, estimate total grams conservatively. For beverages and liquid items (juice, milk, water, coffee, tea, smoothie, soup, broth, soda, etc.), always use portionType \"ml\" and estimate volume in milliliters.",
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze all foods in this image with enhanced portion estimation. For piece-based items, estimate both count and realistic gram weight based on visual size cues. For beverages and liquids, use portionType ml and estimate volume in milliliters. Output only the structured JSON with portionType, count (if pieces), and estimatedWeight fields.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': "data:image/jpeg;base64,$base64Image",
                  'detail': 'low'
                },
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
      // map<String, dynamic>
      final decodedJson =
          jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
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
      final bytes = await compressImage(image);
      final base64Image = base64Encode(bytes);
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. Given a photo, first determine if it contains food or a beverage. If it does NOT contain any food or drink, return ONLY: {\\n  \"is_food\": false\\n}. Do NOT invent nutritional values for non-food images.\\n\\nIf it DOES contain food, return ONLY compact JSON with integer kcal/gram values. No commentary or markdown. If multiple foods are present, estimate TOTAL combined values. JSON shape: {\\n  \"is_food\": true,\\n  \"food_name\": <string>,\\n  \"food_name_english\": <string>,\\n  \"calories\": <int>,\\n  \"protein_g\": <int>,\\n  \"carbohydrates_g\": <int>,\\n  \"fats_g\": <int>\\n}. food_name should be in $currentLang, food_name_english always in English.",
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
                'image_url': {
                  'url': "data:image/jpeg;base64,$base64Image",
                  'detail': 'low'
                },
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

      // map<String, dynamic>
      final decodedJson =
          jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      return data.choices!.first.message!.content.toString();
    } catch (e) {
      if (kDebugMode) print("error is====> $e");
      return "Something Went Wrong";
    }
  }

  // helper to map language code to name
  static String _getLanguageName() {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';

    // map language codes to readable names
    final languageMap = {'en': 'English', 'ar': 'Arabic', 'fr': 'French'};

    return languageMap[currentLang] ?? 'English';
  }


  static Future<Map<String, double>?> estimateNutritionByName(
    String foodName,
    double grams,
  ) async {
    try {
      final parameters = {
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Given a food name, return ONLY compact JSON with numeric per-100g nutritional values. No commentary or markdown.\nJSON shape: {"kcalPer100g":<number>,"proteinPer100g":<number>,"carbsPer100g":<number>,"fatPer100g":<number>}\nUse realistic values. Never return all zeros.',
          },
          {
            'role': 'user',
            'content':
                'Nutritional values per 100g for: "$foodName" (estimated portion ${grams.toInt()}g). Return ONLY the JSON.',
          },
        ],
        'temperature': 0,
        'max_tokens': 150,
      };
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('chatWithOpenRouter');
      final result = await callable.call(parameters);
      final decodedJson =
          jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
      OpenAiModel data = OpenAiModel.fromJson(decodedJson);
      final raw = data.choices!.first.message!.content.toString().trim();
      String cleaned = raw;
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('```');
        final end = cleaned.lastIndexOf('```');
        if (end > start) {
          cleaned = cleaned.substring(start + 3, end).trim();
          if (cleaned.startsWith('json')) {
            cleaned = cleaned.substring(4).trimLeft();
          }
        }
      }
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return {
        'kcalPer100g':
            (parsed['kcalPer100g'] as num?)?.toDouble() ?? 0.0,
        'proteinPer100g':
            (parsed['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
        'carbsPer100g':
            (parsed['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
        'fatPer100g':
            (parsed['fatPer100g'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      if (kDebugMode) print("error estimateNutritionByName====> $e");
      return null;
    }
  }
}
