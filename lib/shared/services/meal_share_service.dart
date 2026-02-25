import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macroaize/Model/calorie_history_model.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/widgets/meal_share_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class MealShareService {
  const MealShareService._();

  static final ScreenshotController _screenshotController =
      ScreenshotController();

  static Future<void> shareMealSnapshot({
    File? mealImage,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final imageUint8List = await _screenshotController.captureFromWidget(
        MealShareCard(
          mealImage: mealImage,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
        ),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/meal_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageUint8List);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my meal on Macroaize!',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      log('SHARE_MEAL_ERROR => $e');
      NotificationService.showError('Error sharing meal result');
    }
  }

  static Future<void> shareHistoryMeal(
    CalorieHistoryModel meal, {
    Rect? sharePositionOrigin,
  }) async {
    File? mealImage;
    try {
      if (meal.image is String) {
        final path = (meal.image as String).trim();
        if (path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            mealImage = file;
          }
        }
      }
    } catch (_) {
      mealImage = null;
    }

    await shareMealSnapshot(
      mealImage: mealImage,
      calories: meal.calorie,
      protein: meal.protein.toDouble(),
      carbs: meal.carbs.toDouble(),
      fats: meal.fats.toDouble(),
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
