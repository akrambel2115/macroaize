import 'package:home_widget/home_widget.dart';

class WidgetService {

  static const String _androidSmallProvider = 'SmallWidgetProvider';
  static const String _androidLargeProvider = 'LargeWidgetProvider';

  static const String _iosSmallKind = 'MacroaizeSmallWidget';
  static const String _iosLargeKind = 'MacroaizeLargeWidget';

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
    final int progress =
        goal > 0 ? ((calories / goal) * 100).clamp(0, 100).toInt() : 0;
    await HomeWidget.saveWidgetData<int>('progress', progress);

    await HomeWidget.updateWidget(
      name: _androidSmallProvider,
      iOSName: _iosSmallKind,
    );
    await HomeWidget.updateWidget(
      name: _androidLargeProvider,
      iOSName: _iosLargeKind,
    );
  }
}
