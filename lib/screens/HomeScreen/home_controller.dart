import 'package:flutter/material.dart';
import 'package:macroaize/Model/sql_calorie_model.dart';
import 'package:macroaize/Model/calorie_history_model.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/shared/services/tutorial_coach_service.dart';
import 'package:macroaize/screens/leadingScreen/leading_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/shared/services/step_tracking_service.dart';
import 'package:macroaize/shared/services/widget_service.dart';
import 'package:macroaize/shared/services/streak_service.dart';
import 'package:macroaize/screens/AdjustGoals/updateDailog/show_update_goal_dialog.dart';
import 'package:macroaize/screens/AdjustGoals/updateDailog/show_water_goal_dialog.dart';
import 'package:macroaize/screens/AnalyticsScreen/update_weight.dart';
import 'package:macroaize/shared/services/weight_update_service.dart';

class HomeController extends GetxController {
  RxInt streakCount = 0.obs;

  int consumedKcal = 0;
  int remainingKcal = 0;
  int consumedProtein = 0;
  int consumedCarbs = 0;
  int consumedFats = 0;
  int caloriesBurned = 0;
  int workoutCaloriesBurned = 0;
  int stepCaloriesBurned = 0;
  int workoutCount = 0;
  int workoutDuration = 0; // minutes

  // pedometer
  int currentSteps = 0;
  bool isStepTrackingAvailable = false;
  Worker? _stepMetricsWorker;

  final StepTrackingService _stepTrackingService =
      Get.find<StepTrackingService>();

  /// Directly exposes the service's reactive step counter for zero-latency UI binding.
  RxInt get liveSteps => _stepTrackingService.dailySteps;

  // carousel page state – the PageController is now owned by _HomeViewState
  // and injected here so it survives controller re-creation.
  PageController trackingPageController = PageController();
  int trackingPageIndex = 0;

  void onTrackingPageChanged(int index) {
    trackingPageIndex = index;
    update();
  }

  // water tracking
  static const int glassVolumeMl = 250;
  int waterGoalMl = 2000;
  int get maxGlasses => waterGoalMl ~/ glassVolumeMl;
  int waterGlasses = 0;
  int displayedWeight = 0;

  final GlobalKey addFoodButtonKey = GlobalKey();
  final GlobalKey trackingCarouselKey = GlobalKey();

  final int daysAgo = 15;
  List<DateTime> dates = [];
  DateTime today = DateTime.now();
  ScrollController scrollController = ScrollController();
  List<SqlCalorieModel> sqlCalorie = [];
  final dbHelper = DatabaseHelper();
  bool isLoading = true;

  CalorieHistoryModel? lastLoggedMeal;

  bool get isSelectedDateToday => _isSameDate(today, DateTime.now());

  @override
  Future<void> onInit() async {
    super.onInit();
    await getAllData();
    await getSqlCalorie();
    await getRecentHistory();
    await loadStepData();
    await loadWaterGoal();
    await _syncStepsFromService();
    _stepMetricsWorker = everAll([
      _stepTrackingService.dailySteps,
      _stepTrackingService.stepCaloriesBurned,
      _stepTrackingService.isTrackingAvailable,
    ], (_) => _onStepMetricsChanged());
    dates = getPreviousDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToTodayCentered();
      scrollToTodayCentered();

      // Check if tutorial is needed
      TutorialCoachService().hasCompletedTutorial().then((hasCompleted) {
        if (!hasCompleted) {
          // Previously this opened a transparent blocking dialog and
          // immediately tried to close it, but the timing was unreliable
          // on iOS – the dialog could stay open and block all interaction.
          // Now we just show the tutorial directly.
          _showAppTipsIfNeeded();
        } else {
          StreakService().checkAndShowNotification();
        }
      });
    });
    isLoading = false;
    _updateWidgets();
    // Sync streak widget with current app data
    StreakService().syncWidget();
    update();
  }

  @override
  void onClose() {
    _stepMetricsWorker?.dispose();
    // NOTE: trackingPageController is NOT disposed here – it is owned by
    // _HomeViewState and disposed there.  Disposing it here caused the
    // gray-box bug because the widget tree still referenced the old
    // disposed controller after Get.delete<HomeController>().
    super.onClose();
  }

  void _updateWidgets() {
    WidgetService.updateWidgetData(
      calories: consumedKcal,
      carbs: consumedCarbs,
      protein: consumedProtein,
      fats: consumedFats,
      goal: ConstantUserMaster.calorieGoal,
    );
  }

  // water tracking helpers
  String _waterKeyForDate(DateTime date) =>
      'water_glasses_${DateFormat('yyyy-MM-dd').format(date)}';

  Future<void> loadWaterData([DateTime? date]) async {
    final targetDate = date ?? today;
    final saved = await SharedPref.readInt(_waterKeyForDate(targetDate));
    waterGlasses = saved ?? 0;
    update();
  }

  Future<void> _saveWaterData([DateTime? date]) async {
    final targetDate = date ?? today;
    await SharedPref.saveInt(_waterKeyForDate(targetDate), waterGlasses);
  }

  void addWaterGlass() {
    if (waterGlasses < maxGlasses) {
      waterGlasses++;
      _saveWaterData();
      update();
    }
  }

  void removeWaterGlass() {
    if (waterGlasses > 0) {
      waterGlasses--;
      _saveWaterData();
      update();
    }
  }

  Future<void> _showAppTipsIfNeeded() async {
    // Ensure we are still on the main dashboard before showing tips
    if (Get.currentRoute != Routes.leadingView && Get.currentRoute != '/') {
      return;
    }
    final context = Get.context;
    if (context != null) {
      // Define interactive tutorial steps with actual UI element targets
      final tutorialSteps = [
        TutorialStep(
          targetKey: addFoodButtonKey,
          titleKey: 'tutorial_add_food_title',
          descriptionKey: 'tutorial_add_food_description',
          position: TooltipPosition.top,
          icon: Icons.add_circle_outline,
        ),
        TutorialStep(
          targetKey: trackingCarouselKey,
          titleKey: 'tutorial_tracking_carousel_title',
          descriptionKey: 'tutorial_tracking_carousel_description',
          position: TooltipPosition.top,
          icon: Icons.swipe_rounded,
          showSpotlight: false,
          onShow: () {
            // Animate the carousel to page 2 so the user sees
            // water, steps & activity tracking.
            if (trackingPageController.hasClients) {
              trackingPageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
        TutorialStep(
          targetKey: LeadingView.scannerTabKey,
          titleKey: 'tutorial_scanner_title',
          descriptionKey: 'tutorial_scanner_description',
          position: TooltipPosition.top,
          icon: Icons.camera_alt_rounded,
        ),
        TutorialStep(
          targetKey: LeadingView.aiCoachButtonKey,
          titleKey: 'tutorial_ai_coach_title',
          descriptionKey: 'tutorial_ai_coach_description',
          position: TooltipPosition.top,
          icon: Icons.psychology_rounded,
        ),
        TutorialStep(
          targetKey: LeadingView.analyticsTabKey,
          titleKey: 'tutorial_analytics_title',
          descriptionKey: 'tutorial_analytics_description',
          position: TooltipPosition.top,
          icon: Icons.analytics_rounded,
        ),
        TutorialStep(
          targetKey: LeadingView.profileTabKey,
          titleKey: 'tutorial_profile_title',
          descriptionKey: 'tutorial_profile_description',
          position: TooltipPosition.top,
          icon: Icons.person_rounded,
        ),
      ];

      await TutorialCoachService().showTutorialIfNeeded(context, tutorialSteps);
    }
  }

  void scrollToTodayCentered() {
    if (scrollController.hasClients && dates.isNotEmpty) {
      int todayIndex = dates.indexWhere(
        (date) =>
            date.day == today.day &&
            date.month == today.month &&
            date.year == today.year,
      );
      if (todayIndex != -1) {
        double itemWidth = 70.0 + 12.0;
        double screenWidth = Get.context?.size?.width ?? 360;
        double visibleWidth = screenWidth - 40;
        double offset =
            (todayIndex * itemWidth) - (visibleWidth - itemWidth) / 2;
        offset = offset.clamp(0.0, scrollController.position.maxScrollExtent);
        scrollController.jumpTo(offset);
      }
    }
  }

  Future<void> loadStepData() async {
    final savedGoal = await SharedPref.readInt(SharePrefKey.stepGoal);
    if (savedGoal != null && savedGoal is int) {
      ConstantUserMaster.stepGoal = savedGoal;
    } else {
      ConstantUserMaster.stepGoal = 10000;
    }
  }

  Future<void> loadWaterGoal() async {
    final saved = await SharedPref.readInt(SharePrefKey.waterGoal);
    ConstantUserMaster.waterGoalMl = (saved != null) ? saved : 2000;    waterGoalMl = ConstantUserMaster.waterGoalMl;  }

  Future<void> _syncStepsFromService() async {
    isStepTrackingAvailable = _stepTrackingService.isTrackingAvailable.value;

    if (_isSameDate(today, DateTime.now())) {
      currentSteps = _stepTrackingService.dailySteps.value;
      stepCaloriesBurned = _stepTrackingService.stepCaloriesBurned.value;
    } else {
      currentSteps = await _stepTrackingService.getDailyStepsForDate(today);
      stepCaloriesBurned = await _stepTrackingService.getStepCaloriesForDate(
        today,
      );
    }

    caloriesBurned = workoutCaloriesBurned + stepCaloriesBurned;
  }

  Future<void> _onStepMetricsChanged() async {
    final isViewingToday = _isSameDate(today, DateTime.now());
    isStepTrackingAvailable = _stepTrackingService.isTrackingAvailable.value;

    if (!isViewingToday) {
      return;
    }

    currentSteps = _stepTrackingService.dailySteps.value;
    stepCaloriesBurned = _stepTrackingService.stepCaloriesBurned.value;
    caloriesBurned = workoutCaloriesBurned + stepCaloriesBurned;

    remainingKcal =
        ConstantUserMaster.calorieGoal - (consumedKcal - caloriesBurned);
    if (remainingKcal < 0) {
      remainingKcal = 0;
    }

    update();
  }

  void editStepGoal() {
    showUpdateGoalDialog(
      ConstantUserMaster.stepGoal,
      (newGoal) async {
        if (newGoal > 0) {
          ConstantUserMaster.stepGoal = newGoal;
          await SharedPref.saveInt(
            SharePrefKey.stepGoal,
            ConstantUserMaster.stepGoal,
          );
          update();
        }
      },
      Get.context!,
      'Update Step Goal'.tr,
    );
  }

  void editWaterGoal(BuildContext context) {
    showWaterGoalDialog(
      ConstantUserMaster.waterGoalMl,
      (newGoalMl) async {
        ConstantUserMaster.waterGoalMl = newGoalMl;
        waterGoalMl = newGoalMl;
        await SharedPref.saveInt(SharePrefKey.waterGoal, newGoalMl);
        if (waterGlasses > maxGlasses) {
          waterGlasses = maxGlasses;
          await _saveWaterData();
        }
        update();
      },
      context,
    );
  }

  void editWeight() {
    if (!isSelectedDateToday) return;
    showUpdateWeightDialog(Get.context!, ConstantUserMaster.weight.toString(), (
      newWeightString,
    ) async {
      int newWeight = int.tryParse(newWeightString) ?? 0;
      if (newWeight > 0) {
        await WeightUpdateService.updateWeightAndOpenOverview(newWeight);
      }
    }, title: 'Update Weight'.tr);
  }

  Future<void> _loadDisplayedWeightForSelectedDate() async {
    final latest = await dbHelper.getLatestWeightOnOrBefore(today);
    displayedWeight = (latest?.round() ?? ConstantUserMaster.weight);
  }

  dateFilter(int index) async {
    today = dates[index];
    List<SqlCalorieModel> matchingData =
        sqlCalorie
            .where(
              (element) =>
                  element.date == DateFormat('dd-MM-yyyy').format(today),
            )
            .toList();

    // Get workout + step calories for this date
    workoutCaloriesBurned = await dbHelper.getTotalCaloriesBurnedForDate(today);
    stepCaloriesBurned = await _stepTrackingService.getStepCaloriesForDate(
      today,
    );
    caloriesBurned = workoutCaloriesBurned + stepCaloriesBurned;
    currentSteps = await _stepTrackingService.getDailyStepsForDate(today);
    await loadWaterData(today);
    await _loadDisplayedWeightForSelectedDate();
    workoutCount = await dbHelper.getWorkoutCountForDate(today);
    workoutDuration = await dbHelper.getTotalWorkoutDurationForDate(today);

    if (matchingData.isNotEmpty &&
        matchingData.first.date == DateFormat('dd-MM-yyyy').format(today)) {
      consumedKcal = matchingData.first.calorie;
      consumedProtein = matchingData.first.protein;
      consumedCarbs = matchingData.first.carbs;
      consumedFats = matchingData.first.fats;
      // Subtract calories burned from consumed calories
      remainingKcal =
          ConstantUserMaster.calorieGoal - (consumedKcal - caloriesBurned);
      if (remainingKcal < 0) {
        remainingKcal = 0;
      }
    } else {
      consumedKcal = 0;
      consumedProtein = 0;
      consumedCarbs = 0;
      consumedFats = 0;
      remainingKcal = ConstantUserMaster.calorieGoal + caloriesBurned;
    }
    _updateWidgets();
    update();
  }

  getSqlCalorie() async {
    sqlCalorie = await dbHelper.getCalorieData();

    // Get workout + step calories for selected day
    workoutCaloriesBurned = await dbHelper.getTotalCaloriesBurnedForDate(today);
    stepCaloriesBurned = await _stepTrackingService.getStepCaloriesForDate(
      today,
    );
    caloriesBurned = workoutCaloriesBurned + stepCaloriesBurned;
    currentSteps = await _stepTrackingService.getDailyStepsForDate(today);
    await loadWaterData(today);
    await _loadDisplayedWeightForSelectedDate();
    workoutCount = await dbHelper.getWorkoutCountForDate(today);
    workoutDuration = await dbHelper.getTotalWorkoutDurationForDate(today);

    if (sqlCalorie.isNotEmpty &&
        sqlCalorie.any(
          (e) => e.date == DateFormat('dd-MM-yyyy').format(today),
        )) {
      final selected =
          sqlCalorie
              .where((e) => e.date == DateFormat('dd-MM-yyyy').format(today))
              .toList()
            ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      consumedKcal = selected.last.calorie;
      consumedProtein = selected.last.protein;
      consumedCarbs = selected.last.carbs;
      consumedFats = selected.last.fats;
      // Subtract calories burned from consumed calories
      remainingKcal =
          ConstantUserMaster.calorieGoal - (consumedKcal - caloriesBurned);
      if (remainingKcal < 0) {
        remainingKcal = 0;
      }
    } else {
      consumedKcal = 0;
      consumedProtein = 0;
      consumedCarbs = 0;
      consumedFats = 0;
      remainingKcal = ConstantUserMaster.calorieGoal + caloriesBurned;
    }
    _updateWidgets();
  }

  getRecentHistory() async {
    List<CalorieHistoryModel> sqlHistory = await dbHelper.getCalorieHistory(
      "All",
    );
    if (sqlHistory.isNotEmpty) {
      sqlHistory.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      lastLoggedMeal = sqlHistory.first;
    } else {
      lastLoggedMeal = null;
    }
    update();
  }

  List<DateTime> getPreviousDays() {
    return List.generate(daysAgo, (index) {
      return today.subtract(Duration(days: daysAgo - index - 1));
    });
  }

  void scrollToEnd() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  getAllData() async {
    ConstantUserMaster.calorieGoal = await SharedPref.readInt(
      SharePrefKey.calorie,
    );
    ConstantUserMaster.proteinGoal = await SharedPref.readInt(
      SharePrefKey.protein,
    );
    ConstantUserMaster.carbGoal = await SharedPref.readInt(SharePrefKey.carbs);
    ConstantUserMaster.fatsGoal = await SharedPref.readInt(SharePrefKey.fat);
    ConstantUserMaster.gender = await SharedPref.readString(
      SharePrefKey.gender,
    );
    ConstantUserMaster.workOutDay = await SharedPref.readString(
      SharePrefKey.workOutDay,
    );
    ConstantUserMaster.height = await SharedPref.readInt(SharePrefKey.height);
    ConstantUserMaster.weight = await SharedPref.readInt(SharePrefKey.weight);
    ConstantUserMaster.goalWeight = await SharedPref.readString(
      SharePrefKey.goalWeight,
    );
    ConstantUserMaster.desiredGoal = await SharedPref.readInt(
      SharePrefKey.desiredWeight,
    );
    ConstantUserMaster.bornDay = await SharedPref.readString(
      SharePrefKey.bornDay,
    );
    ConstantUserMaster.stoppedGoal = await SharedPref.readString(
      SharePrefKey.stoppingGoal,
    );
    ConstantUserMaster.age = await SharedPref.readInt(SharePrefKey.age);
    displayedWeight = ConstantUserMaster.weight;

    // Update streak
    streakCount.value = await StreakService().getCurrentStreak();

    update();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
