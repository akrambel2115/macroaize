import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/Model/calorie_history_model.dart';
import 'package:macroaize/Model/sql_calorie_model.dart';
import 'package:macroaize/NetworkHelp/open_ai_calling.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../Model/sql_daily_calorie_model.dart';
import '../../shared/services/usda_api_service.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/widgets/meal_share_card.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../Model/meal_breakdown_item.dart';
import '../../shared/services/rate_us_service.dart';
import '../../shared/services/widget_promotion_service.dart';
import '../../shared/services/streak_service.dart';
import '../../shared/services/meal_sync_service.dart';
import '../../shared/services/local_notification_service.dart';

enum ScanUnit { unit, gram, ml, cup }

class ScanCalorieController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  File? image;
  static const int kMinQuantity = 1;
  static const int kMaxQuantity = 100;

  // unit selection
  ScanUnit selectedUnit = ScanUnit.unit;
  double customAmount = 1.0;
  double totalNetWeight = 100.0;
  String netWeightUnit = 'g';
  bool isBarcode = false;

  // quantity multiplier
  int quantity = kMinQuantity;
  String response = "";
  String type = "";
  String mealName = "";
  String mealNameEnglish = "";
  bool isLoading = true;
  int calorie = 0;
  int calorieQuantity = 0;
  double protein = 0.0;
  double proteinQuantity = 0.0;
  double carbs = 0.0;
  double carbsQuantity = 0.0;
  double fats = 0.0;
  double fatsQuantity = 0.0;
  final dbHelper = DatabaseHelper();
  int? usdaFdcId;
  bool usdaVerified = false;
  final UsdaApiService _usda = UsdaApiService();
  ScreenshotController screenshotController = ScreenshotController();

  MealShareCard? shareCard;
  List<UsdaFood> usdaOptions = const [];

  final List<MealBreakdownItem> items = [];

  bool get hasBreakdown => items.isNotEmpty;

  int get totalKcalFromItems =>
      items.fold(0, (sum, it) => sum + it.kcal.round());
  int get totalProteinFromItems =>
      items.fold(0, (sum, it) => sum + it.protein.round());
  int get totalCarbsFromItems =>
      items.fold(0, (sum, it) => sum + it.carbs.round());
  int get totalFatFromItems => items.fold(0, (sum, it) => sum + it.fat.round());

  String get displayMealName =>
      localizeMealName(mealName.isNotEmpty ? mealName : type);

  String buildMealDescription() {
    final cal = _fmt(calorieQuantity);
    final protein = _fmt(proteinQuantity.round());
    final carbs = _fmt(carbsQuantity.round());
    final fat = _fmt(fatsQuantity.round());

    final containsText = 'meal_contains'.tr;
    final calUnit = 'kcal_unit'.tr;
    final proteinUnit = 'protein_unit'.tr;
    final carbsUnit = 'carbs_unit'.tr;
    final fatUnit = 'fat_unit'.tr;
    final andWord = 'conjunction_and'.tr;

    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';

    if (currentLang == 'ar') {
      return '$containsText $cal $calUnit، $protein $proteinUnit من البروتين، $carbs $carbsUnit من الكربوهيدرات، $andWord $fat $fatUnit من الدهون.';
    } else if (currentLang == 'fr') {
      return '$containsText $cal $calUnit, $protein $proteinUnit de protéines, $carbs $carbsUnit de glucides $andWord $fat $fatUnit de lipides.';
    } else {
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

    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final candidateKeys = <String>['foods.$normalized', normalized, trimmed];

    for (final key in candidateKeys) {
      final translated = key.tr;
      if (translated != key) return translated;
    }

    return _translateMealName(trimmed);
  }

  String _translateMealName(String originalName) {
    final currentLang = Get.locale?.languageCode.toLowerCase() ?? 'en';

    if (currentLang == 'en') return originalName;

    if (currentLang == 'ar') {
      return _translateToArabic(originalName);
    } else if (currentLang == 'fr') {
      return _translateToFrench(originalName);
    }

    return originalName;
  }

  String _translateToArabic(String name) {
    final lowerName = name.toLowerCase();

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

    if (arabicTranslations.containsKey(lowerName)) {
      return arabicTranslations[lowerName]!;
    }

    for (final entry in arabicTranslations.entries) {
      if (lowerName.contains(entry.key)) {
        return name.replaceAll(
          RegExp(entry.key, caseSensitive: false),
          entry.value,
        );
      }
    }

    return name;
  }

  String _translateToFrench(String name) {
    final lowerName = name.toLowerCase();

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

    if (frenchTranslations.containsKey(lowerName)) {
      return frenchTranslations[lowerName]!;
    }

    for (final entry in frenchTranslations.entries) {
      if (lowerName.contains(entry.key)) {
        return name.replaceAll(
          RegExp(entry.key, caseSensitive: false),
          entry.value,
        );
      }
    }

    return name;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    image = argument['image'];
    image = argument['image'];
    type = argument['type'] ?? argument['isIdentify'] ?? '';

    if (argument['fromBarcode'] == true || argument['calorie'] != null) {
      isBarcode = true;
      mealName = argument['name'] ?? 'Unknown';
      mealNameEnglish = mealName;

      calorie = (argument['calorie'] as num?)?.toInt() ?? 0;
      protein = (argument['protein'] as num?)?.toDouble() ?? 0.0;
      carbs = (argument['carbs'] as num?)?.toDouble() ?? 0.0;
      fats = (argument['fats'] as num?)?.toDouble() ?? 0.0;

      final rawWeight = argument['netWeight'];
      if (rawWeight != null) {
        if (rawWeight is num) {
          totalNetWeight = rawWeight.toDouble();
        } else if (rawWeight is String) {
          totalNetWeight = double.tryParse(rawWeight) ?? 100.0;
        }
      }

      netWeightUnit = (argument['unit'] as String?) ?? 'g';

      selectedUnit = ScanUnit.unit;
      customAmount = 1.0;

      _recalculateTotals();
      isLoading = false;
      update();
      return;
    }

    if (image != null) {
      final itemsJsonStr = await OpenAiCalling.analyzeMealItems(image!);
      final parsedItems = _parseMealItems(itemsJsonStr);
      if (parsedItems.isNotEmpty) {
        await _enrichItemsWithUsda(parsedItems);
        items
          ..clear()
          ..addAll(parsedItems);

        calorie = totalKcalFromItems;
        protein = totalProteinFromItems.toDouble();
        carbs = totalCarbsFromItems.toDouble();
        fats = totalFatFromItems.toDouble();
        _recalculateTotals();
        mealName = _buildCompositeName(parsedItems);
        mealNameEnglish = mealName;
        usdaVerified = items.every((it) => it.usdaVerified);
      } else {
        await OpenAiCalling.sentImageApi(image!).then((value) async {
          response = value;
          log('RAW_AI_RESPONSE => $response');
          Map<String, dynamic> parsed = parseNutritionWithName(response);
          Map<String, int> nutrition = {
            'calories': parsed['calories'] ?? 0,
            'protein': parsed['protein'] ?? 0,
            'carbs': parsed['carbs'] ?? 0,
            'fat': parsed['fat'] ?? 0,
          };

          mealName = (parsed['food_name'] as String?)?.trim() ?? '';
          mealNameEnglish =
              (parsed['food_name_english'] as String?)?.trim() ?? '';

          calorie = nutrition["calories"] ?? 0;
          calorieQuantity = calorie;
          protein = (nutrition["protein"] as num?)?.toDouble() ?? 0.0;
          proteinQuantity = protein;
          carbs = (nutrition["carbs"] as num?)?.toDouble() ?? 0.0;
          carbsQuantity = carbs;
          fats = (nutrition["fat"] as num?)?.toDouble() ?? 0.0;
          fatsQuantity = fats;
        });

        try {
          String searchName =
              mealNameEnglish.trim().isNotEmpty
                  ? mealNameEnglish.trim()
                  : mealName.trim();
          if (searchName.isNotEmpty) {
            log('USDA_SEARCH => Searching for: "$searchName"');
            final results = await _usda.searchFood(searchName, limit: 3);
            log('USDA_RESULTS => Found ${results.length} results');
            if (results.isNotEmpty) {
              for (int i = 0; i < results.length; i++) {
                log(
                  'USDA_RESULT_$i => ${results[i].description} (${results[i].calories} cal)',
                );
              }
              usdaOptions = results;
              final UsdaFood picked = results.first;
              usdaFdcId = picked.fdcId;
              usdaVerified = true;
              log('USDA_VERIFIED => Using: ${picked.description}');
              calorie = picked.calories.round();
              calorieQuantity = calorie * quantity;
              protein = picked.protein.toDouble();
              proteinQuantity = protein * quantity;
              carbs = picked.carbs.toDouble();
              carbsQuantity = carbs * quantity;
              fats = picked.fats.toDouble();
              fatsQuantity = fats * quantity;
            } else {
              log('USDA_NO_RESULTS => No results found for: "$searchName"');
              usdaVerified = false;
            }
          } else {
            log('USDA_NO_MEAL_NAME => No meal name to search');
            usdaVerified = false;
          }
        } catch (e) {
          log('USDA_ERROR => $e');
          usdaVerified = false;
          try {
            NotificationService.showInfo(
              "Couldn't fetch USDA data, using AI estimation instead.",
            );
          } catch (_) {}
        }
      }
    }
    isLoading = false;
    update();
  }

  String _buildCompositeName(List<MealBreakdownItem> list) {
    if (list.isEmpty) return '';
    final parts = list.take(3).map((e) => e.name).toList();
    final extra = list.length > 3 ? ' +${list.length - 3}' : '';
    return parts.join(', ') + extra;
  }

  List<MealBreakdownItem> _parseMealItems(String text) {
    try {
      String raw = text.trim();
      if (raw.isEmpty) return [];

      if (raw.contains('```')) {
        final start = raw.indexOf('```');
        final end = raw.lastIndexOf('```');
        if (end > start) {
          raw = raw.substring(start + 3, end).trim();
          if (raw.startsWith('json')) {
            raw = raw.substring(4).trimLeft();
          }
        }
      }

      if (raw.startsWith('[') && raw.endsWith(']')) {
        raw = '{"mealItems": $raw}';
      }

      if (!(raw.startsWith('{') && raw.endsWith('}'))) {
        final mealIdx = raw.indexOf('mealItems');
        if (mealIdx != -1) {
          final braceStart = raw.lastIndexOf('{', mealIdx);
          final braceEnd = raw.indexOf('}', mealIdx);
          if (braceStart != -1 && braceEnd != -1 && braceEnd > braceStart) {
            raw = raw.substring(braceStart, braceEnd + 1);
          }
        }
      }

      final dynamic decoded = jsonDecode(raw);
      final List list =
          (decoded is Map)
              ? (decoded['mealItems'] as List? ?? const [])
              : (decoded is List ? decoded : const []);

      final result =
          list.map<MealBreakdownItem>((it) {
            final name = (it['name'] ?? '').toString();
            final en = (it['english_name'] ?? '').toString();
            final portionType = (it['portionType'] ?? '').toString();
            final count = (it['count'] ?? 1);
            final doubleCount =
                (count is num)
                    ? count.toDouble()
                    : double.tryParse(count.toString()) ?? 1.0;
            final ew = (it['estimatedWeight'] ?? 0);
            final estimatedWeight =
                (ew is num)
                    ? ew.toDouble()
                    : double.tryParse(ew.toString()) ?? 0.0;

            String estimatedAmount;
            if (portionType == 'pieces' && doubleCount > 0) {
              estimatedAmount = '${doubleCount.toInt()} pieces';
            } else {
              estimatedAmount = '${estimatedWeight.toInt()}g';
            }

            var item = MealBreakdownItem.fromBasic(
              name: name,
              englishName: en.isNotEmpty ? en : name,
              estimatedAmount: estimatedAmount,
            );
            if (estimatedWeight > 0) {
              item = item.copyWith(grams: estimatedWeight);
            }
            // Safety: never allow grams=0 — default to 100g
            if (item.grams <= 0) {
              item = item.copyWith(grams: 100.0);
            }
            return item;
          }).toList();

      log('ITEMS_PARSED => ${result.length} item(s)');
      return result;
    } catch (e) {
      log('ITEMS_PARSE_FAIL => $e');
      return [];
    }
  }

  Future<void> _enrichItemsWithUsda(List<MealBreakdownItem> list) async {
    for (var i = 0; i < list.length; i++) {
      var it = list[i];
      // Ensure grams > 0 before any nutrition calc
      if (it.grams <= 0) {
        it = it.copyWith(grams: 100.0);
        list[i] = it;
      }
      try {
        final results = await _usda.searchFood(it.englishName, limit: 1);
        if (results.isNotEmpty) {
          final r = results.first;
          final updated =
              it
                  .copyWith(
                    fdcId: r.fdcId,
                    usdaVerified: true,
                    kcalPer100g: r.calories,
                    proteinPer100g: r.protein,
                    carbsPer100g: r.carbs,
                    fatPer100g: r.fats,
                  )
                  .recalcFromPer100g();
          list[i] = updated;
        } else {
          // USDA returned no results — try AI estimation fallback
          list[i] = await _applyAiFallback(it);
        }
      } catch (e) {
        log('USDA_ERROR for ${it.englishName} => $e');
        // USDA call failed — try AI estimation fallback
        list[i] = await _applyAiFallback(it);
      }
    }
  }

  /// AI-based nutrition fallback when USDA returns no results or errors.
  Future<MealBreakdownItem> _applyAiFallback(MealBreakdownItem it) async {
    // Ensure grams > 0 before any recalc — default to 100g
    if (it.grams <= 0) {
      it = it.copyWith(grams: 100.0);
    }

    // Hardcoded fallback for common items
    final nameLower = it.englishName.toLowerCase();
    if (nameLower.contains('egg')) {
      log('USDA_FALLBACK => applied egg fallback for ${it.englishName}');
      return it
          .copyWith(
            usdaVerified: false,
            kcalPer100g: 146.0,
            proteinPer100g: 12.0,
            carbsPer100g: 1.1,
            fatPer100g: 10.0,
          )
          .recalcFromPer100g();
    }

    // Try AI estimation
    try {
      final aiNutrition = await OpenAiCalling.estimateNutritionByName(
        it.englishName,
        it.grams,
      );
      if (aiNutrition != null &&
          (aiNutrition['kcalPer100g'] ?? 0) > 0) {
        log('AI_FALLBACK => estimated nutrition for ${it.englishName}: $aiNutrition');
        return it
            .copyWith(
              usdaVerified: false,
              kcalPer100g: aiNutrition['kcalPer100g']!,
              proteinPer100g: aiNutrition['proteinPer100g']!,
              carbsPer100g: aiNutrition['carbsPer100g']!,
              fatPer100g: aiNutrition['fatPer100g']!,
            )
            .recalcFromPer100g();
      }
    } catch (e) {
      log('AI_FALLBACK_ERROR for ${it.englishName} => $e');
    }

    // Last resort: mark as estimated with no data
    log('NO_NUTRITION_DATA for ${it.englishName} — all zeros');
    return it.copyWith(usdaVerified: false).recalcFromPer100g();
  }

  // item editing
  void updateItemAmount(int index, double newAmount, String unit) {
    if (index < 0 || index >= items.length) return;
    final it = items[index];
    double grams = it.grams;
    switch (unit) { 
      case 'piece':
      case 'pieces':
        grams = newAmount * 50;
        break;
      default:
        grams = newAmount;
    }
    final updated =
        it
            .copyWith(amount: newAmount, unit: unit, grams: grams)
            .recalcFromPer100g();
    items[index] = updated;
    _recalcFromItems();
  }

  void _recalcFromItems() {
    calorie = totalKcalFromItems;
    protein = totalProteinFromItems.toDouble();
    carbs = totalCarbsFromItems.toDouble();
    fats = totalFatFromItems.toDouble();
    _recalculateTotals();
    update();
  }

  /// set quantity with validation
  void setQuantity(int q, {bool notify = true}) {
    final newQ = q.clamp(kMinQuantity, kMaxQuantity);
    if (newQ == quantity) return;
    quantity = newQ;
    _recalculateTotals();
    if (notify) update();
  }

  void incrementQuantity() {
    if (quantity >= kMaxQuantity) {
      try {
        NotificationService.showInfo(
          "Maximum quantity reached",
        );
      } catch (_) {}
      return;
    }
    setQuantity(quantity + 1);
  }

  void decrementQuantity() {
    setQuantity(quantity - 1);
  }

  void _recalculateTotals() {
    if (isBarcode) {
      double multiplier = 0.0;

      switch (selectedUnit) {
        case ScanUnit.unit:
          multiplier = (totalNetWeight * customAmount) / 100.0;
          break;

        case ScanUnit.gram:
        case ScanUnit.ml:
          multiplier = customAmount / 100.0;
          break;

        case ScanUnit.cup:
          multiplier = (240.0 * customAmount) / 100.0;
          break;
      }

      calorieQuantity = (calorie * multiplier).round();
      proteinQuantity = protein * multiplier;
      carbsQuantity = carbs * multiplier;
      fatsQuantity = fats * multiplier;
    } else {
      calorieQuantity = (calorie * quantity).round();
      proteinQuantity = protein * quantity;
      carbsQuantity = carbs * quantity;
      fatsQuantity = fats * quantity;
    }
  }

  void setUnit(ScanUnit unit) {
    selectedUnit = unit;
    switch (unit) {
      case ScanUnit.unit:
        customAmount = 1.0;
        break;
      case ScanUnit.gram:
      case ScanUnit.ml:
        customAmount = totalNetWeight;
        break;
      case ScanUnit.cup:
        customAmount = 1.0;
        break;
    }
    _recalculateTotals();
    update();
  }

  void updateCustomAmount(double val) {
    if (selectedUnit == ScanUnit.unit || selectedUnit == ScanUnit.cup) {
      customAmount = (val * 4).round() / 4;
    } else {
      customAmount = val;
    }
    _recalculateTotals();
    update();
  }

  void incrementCustomAmount() {
    if (customAmount >= 20.0) return;
    customAmount = (customAmount + 0.25).clamp(0.25, 20.0);
    _recalculateTotals();
    update();
  }

  void decrementCustomAmount() {
    if (customAmount <= 0.25) return;
    customAmount = (customAmount - 0.25).clamp(0.25, 20.0);
    _recalculateTotals();
    update();
  }

  void updateCustomAmountFromText(String val) {
    if (val.isEmpty) return;
    final parsed = double.tryParse(val);
    if (parsed != null) {
      final maxVal = totalNetWeight * 20;
      customAmount = parsed.clamp(0.0, maxVal);
      _recalculateTotals();
      update();
    }
  }

  void setBaseMacros({
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatsG,
    bool notify = true,
  }) {
    calorie = calories;
    protein = proteinG;
    carbs = carbsG;
    fats = fatsG;
    _recalculateTotals();
    if (notify) update();
  }

  onAddButton(BuildContext context) async {
    List<SqlCalorieModel> calorieData = await dbHelper.getCalorieData();
    if (!context.mounted) return;
    addSqlData(type);
    if (calorieData.isEmpty) {
      int id = await dbHelper.insertCalorie(
        SqlCalorieModel(
          date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          totalGoal: ConstantUserMaster.calorieGoal,
          calorie: calorieQuantity,
          protein: proteinQuantity.round(),
          carbs: carbsQuantity.round(),
          fats: fatsQuantity.round(),
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
      await StreakService().recordActivity();
      // Sync to Firestore for notifications
      MealSyncService().syncMealLog(
        mealType: type,
        calories: calorieQuantity,
        protein: proteinQuantity.round(),
        carbs: carbsQuantity.round(),
        fats: fatsQuantity.round(),
        dailyGoal: ConstantUserMaster.calorieGoal,
      );
      // Check goal progress for notification
      _showGoalNotificationIfNeeded(
        calorieQuantity,
        ConstantUserMaster.calorieGoal,
      );
      Get.offAllNamed(Routes.leadingView);
      RateUsService.showRateUsIfEligible(RateUsService.actionFoodScan);
      WidgetPromotionService().showPromotionIfNeeded();
    } else {
      if (calorieData.last.date ==
          DateFormat('dd-MM-yyyy').format(DateTime.now())) {
        if (calorieData.last.calorie + calorieQuantity >
            ConstantUserMaster.calorieGoal) {
          showCalorieCompleteDialog(context, calorieData);
        } else {
          if (kDebugMode) {
            print("Hello This Is Update Data $calorieQuantity");
          }
          await dbHelper.updateCalorie(
            SqlCalorieModel(
              id: calorieData.last.id,
              date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
              totalGoal: ConstantUserMaster.calorieGoal,
              calorie: calorieData.last.calorie + calorieQuantity,
              protein: calorieData.last.protein + proteinQuantity.round(),
              carbs: calorieData.last.carbs + carbsQuantity.round(),
              fats: calorieData.last.fats + fatsQuantity.round(),
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
          await StreakService().recordActivity();
          // Sync to Firestore for notifications
          MealSyncService().syncMealLog(
            mealType: type,
            calories: calorieQuantity,
            protein: proteinQuantity.round(),
            carbs: carbsQuantity.round(),
            fats: fatsQuantity.round(),
            dailyGoal: ConstantUserMaster.calorieGoal,
          );
          // Check goal progress for notification
          _showGoalNotificationIfNeeded(
            calorieData.last.calorie + calorieQuantity,
            ConstantUserMaster.calorieGoal,
          );
          Get.offAllNamed(Routes.leadingView);
          RateUsService.showRateUsIfEligible(RateUsService.actionFoodScan);
          WidgetPromotionService().showPromotionIfNeeded();
        }
      } else {
        int id = await dbHelper.insertCalorie(
          SqlCalorieModel(
            date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
            totalGoal: ConstantUserMaster.calorieGoal,
            calorie: calorieQuantity,
            protein: proteinQuantity.round(),
            carbs: carbsQuantity.round(),
            fats: fatsQuantity.round(),
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
        await StreakService().recordActivity();
        // Sync to Firestore for notifications
        MealSyncService().syncMealLog(
          mealType: type,
          calories: calorieQuantity,
          protein: proteinQuantity.round(),
          carbs: carbsQuantity.round(),
          fats: fatsQuantity.round(),
          dailyGoal: ConstantUserMaster.calorieGoal,
        );
        Get.offAllNamed(Routes.leadingView);
        RateUsService.showRateUsIfEligible(RateUsService.actionFoodScan);
        WidgetPromotionService().showPromotionIfNeeded();
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
        numeric = numeric.replaceAll(',', '');
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

  // parse nutrition json
  Map<String, dynamic> parseNutritionWithName(String text) {
    try {
      final trimmed = text.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        dynamic data;
        try {
          data = jsonDecode(trimmed);
        } catch (_) {
          data = null;
        }
        if (data is Map<String, dynamic>) {
          int toInt(dynamic v) {
            if (v == null) return 0;
            if (v is int) return v;
            if (v is double) return v.round();
            if (v is String) {
              return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
            return 0;
          }

          final calories = toInt(data['calories']);
          final protein = toInt(data['protein_g']);
          final carbs = toInt(data['carbohydrates_g']);
          final fats = toInt(data['fats_g']);
          final name =
              (data['food_name'] is String)
                  ? (data['food_name'] as String)
                  : '';
          final nameEnglish =
              (data['food_name_english'] is String)
                  ? (data['food_name_english'] as String)
                  : '';
          return {
            'food_name': name,
            'food_name_english': nameEnglish,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fats,
          };
        }
      }
    } catch (e) {
      log('JSON_PARSE_FAIL => $e');
    }
    final vals = extractNutritionalValues(text);
    return {'food_name': '', 'food_name_english': '', ...vals};
  }

  addSqlData(String type) async {
    var imageData = image != null ? await saveImageToFile(image!.path) : null;
    dbHelper.insertCalorieHistory(
      CalorieHistoryModel(
        calorie: calorieQuantity,
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        protein: proteinQuantity.round(),
        carbs: carbsQuantity.round(),
        image: imageData,
        fats: fatsQuantity.round(),
        type: type,
        fdcId: usdaFdcId,
        title:
            (mealNameEnglish.trim().isNotEmpty
                ? mealNameEnglish.trim()
                : mealName.trim()),
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
      if (kDebugMode) {
        print("Error: Image data is null");
      }
      return null;
    }

    await file.writeAsBytes(imageData);
    return filePath; // Store this path in the database
  }

  Future<Uint8List?> fileToBytes(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final file = File(filePath);

    if (await file.exists()) {
      return await file.readAsBytes();
    } else {
      if (kDebugMode) {
        print("Error: File does not exist");
      }
      return null;
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
                Navigator.of(context).pop();
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
                    protein: calorieData.last.protein + proteinQuantity.round(),
                    carbs: calorieData.last.carbs + carbsQuantity.round(),
                    fats: calorieData.last.fats + fatsQuantity.round(),
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

                // Close dialog first to prevent orphaned overlay
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                Get.offAllNamed(Routes.leadingView);
                WidgetPromotionService().showPromotionIfNeeded();
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

  Future<void> shareMealResult({Rect? sharePositionOrigin}) async {
    try {
      final imageUint8List = await screenshotController.captureFromWidget(
        MealShareCard(
          mealImage: image,
          calories: calorieQuantity,
          protein: proteinQuantity,
          carbs: carbsQuantity,
          fats: fatsQuantity,
        ),
        delay: const Duration(milliseconds: 100),
      );

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/meal_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageUint8List);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my meal on Macroaize!',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      log('SHARE_MEAL_ERROR => $e');
      try {
        NotificationService.showError("Error sharing meal result");
      } catch (_) {}
    }
  }

  /// Show goal progress notification (50% and 100% milestones)
  Future<void> _showGoalNotificationIfNeeded(
    int totalCalories,
    int goal,
  ) async {
    if (goal <= 0) return;

    try {
      if (!Get.isRegistered<LocalNotificationService>()) return;

      final int percent = ((totalCalories / goal) * 100).round();
      final localNotifService = Get.find<LocalNotificationService>();

      // Show notification for 50% or 100% milestones
      if (percent >= 100) {
        await localNotifService.showGoalProgress(100);
        if (kDebugMode) print('Goal progress notification: 100%');
      } else if (percent >= 50 && percent < 100) {
        await localNotifService.showGoalProgress(percent);
        if (kDebugMode) print('Goal progress notification: $percent%');
      }
    } catch (e) {
      if (kDebugMode) print('Error showing goal progress notification: $e');
    }
  }
}
