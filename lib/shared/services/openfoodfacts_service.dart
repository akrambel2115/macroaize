import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/product/$barcode');

      if (kDebugMode) {
        print('Fetching product: $url');
      }

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          return parseProductData(data['product']);
        } else {
          if (kDebugMode) {
            print('Product not found in OpenFoodFacts');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('API error: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product: $e');
      }
      return null;
    }
  }

  Map<String, dynamic> parseProductData(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] ?? {};

    String name =
        product['product_name'] ??
        product['product_name_en'] ??
        'Unknown Product';

    final brand = product['brands'];
    if (brand != null && brand.toString().isNotEmpty) {
      name = '$brand $name';
    }

    final calories = _extractNutrient(nutriments, [
      'energy-kcal_100g',
      'energy-kcalories_100g',
      'energy_100g',
    ]);

    final protein = _extractNutrient(nutriments, [
      'proteins_100g',
      'protein_100g',
    ]);

    final carbs = _extractNutrient(nutriments, [
      'carbohydrates_100g',
      'carbs_100g',
    ]);

    final fat = _extractNutrient(nutriments, ['fat_100g', 'fats_100g']);

    final servingSize = product['serving_size'] ?? product['serving_quantity'];

    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving_size': servingSize,
      'quantity': '100g',
      'image_url': product['image_url'],
      'barcode': product['code'],
      'product_quantity': product['product_quantity'],
      'product_quantity_unit': product['product_quantity_unit'],
    };
  }

  double _extractNutrient(Map<String, dynamic> nutriments, List<String> keys) {
    for (final key in keys) {
      final value = nutriments[key];
      if (value != null) {
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }
}
