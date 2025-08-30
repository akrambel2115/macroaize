import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/Model/Recipe.dart';
import 'package:foodcalorietracker/widgets/RecipeCard.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipeDetailScreen.dart';

void main() {
  testWidgets('Tapping recipe card opens detail screen', (tester) async {
    final recipe = Recipe(
      id: 'r1',
      title: 'Tap Smoothie',
      imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop',
      duration: 5,
      calories: 200,
      difficulty: 'Easy',
      tags: const [],
      description: '',
      ingredients: const [],
      instructions: const [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: RecipeCard(
                recipe: recipe,
                onTap: () => Get.to(() => RecipeDetailScreen(recipe: recipe)),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tap Smoothie'), findsOneWidget);

    await tester.tap(find.text('Tap Smoothie'));
    await tester.pumpAndSettle();

    expect(find.text('Tap Smoothie'), findsWidgets); // title still present on detail
    expect(find.byType(RecipeDetailScreen), findsOneWidget);
  });
}
