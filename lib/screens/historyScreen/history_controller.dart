import 'package:macroaize/constant/database_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Model/calorie_history_model.dart';
import '../../Model/sql_calorie_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/services/notification_service.dart';
import '../HomeScreen/home_controller.dart';
import '../leadingScreen/leading_controller.dart';

class HistoryController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;

  List<CalorieHistoryModel> sqlHistory = [];
  String type = "";
  bool sortAsc = false;
  final dbHelper = DatabaseHelper();
  @override
  void onInit() {
    super.onInit();
    type = argument['type'];
    getHistory();
  }

  getHistory() async {
    sqlHistory = await dbHelper.getCalorieHistory(type);
    if (sqlHistory.isNotEmpty) {
      sqlHistory.sort(
        (a, b) =>
            sortAsc
                ? (a.id ?? 0).compareTo(b.id ?? 0)
                : (b.id ?? 0).compareTo(a.id ?? 0),
      );
    }
    update();
  }

  void toggleSort() {
    sortAsc = !sortAsc;
    if (sqlHistory.isNotEmpty) {
      sqlHistory.sort(
        (a, b) =>
            sortAsc
                ? (a.id ?? 0).compareTo(b.id ?? 0)
                : (b.id ?? 0).compareTo(a.id ?? 0),
      );
    }
    update();
  }

  /// Deletes a meal from history and subtracts its nutrition values from
  /// today's daily totals so the home-page stats reflect the change.
  Future<void> deleteMealAndUpdateStats(CalorieHistoryModel meal) async {
    if (meal.id == null) return;

    final todayStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final isTodaysMeal = meal.date == todayStr;

    // 1. Subtract nutrition from today's daily aggregated record.
    if (isTodaysMeal) {
      final List<SqlCalorieModel> calorieData =
          await dbHelper.getCalorieData();
      final todayRecord = calorieData
          .where((e) => e.date == todayStr)
          .toList()
        ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

      if (todayRecord.isNotEmpty) {
        final latest = todayRecord.last;
        await dbHelper.updateCalorie(
          SqlCalorieModel(
            id: latest.id,
            date: latest.date,
            totalGoal: latest.totalGoal,
            calorie: (latest.calorie - meal.calorie).clamp(0, latest.calorie),
            protein: (latest.protein - meal.protein).clamp(0, latest.protein),
            carbs: (latest.carbs - meal.carbs).clamp(0, latest.carbs),
            fats: (latest.fats - meal.fats).clamp(0, latest.fats),
          ),
        );
      }
    }

    // 2. Remove the history entry.
    await dbHelper.deleteCalorieHistory(meal.id!);

    // 3. Refresh home-page stats and navigate there.
    _refreshHomeAndNavigate();

    NotificationService.showSuccess('delete_meal_success');
  }

  /// Switches to the home tab and refreshes the HomeController data.
  Future<void> _refreshHomeAndNavigate() async {
    // Pop back to the leading (home) view first so the user sees the
    // home page immediately.
    Get.until((route) => route.settings.name == Routes.leadingView);

    try {
      if (Get.isRegistered<LeadingController>()) {
        final lc = Get.find<LeadingController>();
        lc.currentIndex = 0;
        lc.update();
      }
      if (Get.isRegistered<HomeController>()) {
        final hc = Get.find<HomeController>();
        await hc.getSqlCalorie();
        await hc.getRecentHistory();
        hc.update();
      }
    } catch (_) {}
  }
}
