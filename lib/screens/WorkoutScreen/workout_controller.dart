import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/Model/parsed_workout.dart';

class WorkoutController extends GetxController {
  final dbHelper = DatabaseHelper();
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final _usageService = Get.find<UsageService>();

  final RxBool isSaving = false.obs;
  final RxString saveError = ''.obs;

  final descriptionController = TextEditingController();
  final RxInt descriptionLength = 0.obs;

  final RxBool isAIProcessing = false.obs;
  final Rx<ParsedWorkout?> parsedWorkout = Rx<ParsedWorkout?>(null);
  final RxString aiError = ''.obs;

  final RxBool _isPremium = false.obs;
  bool get isPremium => _isPremium.value;

  @override
  void onInit() {
    super.onInit();

    _isPremium.value = _usageService.isPremium;
    _usageService.usageStream.listen((_) {
      _isPremium.value = _usageService.isPremium;
    });

    descriptionController.addListener(() {
      descriptionLength.value = descriptionController.text.length;
    });
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> parseWorkoutWithAI() async {
    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      aiError.value = 'please_enter_description'.tr;
      return;
    }

    if (description.length < 5) {
      aiError.value = 'description_too_short'.tr;
      return;
    }

    if (!isPremium) {
      aiError.value = 'premium_feature_workout_ai'.tr;
      NotificationService.showError('premium_feature_workout_ai');
      return;
    }

    isAIProcessing.value = true;
    aiError.value = '';
    parsedWorkout.value = null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        aiError.value = 'auth_required'.tr;
        return;
      }

      await user.getIdToken(true);

      final locale = Get.locale?.languageCode ?? 'en';
      final callable = _functions.httpsCallable('logWorkoutWithAI');
      final result = await callable.call({
        'description': description,
        'locale': locale,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] == true && data['workout'] != null) {
        parsedWorkout.value = ParsedWorkout.fromJson(
          Map<String, dynamic>.from(data['workout'] as Map),
        );
      } else {
        aiError.value = 'failed_to_parse_workout'.tr;
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        aiError.value = 'premium_feature_workout_ai'.tr;
      } else {
        aiError.value = e.message ?? 'failed_to_parse_workout'.tr;
      }
    } catch (_) {
      aiError.value = 'failed_to_parse_workout'.tr;
    } finally {
      isAIProcessing.value = false;
    }
  }

  void clearParsedWorkout() {
    parsedWorkout.value = null;
    aiError.value = '';
    if (saveError.value.isNotEmpty) saveError.value = '';
  }

  Future<void> _saveAIWorkoutInternal() async {
    final workout = parsedWorkout.value;
    if (workout == null) {
      return;
    }

    final now = DateTime.now();

    for (final exercise in workout.exercises) {
      try {
        await dbHelper.insertWorkoutEntry(
          date: now,
          duration: exercise.duration ?? _estimateDuration(exercise),
          type: exercise.type,
          caloriesBurned: exercise.caloriesBurned,
          description: _buildExerciseDescription(exercise),
        );
      } catch (e) {
        rethrow;
      }
    }

    await _refreshAnalytics();
  }

  Future<void> saveAIWorkout() async {
    try {
      if (isSaving.value) return;
      isSaving.value = true;

      await _saveAIWorkoutInternal();

      NotificationService.showSuccess('workout_saved');
      Get.back();
    } catch (_) {
      NotificationService.showError('failed_to_save_workout');
    } finally {
      isSaving.value = false;
    }
  }

  int _estimateDuration(ParsedExercise exercise) {
    if (exercise.sets != null) {
      return exercise.sets! * 3; // minutes per set
    }
    if (exercise.reps != null) {
      return (exercise.reps! / 10).ceil(); // minutes per reps
    }
    return 5; // fallback duration
  }

  String _buildExerciseDescription(ParsedExercise exercise) {
    final parts = <String>[exercise.name];

    if (exercise.muscleGroup != null) {
      parts.add('Muscle: ${exercise.muscleGroup}');
    }
    if (exercise.sets != null) {
      parts.add('Sets: ${exercise.sets}');
    }
    if (exercise.reps != null) {
      parts.add('Reps: ${exercise.reps}');
    }
    if (exercise.weight != null) {
      parts.add('Weight: ${exercise.weight}${exercise.weightUnit ?? 'kg'}');
    }
    if (exercise.distance != null) {
      parts.add('Distance: ${exercise.distance}km');
    }

    return parts.join(', ');
  }

  Future<void> _refreshAnalytics() async {
    try {
      final analyticsController = Get.find<AnalyticsController>();
      await analyticsController.loadWorkoutHistory();
    } catch (_) {
      // controller missing
    }
  }

  Future<bool> _showCaloriesConfirmationDialog(int caloriesBurned) async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Get.theme.cardColor,
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Text(
              'confirm_workout'.tr,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'calories_burned_label'.tr,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutralGrey600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/calorie.png',
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$caloriesBurned',
                            style: Get.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'cal',
                            style: Get.textTheme.titleLarge?.copyWith(
                              color: AppColor.neutralGrey500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.trending_up, color: AppColor.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '+$caloriesBurned cal added to your daily allowance',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppColor.success,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'cancel'.tr,
                  style: Get.textTheme.bodyLarge?.copyWith(
                    color: AppColor.neutralGrey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'confirm_save'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  Future<void> saveWorkout() async {
    if (isSaving.value) {
      return;
    }
    isSaving.value = true;
    saveError.value = '';

    try {
      final workout = parsedWorkout.value;
      if (workout == null) {
        saveError.value = 'please_analyze_or_select_type'.tr;
        NotificationService.showError('please_analyze_or_select_type');
        return;
      }

      final totalCalories = workout.totalCaloriesBurned;

      final confirmed = await _showCaloriesConfirmationDialog(totalCalories);
      if (!confirmed) {
        return;
      }

      await _saveAIWorkoutInternal();
      NotificationService.showSuccess('workout_saved');
      await Future.delayed(const Duration(milliseconds: 100));
      Get.back();
    } catch (_) {
      NotificationService.showError('failed_to_save_workout');
      saveError.value = 'failed_to_save_workout'.tr;
    } finally {
      isSaving.value = false;
    }
  }
}
