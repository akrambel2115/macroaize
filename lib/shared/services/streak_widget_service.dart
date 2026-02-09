import 'package:home_widget/home_widget.dart';

class StreakWidgetService {
  static const String androidWidgetProvider = 'StreakWidgetProvider';
  static const String iosWidgetName = 'StreakWidget';

  static const String keyStreakCount = 'streak_count';
  static const String keyDisciplineScore = 'discipline_score';
  static const String keyIsActiveToday = 'is_active_today';

  static Future<void> updateWidget({
    required int streakCount,
    required double disciplineScore,
    required bool isActiveToday,
  }) async {
    // persist state
    await HomeWidget.saveWidgetData(keyStreakCount, streakCount);
    await HomeWidget.saveWidgetData(keyDisciplineScore, disciplineScore);
    await HomeWidget.saveWidgetData(keyIsActiveToday, isActiveToday);

    // update android platform
    await HomeWidget.updateWidget(
      name: androidWidgetProvider,
      androidName: androidWidgetProvider,
    );

    // update ios platform
    await HomeWidget.updateWidget(name: iosWidgetName, iOSName: iosWidgetName);
  }
}