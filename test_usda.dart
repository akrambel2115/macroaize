import 'dart:io';
import 'lib/shared/services/UsdaApiService.dart';

void main() async {
  print('Testing USDA API with "apple"...');
  
  final service = UsdaApiService();
  
  try {
    final results = await service.searchFood('apple', limit: 3);
    print('Found ${results.length} results:');
    
    for (int i = 0; i < results.length; i++) {
      final food = results[i];
      print('$i: ${food.description}');
      print('   Calories: ${food.calories}, Protein: ${food.protein}g, Carbs: ${food.carbs}g, Fat: ${food.fats}g');
      print('   USDA ID: ${food.fdcId}');
      print('');
    }
    
  } catch (e) {
    print('Error: $e');
  }
  
  exit(0);
}
