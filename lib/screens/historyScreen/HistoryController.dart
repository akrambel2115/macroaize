import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';

import '../../Model/CalorieHistoryModel.dart';

class HistoryController extends GetxController{
  Map<String,dynamic> argument = Get.arguments;

  List<CalorieHistoryModel> sqlHistory = [];
  String type = "";
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
    update();
  }

}