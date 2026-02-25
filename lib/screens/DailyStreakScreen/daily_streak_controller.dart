import 'package:get/get.dart';
import '../../shared/services/streak_service.dart';
import '../../SharePrefHelper/share_pref.dart';
import '../../SharePrefHelper/share_pref_key.dart';

class DailyStreakController extends GetxController {
  Rx<int> currentStreak = 0.obs;
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

    isLoading.value = false;
  }
}
