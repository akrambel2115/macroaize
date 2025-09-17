
class MealBreakdownItem {
  final String name;
  final String englishName;
  final double amount;
  final String unit;
  final double grams;

  // USDA data (per 100g)
  final int? fdcId;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  // Derived from grams
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  final bool usdaVerified;

  const MealBreakdownItem({
    required this.name,
    required this.englishName,
    required this.amount,
    required this.unit,
    required this.grams,
    this.fdcId,
    this.kcalPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.usdaVerified = false,
  });

  MealBreakdownItem copyWith({
    String? name,
    String? englishName,
    double? amount,
    String? unit,
    double? grams,
    int? fdcId,
    double? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? kcal,
    double? protein,
    double? carbs,
    double? fat,
    bool? usdaVerified,
  }) {
    return MealBreakdownItem(
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      grams: grams ?? this.grams,
      fdcId: fdcId ?? this.fdcId,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      usdaVerified: usdaVerified ?? this.usdaVerified,
    );
  }

  static MealBreakdownItem fromBasic({
    required String name,
    required String englishName,
    required String estimatedAmount,
  }) {
    final parsed = _parseAmountToGrams(estimatedAmount);
    return MealBreakdownItem(
      name: name,
      englishName: englishName,
      amount: parsed.amount,
      unit: parsed.unit,
      grams: parsed.grams,
    );
  }

  // Helpers
  static _ParsedAmount _parseAmountToGrams(String raw) {
    final s = raw.trim().toLowerCase();
    final numberMatch = RegExp(r"([0-9]+(?:\.[0-9]+)?)").firstMatch(s);
    double value = 0;
    if (numberMatch != null) {
      value = double.tryParse(numberMatch.group(1)!) ?? 0;
    }
    // unit parsing and simple approximations
    String unit = 'g';
    if (s.contains('piece') || s.contains('pcs') || s.contains('pc')) {
      unit = 'piece';
    } else if (s.contains('g') || s.contains('gram')) {
      unit = 'g';
    } else {
      if (s.contains('ml')) {
        value = value * 1.0;
      } else if (s.contains('cup')) {
        value = value * 240;
      } else if (s.contains('slice')) {
        value = value * 30;
      }
      unit = 'g';
    }

    double grams = value;
    switch (unit) {
      case 'piece':
        grams = value * 50;
        break;
      case 'g':
      default:
        grams = value;
    }
    return _ParsedAmount(amount: value, unit: unit, grams: grams);
  }

  MealBreakdownItem recalcFromPer100g() {
    final kcal = (kcalPer100g * grams) / 100.0;
    final protein = (proteinPer100g * grams) / 100.0;
    final carbs = (carbsPer100g * grams) / 100.0;
    final fat = (fatPer100g * grams) / 100.0;
    return copyWith(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
  }
}

class _ParsedAmount {
  final double amount;
  final String unit;
  final double grams;
  const _ParsedAmount({required this.amount, required this.unit, required this.grams});
}
