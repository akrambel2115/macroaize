import 'package:flutter/material.dart';
import 'package:foodcalorietracker/Model/SqlCalorieModel.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class HomeController extends GetxController{

  int consumedKcal = 0;
  int remainingKcal = 0;
  int consumedProtein = 0;
  int consumedCarbs = 0;
  int consumedFats = 0;

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
    getAllData();
    await getSqlCalorie();
    dates = getPreviousDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToTodayCentered();
    });
    isLoading = false;
    update();
  }

  void scrollToTodayCentered() {
    if (scrollController.hasClients && dates.isNotEmpty) {
      int todayIndex = dates.indexWhere((date) =>
        date.day == today.day &&
        date.month == today.month &&
        date.year == today.year
      );
      if (todayIndex != -1) {
        double itemWidth = 70.0 + 12.0;
        double screenWidth = Get.context?.size?.width ?? 360;
        double visibleWidth = screenWidth - 40;
        double offset = (todayIndex * itemWidth) - (visibleWidth - itemWidth) / 2;
        offset = offset.clamp(0.0, scrollController.position.maxScrollExtent);
        scrollController.jumpTo(offset);
      }
    }
  }
  dateFilter(int index)
  {
    today = dates[index];
    List<SqlCalorieModel> matchingData = sqlCalorie.where((element) => element.date == DateFormat('dd-MM-yyyy').format(today)).toList();
    if(matchingData.isNotEmpty && matchingData.first.date == DateFormat('dd-MM-yyyy').format(today))
    {
      consumedKcal = matchingData.first.calorie;
      consumedProtein = matchingData.first.protein;
      consumedCarbs = matchingData.first.carbs;
      consumedFats = matchingData.first.fats;
      remainingKcal = ConstantUserMaster.calorieGoal - consumedKcal;
      if (remainingKcal < 0) {
        remainingKcal = 0;
      }
    }else{
      consumedKcal = 0;
      consumedProtein = 0;
      consumedCarbs = 0;
      consumedFats = 0;
      remainingKcal = ConstantUserMaster.calorieGoal;
    }
    update();
  }

  getSqlCalorie()
  async {
    sqlCalorie = await dbHelper.getCalorieData();
    if(sqlCalorie.isNotEmpty && sqlCalorie.last.date == DateFormat('dd-MM-yyyy').format(DateTime.now()))
      {
        consumedKcal = sqlCalorie.last.calorie;
        consumedProtein = sqlCalorie.last.protein;
        consumedCarbs = sqlCalorie.last.carbs;
        consumedFats = sqlCalorie.last.fats;
        remainingKcal = ConstantUserMaster.calorieGoal - consumedKcal;
        if (remainingKcal < 0) {
          remainingKcal = 0;
        }
      }else{
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
  getAllData()
  async {
    ConstantUserMaster.calorieGoal = await SharedPref.readInt(SharePrefKey.calorie);
    ConstantUserMaster.proteinGoal = await SharedPref.readInt(SharePrefKey.protein);
    ConstantUserMaster.carbGoal = await SharedPref.readInt(SharePrefKey.carbs);
    ConstantUserMaster.fatsGoal = await SharedPref.readInt(SharePrefKey.fat);
    ConstantUserMaster.gender = await SharedPref.readString(SharePrefKey.gender);
    ConstantUserMaster.workOutDay = await SharedPref.readString(SharePrefKey.workOutDay);
    ConstantUserMaster.height = await SharedPref.readInt(SharePrefKey.height);
    ConstantUserMaster.weight = await SharedPref.readInt(SharePrefKey.weight);
    ConstantUserMaster.goalWeight = await SharedPref.readString(SharePrefKey.goalWeight);
    ConstantUserMaster.desiredGoal = await SharedPref.readInt(SharePrefKey.desiredWeight);
    ConstantUserMaster.bornDay = await SharedPref.readString(SharePrefKey.bornDay);
    ConstantUserMaster.stoppedGoal = await SharedPref.readString(SharePrefKey.stoppingGoal);
    ConstantUserMaster.age = await SharedPref.readInt(SharePrefKey.age);
    update();
  }


}
