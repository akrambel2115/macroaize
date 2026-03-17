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

  static String _normalizeModelJsonText(String text) {
    return _stripMarkdownFences(text).trim();
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
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. Return valid JSON only (no markdown, no comments). "
                "First classify the image: if no edible food or drink is present, return exactly {\"is_food\": false}. "
                "If food/drink is present, return exactly this shape: "
                "{\"is_food\":true,\"mealItems\":[{\"name\":string($currentLang),\"english_name\":string(English),\"isLiquid\":bool,\"portionType\":\"pieces\"|\"grams\"|\"ml\",\"count\":number(optional, pieces only),\"estimatedWeight\":number}]}. "
                "Rules: identify distinct edible items only, be conservative, and keep estimatedWeight realistic. "
                "For liquids use isLiquid=true, portionType=\"ml\", estimatedWeight in ml. "
                "For solids use grams or pieces. For pieces include both count and realistic total weight.",
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
        'max_tokens': 450,
      };
      final result = await _callWithRetry(parameters);
      return _normalizeModelJsonText(_extractContent(result));
    } catch (e) {
      if (kDebugMode) print("error analyzeMealItems====> $e");
      // Allow caller to continue to fallback nutrition analysis path.
      return '{"is_food":null,"mealItems":[]}';
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
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a nutrition analysis assistant. Return valid JSON only (no markdown, no comments). "
                "If image has no edible food/drink, return exactly {\"is_food\": false}. "
                "If food exists, return exactly: "
                "{\"is_food\":true,\"food_name\":string($currentLang),\"food_name_english\":string(English),\"calories\":int,\"protein_g\":int,\"carbohydrates_g\":int,\"fats_g\":int,\"estimated\":true}. "
                "If multiple foods exist, estimate totals for the full visible meal. "
                "Use conservative but realistic values.",
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
        'max_tokens': 220,
      };
      final result = await _callWithRetry(parameters);
      return _normalizeModelJsonText(_extractContent(result));
    } catch (e) {
      if (kDebugMode) print("error sentImageApi====> $e");
      return '{"is_food":null,"food_name":"","food_name_english":"","calories":0,"protein_g":0,"carbohydrates_g":0,"fats_g":0,"estimated":true}';
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
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Given a food name, return ONLY compact JSON '
                'with numeric per-100 g nutritional values. No commentary or markdown.\n'
                'JSON shape: {"kcalPer100g":<number>,"proteinPer100g":<number>,'
                '"carbsPer100g":<number>,"fatPer100g":<number>}\n'
                'If exact data is unavailable, return a conservative realistic estimate based on similar foods.',
          },
          {
            'role': 'user',
            'content':
                'Nutritional values per 100 g for: "$foodName" '
                '(estimated portion ${grams.toInt()} g). Return ONLY the JSON.',
          },
        ],
        'max_tokens': 80,
      };
      final result = await _callWithRetry(parameters);
      final raw = _extractContent(result);
      final cleaned = _normalizeModelJsonText(raw);
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
        'temperature': 0,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a nutrition database. Given a numbered list of food names, '
                'return ONLY a JSON array with one object per item (same order). '
                'No commentary or markdown.\n'
                'Each object shape: {"kcalPer100g":<number>,"proteinPer100g":<number>,'
                '"carbsPer100g":<number>,"fatPer100g":<number>}\n'
                'If exact data is unavailable, return conservative realistic estimates.',
          },
          {
            'role': 'user',
            'content':
                'Nutritional values per 100 g for each item:\n$itemsList\n\n'
                'Return ONLY the JSON array.',
          },
        ],
        'max_tokens': foodNames.length * 45,
      };
      final result = await _callWithRetry(parameters);
      final raw = _extractContent(result);
      final cleaned = _normalizeModelJsonText(raw);
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
