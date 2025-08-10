import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/Model/CalorieHistoryModel.dart';
import 'package:foodcalorietracker/Model/SqlCalorieModel.dart';
import 'package:foodcalorietracker/NetworkHelp/openAiCalling.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../Model/SqlDailyCalorieModel.dart';

class ScanCalorieController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  late File image;
  int quantity = 1;
  String response = "";
  String type = "";
  bool isLoading = true;
  int calorie = 0;
  int calorieQuantity = 0;
  int protein = 0;
  int proteinQuantity = 0;
  int carbs = 0;
  int carbsQuantity = 0;
  int fats = 0;
  int fatsQuantity = 0;
  final dbHelper = DatabaseHelper();

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    image = argument['image'];
    type = argument['type'];
    await OpenAiCalling.sentImageApi(image).then((value) {
      response = value;
      log('RAW_AI_RESPONSE => ' + response);
      Map<String, int> nutrition = parseNutrition(response);
      log('PARSED_NUTRITION => ' + nutrition.toString());
      calorie = nutrition["calories"] ?? 0;
      calorieQuantity = calorie;
      protein = nutrition["protein"] ?? 0;
      proteinQuantity = protein;
      carbs = nutrition["carbs"] ?? 0;
      carbsQuantity = carbs;
      fats = nutrition["fat"] ?? 0;
      fatsQuantity = fats;
    });
    isLoading = false;
    update();
  }


  incrementQuantity() {
    quantity++;
    changeQuantity();
    update();
  }

  decrementQuantity() {
    if (quantity > 0) {
      quantity--;
    }
    changeQuantity();
    update();
  }

  changeQuantity() {
    calorieQuantity = calorie * quantity;
    proteinQuantity = protein * quantity;
    carbsQuantity = carbs * quantity;
    fatsQuantity = fats * quantity;
  }

  onAddButton(BuildContext context) async {
    List<SqlCalorieModel> calorieData = await dbHelper.getCalorieData();
    addSqlData(type);
    if (calorieData.isEmpty) {
      int id = await dbHelper.insertCalorie(
        SqlCalorieModel(
          date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          totalGoal: ConstantUserMaster.calorieGoal,
          calorie: calorieQuantity,
          protein: proteinQuantity,
          carbs: carbsQuantity,
          fats: fatsQuantity,
        ),
      );
      await dbHelper.insertDailyWater(
        DailyCalorieModel(
          date: DateTime.now().toString(),
          time: DateFormat('hh:mm a').format(DateTime.now()),
          calorie: calorieQuantity,
          calorieId: id,
        ),
      );
      Get.offAllNamed(Routes.leadingView);
    } else {
      if (calorieData.last.date ==
          DateFormat('dd-MM-yyyy').format(DateTime.now())) {
        if (calorieData.last.calorie + calorieQuantity >
            ConstantUserMaster.calorieGoal) {
          showCalorieCompleteDialog(context, calorieData);
        } else {
          print("Hello This Is Update Data $calorieQuantity");
          await dbHelper.updateCalorie(
            SqlCalorieModel(
              id: calorieData.last.id,
              date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
              totalGoal: ConstantUserMaster.calorieGoal,
              calorie: calorieData.last.calorie + calorieQuantity,
              protein: calorieData.last.protein + proteinQuantity,
              carbs: calorieData.last.carbs + carbsQuantity,
              fats: calorieData.last.fats + fatsQuantity,
            ),
          );
          await dbHelper.insertDailyWater(
            DailyCalorieModel(
              date: DateTime.now().toString(),
              time: DateFormat('hh:mm a').format(DateTime.now()),
              calorie: calorieData.last.calorie + calorieQuantity,
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
            calorie: calorieQuantity,
            protein: proteinQuantity,
            carbs: carbsQuantity,
            fats: fatsQuantity,
          ),
        );
        await dbHelper.insertDailyWater(
          DailyCalorieModel(
            date: DateTime.now().toString(),
            time: DateFormat('hh:mm a').format(DateTime.now()),
            calorie: calorieQuantity,
            calorieId: id,
          ),
        );
        Get.offAllNamed(Routes.leadingView);
      }
    }

  }

  Map<String, int> extractNutritionalValues(String text) {
    RegExp calorieRegex = RegExp(r'Calories:\s*(\d+)');
    RegExp proteinRegex = RegExp(r'Protein:\s*(\d+)g');
    RegExp carbsRegex = RegExp(r'Carbohydrates:\s*(\d+)g');
    RegExp fatRegex = RegExp(r'Fats:\s*(\d+)g');

    int extractValue(RegExp regex, String text) {
      Match? match = regex.firstMatch(text);
      if (match != null) {
        String numeric = match.group(1)!;
        numeric = numeric.replaceAll(',', ''); // Remove commas
        return int.parse(numeric);
      }
      return 0;
    }

    return {
      "calories": extractValue(calorieRegex, text),
      "protein": extractValue(proteinRegex, text),
      "carbs": extractValue(carbsRegex, text),
      "fat": extractValue(fatRegex, text),
    };
  }

  // New: Try JSON first, fallback to legacy regex
  Map<String,int> parseNutrition(String text){
    // Attempt strict JSON parse
    try{
      final trimmed = text.trim();
      if(trimmed.startsWith('{') && trimmed.endsWith('}')){
        dynamic data;
        try { data = jsonDecode(trimmed); } catch(_){ data = null; }
        if(data is Map<String,dynamic>){
          int toInt(dynamic v){
            if(v==null) return 0; if(v is int) return v; if(v is double) return v.round();
            if(v is String){ return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'),'')) ?? 0; }
            return 0;
          }
          final calories = toInt(data['calories']);
          final protein  = toInt(data['protein_g']);
          final carbs    = toInt(data['carbohydrates_g']);
            final fats     = toInt(data['fats_g']);
          if([calories,protein,carbs,fats].any((e)=> e>0)){
            return {
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fats,
            };
          }
        }
      }
    }catch(e){
      log('JSON_PARSE_FAIL => $e');
    }
    // Fallback regex method
    return extractNutritionalValues(text);
  }

  addSqlData(String type) async {
    var imageData = await saveImageToFile(image.path);
    dbHelper.insertCalorieHistory(
      CalorieHistoryModel(
        calorie: calorieQuantity,
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        protein: proteinQuantity,
        carbs: carbsQuantity,
        image: imageData,
        fats: fats,
        type: type,
      ),
    );
  }

  Future<String?> saveImageToFile(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    File file = File(filePath);

    Uint8List? imageData = await fileToBytes(imagePath);

    if (imageData == null) {
      print("Error: Image data is null");
      return null; // Return null if image data is null
    }

    await file.writeAsBytes(imageData);
    return filePath; // Store this path in the database
  }

  Future<Uint8List?> fileToBytes(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null; // Return null if filePath is null or empty.
    }

    final file = File(filePath);

    if (await file.exists()) {
      return await file.readAsBytes(); // Read and return the bytes if the file exists.
    } else {
      print("Error: File does not exist");
      return null; // Return null if the file does not exist.
    }
  }

  showCalorieCompleteDialog(
    BuildContext context,
    List<SqlCalorieModel> calorieData,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.cardColor,
          title: Text(
            "🎯 Calorie Goal Reached",
            style: context.textTheme.headlineMedium,
          ),
          content: Text(
            "You've completed your calorie goal for today. Would you like to add more?",
            style: context.textTheme.titleSmall,
          ),
          actions: [
            TextButton(
              child: Text(
                "Done",
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
                    calorie: calorieData.last.calorie + calorieQuantity,
                    protein: calorieData.last.protein + proteinQuantity,
                    carbs: calorieData.last.carbs + carbsQuantity,
                    fats: calorieData.last.fats + fatsQuantity,
                  ),
                );
                await dbHelper.insertDailyWater(
                  DailyCalorieModel(
                    date: DateTime.now().toString(),
                    time: DateFormat('hh:mm a').format(DateTime.now()),
                    calorie: calorieData.last.calorie + calorieQuantity,
                    calorieId: calorieData.last.id!,
                  ),
                );

                Get.offAllNamed(Routes.leadingView);
              },
              child: Text(
                "Add More Calories",
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
