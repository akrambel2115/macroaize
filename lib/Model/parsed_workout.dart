class ParsedExercise {
  final String name;
  final String type; // exercise categories
  final String? muscleGroup;
  final int? sets;
  final int? reps;
  final double? weight;
  final String? weightUnit; // kg or lbs
  final int? duration; // minutes
  final double? distance; // kilometers
  final int caloriesBurned;

  ParsedExercise({
    required this.name,
    required this.type,
    this.muscleGroup,
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit,
    this.duration,
    this.distance,
    this.caloriesBurned = 0,
  });

  factory ParsedExercise.fromJson(Map<String, dynamic> json) {
    return ParsedExercise(
      name: json['name'] as String? ?? 'Unknown Exercise',
      type: json['type'] as String? ?? 'other',
      muscleGroup: json['muscleGroup'] as String?,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'weightUnit': weightUnit,
      'duration': duration,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
    };
  }

  String get formattedDescription {
    final parts = <String>[];

    if (muscleGroup != null) {
      parts.add(muscleGroup!);
    }

    if (sets != null && reps != null) {
      parts.add('$sets sets × $reps reps');
    } else if (reps != null) {
      parts.add('$reps reps');
    } else if (sets != null) {
      parts.add('$sets sets');
    }

    if (weight != null) {
      parts.add('${weight!.toStringAsFixed(1)} ${weightUnit ?? 'kg'}');
    }

    if (type == 'cardio') {
      if (duration != null && duration! > 0) {
        parts.add('$duration min');
      }

      if (distance != null && distance! > 0) {
        parts.add('${distance!.toStringAsFixed(2)} km');
      }
    }

    return parts.join(' • ');
  }
}

class ParsedWorkout {
  final List<ParsedExercise> exercises;
  final int totalDuration; // minutes
  final int totalCaloriesBurned;
  final String summary;

  ParsedWorkout({
    required this.exercises,
    required this.totalDuration,
    required this.totalCaloriesBurned,
    required this.summary,
  });

  factory ParsedWorkout.fromJson(Map<String, dynamic> json) {
    final exercisesList = (json['exercises'] as List<dynamic>?)
        ?.map((e) => ParsedExercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ??
      [];

    return ParsedWorkout(
      exercises: exercisesList,
      totalDuration: (json['totalDuration'] as num?)?.toInt() ?? 0,
      totalCaloriesBurned: (json['totalCaloriesBurned'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'totalDuration': totalDuration,
      'totalCaloriesBurned': totalCaloriesBurned,
      'summary': summary,
    };
  }

  bool get hasBodybuilding =>
      exercises.any((e) => e.type == 'bodybuilding');

  bool get hasCardio => exercises.any((e) => e.type == 'cardio');

  bool get hasCalisthenics =>
      exercises.any((e) => e.type == 'calisthenics');

  List<ParsedExercise> getExercisesByType(String type) {
    return exercises.where((e) => e.type == type).toList();
  }
}