import 'package:flutter/material.dart';
import 'dart:async';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Model/CalorieHistoryModel.dart';
import '../../Model/SqlCalorieModel.dart';
import '../../Model/SqlDailyCalorieModel.dart';
import '../../SharePrefHelper/ConstantUserMaster.dart';
import '../../constant/FontFamily.dart';
import '../../routes/app_routes.dart';

class LocalFoodController extends GetxController {
  Map<String,dynamic> argument = Get.arguments;
  TextEditingController textController = TextEditingController();
  List<FoodItem> filteredItems = [];
  Timer? _searchDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  bool isFiltering = false;
  final dbHelper = DatabaseHelper();
  List<FoodItem> breakfastFoods = [
    FoodItem(name: 'Boiled Egg', calories: 78, carbs: 1, protein: 6, fats: 5, quantity: '1 egg'),
    FoodItem(name: 'Oatmeal', calories: 150, carbs: 27, protein: 5, fats: 3, quantity: '1 bowl'),
    FoodItem(name: 'Banana', calories: 105, carbs: 27, protein: 1, fats: 0, quantity: '1 medium'),
    FoodItem(name: 'Paratha', calories: 250, carbs: 35, protein: 5, fats: 12, quantity: '1 piece'),
    FoodItem(name: 'Idli', calories: 58, carbs: 12, protein: 2, fats: 0, quantity: '1 piece'),
    FoodItem(name: 'Dosa', calories: 133, carbs: 22, protein: 3, fats: 4, quantity: '1 piece'),
    FoodItem(name: 'Upma', calories: 180, carbs: 30, protein: 4, fats: 5, quantity: '1 cup'),
    FoodItem(name: 'Poha', calories: 180, carbs: 30, protein: 3, fats: 5, quantity: '1 cup'),
    FoodItem(name: 'Bread Butter', calories: 150, carbs: 20, protein: 3, fats: 7, quantity: '2 slices'),
    FoodItem(name: 'Cornflakes with Milk', calories: 200, carbs: 35, protein: 6, fats: 4, quantity: '1 bowl'),
    FoodItem(name: 'Chilla (Besan)', calories: 120, carbs: 10, protein: 7, fats: 5, quantity: '1 piece'),
    FoodItem(name: 'Sprouts Salad', calories: 100, carbs: 15, protein: 7, fats: 2, quantity: '1 bowl'),
    FoodItem(name: 'Pancakes', calories: 175, carbs: 25, protein: 4, fats: 6, quantity: '2 small pieces'),
    FoodItem(name: 'Apple', calories: 95, carbs: 25, protein: 0, fats: 0, quantity: '1 medium'),
    FoodItem(name: 'Milk', calories: 122, carbs: 12, protein: 8, fats: 5, quantity: '1 cup'),
    FoodItem(name: 'Almonds', calories: 100, carbs: 4, protein: 4, fats: 9, quantity: '10 pieces'),
    FoodItem(name: 'Smoothie (Fruit)', calories: 180, carbs: 30, protein: 4, fats: 4, quantity: '1 glass'),
    FoodItem(name: 'Yogurt (Plain)', calories: 100, carbs: 5, protein: 8, fats: 5, quantity: '1 cup'),
    FoodItem(name: 'Khichdi', calories: 220, carbs: 35, protein: 6, fats: 5, quantity: '1 bowl'),
    FoodItem(name: 'Thepla', calories: 120, carbs: 15, protein: 3, fats: 6, quantity: '1 piece'),
    FoodItem(name: 'Cheela (Moong dal)', calories: 110, carbs: 10, protein: 6, fats: 3, quantity: '1 piece'),
    FoodItem(name: 'Pav Bhaji', calories: 300, carbs: 40, protein: 6, fats: 12, quantity: '2 pavs + bhaji'),
    FoodItem(name: 'Sabudana Khichdi', calories: 250, carbs: 45, protein: 2, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Roti with Sabzi', calories: 220, carbs: 30, protein: 4, fats: 8, quantity: '1 roti + sabzi'),
    FoodItem(name: 'Peanut Butter Bread', calories: 200, carbs: 20, protein: 5, fats: 10, quantity: '2 slices'),
    FoodItem(name: 'Fruit Bowl', calories: 120, carbs: 28, protein: 1, fats: 0, quantity: '1 bowl'),
    FoodItem(name: 'Vegetable Sandwich', calories: 180, carbs: 25, protein: 5, fats: 6, quantity: '1 sandwich'),
    FoodItem(name: 'Rice Idli with Sambar', calories: 200, carbs: 30, protein: 6, fats: 3, quantity: '2 idlis + sambar'),
    FoodItem(name: 'Boiled Corn', calories: 100, carbs: 22, protein: 3, fats: 1, quantity: '1 cup'),
    FoodItem(name: 'Paneer Bhurji', calories: 250, carbs: 5, protein: 15, fats: 20, quantity: '1 bowl'),
    FoodItem(name: 'Protein Shake', calories: 180, carbs: 5, protein: 25, fats: 3, quantity: '1 glass'),
    FoodItem(name: 'Muesli with Milk', calories: 220, carbs: 30, protein: 7, fats: 6, quantity: '1 bowl'),
    FoodItem(name: 'Chapati with Curd', calories: 210, carbs: 25, protein: 5, fats: 7, quantity: '1 chapati + ½ cup curd'),
    FoodItem(name: 'Porridge (Daliya)', calories: 190, carbs: 35, protein: 5, fats: 3, quantity: '1 bowl'),
    FoodItem(name: 'Rava Upma', calories: 180, carbs: 28, protein: 4, fats: 5, quantity: '1 bowl'),
    FoodItem(name: 'Chickpea Salad', calories: 160, carbs: 20, protein: 8, fats: 5, quantity: '1 bowl'),
    FoodItem(name: 'Boiled Sweet Potato', calories: 115, carbs: 26, protein: 2, fats: 0, quantity: '1 medium'),
    FoodItem(name: 'Coconut Water', calories: 46, carbs: 9, protein: 1, fats: 0, quantity: '1 glass'),
    FoodItem(name: 'Masala Omelette', calories: 190, carbs: 2, protein: 10, fats: 15, quantity: '1 egg'),
    FoodItem(name: 'Vegetable Poha', calories: 200, carbs: 30, protein: 4, fats: 6, quantity: '1 bowl'),
  ];

  List<FoodItem> lunchFoods = [
    FoodItem(name: 'Roti with Sabzi', calories: 220, carbs: 30, protein: 4, fats: 8, quantity: '2 rotis + sabzi'),
    FoodItem(name: 'Rice with Dal', calories: 300, carbs: 40, protein: 10, fats: 6, quantity: '1 cup rice + 1 cup dal'),
    FoodItem(name: 'Grilled Chicken', calories: 250, carbs: 0, protein: 30, fats: 12, quantity: '1 breast'),
    FoodItem(name: 'Paneer Curry', calories: 280, carbs: 10, protein: 14, fats: 20, quantity: '1 bowl'),
    FoodItem(name: 'Mixed Vegetable Curry', calories: 180, carbs: 20, protein: 4, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Chapati with Daal', calories: 250, carbs: 35, protein: 8, fats: 7, quantity: '2 chapatis + dal'),
    FoodItem(name: 'Fish Curry with Rice', calories: 320, carbs: 35, protein: 20, fats: 10, quantity: '1 bowl curry + 1 cup rice'),
    FoodItem(name: 'Rajma Chawal', calories: 350, carbs: 50, protein: 12, fats: 7, quantity: '1 bowl'),
    FoodItem(name: 'Chole Bhature', calories: 450, carbs: 50, protein: 10, fats: 25, quantity: '1 bhatura + chole'),
    FoodItem(name: 'Kadhi with Rice', calories: 300, carbs: 40, protein: 8, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Palak Paneer', calories: 280, carbs: 10, protein: 15, fats: 18, quantity: '1 bowl'),
    FoodItem(name: 'Stuffed Paratha', calories: 300, carbs: 35, protein: 6, fats: 14, quantity: '1 paratha'),
    FoodItem(name: 'Veg Pulao', calories: 320, carbs: 45, protein: 6, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Biryani with Raita', calories: 450, carbs: 55, protein: 15, fats: 20, quantity: '1 plate'),
    FoodItem(name: 'Tofu Stir Fry', calories: 250, carbs: 15, protein: 18, fats: 12, quantity: '1 bowl'),
    FoodItem(name: 'Chicken Tikka', calories: 320, carbs: 6, protein: 28, fats: 18, quantity: '1 plate'),
    FoodItem(name: 'Veg Fried Rice', calories: 330, carbs: 48, protein: 6, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Aloo Gobi with Roti', calories: 280, carbs: 30, protein: 5, fats: 10, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Baingan Bharta', calories: 200, carbs: 18, protein: 3, fats: 12, quantity: '1 bowl'),
    FoodItem(name: 'Sambar with Rice', calories: 280, carbs: 40, protein: 8, fats: 6, quantity: '1 cup + 1 bowl'),
    FoodItem(name: 'Chicken Curry with Roti', calories: 350, carbs: 25, protein: 20, fats: 18, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Bhindi Masala with Roti', calories: 230, carbs: 20, protein: 4, fats: 12, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Egg Curry with Rice', calories: 320, carbs: 35, protein: 14, fats: 15, quantity: '1 bowl + 1 cup rice'),
    FoodItem(name: 'Pav Bhaji', calories: 400, carbs: 45, protein: 7, fats: 20, quantity: '2 pavs + bhaji'),
    FoodItem(name: 'Lentil Soup with Bread', calories: 280, carbs: 35, protein: 10, fats: 6, quantity: '1 bowl + 1 bread slice'),
    FoodItem(name: 'Methi Thepla with Curd', calories: 260, carbs: 30, protein: 6, fats: 10, quantity: '2 theplas + ½ cup curd'),
    FoodItem(name: 'Chickpea Salad', calories: 220, carbs: 25, protein: 10, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Soybean Curry with Rice', calories: 300, carbs: 30, protein: 15, fats: 10, quantity: '1 bowl + 1 cup rice'),
    FoodItem(name: 'Cabbage Sabzi with Chapati', calories: 200, carbs: 25, protein: 4, fats: 8, quantity: '1 bowl + 2 chapatis'),
    FoodItem(name: 'Dal Makhani with Naan', calories: 400, carbs: 45, protein: 12, fats: 18, quantity: '1 bowl + 1 naan'),
    FoodItem(name: 'Vegetable Korma with Roti', calories: 300, carbs: 35, protein: 5, fats: 15, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Tandoori Roti with Paneer', calories: 320, carbs: 30, protein: 12, fats: 14, quantity: '2 rotis + paneer'),
    FoodItem(name: 'Mixed Dal with Rice', calories: 280, carbs: 40, protein: 10, fats: 6, quantity: '1 bowl + 1 cup rice'),
    FoodItem(name: 'Bottle Gourd Curry with Roti', calories: 210, carbs: 20, protein: 4, fats: 8, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Kofta Curry with Roti', calories: 340, carbs: 28, protein: 10, fats: 18, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Paneer Bhurji with Bread', calories: 300, carbs: 28, protein: 15, fats: 14, quantity: '1 bowl + 2 slices'),
    FoodItem(name: 'Chana Masala with Rice', calories: 330, carbs: 45, protein: 12, fats: 10, quantity: '1 bowl + 1 cup rice'),
    FoodItem(name: 'Curd Rice', calories: 250, carbs: 35, protein: 6, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Tomato Rice', calories: 260, carbs: 38, protein: 5, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Vegetable Stew with Appam', calories: 350, carbs: 40, protein: 6, fats: 15, quantity: '1 bowl + 2 appams'),
    FoodItem(name: 'Dhokla with Green Chutney', calories: 180, carbs: 25, protein: 6, fats: 6, quantity: '3 pieces'),
    FoodItem(name: 'Besan Chilla with Salad', calories: 220, carbs: 18, protein: 8, fats: 10, quantity: '2 chillas + salad'),
    FoodItem(name: 'Lauki Chana Dal', calories: 240, carbs: 28, protein: 10, fats: 6, quantity: '1 bowl'),
    FoodItem(name: 'Spinach Corn Curry', calories: 260, carbs: 20, protein: 6, fats: 12, quantity: '1 bowl'),
    FoodItem(name: 'Tinda Masala with Roti', calories: 210, carbs: 22, protein: 4, fats: 9, quantity: '1 bowl + 2 rotis'),
    FoodItem(name: 'Masoor Dal with Rice', calories: 290, carbs: 38, protein: 11, fats: 8, quantity: '1 bowl + 1 cup rice'),
    FoodItem(name: 'Vegetable Handi with Naan', calories: 350, carbs: 40, protein: 8, fats: 15, quantity: '1 bowl + 1 naan'),
    FoodItem(name: 'Egg Bhurji with Chapati', calories: 300, carbs: 20, protein: 14, fats: 18, quantity: '1 bowl + 2 chapatis'),
    FoodItem(name: 'Pumpkin Curry with Rice', calories: 260, carbs: 35, protein: 5, fats: 8, quantity: '1 bowl + 1 cup rice'),
  ];


  List<FoodItem> snackFoods = [
    FoodItem(name: 'Fruit Salad', calories: 120, carbs: 28, protein: 1, fats: 0, quantity: '1 bowl'),
    FoodItem(name: 'Sprouts Salad', calories: 100, carbs: 15, protein: 7, fats: 2, quantity: '1 bowl'),
    FoodItem(name: 'Boiled Corn', calories: 100, carbs: 22, protein: 3, fats: 1, quantity: '1 cup'),
    FoodItem(name: 'Roasted Chickpeas', calories: 150, carbs: 18, protein: 7, fats: 5, quantity: '1/2 cup'),
    FoodItem(name: 'Mixed Nuts', calories: 200, carbs: 6, protein: 6, fats: 18, quantity: '1 handful'),
    FoodItem(name: 'Yogurt with Honey', calories: 130, carbs: 18, protein: 5, fats: 4, quantity: '1 bowl'),
    FoodItem(name: 'Banana', calories: 105, carbs: 27, protein: 1, fats: 0, quantity: '1 medium'),
    FoodItem(name: 'Apple with Peanut Butter', calories: 180, carbs: 25, protein: 4, fats: 8, quantity: '1 apple + 1 tbsp PB'),
    FoodItem(name: 'Protein Bar', calories: 200, carbs: 20, protein: 15, fats: 7, quantity: '1 bar'),
    FoodItem(name: 'Whole Wheat Crackers', calories: 130, carbs: 20, protein: 3, fats: 5, quantity: '5 pieces'),
    FoodItem(name: 'Granola Bar', calories: 190, carbs: 28, protein: 4, fats: 7, quantity: '1 bar'),
    FoodItem(name: 'Peanut Chikki', calories: 150, carbs: 20, protein: 4, fats: 7, quantity: '1 piece'),
    FoodItem(name: 'Bhel Puri', calories: 180, carbs: 30, protein: 5, fats: 4, quantity: '1 bowl'),
    FoodItem(name: 'Khakra', calories: 100, carbs: 15, protein: 2, fats: 4, quantity: '1 piece'),
    FoodItem(name: 'Masala Makhana', calories: 140, carbs: 12, protein: 5, fats: 8, quantity: '1 cup'),
    FoodItem(name: 'Hummus with Veggies', calories: 160, carbs: 14, protein: 6, fats: 9, quantity: '½ cup hummus + veggies'),
    FoodItem(name: 'Boiled Egg', calories: 78, carbs: 1, protein: 6, fats: 5, quantity: '1 egg'),
    FoodItem(name: 'Paneer Cubes', calories: 150, carbs: 2, protein: 10, fats: 12, quantity: '50g'),
    FoodItem(name: 'Coconut Water', calories: 46, carbs: 9, protein: 1, fats: 0, quantity: '1 glass'),
    FoodItem(name: 'Milkshake (Low Sugar)', calories: 160, carbs: 20, protein: 6, fats: 5, quantity: '1 glass'),
    FoodItem(name: 'Dhokla', calories: 120, carbs: 15, protein: 4, fats: 4, quantity: '3 pieces'),
    FoodItem(name: 'Vegetable Soup', calories: 90, carbs: 14, protein: 3, fats: 3, quantity: '1 bowl'),
    FoodItem(name: 'Idli with Chutney', calories: 120, carbs: 20, protein: 3, fats: 3, quantity: '1 idli + chutney'),
    FoodItem(name: 'Cheese Slice', calories: 80, carbs: 1, protein: 5, fats: 6, quantity: '1 slice'),
    FoodItem(name: 'Chana Chaat', calories: 180, carbs: 20, protein: 8, fats: 6, quantity: '1 bowl'),
    FoodItem(name: 'Moong Dal Chilla', calories: 110, carbs: 10, protein: 6, fats: 3, quantity: '1 chilla'),
    FoodItem(name: 'Rice Cake with Peanut Butter', calories: 170, carbs: 22, protein: 4, fats: 8, quantity: '1 cake + 1 tbsp PB'),
    FoodItem(name: 'Popcorn (Air-popped)', calories: 90, carbs: 15, protein: 3, fats: 2, quantity: '2 cups'),
    FoodItem(name: 'Avocado Toast', calories: 200, carbs: 18, protein: 4, fats: 12, quantity: '1 toast'),
    FoodItem(name: 'Stuffed Dates', calories: 150, carbs: 20, protein: 2, fats: 6, quantity: '3 dates'),
    FoodItem(name: 'Oats Cookies', calories: 180, carbs: 22, protein: 3, fats: 8, quantity: '2 cookies'),
    FoodItem(name: 'Fruit Smoothie', calories: 180, carbs: 30, protein: 4, fats: 4, quantity: '1 glass'),
    FoodItem(name: 'Carrot Sticks with Hummus', calories: 130, carbs: 12, protein: 4, fats: 7, quantity: '½ cup'),
    FoodItem(name: 'Soy Nuts', calories: 160, carbs: 10, protein: 12, fats: 8, quantity: '½ cup'),
    FoodItem(name: 'Trail Mix', calories: 220, carbs: 18, protein: 5, fats: 14, quantity: '1 handful'),
    FoodItem(name: 'Besan Ladoo', calories: 140, carbs: 18, protein: 3, fats: 7, quantity: '1 piece'),
    FoodItem(name: 'Vegetable Sandwich', calories: 180, carbs: 25, protein: 5, fats: 6, quantity: '1 sandwich'),
    FoodItem(name: 'Upma (small portion)', calories: 150, carbs: 25, protein: 4, fats: 5, quantity: '1 small bowl'),
    FoodItem(name: 'Egg Roll (Mini)', calories: 200, carbs: 20, protein: 8, fats: 10, quantity: '1 roll'),
    FoodItem(name: 'Rice Idli', calories: 58, carbs: 12, protein: 2, fats: 0, quantity: '1 piece'),
    FoodItem(name: 'Cucumber Sandwich', calories: 120, carbs: 20, protein: 3, fats: 4, quantity: '2 slices'),
    FoodItem(name: 'Fruit Chaat', calories: 130, carbs: 25, protein: 2, fats: 1, quantity: '1 bowl'),
    FoodItem(name: 'Lassi (Sweet)', calories: 180, carbs: 25, protein: 6, fats: 6, quantity: '1 glass'),
    FoodItem(name: 'Cold Coffee (Low Sugar)', calories: 120, carbs: 14, protein: 4, fats: 4, quantity: '1 glass'),
    FoodItem(name: 'Rava Dhokla', calories: 160, carbs: 22, protein: 4, fats: 6, quantity: '3 pieces'),
    FoodItem(name: 'Vegetable Cutlet', calories: 150, carbs: 20, protein: 4, fats: 6, quantity: '1 piece'),
    FoodItem(name: 'Chikki with Jaggery', calories: 160, carbs: 22, protein: 3, fats: 7, quantity: '1 bar'),
    FoodItem(name: 'Milk (Low Fat)', calories: 100, carbs: 12, protein: 8, fats: 2, quantity: '1 glass'),
    FoodItem(name: 'Baked Samosa', calories: 180, carbs: 22, protein: 4, fats: 7, quantity: '1 piece'),
    FoodItem(name: 'Vegetable Wrap', calories: 200, carbs: 25, protein: 6, fats: 8, quantity: '1 wrap'),
    FoodItem(name: 'Roasted Soybeans', calories: 170, carbs: 10, protein: 14, fats: 8, quantity: '½ cup'),
  ];


  List<FoodItem> dinnerFoods = [
    FoodItem(name: 'Chapati with Sabzi', calories: 220, carbs: 30, protein: 5, fats: 7, quantity: '2 chapatis + sabzi'),
    FoodItem(name: 'Grilled Fish', calories: 250, carbs: 0, protein: 25, fats: 15, quantity: '1 fillet'),
    FoodItem(name: 'Moong Dal Khichdi', calories: 210, carbs: 35, protein: 7, fats: 4, quantity: '1 bowl'),
    FoodItem(name: 'Paneer Bhurji with Roti', calories: 320, carbs: 25, protein: 18, fats: 15, quantity: '1 bowl + 1 roti'),
    FoodItem(name: 'Brown Rice with Veg Curry', calories: 280, carbs: 38, protein: 6, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Quinoa with Stir Fry Veggies', calories: 300, carbs: 30, protein: 10, fats: 12, quantity: '1 bowl'),
    FoodItem(name: 'Grilled Tofu with Salad', calories: 240, carbs: 12, protein: 16, fats: 12, quantity: '1 plate'),
    FoodItem(name: 'Masoor Dal with Rice', calories: 290, carbs: 40, protein: 10, fats: 6, quantity: '1 cup rice + dal'),
    FoodItem(name: 'Vegetable Pulao', calories: 250, carbs: 35, protein: 6, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Palak Paneer with Chapati', calories: 330, carbs: 28, protein: 15, fats: 18, quantity: '1 bowl + 1 roti'),
    FoodItem(name: 'Mixed Vegetable Soup', calories: 100, carbs: 15, protein: 3, fats: 3, quantity: '1 bowl'),
    FoodItem(name: 'Stuffed Paratha with Curd', calories: 280, carbs: 30, protein: 6, fats: 12, quantity: '1 paratha + ½ cup curd'),
    FoodItem(name: 'Oats Khichdi', calories: 230, carbs: 32, protein: 6, fats: 6, quantity: '1 bowl'),
    FoodItem(name: 'Egg Curry with Rice', calories: 320, carbs: 25, protein: 14, fats: 16, quantity: '1 bowl curry + 1 cup rice'),
    FoodItem(name: 'Lauki Chana Dal', calories: 220, carbs: 22, protein: 9, fats: 7, quantity: '1 bowl'),
    FoodItem(name: 'Roti with Bhindi', calories: 200, carbs: 28, protein: 4, fats: 6, quantity: '2 rotis + bhindi'),
    FoodItem(name: 'Dal Tadka with Jeera Rice', calories: 300, carbs: 40, protein: 10, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Vegetable Handvo', calories: 240, carbs: 30, protein: 8, fats: 10, quantity: '1 slice'),
    FoodItem(name: 'Kadhi with Bajra Roti', calories: 280, carbs: 34, protein: 7, fats: 10, quantity: '1 roti + 1 bowl kadhi'),
    FoodItem(name: 'Tofu Curry with Quinoa', calories: 290, carbs: 25, protein: 15, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Bhakri with Thecha', calories: 270, carbs: 28, protein: 5, fats: 12, quantity: '1 bhakri + chutney'),
    FoodItem(name: 'Chicken Curry with Roti', calories: 340, carbs: 20, protein: 25, fats: 18, quantity: '1 bowl curry + 1 roti'),
    FoodItem(name: 'Biryani (Veg)', calories: 330, carbs: 42, protein: 8, fats: 12, quantity: '1 bowl'),
    FoodItem(name: 'Rajma with Brown Rice', calories: 350, carbs: 45, protein: 12, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Daliya (Broken Wheat Porridge)', calories: 250, carbs: 38, protein: 7, fats: 6, quantity: '1 bowl'),
    FoodItem(name: 'Besan Chilla with Salad', calories: 200, carbs: 18, protein: 10, fats: 8, quantity: '2 chillas'),
    FoodItem(name: 'Pumpkin Sabzi with Chapati', calories: 220, carbs: 26, protein: 4, fats: 7, quantity: '2 rotis + sabzi'),
    FoodItem(name: 'Cauliflower Stir Fry', calories: 180, carbs: 15, protein: 4, fats: 9, quantity: '1 bowl'),
    FoodItem(name: 'Boiled Egg Salad', calories: 160, carbs: 5, protein: 10, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Tomato Rasam with Rice', calories: 270, carbs: 35, protein: 6, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Sweet Potato with Curd', calories: 210, carbs: 30, protein: 5, fats: 4, quantity: '1 bowl + ½ cup curd'),
    FoodItem(name: 'Stuffed Capsicum', calories: 240, carbs: 20, protein: 8, fats: 10, quantity: '1 piece'),
    FoodItem(name: 'Paneer Tikka with Mint Chutney', calories: 280, carbs: 10, protein: 18, fats: 16, quantity: '1 serving'),
    FoodItem(name: 'Rice with Sambar', calories: 320, carbs: 45, protein: 10, fats: 6, quantity: '1 cup rice + sambar'),
    FoodItem(name: 'Cabbage Sabzi with Chapati', calories: 200, carbs: 26, protein: 4, fats: 6, quantity: '2 rotis + sabzi'),
    FoodItem(name: 'Vegetable Thepla with Dahi', calories: 260, carbs: 30, protein: 6, fats: 10, quantity: '1 thepla + curd'),
    FoodItem(name: 'Grilled Mushroom Skewers', calories: 180, carbs: 8, protein: 6, fats: 12, quantity: '1 skewer'),
    FoodItem(name: 'Beetroot Sabzi with Roti', calories: 210, carbs: 25, protein: 4, fats: 7, quantity: '1 bowl'),
    FoodItem(name: 'Spinach Dal with Rice', calories: 280, carbs: 35, protein: 10, fats: 8, quantity: '1 bowl'),
    FoodItem(name: 'Lentil Soup with Toast', calories: 220, carbs: 30, protein: 10, fats: 5, quantity: '1 bowl + 1 toast'),
    FoodItem(name: 'Tinda Curry with Chapati', calories: 200, carbs: 24, protein: 5, fats: 6, quantity: '2 rotis + sabzi'),
    FoodItem(name: 'Egg Bhurji with Roti', calories: 270, carbs: 20, protein: 14, fats: 14, quantity: '1 bowl + 1 roti'),
    FoodItem(name: 'Chana Masala with Rice', calories: 340, carbs: 45, protein: 12, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Karela Sabzi with Roti', calories: 190, carbs: 20, protein: 5, fats: 7, quantity: '2 rotis + sabzi'),
    FoodItem(name: 'Vegetable Stew with Appam', calories: 330, carbs: 35, protein: 6, fats: 14, quantity: '1 bowl + 1 appam'),
    FoodItem(name: 'Zucchini Stir Fry', calories: 170, carbs: 12, protein: 3, fats: 10, quantity: '1 bowl'),
    FoodItem(name: 'Low Carb Paneer Bowl', calories: 240, carbs: 8, protein: 18, fats: 14, quantity: '1 bowl'),
    FoodItem(name: 'Stuffed Tomato', calories: 220, carbs: 18, protein: 6, fats: 10, quantity: '1 tomato'),
    FoodItem(name: 'Vegetable Rava Upma', calories: 230, carbs: 32, protein: 5, fats: 8, quantity: '1 bowl'),
  ];




  String type = "";





  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    type = argument['value'];
  if(type == "Breakfast" || type == "BreakFast")
      {
        filteredItems = breakfastFoods;
      }else if(type == "Lunch")
        {
          filteredItems = lunchFoods;
        }else if(type == "snack(s)")
        {
          filteredItems = snackFoods;
        }else{
      filteredItems = dinnerFoods;
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

    final runFilter = () {
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
          filteredItems = breakfastFoods.where((item) => item.name.toLowerCase().contains(q)).toList();
        } else if (type == "Lunch") {
          filteredItems = lunchFoods.where((item) => item.name.toLowerCase().contains(q)).toList();
        } else if (type == "snack(s)") {
          filteredItems = snackFoods.where((item) => item.name.toLowerCase().contains(q)).toList();
        } else {
          filteredItems = dinnerFoods.where((item) => item.name.toLowerCase().contains(q)).toList();
        }
      }

      // filter completed
      isFiltering = false;
      update();
    };

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

  addSqlData(String type,FoodItem item) async {
    dbHelper.insertCalorieHistory(
      CalorieHistoryModel(
        calorie: item.calories,
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        protein: item.protein,
        carbs: item.carbs,
        fats: item.fats,
        type: type,
      ),
    );
  }

  onAddButton(BuildContext context,FoodItem item) async {
    List<SqlCalorieModel> calorieData = await dbHelper.getCalorieData();
    addSqlData(type,item);

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
        if (calorieData.last.calorie + item.calories > ConstantUserMaster.calorieGoal) {
          showCalorieCompleteDialog(context, calorieData,item);
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
      FoodItem item
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
            "You've completed your calorie goal for today. Would you like to add more?".tr,
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
}
