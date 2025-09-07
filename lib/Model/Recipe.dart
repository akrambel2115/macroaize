class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int duration; // in minutes
  final int calories;
  final int carbs; // grams
  final int protein; // grams
  final int fat; // grams
  final String difficulty;
  final List<String> tags;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  // Optional localized fields per language code (e.g., 'en', 'ar', 'fr')
  final Map<String, String>? descriptionL10n;
  final Map<String, List<String>>? ingredientsL10n;
  final Map<String, List<String>>? instructionsL10n;

  const Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.calories,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
    this.difficulty = 'Easy',
    this.tags = const [],
    this.description = '',
    this.ingredients = const [],
    this.instructions = const [],
  this.descriptionL10n,
  this.ingredientsL10n,
  this.instructionsL10n,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Build localized maps when provided (backwards compatible)
    Map<String, String>? descL10n;
    Map<String, List<String>>? ingL10n;
    Map<String, List<String>>? instrL10n;

    String? descEn = json['description_en'];
    String? descAr = json['description_ar'];
    String? descFr = json['description_fr'];
    if (descEn != null || descAr != null || descFr != null) {
      descL10n = {};
      if (descEn != null) descL10n['en'] = descEn;
      if (descAr != null) descL10n['ar'] = descAr;
      if (descFr != null) descL10n['fr'] = descFr;
    }

    List<dynamic>? ingEn = json['ingredients_en'];
    List<dynamic>? ingAr = json['ingredients_ar'];
    List<dynamic>? ingFr = json['ingredients_fr'];
    if (ingEn != null || ingAr != null || ingFr != null) {
      ingL10n = {};
      if (ingEn != null) ingL10n['en'] = List<String>.from(ingEn);
      if (ingAr != null) ingL10n['ar'] = List<String>.from(ingAr);
      if (ingFr != null) ingL10n['fr'] = List<String>.from(ingFr);
    }

    List<dynamic>? stEn = json['instructions_en'];
    List<dynamic>? stAr = json['instructions_ar'];
    List<dynamic>? stFr = json['instructions_fr'];
    if (stEn != null || stAr != null || stFr != null) {
      instrL10n = {};
      if (stEn != null) instrL10n['en'] = List<String>.from(stEn);
      if (stAr != null) instrL10n['ar'] = List<String>.from(stAr);
      if (stFr != null) instrL10n['fr'] = List<String>.from(stFr);
    }

    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      duration: json['duration'] ?? 0,
      calories: json['calories'] ?? 0,
      carbs: json['carbs'] ?? 0,
      protein: json['protein'] ?? 0,
      fat: json['fat'] ?? 0,
      difficulty: json['difficulty'] ?? 'Easy',
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      descriptionL10n: descL10n,
      ingredientsL10n: ingL10n,
      instructionsL10n: instrL10n,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'duration': duration,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
      'difficulty': difficulty,
      'tags': tags,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      if (descriptionL10n != null) ...{
        'description_en': descriptionL10n!['en'],
        'description_ar': descriptionL10n!['ar'],
        'description_fr': descriptionL10n!['fr'],
      },
      if (ingredientsL10n != null) ...{
        'ingredients_en': ingredientsL10n!['en'],
        'ingredients_ar': ingredientsL10n!['ar'],
        'ingredients_fr': ingredientsL10n!['fr'],
      },
      if (instructionsL10n != null) ...{
        'instructions_en': instructionsL10n!['en'],
        'instructions_ar': instructionsL10n!['ar'],
        'instructions_fr': instructionsL10n!['fr'],
      },
    };
  }

  // Convenience getters for localized content
  String localizedDescription(String langCode) {
    return descriptionL10n != null && descriptionL10n![langCode]?.isNotEmpty == true
        ? descriptionL10n![langCode]!
        : description;
  }

  List<String> localizedIngredients(String langCode) {
    return ingredientsL10n != null && (ingredientsL10n![langCode]?.isNotEmpty == true)
        ? ingredientsL10n![langCode]!
        : ingredients;
  }

  List<String> localizedInstructions(String langCode) {
    return instructionsL10n != null && (instructionsL10n![langCode]?.isNotEmpty == true)
        ? instructionsL10n![langCode]!
        : instructions;
  }
}
