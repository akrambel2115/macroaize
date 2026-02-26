import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:macroaize/Model/parsed_workout.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/WorkoutScreen/workout_controller.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:macroaize/routes/app_routes.dart';

class WorkoutView extends GetView<WorkoutController> {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color:
                    context.theme.brightness == Brightness.dark
                        ? Colors.white
                        : AppColor.neutralGrey700,
              ),
              onPressed: () async {
                final popped = await Navigator.of(context).maybePop();
                if (!popped && context.mounted) {
                  Get.offAllNamed(Routes.leadingView);
                }
              },
            ),
          ),
          title: Text(
            'log_workout'.tr,
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  context.theme.brightness == Brightness.dark
                      ? AppColor.darkText
                      : AppColor.neutralGrey900,
            ),
          ),
          actions: [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'describe_workout_ai'.tr),
              const SizedBox(height: 10),
              ModernFadeSlideTransition(child: _buildAICard(context)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.isSaving.value ||
                                controller.parsedWorkout.value == null
                            ? null
                            : () => controller.saveWorkout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        controller.isSaving.value
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              'save_workout'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ),
              Obx(() {
                final msg = controller.saveError.value;
                if (msg.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAICard(BuildContext context) {
    return Obx(() {
      final isProcessing = controller.isAIProcessing.value;
      final parsedWorkout = controller.parsedWorkout.value;
      final aiError = controller.aiError.value;

      if (parsedWorkout != null) {
        return _buildParsedWorkoutPreview(context, parsedWorkout);
      }

      return Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!controller.isPremium)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed(Routes.premiumView),
                  child: Text(
                    'upgrade'.tr,
                    style: TextStyle(
                      color: AppColor.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            TextField(
              controller: controller.descriptionController,
              maxLines: 5,
              maxLength: 500,
              enabled: !isProcessing,
              style: context.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'describe_workout_hint'.tr,
                hintStyle: context.textTheme.bodySmall?.copyWith(
                  color: AppColor.neutralGrey500,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${controller.descriptionLength.value}/500',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColor.neutralGrey500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ModernButton(
              text: isProcessing ? 'analyzing'.tr : 'analyze_with_ai'.tr,
              onPressed: controller.parseWorkoutWithAI,
              loading: isProcessing,
              width: double.infinity,
              height: 52,
              size: ModernButtonSize.medium,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              style: ModernButtonStyle.primary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (aiError.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                aiError,
                style: TextStyle(color: Colors.red.shade400, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildParsedWorkoutPreview(
    BuildContext context,
    ParsedWorkout workout,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColor.primaryOrange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColor.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'analyze_with_ai'.tr,
                      style: TextStyle(
                        color: AppColor.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.clearParsedWorkout,
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.neutralGrey600,
                ),
                child: Text('edit'.tr),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            workout.summary,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatChip(
                context,
                Icons.timer,
                '${workout.totalDuration} min',
              ),
              _buildStatChip(
                context,
                Icons.local_fire_department,
                '${workout.totalCaloriesBurned} cal',
              ),
              _buildStatChip(
                context,
                Icons.fitness_center,
                '${workout.exercises.length} exercises',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...workout.exercises.map<Widget>(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getExerciseTypeColor(
                        context,
                        exercise.type,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getExerciseTypeIcon(exercise.type),
                        size: 16,
                        color: _getExerciseTypeColor(context, exercise.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (exercise.formattedDescription.isNotEmpty)
                          Text(
                            exercise.formattedDescription,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColor.neutralGrey500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (exercise.caloriesBurned > 0)
                    Text(
                      '${exercise.caloriesBurned} cal',
                      style: TextStyle(
                        color: AppColor.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.primaryOrange),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColor.primaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getExerciseTypeColor(BuildContext context, String type) {
    switch (type) {
      case 'bodybuilding':
        return context.theme.colorScheme.primary;
      case 'cardio':
        return context.theme.colorScheme.error;
      case 'calisthenics':
        return context.theme.colorScheme.secondary;
      default:
        return AppColor.primaryOrange;
    }
  }

  IconData _getExerciseTypeIcon(String type) {
    switch (type) {
      case 'cardio':
        return Icons.directions_run;
      case 'bodybuilding':
        return Icons.fitness_center;
      case 'calisthenics':
        return Icons.accessibility_new;
      default:
        return Icons.sports;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColor.primaryOrange,
        fontSize: 14,
      ),
    );
  }
}
