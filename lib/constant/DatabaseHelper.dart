import 'package:foodcalorietracker/Model/MainChatModel.dart';
import 'package:foodcalorietracker/Model/SubchatModel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import '../Model/CalorieHistoryModel.dart';
import '../Model/SqlCalorieModel.dart';
import '../Model/SqlDailyCalorieModel.dart';

class DatabaseHelper {
  static Database? _database;
  final String calorie = 'Calorie';
  final String dailyCalorie = 'DailyCalorie';
  final String history = 'CalorieHistory';
  final String localFood = 'LocalFood';
  final String mainChat = 'MainChat';
  final String subChat = 'SubChat';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'my_database.db');
    return await openDatabase(
      path,
      version: 4,
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
      },
    );
  }

  Future<int> insertCalorie(SqlCalorieModel details) async {
    final db = await database;
    final int id = await db.insert(calorie, details.toMap());
    return id;
  }

  // Local food helpers
  Future<int> insertLocalFood(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(localFood, data);
  }

  Future<List<Map<String, dynamic>>> getLocalFoods(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      localFood,
      where: 'type=?',
      whereArgs: [type],
    );
    return maps;
  }

  Future<void> deleteLocalFoodsByType(String type) async {
    final db = await database;
    await db.delete(localFood, where: 'type = ?', whereArgs: [type]);
  }

  Future<int> insertCalorieHistory(CalorieHistoryModel model) async {
    final db = await database;
    return await db.insert(history, model.toMap());
  }

  Future<int> insertDailyWater(DailyCalorieModel details) async {
    final db = await database;
    return await db.insert(dailyCalorie, details.toMap());
  }

  Future<int> insertMainChatModel(MainChatModel details) async {
    final db = await database;
    return await db.insert(mainChat, details.toMap());
  }

  Future<int> insertSubChatModel(SubChatModel details) async {
    final db = await database;
    return await db.insert(subChat, details.toMap());
  }

  Future<List<MainChatModel>> getMainChat() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(mainChat);
    return List.generate(maps.length, (i) {
      return MainChatModel.fromMap(maps[i]);
    });
  }

  Future<List<SubChatModel>> getSubChat(int mainChatId) async {
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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(calorie);
    return List.generate(maps.length, (i) {
      return SqlCalorieModel.fromMap(maps[i]);
    });
  }

  Future<List<CalorieHistoryModel>> getCalorieHistory(String type) async {
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
    final db = await database;
    await db.delete(history, where: 'id = ?', whereArgs: [id]);
    // return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteMainChat(int id) async {
    final db = await database;
    await db.delete(mainChat, where: 'id = ?', whereArgs: [id]);
    // return result.isNotEmpty ? result.first : null;
  }

  Future<List<SqlCalorieModel>> getCalorieDataForMonth(
    DateTime startDate,
    DateTime endDate,
  ) async {
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
    final db = await database;
    await db.update(
      calorie,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<void> sqlClear() async {
    final db = await database;
    db.delete(calorie);
    db.delete(history);
    db.delete(dailyCalorie);
    db.delete(mainChat);
    db.delete(subChat);
  }
}
