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
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../Model/SqlDailyCalorieModel.dart';

class ScanCalorieController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  late File image;
  // Minimum and maximum quantity constants for easy future tuning
  static const int kMinQuantity = 1;
  static const int kMaxQuantity = 100; // safe default upper bound

  int quantity = kMinQuantity;
  String response = "";
  String type = "";
  String mealName = "";
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

  String get displayMealName => localizeMealName(mealName.isNotEmpty ? mealName : type);

  String buildMealDescription() {
    final cal = _fmt(calorieQuantity);
    final protein = _fmt(proteinQuantity);
    final carbs = _fmt(carbsQuantity);
    final fat = _fmt(fatsQuantity);
    
    final containsText = 'meal_contains'.tr;
    final calUnit = 'kcal_unit'.tr;
    final proteinUnit = 'protein_unit'.tr;
    final carbsUnit = 'carbs_unit'.tr;
    final fatUnit = 'fat_unit'.tr;
    final andWord = 'conjunction_and'.tr;
    
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';
    
    if (currentLang == 'ar') {
      // Arabic: improved structure with proper conjunction usage
      return '$containsText $cal $calUnit، $protein $proteinUnit من البروتين، $carbs $carbsUnit من الكربوهيدرات، $andWord $fat $fatUnit من الدهون.';
    } else if (currentLang == 'fr') {
      // French: improved structure with proper conjunction usage  
      return '$containsText $cal $calUnit, $protein $proteinUnit de protéines, $carbs $carbsUnit de glucides $andWord $fat $fatUnit de lipides.';
    } else {
      // English: improved structure with proper conjunction usage
      return '$containsText $cal $calUnit, $protein $proteinUnit protein, $carbs $carbsUnit carbs $andWord $fat $fatUnit fat.';
    }
  }


  String _fmt(int v) {
    final locale = Get.locale?.toString();
    final nf = NumberFormat.decimalPattern(locale);
    return nf.format(v);
  }


  String localizeMealName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return type.tr;
    
    // First, try direct translation lookup
    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
        
    final candidateKeys = <String>[
      'foods.$normalized', // preferred namespace for food items
      normalized,          // direct key
      trimmed,             // as-is key
    ];
    
    for (final key in candidateKeys) {
      final translated = key.tr;
      if (translated != key) return translated; // found a translation
    }
    
    // If no direct translation, attempt AI-powered translation
    return _translateMealName(trimmed);
  }

  String _translateMealName(String originalName) {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';
    
    // If already in English or no translation needed, return as-is
    if (currentLang == 'en') return originalName;
    
    // For Arabic and French, provide context-aware translations
    // This would ideally be powered by AI, but for now we'll use pattern matching
    // and common food name translations
    
    if (currentLang == 'ar') {
      return _translateToArabic(originalName);
    } else if (currentLang == 'fr') {
      return _translateToFrench(originalName);
    }
    
    return originalName; // fallback to original
  }

  String _translateToArabic(String name) {
    final lowerName = name.toLowerCase();
    
    // Common food translations to Arabic
    final arabicTranslations = {
      'chicken': 'دجاج',
      'rice': 'أرز',
      'beef': 'لحم بقر',
      'fish': 'سمك',
      'bread': 'خبز',
      'egg': 'بيض',
      'pasta': 'مكرونة',
      'pizza': 'بيتزا',
      'salad': 'سلطة',
      'soup': 'شوربة',
      'burger': 'برجر',
      'sandwich': 'شطيرة',
      'apple': 'تفاح',
      'banana': 'موز',
      'orange': 'برتقال',
      'vegetable': 'خضروات',
      'meat': 'لحم',
      'cheese': 'جبن',
      'milk': 'حليب',
      'yogurt': 'زبادي',
      'curry': 'كاري',
      'steak': 'ستيك',
      'grilled': 'مشوي',
      'fried': 'مقلي',
      'roasted': 'محمص',
      'baked': 'مخبوز',
    };
    
    // Try exact matches first
    if (arabicTranslations.containsKey(lowerName)) {
      return arabicTranslations[lowerName]!;
    }
    
    // Try partial matches for compound food names
    for (final entry in arabicTranslations.entries) {
      if (lowerName.contains(entry.key)) {
        return name.replaceAll(
          RegExp(entry.key, caseSensitive: false), 
          entry.value
        );
      }
    }
    
    return name; // fallback to original
  }

  String _translateToFrench(String name) {
    final lowerName = name.toLowerCase();
    
    // Common food translations to French
    final frenchTranslations = {
      'chicken': 'poulet',
      'rice': 'riz',
      'beef': 'bœuf',
      'fish': 'poisson',
      'bread': 'pain',
      'egg': 'œuf',
      'pasta': 'pâtes',
      'pizza': 'pizza',
      'salad': 'salade',
      'soup': 'soupe',
      'burger': 'burger',
      'sandwich': 'sandwich',
      'apple': 'pomme',
      'banana': 'banane',
      'orange': 'orange',
      'vegetable': 'légume',
      'meat': 'viande',
      'cheese': 'fromage',
      'milk': 'lait',
      'yogurt': 'yaourt',
      'curry': 'curry',
      'steak': 'steak',
      'grilled': 'grillé',
      'fried': 'frit',
      'roasted': 'rôti',
      'baked': 'cuit au four',
    };
    
    // Try exact matches first
    if (frenchTranslations.containsKey(lowerName)) {
      return frenchTranslations[lowerName]!;
    }
    
    // Try partial matches for compound food names
    for (final entry in frenchTranslations.entries) {
      if (lowerName.contains(entry.key)) {
        return name.replaceAll(
          RegExp(entry.key, caseSensitive: false), 
          entry.value
        );
      }
    }
    
    return name; // fallback to original
  }

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    image = argument['image'];
    type = argument['type'];
    await OpenAiCalling.sentImageApi(image).then((value) async {
      response = value;
      log('RAW_AI_RESPONSE => ' + response);
      Map<String, dynamic> parsed = parseNutritionWithName(response);
      Map<String, int> nutrition = {
        'calories': parsed['calories'] ?? 0,
        'protein': parsed['protein'] ?? 0,
        'carbs': parsed['carbs'] ?? 0,
        'fat': parsed['fat'] ?? 0,
      };
      
      mealName = (parsed['food_name'] as String?)?.trim() ?? '';
      
      log('PARSED_NUTRITION => ' + nutrition.toString());
      log('AI_MEAL_NAME => ' + mealName);
      
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


  /// Set quantity with validation (clamped between kMinQuantity and kMaxQuantity)
  void setQuantity(int q, {bool notify = true}) {
    final newQ = q.clamp(kMinQuantity, kMaxQuantity);
    if (newQ == quantity) return; // no-op if unchanged
    quantity = newQ;
    _recalculateTotals();
    if (notify) update();
  }

  void incrementQuantity() {
    if (quantity >= kMaxQuantity) {
      // Inform user they reached maximum allowed quantity
      try {
        Fluttertoast.showToast(
          msg: "Maximum quantity reached",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (_) {}
      return;
    }
    setQuantity(quantity + 1);
  }

  void decrementQuantity() {
    // ensure we never go below the minimum
    setQuantity(quantity - 1);
  }

  void _recalculateTotals() {
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

  // New: Try JSON first, fallback to legacy regex. Also parse optional food_name.
  Map<String,dynamic> parseNutritionWithName(String text){

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
          final name = (data['food_name'] is String) ? (data['food_name'] as String) : '';
          return {
            'food_name': name,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fats,
          };
        }
      }
    }catch(e){
      log('JSON_PARSE_FAIL => $e');
    }
    // Fallback regex method
    final vals = extractNutritionalValues(text);
    return {
      'food_name': '',
      ...vals,
    };
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
            "Calorie Goal Reached",
            style: context.textTheme.headlineMedium,
          ),
          content: Text(
            "You've completed your calorie goal for today. Would you like to add more?",
            style: context.textTheme.titleSmall,
          ),
          actions: [
            TextButton(
              child: Text(
                "Done".tr,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.theme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                "Add More Calories".tr,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.theme.focusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
