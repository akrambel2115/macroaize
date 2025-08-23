class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int duration; // in minutes
  final int calories;
  final String difficulty;
  final List<String> tags;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;

  const Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.calories,
    this.difficulty = 'Easy',
    this.tags = const [],
    this.description = '',
    this.ingredients = const [],
    this.instructions = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      duration: json['duration'] ?? 0,
      calories: json['calories'] ?? 0,
      difficulty: json['difficulty'] ?? 'Easy',
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'duration': duration,
      'calories': calories,
      'difficulty': difficulty,
      'tags': tags,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
    };
  }
}
