import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';

import '../../Model/CalorieHistoryModel.dart';

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
}
