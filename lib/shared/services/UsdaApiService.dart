import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foodcalorietracker/constant/Appkey.dart';

class UsdaFood {
  final int fdcId;
  final String description;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  UsdaFood({
    required this.fdcId,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

class UsdaApiFailure implements Exception {
  final String message;
  final int? statusCode;
  UsdaApiFailure(this.message, {this.statusCode});
  @override
  String toString() => 'UsdaApiFailure($statusCode): $message';
}

class UsdaApiService {
  static const _base = 'https://api.nal.usda.gov/fdc/v1/foods/search';

  /// Search top results for a food name. Returns up to [limit] items.
  Future<List<UsdaFood>> searchFood(String query, {int limit = 3, String? locale}) async {
    if (query.trim().isEmpty) return [];

    final key = usdaApiKey;
    if (key.isEmpty || key == 'YOUR_USDA_API_KEY' || key == 'ENTER_USDA_API_KEY') {
      // Missing key — treat as failure so callers can fallback.
      throw UsdaApiFailure('Missing USDA API key');
    }

    final uri = Uri.parse(_base).replace(queryParameters: {
      'query': query,
      'api_key': key,
      'pageSize': '$limit',
      // 'sortBy': 'dataType.keyword', // optional
    });

    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw UsdaApiFailure('Network error: $e');
    }

    if (res.statusCode != 200) {
      throw UsdaApiFailure('HTTP ${res.statusCode}', statusCode: res.statusCode);
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw UsdaApiFailure('Invalid JSON: $e');
    }

    final foods = (json['foods'] as List<dynamic>? ?? []);
    return foods.map<UsdaFood>((f) {
      final nutrients = (f['foodNutrients'] as List<dynamic>? ?? []);

      double getValue(List names) {
        for (final n in nutrients) {
          final name = (n['nutrientName'] ?? '').toString();
          if (names.contains(name)) {
            final v = n['value'];
            if (v is num) return v.toDouble();
            try { return double.parse(v.toString()); } catch (_) { return 0.0; }
          }
        }
        return 0.0;
      }

      final kcal = getValue(['Energy', 'Energy (Atwater General Factors)']);
      final protein = getValue(['Protein']);
      final carbs = getValue(['Carbohydrate, by difference']);
      final fat = getValue(['Total lipid (fat)']);

      return UsdaFood(
        fdcId: (f['fdcId'] as num?)?.toInt() ?? 0,
        description: (f['description'] ?? '').toString(),
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fats: fat,
      );
    }).toList();
  }
}
