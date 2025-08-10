import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';


class PersonalDetailsController extends GetxController{

  int selectedDesiredWeight = 51;
  int selectedView = 0;
  String selectedGender = "";
  bool isMetric = true; // Toggle state
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 165;
  int selectedWeightLb = 119;
  int selectedWeightKg = 54;
  int selectedMonth = 0; // January
  int selectedDay = 1; // 1st
  int selectedYear = 2012; // Default Year
  List<int> days = List.generate(31, (index) => index + 1); // Days 1-31

@override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    selectedDesiredWeight = ConstantUserMaster.desiredGoal;
    selectedWeightKg = ConstantUserMaster.weight;
    selectedWeightLb = (selectedWeightKg * 2.20462).round();
    selectedCm = ConstantUserMaster.height;
    DateTime date = DateFormat("dd-MM-yyyy").parse(ConstantUserMaster.bornDay);
    selectedDay = date.day;
    selectedMonth = date.month;
    selectedYear = date.year;
    selectedGender = ConstantUserMaster.gender;
    update();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<int> years = List.generate(
    50,(index) => 1975 + index,
  ); //

  onChangeDesiredWeight(int value) {
    selectedDesiredWeight = value;
    update();
  }
  onChangeSelectedView(int value)
  {
    selectedView = value;
    update();
  }
  onChangeMetric(bool value) {
    isMetric = value;
    selectedWeightKg = ConstantUserMaster.weight;
    selectedWeightLb = (selectedWeightKg * 2.20462).round();
    update();
  }

  updateWeight()
  {
    if(isMetric)
      {
        ConstantUserMaster.weight = selectedWeightKg;
        SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
        update();
      }else{
      // selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
      selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
      ConstantUserMaster.weight = selectedWeightKg;
      SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
      update();
    }
  }
  updateHeight()
  {
    if(isMetric)
  {
    ConstantUserMaster.height = selectedCm;
    SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
    update();
  }else{
    selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
    ConstantUserMaster.height = selectedCm;
    SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
    update();
  }


  }
  updateBornDay()
  {
    DateTime selectedDate = DateTime(selectedYear, selectedMonth+1, selectedDay);
    String formattedDate = "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    ConstantUserMaster.bornDay = formattedDate;
    SharedPref.saveString(SharePrefKey.bornDay,formattedDate);
    DateTime today = DateTime.now();
    int birthYear = selectedYear;
    int age = today.year - birthYear;
    SharedPref.saveInt(SharePrefKey.age,age);
    ConstantUserMaster.age = age;
    update();
  }
  updateGender()
  {
    ConstantUserMaster.gender = selectedGender;
    SharedPref.saveString(SharePrefKey.gender, ConstantUserMaster.gender);
    update();
  }
  void updateDaysInMonth() {
    int daysInMonth = getDaysInMonth(selectedMonth, selectedYear);

    days = List.generate(daysInMonth, (index) => index + 1);
    update();
    if (selectedDay > daysInMonth) {
      selectedDay =
          daysInMonth; // Adjust if previously selected day is now invalid
    }
  }
  onChangeGender(String value) {
    selectedGender = value;
    update();
  }
  int getDaysInMonth(int month, int year) {
    if (month == 1) {
      // February (check leap year)
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      } else {
        return 28;
      }
    }
    // Months with 30 days: April, June, September, November
    if ([3, 5, 8, 10].contains(month)) {
      return 30;
    }
    return 31; // Default months have 31 days
  }
}