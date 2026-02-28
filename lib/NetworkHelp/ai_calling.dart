import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;
import '../Model/ai_model.dart';
import 'package:macroaize/shared/services/app_config_service.dart';

class OpenAiCalling {
  static const int _maxImageDimension = 1280;
  static const int _compressQuality = 80;
  static const int _maxImageBytes = 2 * 1024 * 1024;

  static const Duration _callTimeout = Duration(seconds: 45);
  static const int _maxRetries = 2;

  static Future<Uint8List> compressImage(File imageFile) async {
    final rawBytes = await imageFile.readAsBytes();
    final decoded = await compute(_decodeAndResize, rawBytes);
    if (decoded != null) return decoded;

    final fallback = await compute(_fallbackCompress, rawBytes);
    if (fallback != null) return fallback;

    return rawBytes;
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

  static Uint8List? _fallbackCompress(Uint8List rawBytes) {
    try {
      var decoded = img.decodeJpg(rawBytes);
      decoded ??= img.decodePng(rawBytes);
      if (decoded == null) return null;

      const safeMax = 800;
      if (decoded.width > safeMax || decoded.height > safeMax) {
        if (decoded.width >= decoded.height) {
          decoded = img.copyResize(decoded, width: safeMax);
        } else {
          decoded = img.copyResize(decoded, height: safeMax);
        }
      }

      return Uint8List.fromList(img.encodeJpg(decoded, quality: 60));
    } catch (e) {
      return null;
    }
  }

  static String _stripMarkdownFences(String text) {
    var s = text.trim();
    if (s.contains('```')) {
      final start = s.indexOf('```');
      final end = s.lastIndexOf('```');
      if (end > start) {
        s = s.substring(start + 3, end).trim();
        if (s.startsWith('json')) {
          s = s.substring(4).trimLeft();
        }
      }
    }
    return s;
  }

  static Future<HttpsCallableResult> _callWithRetry(
    Map<String, dynamic> parameters,
  ) async {
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final callable = functions.httpsCallable(
      'chatWithOpenRouter',
      options: HttpsCallableOptions(timeout: _callTimeout),
    );

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await callable.call(parameters);
      } on FirebaseFunctionsException catch (e) {
        lastError = e;
        final retryable = e.code == 'resource-exhausted' ||
            e.code == 'internal' ||
            e.code == 'unavailable';
        if (!retryable || attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      } catch (e) {
        lastError = e;
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    throw lastError ?? Exception('AI call failed');
  }

  static String _extractContent(HttpsCallableResult result) {
    final decodedJson =
        jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
    final data = OpenAiModel.fromJson(decodedJson);
    return data.choices!.first.message!.content.toString();
  }

  static String _getLanguageName() {
    final code = Get.locale?.languageCode.toLowerCase() ?? 'en';
    const map = {'en': 'English', 'ar': 'Arabic', 'fr': 'French'};
    return map[code] ?? 'English';
  }

  static Future<String> analyzeMealItems(File image) async {
    try {
      final currentLang = _getLanguageName();
      final bytes = await compressImage(image);
      final base64Image = base64Encode(bytes);
      final parameters = <String, dynamic>{
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant with advanced portion estimation capabilities. "
                "Given a photo, first determine whether the image contains food or a beverage. "
                "If the image does NOT contain any food or drink, return ONLY: {\"is_food\": false}. "
                "Do NOT invent nutritional values for non-food images.\n\n"
                "If the image DOES contain food, return ONLY compact JSON listing distinct items with portion analysis. "
                "No commentary or markdown.\n\n"
                "JSON shape:\n"
                "{\n"
                "  \"is_food\": true,\n"
                "  \"mealItems\": [\n"
                "    {\n"
                "      \"name\": <string in $currentLang>,\n"
                "      \"english_name\": <string in English>,\n"
                "      \"isLiquid\": <bool>,\n"
                "      \"portionType\": \"pieces\" | \"grams\" | \"ml\",\n"
                "      \"count\": <number, only if portionType is pieces>,\n"
                "      \"estimatedWeight\": <number in grams or ml>\n"
                "    }\n"
                "  ]\n"
                "}\n\n"
                "Rules:\n"
                "- isLiquid=true for any drinkable, pourable, or liquid-first item "
                "(beverages, soups, broths, shakes, juices, milk, etc.). "
                "Then set portionType=\"ml\" and estimatedWeight in milliliters.\n"
                "- Be conservative with portion estimates.\n"
                "- Common references: medium egg ≈ 50 g, thin bread slice ≈ 25 g, "
                "thick bread slice ≈ 35 g, medium apple ≈ 150 g, banana ≈ 120 g.\n"
                "- For piece-based items provide count AND realistic total weight.\n"
                "- For weight-based items estimate total grams conservatively.",
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Identify every food item in this image. '
                    'For each, determine isLiquid, portionType, count (if pieces), '
                    'and estimatedWeight. Output ONLY the JSON.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': "data:image/jpeg;base64,$base64Image",
                  'detail': 'high',
                },
              },
            ],
          },
        ],
        'temperature': 0,
        'max_tokens': 600,
      };
      final result = await _callWithRetry(parameters);
      return _extractContent(result);
    } catch (e) {
      if (kDebugMode) print("error analyzeMealItems====> $e");
      return "Something Went Wrong";
    }
  }

  static Future<String> sentImageApi(File image) async {
    try {
      final currentLang = _getLanguageName();
      final bytes = await compressImage(image);
      final base64Image = base64Encode(bytes);
      final parameters = <String, dynamic>{
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. "
                "Given a photo, first determine if it contains food or a beverage. "
                "If it does NOT, return ONLY: {\"is_food\": false}. "
                "Do NOT invent nutritional values for non-food images.\n\n"
                "If it DOES contain food, return ONLY compact JSON with integer kcal/gram values. "
                "No commentary or markdown. If multiple foods are present, estimate TOTAL combined values.\n\n"
                "JSON shape:\n"
                "{\n"
                "  \"is_food\": true,\n"
                "  \"food_name\": <string in $currentLang>,\n"
                "  \"food_name_english\": <string in English>,\n"
                "  \"calories\": <int>,\n"
                "  \"protein_g\": <int>,\n"
                "  \"carbohydrates_g\": <int>,\n"
                "  \"fats_g\": <int>\n"
                "}",
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze this image and output ONLY the JSON described. '
                    'food_name in $currentLang, food_name_english in English.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': "data:image/jpeg;base64,$base64Image",
                  'detail': 'high',
                },
              },
            ],
          },
        ],
        'temperature': 0,
        'max_tokens': 300,
      };
      final result = await _callWithRetry(parameters);
      return _extractContent(result);
    } catch (e) {
      if (kDebugMode) print("error sentImageApi====> $e");
      return "Something Went Wrong";
    }
  }

  static Future<Map<String, double>?> estimateNutritionByName(
    String foodName,
    double grams,
  ) async {
    try {
      final parameters = <String, dynamic>{
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Given a food name, return ONLY compact JSON '
                'with numeric per-100 g nutritional values. No commentary or markdown.\n'
                'JSON shape: {"kcalPer100g":<number>,"proteinPer100g":<number>,'
                '"carbsPer100g":<number>,"fatPer100g":<number>}\n'
                'Use realistic values. Never return all zeros.',
          },
          {
            'role': 'user',
            'content':
                'Nutritional values per 100 g for: "$foodName" '
                '(estimated portion ${grams.toInt()} g). Return ONLY the JSON.',
          },
        ],
        'temperature': 0,
        'max_tokens': 100,
      };
      final result = await _callWithRetry(parameters);
      final raw = _extractContent(result);
      final cleaned = _stripMarkdownFences(raw);
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return {
        'kcalPer100g': (parsed['kcalPer100g'] as num?)?.toDouble() ?? 0.0,
        'proteinPer100g':
            (parsed['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
        'carbsPer100g': (parsed['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
        'fatPer100g': (parsed['fatPer100g'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      if (kDebugMode) print("error estimateNutritionByName====> $e");
      return null;
    }
  }

  static Future<List<Map<String, double>?>> estimateNutritionBatch(
    List<String> foodNames,
  ) async {
    if (foodNames.isEmpty) return [];
    if (foodNames.length == 1) {
      final single = await estimateNutritionByName(foodNames.first, 100);
      return [single];
    }
    try {
      final itemsList = foodNames
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}')
          .join('\n');
      final parameters = <String, dynamic>{
        'model': Get.find<AppConfigService>().aiModel,
        'context': 'scan',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Given a numbered list of food names, '
                'return ONLY a JSON array with one object per item (same order). '
                'No commentary or markdown.\n'
                'Each object shape: {"kcalPer100g":<number>,"proteinPer100g":<number>,'
                '"carbsPer100g":<number>,"fatPer100g":<number>}\n'
                'Use realistic values. Never return all zeros.',
          },
          {
            'role': 'user',
            'content':
                'Nutritional values per 100 g for each item:\n$itemsList\n\n'
                'Return ONLY the JSON array.',
          },
        ],
        'temperature': 0,
        'max_tokens': foodNames.length * 60,
      };
      final result = await _callWithRetry(parameters);
      final raw = _extractContent(result);
      final cleaned = _stripMarkdownFences(raw);
      final decoded = jsonDecode(cleaned);
      final List list = decoded is List ? decoded : [];
      return List.generate(foodNames.length, (i) {
        if (i >= list.length) return null;
        final m = list[i];
        if (m is! Map) return null;
        return {
          'kcalPer100g': (m['kcalPer100g'] as num?)?.toDouble() ?? 0.0,
          'proteinPer100g': (m['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
          'carbsPer100g': (m['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
          'fatPer100g': (m['fatPer100g'] as num?)?.toDouble() ?? 0.0,
        };
      });
    } catch (e) {
      if (kDebugMode) print("error estimateNutritionBatch====> $e");
      final results = <Map<String, double>?>[];
      for (final name in foodNames) {
        results.add(await estimateNutritionByName(name, 100));
      }
      return results;
    }
  }
}
