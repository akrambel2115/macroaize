import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/Model/Recipe.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipeDetailScreen.dart';

void main() {
  testWidgets('RecipeDetailScreen shows title and image', (tester) async {
    final recipe = Recipe(
      id: 'test',
      title: 'Test Smoothie',
      imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop',
      duration: 10,
      calories: 300,
      difficulty: 'Easy',
      tags: const [],
      description: 'Test description',
      ingredients: const ['blueberries 200g', 'almond milk 200g'],
      instructions: const ['Blend', 'Serve'],
    );

    await tester.pumpWidget(GetMaterialApp(home: RecipeDetailScreen(recipe: recipe)));

    await tester.pumpAndSettle();

    expect(find.text('Test Smoothie'), findsOneWidget);
    // image should be present as a network image widget
    expect(find.byType(Image), findsWidgets);
  });
}
