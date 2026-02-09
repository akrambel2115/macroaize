import 'package:get/get.dart';
import '../../shared/services/streak_service.dart';
import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

class DailyStreakController extends GetxController {
  Rx<int> currentStreak = 0.obs;
  Rx<double> disciplineScore = 0.0.obs;
  RxList<String> historyDates = <String>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;

    currentStreak.value = await StreakService().getCurrentStreak();

    List<String> history = await SharedPref.readList(
      SharePrefKey.streakHistory,
    );
    historyDates.assignAll(history);

    calculateDiscipline(history);

    isLoading.value = false;
  }

  void calculateDiscipline(List<String> history) {
    if (history.isEmpty) {
      disciplineScore.value = 0.0;
      return;
    }

    DateTime now = DateTime.now();
    DateTime earliest = now;

    if (history.isNotEmpty) {
      // chronological order
      List<DateTime> dates =
          history.map((e) => DateTime.parse(e)).toList()..sort();
      earliest = dates.first;
    }

    // day difference calculation
    int totalDays = now.difference(earliest).inDays + 1;
    if (totalDays < 1) totalDays = 1;

    // unique active days
    int activeDays = history.toSet().length;

    double score = (activeDays / totalDays) * 100;
    if (score > 100) score = 100;

    disciplineScore.value = score;
  }
}
