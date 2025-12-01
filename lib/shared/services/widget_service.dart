import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String androidWidgetProvider = 'HomeWidgetProvider';
  static const String iOSWidgetName = 'foodcalorietrackerWidget';

  static Future<void> updateWidgetData({
    required int calories,
    required int carbs,
    required int protein,
    required int fats,
    required int goal,
  }) async {
    await HomeWidget.saveWidgetData<int>('calories', calories);
    await HomeWidget.saveWidgetData<int>('carbs', carbs);
    await HomeWidget.saveWidgetData<int>('protein', protein);
    await HomeWidget.saveWidgetData<int>('fats', fats);
    await HomeWidget.saveWidgetData<int>('goal', goal);

    // calculate progress for circular indicator (0-100)
    int progress =
        goal > 0 ? ((calories / goal) * 100).clamp(0, 100).toInt() : 0;
    await HomeWidget.saveWidgetData<int>('progress', progress);

    await HomeWidget.updateWidget(
      name: 'SmallWidgetProvider',
      iOSName: 'SmallWidget',
    );
    await HomeWidget.updateWidget(
      name: 'LargeWidgetProvider',
      iOSName: 'LargeWidget',
    );
  }
}
