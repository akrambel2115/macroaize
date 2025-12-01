import 'package:flutter/material.dart';
import 'package:foodcalorietracker/Model/SqlCalorieModel.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/shared/services/tutorial_coach_service.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingView.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/shared/services/widget_service.dart';

class HomeController extends GetxController {
  int consumedKcal = 0;
  int remainingKcal = 0;
  int consumedProtein = 0;
  int consumedCarbs = 0;
  int consumedFats = 0;

  final GlobalKey addFoodButtonKey = GlobalKey();

  final int daysAgo = 15;
  List<DateTime> dates = [];
  DateTime today = DateTime.now();
  ScrollController scrollController = ScrollController();
  List<SqlCalorieModel> sqlCalorie = [];
  final dbHelper = DatabaseHelper();
  bool isLoading = true;

  @override
  Future<void> onInit() async {
    super.onInit();
    await getAllData();
    await getSqlCalorie();
    dates = getPreviousDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToTodayCentered();
      scrollToTodayCentered();

      // Check if tutorial is needed
      TutorialCoachService().hasCompletedTutorial().then((hasCompleted) {
        if (!hasCompleted) {
          // Block interaction immediately
          Get.dialog(
            const PopScope(
              canPop: false,
              child: Center(child: SizedBox()), // Transparent blocking overlay
            ),
            barrierDismissible: false,
            barrierColor: Colors.transparent,
          );

          // Wait for the delay
          Future.delayed(const Duration(milliseconds: 800), () {
            // Close the blocking dialog
            if (Get.isDialogOpen == true) {
              Get.back();
            }
            // Show the actual tutorial
            _showAppTipsIfNeeded();
          });
        } else {
          // If already completed, just proceed normally (no blocking)
          Future.delayed(const Duration(milliseconds: 800), () {
            _showAppTipsIfNeeded();
          });
        }
      });
    });
    isLoading = false;
    _updateWidgets();
    update();
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

  dateFilter(int index) {
    today = dates[index];
    List<SqlCalorieModel> matchingData =
        sqlCalorie
            .where(
              (element) =>
                  element.date == DateFormat('dd-MM-yyyy').format(today),
            )
            .toList();
    if (matchingData.isNotEmpty &&
        matchingData.first.date == DateFormat('dd-MM-yyyy').format(today)) {
      consumedKcal = matchingData.first.calorie;
      consumedProtein = matchingData.first.protein;
      consumedCarbs = matchingData.first.carbs;
      consumedFats = matchingData.first.fats;
      remainingKcal = ConstantUserMaster.calorieGoal - consumedKcal;
      if (remainingKcal < 0) {
        remainingKcal = 0;
      }
    } else {
      consumedKcal = 0;
      consumedProtein = 0;
      consumedCarbs = 0;
      consumedFats = 0;
      remainingKcal = ConstantUserMaster.calorieGoal;
    }
    _updateWidgets();
    update();
  }

  getSqlCalorie() async {
    sqlCalorie = await dbHelper.getCalorieData();
    if (sqlCalorie.isNotEmpty &&
        sqlCalorie.last.date ==
            DateFormat('dd-MM-yyyy').format(DateTime.now())) {
      consumedKcal = sqlCalorie.last.calorie;
      consumedProtein = sqlCalorie.last.protein;
      consumedCarbs = sqlCalorie.last.carbs;
      consumedFats = sqlCalorie.last.fats;
      remainingKcal = ConstantUserMaster.calorieGoal - consumedKcal;
      if (remainingKcal < 0) {
        remainingKcal = 0;
      }
    } else {
      remainingKcal = ConstantUserMaster.calorieGoal;
    }
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
    update();
  }
}
