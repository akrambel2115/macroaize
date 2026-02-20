import 'package:macroaize/Model/main_chat_model.dart';
import 'package:macroaize/Model/subchat_model.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import '../Model/calorie_history_model.dart';
import '../Model/sql_calorie_model.dart';
import '../Model/sql_daily_calorie_model.dart';

import 'package:flutter/foundation.dart'; // Add this import

class DatabaseHelper {
  static Database? _database;
  final String calorie = 'Calorie';
  final String dailyCalorie = 'DailyCalorie';
  final String history = 'CalorieHistory';
  final String localFood = 'LocalFood';
  final String mainChat = 'MainChat';
  final String subChat = 'SubChat';
  final String weightHistory = 'WeightHistory';
  final String workoutHistory = 'WorkoutHistory';

  Future<Database> get database async {
    if (kIsWeb) {
      // This should ideally not be reached if initDatabase is skipped,
      // but if it is, we can't return a Database object.
      // We'll throw an error that should be caught by the caller or return a dummy if possible.
      throw UnsupportedError('Database not supported on web');
    }
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database not supported on web');
    }
    String path = join(await getDatabasesPath(), 'my_database.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $calorie (
            id INTEGER PRIMARY KEY,
        date TEXT,
        totalGoal INTEGER,
        calorie INTEGER,
        protein INTEGER,
        carbs INTEGER,
        fats INTEGER
             )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $dailyCalorie (
            id INTEGER PRIMARY KEY,
        time TEXT,
        calorie INTEGER,
        date TEXT,
        calorieId INTEGER
             )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $history (
            id INTEGER PRIMARY KEY,
            calorie INTEGER,
            date TEXT,
            protein INTEGER,
            carbs INTEGER,
            fats INTEGER,
            type TEXT,
            image BLOB,
            fdcId INTEGER,
            title TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $localFood (
            id INTEGER PRIMARY KEY,
            name TEXT,
            quantity TEXT,
            calories INTEGER,
            carbs INTEGER,
            protein INTEGER,
            fats INTEGER,
            type TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $mainChat (
            id INTEGER PRIMARY KEY,
            Question TEXT,
            Answer TEXT,
            Date TEXT
             )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $subChat (
            id INTEGER PRIMARY KEY,
            MainChatID INTEGER,
            Question TEXT,
            Answer TEXT,
            Date TEXT,
            image TEXT
             )
             ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $weightHistory (
            id INTEGER PRIMARY KEY,
            weight REAL,
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $workoutHistory (
            id INTEGER PRIMARY KEY,
            date TEXT,
            duration INTEGER,
            type TEXT,
            calories_burned INTEGER,
            description TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // migrate from versions <2
        if (oldVersion < 2) {
          // Add fdcId column if not exists
          try {
            await db.execute('ALTER TABLE $history ADD COLUMN fdcId INTEGER');
          } catch (_) {
            // ignore if already exists
          }
        }
        // ensure LocalFood table exists when upgrading to version 3
        if (oldVersion < 3) {
          try {
            await db.execute('''
          CREATE TABLE IF NOT EXISTS $localFood (
            id INTEGER PRIMARY KEY,
            name TEXT,
            quantity TEXT,
            calories INTEGER,
            carbs INTEGER,
            protein INTEGER,
            fats INTEGER,
            type TEXT
          )
        ''');
          } catch (_) {
            // ignore if creation fails for any reason
          }
        }
        // add title column to history when upgrading to version 4
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE $history ADD COLUMN title TEXT');
          } catch (_) {
            // ignore if already exists
          }
        }
        // add weight history table when upgrading to version 5
        if (oldVersion < 5) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $weightHistory (
                id INTEGER PRIMARY KEY,
                weight REAL,
                date TEXT
              )
            ''');
          } catch (_) {
            // ignore if creation fails
          }
        }
        // add workout history table when upgrading to version 6
        if (oldVersion < 6) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $workoutHistory (
                id INTEGER PRIMARY KEY,
                date TEXT,
                duration INTEGER,
                type TEXT,
                calories_burned INTEGER,
                description TEXT
              )
            ''');
          } catch (_) {
            // ignore if creation fails
          }
        }
      },
    );
  }

  Future<int> insertCalorie(SqlCalorieModel details) async {
    if (kIsWeb) return 0;
    final db = await database;
    final int id = await db.insert(calorie, details.toMap());
    return id;
  }

  // Local food helpers
  Future<int> insertLocalFood(Map<String, dynamic> data) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(localFood, data);
  }

  Future<List<Map<String, dynamic>>> getLocalFoods(String type) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      localFood,
      where: 'type=?',
      whereArgs: [type],
    );
    return maps;
  }

  Future<void> deleteLocalFoodsByType(String type) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(localFood, where: 'type = ?', whereArgs: [type]);
  }

  Future<int> insertCalorieHistory(CalorieHistoryModel model) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(history, model.toMap());
  }

  Future<int> insertDailyWater(DailyCalorieModel details) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(dailyCalorie, details.toMap());
  }

  Future<int> insertMainChatModel(MainChatModel details) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(mainChat, details.toMap());
  }

  Future<int> insertSubChatModel(SubChatModel details) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(subChat, details.toMap());
  }

  Future<List<MainChatModel>> getMainChat() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(mainChat);
    return List.generate(maps.length, (i) {
      return MainChatModel.fromMap(maps[i]);
    });
  }

  Future<List<SubChatModel>> getSubChat(int mainChatId) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      subChat,
      where: 'MainChatID=?',
      whereArgs: [mainChatId],
    );
    return List.generate(maps.length, (i) {
      return SubChatModel.fromMap(maps[i]);
    });
  }

  //
  Future<List<SqlCalorieModel>> getCalorieData() async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(calorie);
    return List.generate(maps.length, (i) {
      return SqlCalorieModel.fromMap(maps[i]);
    });
  }

  Future<List<CalorieHistoryModel>> getCalorieHistory(String type) async {
    if (kIsWeb) return [];
    final db = await database;
    if (type == "All") {
      final List<Map<String, dynamic>> maps = await db.query(history);
      return List.generate(maps.length, (i) {
        return CalorieHistoryModel.fromMap(maps[i]);
      });
    } else {
      final List<Map<String, dynamic>> maps = await db.query(
        history,
        where: 'type=?',
        whereArgs: [type],
      );
      return List.generate(maps.length, (i) {
        return CalorieHistoryModel.fromMap(maps[i]);
      });
    }
  }

  Future<void> deleteCalorieHistory(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(history, where: 'id = ?', whereArgs: [id]);
    // return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteMainChat(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(mainChat, where: 'id = ?', whereArgs: [id]);
    // return result.isNotEmpty ? result.first : null;
  }

  Future<List<SqlCalorieModel>> getCalorieDataForMonth(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    var result = await db.query(calorie);
    List<SqlCalorieModel> filteredResults =
        result.map((e) => SqlCalorieModel.fromMap(e)).where((data) {
          DateTime dataDate = DateFormat('dd-MM-yyyy').parse(data.date);
          return dataDate.isAfter(startDate.subtract(Duration(days: 1))) &&
              dataDate.isBefore(endDate.add(Duration(days: 1)));
        }).toList();
    return filteredResults;
  }

  Future<void> updateCalorie(SqlCalorieModel data) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      calorie,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<void> sqlClear() async {
    if (kIsWeb) return;
    final db = await database;
    db.delete(calorie);
    db.delete(history);
    db.delete(dailyCalorie);
    db.delete(mainChat);
    db.delete(subChat);
  }

  // Weight History methods
  Future<int> insertWeightEntry(double weight, DateTime date) async {
    if (kIsWeb) return 0;
    final db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    // Always insert a new entry (don't update existing)
    // This preserves the first entry as historical baseline
    return await db.insert(weightHistory, {'weight': weight, 'date': dateStr});
  }

  /// Get the very first weight entry ever recorded (for baseline)
  Future<double?> getFirstWeightEntry() async {
    if (kIsWeb) return null;
    final db = await database;
    final result = await db.query(weightHistory, orderBy: 'id ASC', limit: 1);
    if (result.isNotEmpty) {
      return (result.first['weight'] as num).toDouble();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getWeightHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) return [];
    final db = await database;

    String query;
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);
      // Get the LATEST entry per date within range
      query = '''
        SELECT date, weight FROM $weightHistory 
        WHERE date >= ? AND date <= ?
        GROUP BY date
        HAVING id = MAX(id)
        ORDER BY date ASC
      ''';
      args = [startStr, endStr];
    } else {
      // Get the LATEST entry per date for all history
      query = '''
        SELECT date, weight FROM $weightHistory 
        GROUP BY date
        HAVING id = MAX(id)
        ORDER BY date ASC
      ''';
    }

    return await db.rawQuery(query, args);
  }

  // Workout History Methods
  Future<int> insertWorkoutEntry({
    required DateTime date,
    required int duration,
    required String type,
    int caloriesBurned = 0,
    String description = '',
  }) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(workoutHistory, {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'duration': duration,
      'type': type,
      'calories_burned': caloriesBurned,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) return [];
    final db = await database;

    String query;
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);
      query = '''
        SELECT * FROM $workoutHistory 
        WHERE date >= ? AND date <= ?
        ORDER BY date ASC
      ''';
      args = [startStr, endStr];
    } else {
      query = '''
        SELECT * FROM $workoutHistory 
        ORDER BY date ASC
      ''';
    }

    return await db.rawQuery(query, args);
  }

  /// Get total workout duration grouped by date
  Future<Map<String, int>> getWorkoutDurationByDate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) return {};
    final db = await database;

    String query;
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);
      query = '''
        SELECT date, SUM(duration) as total_duration 
        FROM $workoutHistory 
        WHERE date >= ? AND date <= ?
        GROUP BY date
        ORDER BY date ASC
      ''';
      args = [startStr, endStr];
    } else {
      query = '''
        SELECT date, SUM(duration) as total_duration 
        FROM $workoutHistory 
        GROUP BY date
        ORDER BY date ASC
      ''';
    }

    final results = await db.rawQuery(query, args);
    Map<String, int> durationMap = {};
    for (final row in results) {
      durationMap[row['date'] as String] =
          (row['total_duration'] as num).toInt();
    }
    return durationMap;
  }

  /// Get total calories burned from workouts for a specific date
  Future<int> getTotalCaloriesBurnedForDate(DateTime date) async {
    if (kIsWeb) return 0;
    final db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final result = await db.rawQuery('''
      SELECT SUM(calories_burned) as total_calories
      FROM $workoutHistory
      WHERE date = ?
    ''', [dateStr]);
    
    if (result.isEmpty || result.first['total_calories'] == null) {
      return 0;
    }
    return (result.first['total_calories'] as num).toInt();
  }
}
