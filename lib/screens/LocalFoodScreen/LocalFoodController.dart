import 'package:flutter/material.dart';
import 'dart:async';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Model/CalorieHistoryModel.dart';
import '../../Model/SqlCalorieModel.dart';
import '../../Model/SqlDailyCalorieModel.dart';
import '../../SharePrefHelper/ConstantUserMaster.dart';
import '../../constant/FontFamily.dart';
import '../../routes/app_routes.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/PremiumRequiredDialog.dart';

class LocalFoodController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  TextEditingController textController = TextEditingController();
  List<FoodItem> filteredItems = [];
  Timer? _searchDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  bool isFiltering = false;
  final dbHelper = DatabaseHelper();
  final _appUserService = AppUserService();
  List<FoodItem> breakfastFoods = [
    FoodItem(
      name: 'Boiled Egg'.tr,
      calories: 78,
      carbs: 1,
      protein: 6,
      fats: 5,
      quantity: '1 egg'.tr,
    ),
    FoodItem(
      name: 'Oatmeal'.tr,
      calories: 150,
      carbs: 27,
      protein: 5,
      fats: 3,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Banana'.tr,
      calories: 105,
      carbs: 27,
      protein: 1,
      fats: 0,
      quantity: '1 medium'.tr,
    ),
    FoodItem(
      name: 'Paratha'.tr,
      calories: 250,
      carbs: 35,
      protein: 5,
      fats: 12,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Idli'.tr,
      calories: 58,
      carbs: 12,
      protein: 2,
      fats: 0,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Dosa'.tr,
      calories: 133,
      carbs: 22,
      protein: 3,
      fats: 4,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Upma'.tr,
      calories: 180,
      carbs: 30,
      protein: 4,
      fats: 5,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Poha'.tr,
      calories: 180,
      carbs: 30,
      protein: 3,
      fats: 5,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Bread Butter'.tr,
      calories: 150,
      carbs: 20,
      protein: 3,
      fats: 7,
      quantity: '2 slices'.tr,
    ),
    FoodItem(
      name: 'Cornflakes with Milk'.tr,
      calories: 200,
      carbs: 35,
      protein: 6,
      fats: 4,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chilla (Besan)'.tr,
      calories: 120,
      carbs: 10,
      protein: 7,
      fats: 5,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Sprouts Salad'.tr,
      calories: 100,
      carbs: 15,
      protein: 7,
      fats: 2,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Pancakes'.tr,
      calories: 175,
      carbs: 25,
      protein: 4,
      fats: 6,
      quantity: '2 small pieces'.tr,
    ),
    FoodItem(
      name: 'Apple'.tr,
      calories: 95,
      carbs: 25,
      protein: 0,
      fats: 0,
      quantity: '1 medium'.tr,
    ),
    FoodItem(
      name: 'Milk'.tr,
      calories: 122,
      carbs: 12,
      protein: 8,
      fats: 5,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Almonds'.tr,
      calories: 100,
      carbs: 4,
      protein: 4,
      fats: 9,
      quantity: '10 pieces'.tr,
    ),
    FoodItem(
      name: 'Smoothie (Fruit)'.tr,
      calories: 180,
      carbs: 30,
      protein: 4,
      fats: 4,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Yogurt (Plain)'.tr,
      calories: 100,
      carbs: 5,
      protein: 8,
      fats: 5,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Khichdi'.tr,
      calories: 220,
      carbs: 35,
      protein: 6,
      fats: 5,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Thepla'.tr,
      calories: 120,
      carbs: 15,
      protein: 3,
      fats: 6,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Cheela (Moong dal)'.tr,
      calories: 110,
      carbs: 10,
      protein: 6,
      fats: 3,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Pav Bhaji'.tr,
      calories: 300,
      carbs: 40,
      protein: 6,
      fats: 12,
      quantity: '2 pavs + bhaji'.tr,
    ),
    FoodItem(
      name: 'Sabudana Khichdi'.tr,
      calories: 250,
      carbs: 45,
      protein: 2,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Roti with Sabzi'.tr,
      calories: 220,
      carbs: 30,
      protein: 4,
      fats: 8,
      quantity: '1 roti + sabzi'.tr,
    ),
    FoodItem(
      name: 'Peanut Butter Bread'.tr,
      calories: 200,
      carbs: 20,
      protein: 5,
      fats: 10,
      quantity: '2 slices'.tr,
    ),
    FoodItem(
      name: 'Fruit Bowl'.tr,
      calories: 120,
      carbs: 28,
      protein: 1,
      fats: 0,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Vegetable Sandwich'.tr,
      calories: 180,
      carbs: 25,
      protein: 5,
      fats: 6,
      quantity: '1 sandwich'.tr,
    ),
    FoodItem(
      name: 'Rice Idli with Sambar'.tr,
      calories: 200,
      carbs: 30,
      protein: 6,
      fats: 3,
      quantity: '2 idlis + sambar'.tr,
    ),
    FoodItem(
      name: 'Boiled Corn'.tr,
      calories: 100,
      carbs: 22,
      protein: 3,
      fats: 1,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Paneer Bhurji'.tr,
      calories: 250,
      carbs: 5,
      protein: 15,
      fats: 20,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Protein Shake'.tr,
      calories: 180,
      carbs: 5,
      protein: 25,
      fats: 3,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Muesli with Milk'.tr,
      calories: 220,
      carbs: 30,
      protein: 7,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chapati with Curd'.tr,
      calories: 210,
      carbs: 25,
      protein: 5,
      fats: 7,
      quantity: '1 chapati + ½ cup curd'.tr,
    ),
    FoodItem(
      name: 'Porridge (Daliya)'.tr,
      calories: 190,
      carbs: 35,
      protein: 5,
      fats: 3,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Rava Upma'.tr,
      calories: 180,
      carbs: 28,
      protein: 4,
      fats: 5,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chickpea Salad'.tr,
      calories: 160,
      carbs: 20,
      protein: 8,
      fats: 5,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Boiled Sweet Potato'.tr,
      calories: 115,
      carbs: 26,
      protein: 2,
      fats: 0,
      quantity: '1 medium'.tr,
    ),
    FoodItem(
      name: 'Coconut Water'.tr,
      calories: 46,
      carbs: 9,
      protein: 1,
      fats: 0,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Masala Omelette'.tr,
      calories: 190,
      carbs: 2,
      protein: 10,
      fats: 15,
      quantity: '1 egg'.tr,
    ),
    FoodItem(
      name: 'Vegetable Poha'.tr,
      calories: 200,
      carbs: 30,
      protein: 4,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
  ];

  List<FoodItem> lunchFoods = [
    FoodItem(
      name: 'Roti with Sabzi'.tr,
      calories: 220,
      carbs: 30,
      protein: 4,
      fats: 8,
      quantity: '2 rotis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Rice with Dal'.tr,
      calories: 300,
      carbs: 40,
      protein: 10,
      fats: 6,
      quantity: '1 cup rice + 1 cup dal'.tr,
    ),
    FoodItem(
      name: 'Grilled Chicken'.tr,
      calories: 250,
      carbs: 0,
      protein: 30,
      fats: 12,
      quantity: '1 breast'.tr,
    ),
    FoodItem(
      name: 'Paneer Curry'.tr,
      calories: 280,
      carbs: 10,
      protein: 14,
      fats: 20,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Mixed Vegetable Curry'.tr,
      calories: 180,
      carbs: 20,
      protein: 4,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chapati with Daal'.tr,
      calories: 250,
      carbs: 35,
      protein: 8,
      fats: 7,
      quantity: '2 chapatis + dal'.tr,
    ),
    FoodItem(
      name: 'Fish Curry with Rice'.tr,
      calories: 320,
      carbs: 35,
      protein: 20,
      fats: 10,
      quantity: '1 bowl curry + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Rajma Chawal'.tr,
      calories: 350,
      carbs: 50,
      protein: 12,
      fats: 7,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chole Bhature'.tr,
      calories: 450,
      carbs: 50,
      protein: 10,
      fats: 25,
      quantity: '1 bhatura + chole'.tr,
    ),
    FoodItem(
      name: 'Kadhi with Rice'.tr,
      calories: 300,
      carbs: 40,
      protein: 8,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Palak Paneer'.tr,
      calories: 280,
      carbs: 10,
      protein: 15,
      fats: 18,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Stuffed Paratha'.tr,
      calories: 300,
      carbs: 35,
      protein: 6,
      fats: 14,
      quantity: '1 paratha'.tr,
    ),
    FoodItem(
      name: 'Veg Pulao'.tr,
      calories: 320,
      carbs: 45,
      protein: 6,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Biryani with Raita'.tr,
      calories: 450,
      carbs: 55,
      protein: 15,
      fats: 20,
      quantity: '1 plate'.tr,
    ),
    FoodItem(
      name: 'Tofu Stir Fry'.tr,
      calories: 250,
      carbs: 15,
      protein: 18,
      fats: 12,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chicken Tikka'.tr,
      calories: 320,
      carbs: 6,
      protein: 28,
      fats: 18,
      quantity: '1 plate'.tr,
    ),
    FoodItem(
      name: 'Veg Fried Rice'.tr,
      calories: 330,
      carbs: 48,
      protein: 6,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Aloo Gobi with Roti'.tr,
      calories: 280,
      carbs: 30,
      protein: 5,
      fats: 10,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Baingan Bharta'.tr,
      calories: 200,
      carbs: 18,
      protein: 3,
      fats: 12,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Sambar with Rice'.tr,
      calories: 280,
      carbs: 40,
      protein: 8,
      fats: 6,
      quantity: '1 cup + 1 bowl'.tr,
    ),
    FoodItem(
      name: 'Chicken Curry with Roti'.tr,
      calories: 350,
      carbs: 25,
      protein: 20,
      fats: 18,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Bhindi Masala with Roti'.tr,
      calories: 230,
      carbs: 20,
      protein: 4,
      fats: 12,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Egg Curry with Rice'.tr,
      calories: 320,
      carbs: 35,
      protein: 14,
      fats: 15,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Pav Bhaji'.tr,
      calories: 400,
      carbs: 45,
      protein: 7,
      fats: 20,
      quantity: '2 pavs + bhaji'.tr,
    ),
    FoodItem(
      name: 'Lentil Soup with Bread'.tr,
      calories: 280,
      carbs: 35,
      protein: 10,
      fats: 6,
      quantity: '1 bowl + 1 bread slice'.tr,
    ),
    FoodItem(
      name: 'Methi Thepla with Curd'.tr,
      calories: 260,
      carbs: 30,
      protein: 6,
      fats: 10,
      quantity: '2 theplas + ½ cup curd'.tr,
    ),
    FoodItem(
      name: 'Chickpea Salad'.tr,
      calories: 220,
      carbs: 25,
      protein: 10,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Soybean Curry with Rice'.tr,
      calories: 300,
      carbs: 30,
      protein: 15,
      fats: 10,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Cabbage Sabzi with Chapati'.tr,
      calories: 200,
      carbs: 25,
      protein: 4,
      fats: 8,
      quantity: '1 bowl + 2 chapatis'.tr,
    ),
    FoodItem(
      name: 'Dal Makhani with Naan'.tr,
      calories: 400,
      carbs: 45,
      protein: 12,
      fats: 18,
      quantity: '1 bowl + 1 naan'.tr,
    ),
    FoodItem(
      name: 'Vegetable Korma with Roti'.tr,
      calories: 300,
      carbs: 35,
      protein: 5,
      fats: 15,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Tandoori Roti with Paneer'.tr,
      calories: 320,
      carbs: 30,
      protein: 12,
      fats: 14,
      quantity: '2 rotis + paneer'.tr,
    ),
    FoodItem(
      name: 'Mixed Dal with Rice'.tr,
      calories: 280,
      carbs: 40,
      protein: 10,
      fats: 6,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Bottle Gourd Curry with Roti'.tr,
      calories: 210,
      carbs: 20,
      protein: 4,
      fats: 8,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Kofta Curry with Roti'.tr,
      calories: 340,
      carbs: 28,
      protein: 10,
      fats: 18,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Paneer Bhurji with Bread'.tr,
      calories: 300,
      carbs: 28,
      protein: 15,
      fats: 14,
      quantity: '1 bowl + 2 slices'.tr,
    ),
    FoodItem(
      name: 'Chana Masala with Rice'.tr,
      calories: 330,
      carbs: 45,
      protein: 12,
      fats: 10,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Curd Rice'.tr,
      calories: 250,
      carbs: 35,
      protein: 6,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Tomato Rice'.tr,
      calories: 260,
      carbs: 38,
      protein: 5,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Vegetable Stew with Appam'.tr,
      calories: 350,
      carbs: 40,
      protein: 6,
      fats: 15,
      quantity: '1 bowl + 2 appams'.tr,
    ),
    FoodItem(
      name: 'Dhokla with Green Chutney'.tr,
      calories: 180,
      carbs: 25,
      protein: 6,
      fats: 6,
      quantity: '3 pieces'.tr,
    ),
    FoodItem(
      name: 'Besan Chilla with Salad'.tr,
      calories: 220,
      carbs: 18,
      protein: 8,
      fats: 10,
      quantity: '2 chillas + salad'.tr,
    ),
    FoodItem(
      name: 'Lauki Chana Dal'.tr,
      calories: 240,
      carbs: 28,
      protein: 10,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Spinach Corn Curry'.tr,
      calories: 260,
      carbs: 20,
      protein: 6,
      fats: 12,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Tinda Masala with Roti'.tr,
      calories: 210,
      carbs: 22,
      protein: 4,
      fats: 9,
      quantity: '1 bowl + 2 rotis'.tr,
    ),
    FoodItem(
      name: 'Masoor Dal with Rice'.tr,
      calories: 290,
      carbs: 38,
      protein: 11,
      fats: 8,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Vegetable Handvo with Naan'.tr,
      calories: 350,
      carbs: 40,
      protein: 8,
      fats: 15,
      quantity: '1 bowl + 1 naan'.tr,
    ),
    FoodItem(
      name: 'Egg Bhurji with Chapati'.tr,
      calories: 300,
      carbs: 20,
      protein: 14,
      fats: 18,
      quantity: '1 bowl + 2 chapatis'.tr,
    ),
    FoodItem(
      name: 'Pumpkin Curry with Rice'.tr,
      calories: 260,
      carbs: 35,
      protein: 5,
      fats: 8,
      quantity: '1 bowl + 1 cup rice'.tr,
    ),
  ];

  List<FoodItem> snackFoods = [
    FoodItem(
      name: 'Fruit Salad'.tr,
      calories: 120,
      carbs: 28,
      protein: 1,
      fats: 0,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Sprouts Salad'.tr,
      calories: 100,
      carbs: 15,
      protein: 7,
      fats: 2,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Boiled Corn'.tr,
      calories: 100,
      carbs: 22,
      protein: 3,
      fats: 1,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Roasted Chickpeas'.tr,
      calories: 150,
      carbs: 18,
      protein: 7,
      fats: 5,
      quantity: '1/2 cup'.tr,
    ),
    FoodItem(
      name: 'Mixed Nuts'.tr,
      calories: 200,
      carbs: 6,
      protein: 6,
      fats: 18,
      quantity: '1 handful'.tr,
    ),
    FoodItem(
      name: 'Yogurt with Honey'.tr,
      calories: 130,
      carbs: 18,
      protein: 5,
      fats: 4,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Banana'.tr,
      calories: 105,
      carbs: 27,
      protein: 1,
      fats: 0,
      quantity: '1 medium'.tr,
    ),
    FoodItem(
      name: 'Apple with Peanut Butter'.tr,
      calories: 180,
      carbs: 25,
      protein: 4,
      fats: 8,
      quantity: '1 apple + 1 tbsp PB'.tr,
    ),
    FoodItem(
      name: 'Protein Bar'.tr,
      calories: 200,
      carbs: 20,
      protein: 15,
      fats: 7,
      quantity: '1 bar'.tr,
    ),
    FoodItem(
      name: 'Whole Wheat Crackers'.tr,
      calories: 130,
      carbs: 20,
      protein: 3,
      fats: 5,
      quantity: '5 pieces'.tr,
    ),
    FoodItem(
      name: 'Granola Bar'.tr,
      calories: 190,
      carbs: 28,
      protein: 4,
      fats: 7,
      quantity: '1 bar'.tr,
    ),
    FoodItem(
      name: 'Peanut Chikki'.tr,
      calories: 150,
      carbs: 20,
      protein: 4,
      fats: 7,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Bhel Puri'.tr,
      calories: 180,
      carbs: 30,
      protein: 5,
      fats: 4,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Khakra'.tr,
      calories: 100,
      carbs: 15,
      protein: 2,
      fats: 4,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Masala Makhana'.tr,
      calories: 140,
      carbs: 12,
      protein: 5,
      fats: 8,
      quantity: '1 cup'.tr,
    ),
    FoodItem(
      name: 'Hummus with Veggies'.tr,
      calories: 160,
      carbs: 14,
      protein: 6,
      fats: 9,
      quantity: '½ cup hummus + veggies'.tr,
    ),
    FoodItem(
      name: 'Boiled Egg'.tr,
      calories: 78,
      carbs: 1,
      protein: 6,
      fats: 5,
      quantity: '1 egg'.tr,
    ),
    FoodItem(
      name: 'Paneer Cubes'.tr,
      calories: 150,
      carbs: 2,
      protein: 10,
      fats: 12,
      quantity: '50g'.tr,
    ),
    FoodItem(
      name: 'Coconut Water'.tr,
      calories: 46,
      carbs: 9,
      protein: 1,
      fats: 0,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Milkshake (Low Sugar)'.tr,
      calories: 160,
      carbs: 20,
      protein: 6,
      fats: 5,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Dhokla'.tr,
      calories: 120,
      carbs: 15,
      protein: 4,
      fats: 4,
      quantity: '3 pieces'.tr,
    ),
    FoodItem(
      name: 'Vegetable Soup'.tr,
      calories: 90,
      carbs: 14,
      protein: 3,
      fats: 3,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Idli with Chutney'.tr,
      calories: 120,
      carbs: 20,
      protein: 3,
      fats: 3,
      quantity: '1 idli + chutney'.tr,
    ),
    FoodItem(
      name: 'Cheese Slice'.tr,
      calories: 80,
      carbs: 1,
      protein: 5,
      fats: 6,
      quantity: '1 slice'.tr,
    ),
    FoodItem(
      name: 'Chana Chaat'.tr,
      calories: 180,
      carbs: 20,
      protein: 8,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Moong Dal Chilla'.tr,
      calories: 110,
      carbs: 10,
      protein: 6,
      fats: 3,
      quantity: '1 chilla'.tr,
    ),
    FoodItem(
      name: 'Rice Cake with Peanut Butter'.tr,
      calories: 170,
      carbs: 22,
      protein: 4,
      fats: 8,
      quantity: '1 cake + 1 tbsp PB'.tr,
    ),
    FoodItem(
      name: 'Popcorn (Air-popped)'.tr,
      calories: 90,
      carbs: 15,
      protein: 3,
      fats: 2,
      quantity: '2 cups'.tr,
    ),
    FoodItem(
      name: 'Avocado Toast'.tr,
      calories: 200,
      carbs: 18,
      protein: 4,
      fats: 12,
      quantity: '1 toast'.tr,
    ),
    FoodItem(
      name: 'Stuffed Dates'.tr,
      calories: 150,
      carbs: 20,
      protein: 2,
      fats: 6,
      quantity: '3 dates'.tr,
    ),
    FoodItem(
      name: 'Oats Cookies'.tr,
      calories: 180,
      carbs: 22,
      protein: 3,
      fats: 8,
      quantity: '2 cookies'.tr,
    ),
    FoodItem(
      name: 'Fruit Smoothie'.tr,
      calories: 180,
      carbs: 30,
      protein: 4,
      fats: 4,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Carrot Sticks with Hummus'.tr,
      calories: 130,
      carbs: 12,
      protein: 4,
      fats: 7,
      quantity: '½ cup'.tr,
    ),
    FoodItem(
      name: 'Soy Nuts'.tr,
      calories: 160,
      carbs: 10,
      protein: 12,
      fats: 8,
      quantity: '½ cup'.tr,
    ),
    FoodItem(
      name: 'Trail Mix'.tr,
      calories: 220,
      carbs: 18,
      protein: 5,
      fats: 14,
      quantity: '1 handful'.tr,
    ),
    FoodItem(
      name: 'Besan Ladoo'.tr,
      calories: 140,
      carbs: 18,
      protein: 3,
      fats: 7,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Vegetable Sandwich'.tr,
      calories: 180,
      carbs: 25,
      protein: 5,
      fats: 6,
      quantity: '1 sandwich'.tr,
    ),
    FoodItem(
      name: 'Upma (small portion)'.tr,
      calories: 150,
      carbs: 25,
      protein: 4,
      fats: 5,
      quantity: '1 small bowl'.tr,
    ),
    FoodItem(
      name: 'Egg Roll (Mini)'.tr,
      calories: 200,
      carbs: 20,
      protein: 8,
      fats: 10,
      quantity: '1 roll'.tr,
    ),
    FoodItem(
      name: 'Rice Idli'.tr,
      calories: 58,
      carbs: 12,
      protein: 2,
      fats: 0,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Cucumber Sandwich'.tr,
      calories: 120,
      carbs: 20,
      protein: 3,
      fats: 4,
      quantity: '2 slices'.tr,
    ),
    FoodItem(
      name: 'Fruit Chaat'.tr,
      calories: 130,
      carbs: 25,
      protein: 2,
      fats: 1,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Lassi (Sweet)'.tr,
      calories: 180,
      carbs: 25,
      protein: 6,
      fats: 6,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Cold Coffee (Low Sugar)'.tr,
      calories: 120,
      carbs: 14,
      protein: 4,
      fats: 4,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Rava Dhokla'.tr,
      calories: 160,
      carbs: 22,
      protein: 4,
      fats: 6,
      quantity: '3 pieces'.tr,
    ),
    FoodItem(
      name: 'Vegetable Cutlet'.tr,
      calories: 150,
      carbs: 20,
      protein: 4,
      fats: 6,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Chikki with Jaggery'.tr,
      calories: 160,
      carbs: 22,
      protein: 3,
      fats: 7,
      quantity: '1 bar'.tr,
    ),
    FoodItem(
      name: 'Milk (Low Fat)'.tr,
      calories: 100,
      carbs: 12,
      protein: 8,
      fats: 2,
      quantity: '1 glass'.tr,
    ),
    FoodItem(
      name: 'Baked Samosa'.tr,
      calories: 180,
      carbs: 22,
      protein: 4,
      fats: 7,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Vegetable Wrap'.tr,
      calories: 200,
      carbs: 25,
      protein: 6,
      fats: 8,
      quantity: '1 wrap'.tr,
    ),
    FoodItem(
      name: 'Roasted Soybeans'.tr,
      calories: 170,
      carbs: 10,
      protein: 14,
      fats: 8,
      quantity: '½ cup'.tr,
    ),
  ];

  List<FoodItem> dinnerFoods = [
    FoodItem(
      name: 'Chapati with Sabzi'.tr,
      calories: 220,
      carbs: 30,
      protein: 5,
      fats: 7,
      quantity: '2 chapatis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Grilled Fish'.tr,
      calories: 250,
      carbs: 0,
      protein: 25,
      fats: 15,
      quantity: '1 fillet'.tr,
    ),
    FoodItem(
      name: 'Moong Dal Khichdi'.tr,
      calories: 210,
      carbs: 35,
      protein: 7,
      fats: 4,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Paneer Bhurji with Roti'.tr,
      calories: 320,
      carbs: 25,
      protein: 18,
      fats: 15,
      quantity: '1 bowl + 1 roti'.tr,
    ),
    FoodItem(
      name: 'Brown Rice with Veg Curry'.tr,
      calories: 280,
      carbs: 38,
      protein: 6,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Quinoa with Stir Fry Veggies'.tr,
      calories: 300,
      carbs: 30,
      protein: 10,
      fats: 12,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Grilled Tofu with Salad'.tr,
      calories: 240,
      carbs: 12,
      protein: 16,
      fats: 12,
      quantity: '1 plate'.tr,
    ),
    FoodItem(
      name: 'Masoor Dal with Rice'.tr,
      calories: 290,
      carbs: 40,
      protein: 10,
      fats: 6,
      quantity: '1 cup rice + dal'.tr,
    ),
    FoodItem(
      name: 'Vegetable Pulao'.tr,
      calories: 250,
      carbs: 35,
      protein: 6,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Palak Paneer with Chapati'.tr,
      calories: 330,
      carbs: 28,
      protein: 15,
      fats: 18,
      quantity: '1 bowl + 1 roti'.tr,
    ),
    FoodItem(
      name: 'Mixed Vegetable Soup'.tr,
      calories: 100,
      carbs: 15,
      protein: 3,
      fats: 3,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Stuffed Paratha with Curd'.tr,
      calories: 280,
      carbs: 30,
      protein: 6,
      fats: 12,
      quantity: '1 paratha + ½ cup curd'.tr,
    ),
    FoodItem(
      name: 'Oats Khichdi'.tr,
      calories: 230,
      carbs: 32,
      protein: 6,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Egg Curry with Rice'.tr,
      calories: 320,
      carbs: 25,
      protein: 14,
      fats: 16,
      quantity: '1 bowl curry + 1 cup rice'.tr,
    ),
    FoodItem(
      name: 'Lauki Chana Dal'.tr,
      calories: 220,
      carbs: 22,
      protein: 9,
      fats: 7,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Roti with Bhindi'.tr,
      calories: 200,
      carbs: 28,
      protein: 4,
      fats: 6,
      quantity: '2 rotis + bhindi'.tr,
    ),
    FoodItem(
      name: 'Dal Tadka with Jeera Rice'.tr,
      calories: 300,
      carbs: 40,
      protein: 10,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Vegetable Handvo'.tr,
      calories: 240,
      carbs: 30,
      protein: 8,
      fats: 10,
      quantity: '1 slice'.tr,
    ),
    FoodItem(
      name: 'Kadhi with Bajra Roti'.tr,
      calories: 280,
      carbs: 34,
      protein: 7,
      fats: 10,
      quantity: '1 roti + 1 bowl kadhi'.tr,
    ),
    FoodItem(
      name: 'Tofu Curry with Quinoa'.tr,
      calories: 290,
      carbs: 25,
      protein: 15,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Bhakri with Thecha'.tr,
      calories: 270,
      carbs: 28,
      protein: 5,
      fats: 12,
      quantity: '1 bhakri + chutney'.tr,
    ),
    FoodItem(
      name: 'Chicken Curry with Roti'.tr,
      calories: 340,
      carbs: 20,
      protein: 25,
      fats: 18,
      quantity: '1 bowl curry + 1 roti'.tr,
    ),
    FoodItem(
      name: 'Biryani (Veg)'.tr,
      calories: 330,
      carbs: 42,
      protein: 8,
      fats: 12,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Rajma with Brown Rice'.tr,
      calories: 350,
      carbs: 45,
      protein: 12,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Daliya (Broken Wheat Porridge)'.tr,
      calories: 250,
      carbs: 38,
      protein: 7,
      fats: 6,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Besan Chilla with Salad'.tr,
      calories: 200,
      carbs: 18,
      protein: 10,
      fats: 8,
      quantity: '2 chillas'.tr,
    ),
    FoodItem(
      name: 'Pumpkin Sabzi with Chapati'.tr,
      calories: 220,
      carbs: 26,
      protein: 4,
      fats: 7,
      quantity: '2 rotis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Cauliflower Stir Fry'.tr,
      calories: 180,
      carbs: 15,
      protein: 4,
      fats: 9,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Boiled Egg Salad'.tr,
      calories: 160,
      carbs: 5,
      protein: 10,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Tomato Rasam with Rice'.tr,
      calories: 270,
      carbs: 35,
      protein: 6,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Sweet Potato with Curd'.tr,
      calories: 210,
      carbs: 30,
      protein: 5,
      fats: 4,
      quantity: '1 bowl + ½ cup curd'.tr,
    ),
    FoodItem(
      name: 'Stuffed Capsicum'.tr,
      calories: 240,
      carbs: 20,
      protein: 8,
      fats: 10,
      quantity: '1 piece'.tr,
    ),
    FoodItem(
      name: 'Paneer Tikka with Mint Chutney'.tr,
      calories: 280,
      carbs: 10,
      protein: 18,
      fats: 16,
      quantity: '1 serving'.tr,
    ),
    FoodItem(
      name: 'Rice with Sambar'.tr,
      calories: 320,
      carbs: 45,
      protein: 10,
      fats: 6,
      quantity: '1 cup rice + sambar'.tr,
    ),
    FoodItem(
      name: 'Cabbage Sabzi with Chapati'.tr,
      calories: 200,
      carbs: 26,
      protein: 4,
      fats: 6,
      quantity: '2 rotis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Vegetable Thepla with Dahi'.tr,
      calories: 260,
      carbs: 30,
      protein: 6,
      fats: 10,
      quantity: '1 thepla + curd'.tr,
    ),
    FoodItem(
      name: 'Grilled Mushroom Skewers'.tr,
      calories: 180,
      carbs: 8,
      protein: 6,
      fats: 12,
      quantity: '1 skewer'.tr,
    ),
    FoodItem(
      name: 'Beetroot Sabzi with Roti'.tr,
      calories: 210,
      carbs: 25,
      protein: 4,
      fats: 7,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Spinach Dal with Rice'.tr,
      calories: 280,
      carbs: 35,
      protein: 10,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Lentil Soup with Toast'.tr,
      calories: 220,
      carbs: 30,
      protein: 10,
      fats: 5,
      quantity: '1 bowl + 1 toast'.tr,
    ),
    FoodItem(
      name: 'Tinda Curry with Chapati'.tr,
      calories: 200,
      carbs: 24,
      protein: 5,
      fats: 6,
      quantity: '2 rotis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Egg Bhurji with Roti'.tr,
      calories: 270,
      carbs: 20,
      protein: 14,
      fats: 14,
      quantity: '1 bowl + 1 roti'.tr,
    ),
    FoodItem(
      name: 'Chana Masala with Rice'.tr,
      calories: 340,
      carbs: 45,
      protein: 12,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Karela Sabzi with Roti'.tr,
      calories: 190,
      carbs: 20,
      protein: 5,
      fats: 7,
      quantity: '2 rotis + sabzi'.tr,
    ),
    FoodItem(
      name: 'Vegetable Stew with Appam'.tr,
      calories: 330,
      carbs: 35,
      protein: 6,
      fats: 14,
      quantity: '1 bowl + 1 appam'.tr,
    ),
    FoodItem(
      name: 'Zucchini Stir Fry'.tr,
      calories: 170,
      carbs: 12,
      protein: 3,
      fats: 10,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Low Carb Paneer Bowl'.tr,
      calories: 240,
      carbs: 8,
      protein: 18,
      fats: 14,
      quantity: '1 bowl'.tr,
    ),
    FoodItem(
      name: 'Stuffed Tomato'.tr,
      calories: 220,
      carbs: 18,
      protein: 6,
      fats: 10,
      quantity: '1 tomato'.tr,
    ),
    FoodItem(
      name: 'Vegetable Rava Upma'.tr,
      calories: 230,
      carbs: 32,
      protein: 5,
      fats: 8,
      quantity: '1 bowl'.tr,
    ),
  ];

  String type = "";
  // Edit mode state and selection tracking
  bool isEditing = false;
  // selected indices refer to positions in filteredItems
  final Set<int> selectedIndices = {};

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    type = argument['value'];
    if (type == "Breakfast" || type == "BreakFast") {
        filteredItems = breakfastFoods;
    } else if (type == "Lunch") {
          filteredItems = lunchFoods;
    } else if (type == "snack(s)") {
          filteredItems = snackFoods;
    } else {
      filteredItems = dinnerFoods;
    }
  // Load any persisted modifications (adds/edits/deletes) for this meal type from DB
  _loadPersistedFoodsFromDb();
  }

  void toggleEditMode() {
    isEditing = !isEditing;
    // clear selection when exiting edit mode
    if (!isEditing) selectedIndices.clear();
    update();
  }

  void toggleSelect(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
    }
    update();
  }

  /// Put the page into edit/config mode and select a single item.
  /// Clears existing selection and selects [index]. Useful for long-press flow.
  void selectAndEnterEdit(int index) {
    // enter edit mode if not already
    if (!isEditing) isEditing = true;
    // clear any previous selections and select this index
    selectedIndices.clear();
    selectedIndices.add(index);
    update();
  }

  void addCustomFood(FoodItem item) async {
    // Secure check: ask server for current premium status (non-reactive)
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    filteredItems.insert(0, item);
    update();
    NotificationService.showSuccess('food_added_success');
    // persist changes to DB
    _saveCurrentFoodsToDb();
  }

  void editFoodAt(int index, FoodItem item) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (index >= 0 && index < filteredItems.length) {
      filteredItems[index] = item;
      update();
      NotificationService.showSuccess('food_updated_success');
      // persist changes to DB
      _saveCurrentFoodsToDb();
    }
  }

  void deleteSelected(BuildContext context) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (selectedIndices.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        backgroundColor: ctx.theme.cardColor,
        title: Text('delete_items_title'.tr),
            content: Text(
              'delete_items_message'.trParams({
                'count': selectedIndices.length.toString(),
              }),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'delete'.tr,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // remove by index descending to avoid reindexing issues
      final indices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        filteredItems.removeAt(i);
      }
      selectedIndices.clear();
      isEditing = false;
      update();
      NotificationService.showSuccess(
        'food_deleted_success',
        params: {'count': indices.length.toString()},
      );
      // persist changes to DB
      _saveCurrentFoodsToDb();
    }
  }

  Future<void> _saveCurrentFoodsToDb() async {
    try {
      final t = type;
      // remove existing rows for this type
      await dbHelper.deleteLocalFoodsByType(t);
      // insert current items
      for (final f in filteredItems) {
        await dbHelper.insertLocalFood({
          'name': f.name,
          'quantity': f.quantity,
          'calories': f.calories,
          'carbs': f.carbs,
          'protein': f.protein,
          'fats': f.fats,
          'type': t,
        });
      }
    } catch (_) {
      // ignore DB errors for now
    }
  }

  Future<void> _loadPersistedFoodsFromDb() async {
    try {
      final t = type;
      final rows = await dbHelper.getLocalFoods(t);
      if (rows.isEmpty) return;
      final items = rows.map((r) => FoodItem.fromJson(r)).toList();
      if (type == "Breakfast" || type == "BreakFast") {
        breakfastFoods = items;
      } else if (type == "Lunch") {
        lunchFoods = items;
      } else if (type == "snack(s)") {
        snackFoods = items;
      } else {
        dinnerFoods = items;
      }
      filteredItems = items;
      update();
    } catch (_) {
      // ignore DB read errors
    }
  }

  /// Filters the local food list. Debounces rapid calls by default.
  ///
  /// Use `immediate: true` to perform the filter instantly (for submit/clear actions).
  void searchFilter(String query, {bool immediate = false}) {
    // cancel any pending debounce
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    runFilter() {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        // reset to full list depending on type
        if (type == "Breakfast" || type == "BreakFast") {
          filteredItems = breakfastFoods;
        } else if (type == "Lunch") {
          filteredItems = lunchFoods;
        } else if (type == "snack(s)") {
          filteredItems = snackFoods;
        } else {
          filteredItems = dinnerFoods;
        }
      } else {
        if (type == "Breakfast" || type == "BreakFast") {
          filteredItems =
              breakfastFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else if (type == "Lunch") {
          filteredItems =
              lunchFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else if (type == "snack(s)") {
          filteredItems =
              snackFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else {
          filteredItems =
              dinnerFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        }
      }

      // filter completed
      isFiltering = false;
      update();
    }

    if (immediate) {
      isFiltering = true;
      update();
      runFilter();
      return;
    }

    // show filtering indicator and debounce
    isFiltering = true;
    update();
    _searchDebounce = Timer(_debounceDuration, runFilter);
  }

  addSqlData(String type, FoodItem item) async {
    dbHelper.insertCalorieHistory(
      CalorieHistoryModel(
        calorie: item.calories,
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        protein: item.protein,
        carbs: item.carbs,
        fats: item.fats,
        type: type,
        title: item.name,
      ),
    );
  }

  onAddButton(BuildContext context, FoodItem item) async {
    List<SqlCalorieModel> calorieData = await dbHelper.getCalorieData();
    addSqlData(type, item);

    if (calorieData.isEmpty) {
      int id = await dbHelper.insertCalorie(
        SqlCalorieModel(
          date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          totalGoal: ConstantUserMaster.calorieGoal,
          calorie: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fats: item.fats,
        ),
      );
      await dbHelper.insertDailyWater(
        DailyCalorieModel(
          date: DateTime.now().toString(),
          time: DateFormat('hh:mm a').format(DateTime.now()),
          calorie: item.calories,
          calorieId: id,
        ),
      );
      Get.offAllNamed(Routes.leadingView);
    } else {
      if (calorieData.last.date ==
          DateFormat('dd-MM-yyyy').format(DateTime.now())) {
        if (calorieData.last.calorie + item.calories >
            ConstantUserMaster.calorieGoal) {
          showCalorieCompleteDialog(context, calorieData, item);
        } else {
          await dbHelper.updateCalorie(
            SqlCalorieModel(
              id: calorieData.last.id,
              date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
              totalGoal: ConstantUserMaster.calorieGoal,
              calorie: calorieData.last.calorie + item.calories,
              protein: calorieData.last.protein + item.protein,
              carbs: calorieData.last.carbs + item.carbs,
              fats: calorieData.last.fats + item.fats,
            ),
          );
          await dbHelper.insertDailyWater(
            DailyCalorieModel(
              date: DateTime.now().toString(),
              time: DateFormat('hh:mm a').format(DateTime.now()),
              calorie: calorieData.last.calorie + item.calories,
              calorieId: calorieData.last.id!,
            ),
          );
          Get.offAllNamed(Routes.leadingView);
        }
      } else {
        int id = await dbHelper.insertCalorie(
          SqlCalorieModel(
            date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
            totalGoal: ConstantUserMaster.calorieGoal,
            calorie: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fats: item.fats,
          ),
        );
        await dbHelper.insertDailyWater(
          DailyCalorieModel(
            date: DateTime.now().toString(),
            time: DateFormat('hh:mm a').format(DateTime.now()),
            calorie: item.calories,
            calorieId: id,
          ),
        );
        Get.offAllNamed(Routes.leadingView);
      }
    }
  }

  showCalorieCompleteDialog(
      BuildContext context,
      List<SqlCalorieModel> calorieData,
    FoodItem item,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.cardColor,
          title: Text(
            "Calorie Goal Reached".tr,
            style: context.textTheme.headlineMedium,
          ),
          content: Text(
            "You've completed your calorie goal for today. Would you like to add more?"
                .tr,
            style: context.textTheme.titleSmall,
          ),
          actions: [
            TextButton(
              child: Text(
                "Done".tr,
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontFamily: poppins,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              onPressed: () async {
                await dbHelper.updateCalorie(
                  SqlCalorieModel(
                    id: calorieData.last.id,
                    date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                    totalGoal: ConstantUserMaster.calorieGoal,
                    calorie: calorieData.last.calorie + item.calories,
                    protein: calorieData.last.protein + item.protein,
                    carbs: calorieData.last.carbs + item.carbs,
                    fats: calorieData.last.fats + item.fats,
                  ),
                );
                await dbHelper.insertDailyWater(
                  DailyCalorieModel(
                    date: DateTime.now().toString(),
                    time: DateFormat('hh:mm a').format(DateTime.now()),
                    calorie: calorieData.last.calorie + item.calories,
                    calorieId: calorieData.last.id!,
                  ),
                );

                Get.offAllNamed(Routes.leadingView);
              },
              child: Text(
                "Add More Calories".tr,
                style: TextStyle(
                  color: context.theme.focusColor,
                  fontFamily: poppins,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showPremiumRequiredDialog() {
    Get.dialog(
      PremiumRequiredDialog(
        title: 'premium_feature'.tr,
        message: 'local_food_premium_message'.tr,
        badge: Text(
          'local_food_premium_badge'.tr,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        onUpgrade: () {
          Get.back();
          Get.toNamed(Routes.premiumView);
        },
        onCancel: () => Get.back(),
      ),
      barrierDismissible: false,
    );
  }
}

class FoodItem {
  final String name;
  final String quantity;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;

  FoodItem({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.quantity,
    required this.fats,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0) as int,
      carbs: (json['carbs'] ?? 0) as int,
      protein: (json['protein'] ?? 0) as int,
      quantity: json['quantity'] ?? '',
      fats: (json['fats'] ?? 0) as int,
    );
  }
}
