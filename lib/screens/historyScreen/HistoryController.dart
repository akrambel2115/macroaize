import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';

import '../../Model/CalorieHistoryModel.dart';

class HistoryController extends GetxController{
  Map<String,dynamic> argument = Get.arguments;

  List<CalorieHistoryModel> sqlHistory = [];
  String type = "";
  // false -> newest first (descending by id), true -> oldest first (ascending)
  bool sortAsc = false;
  final dbHelper = DatabaseHelper();
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    type = argument['type'];
    getHistory();

  }
  getHistory()
  async {
    sqlHistory =  await dbHelper.getCalorieHistory(type);
    // apply current sort preference
    if (sqlHistory.isNotEmpty) {
      sqlHistory.sort((a, b) => sortAsc
          ? (a.id ?? 0).compareTo(b.id ?? 0)
          : (b.id ?? 0).compareTo(a.id ?? 0));
    }
    update();
  }

  /// Toggle the list sort order and refresh the view.
  void toggleSort() {
    sortAsc = !sortAsc;
    if (sqlHistory.isNotEmpty) {
      sqlHistory.sort((a, b) => sortAsc
          ? (a.id ?? 0).compareTo(b.id ?? 0)
          : (b.id ?? 0).compareTo(a.id ?? 0));
    }
    update();
  }

}