class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int duration;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String difficulty;
  final Map<String, String>? titleL10n;
  final Map<String, String>? difficultyL10n;
  final List<String> tags;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
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
  this.titleL10n,
  this.difficultyL10n,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // build localized maps when provided
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

    // localized title
    Map<String, String>? titleL10n;
    String? tEn = json['title_en'];
    String? tAr = json['title_ar'];
    String? tFr = json['title_fr'];
    if (tEn != null || tAr != null || tFr != null) {
      titleL10n = {};
      if (tEn != null) titleL10n['en'] = tEn;
      if (tAr != null) titleL10n['ar'] = tAr;
      if (tFr != null) titleL10n['fr'] = tFr;
    }

    // localized difficulty
    Map<String, String>? difficultyL10n;
    String? dEn = json['difficulty_en'];
    String? dAr = json['difficulty_ar'];
    String? dFr = json['difficulty_fr'];
    if (dEn != null || dAr != null || dFr != null) {
      difficultyL10n = {};
      if (dEn != null) difficultyL10n['en'] = dEn;
      if (dAr != null) difficultyL10n['ar'] = dAr;
      if (dFr != null) difficultyL10n['fr'] = dFr;
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
      titleL10n: titleL10n,
      difficultyL10n: difficultyL10n,
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
      if (titleL10n != null) ...{
        'title_en': titleL10n!['en'],
        'title_ar': titleL10n!['ar'],
        'title_fr': titleL10n!['fr'],
      },
      if (difficultyL10n != null) ...{
        'difficulty_en': difficultyL10n!['en'],
        'difficulty_ar': difficultyL10n!['ar'],
        'difficulty_fr': difficultyL10n!['fr'],
      },
    };
  }
  // convenience getters for localized content
  String localizedDescription(String langCode) {
    return descriptionL10n != null && descriptionL10n![langCode]?.isNotEmpty == true
        ? descriptionL10n![langCode]!
        : description;
  }

  String localizedTitle(String langCode) {
    return titleL10n != null && titleL10n![langCode]?.isNotEmpty == true
        ? titleL10n![langCode]!
        : title;
  }

  String localizedDifficulty(String langCode) {
    return difficultyL10n != null && difficultyL10n![langCode]?.isNotEmpty == true
        ? difficultyL10n![langCode]!
        : difficulty;
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
