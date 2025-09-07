import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

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

  /// Search top results for a food name. Returns up to [limit] items.
  Future<List<UsdaFood>> searchFood(String query, {int limit = 3, String? locale}) async {
    if (query.trim().isEmpty) return [];
    // Call secure backend proxy to avoid exposing API key in client
    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    HttpsCallable callable = functions.httpsCallable('searchUsdaFoods');
    dynamic raw;
    try {
      final res = await callable.call({'query': query, 'limit': limit});
      raw = res.data;
    } on FirebaseFunctionsException catch (e) {
      throw UsdaApiFailure(e.message ?? 'USDA function error', statusCode: e.code == 'unavailable' ? 503 : null);
    } catch (e) {
      throw UsdaApiFailure('Function call error: $e');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
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
