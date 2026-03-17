import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const int _driftSchemaVersion = 3;
const int _catalogVersion = 4;
const int _minimumExpectedRows = 3800;

void main() {
  final repoRoot = Directory.current.path;
  final csvPath = p.join(repoRoot, 'data', 'food_data_v3.csv');
  final outputPath = p.join(repoRoot, 'assets', 'database', 'local_food.db');
  final reportPath = p.join(repoRoot, 'tool', 'local_food_build_report.json');

  final csvFile = File(csvPath);
  if (!csvFile.existsSync()) {
    stderr.writeln('CSV not found: $csvPath');
    exitCode = 1;
    return;
  }

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  if (outputFile.existsSync()) {
    outputFile.deleteSync();
  }

  final csvRaw = csvFile.readAsStringSync();
  final rows = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(csvRaw);

  if (rows.isEmpty) {
    stderr.writeln('CSV file is empty.');
    exitCode = 1;
    return;
  }

  final db = sqlite3.open(outputPath);
  try {
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');

    db.execute('''
      CREATE TABLE foods_catalog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_fr TEXT,
        name_ar TEXT,
        calories REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        fats REAL NOT NULL DEFAULT 0,
        quantity_en TEXT NOT NULL,
        quantity_fr TEXT,
        quantity_ar TEXT,
        is_popular INTEGER NOT NULL DEFAULT 0
      )
    ''');

    db.execute('''
      CREATE TABLE user_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_type TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity TEXT NOT NULL,
        calories INTEGER NOT NULL DEFAULT 0,
        carbs INTEGER NOT NULL DEFAULT 0,
        protein INTEGER NOT NULL DEFAULT 0,
        fats INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    db.execute('''
      CREATE TABLE meta_entries (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    db.execute('''
      CREATE VIRTUAL TABLE foods_catalog_fts USING fts5(
        name,
        name_fr,
        name_ar,
        content='foods_catalog',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');

    db.execute('''
      CREATE TRIGGER foods_catalog_ai AFTER INSERT ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(rowid, name, name_fr, name_ar)
        VALUES (new.id, new.name, new.name_fr, new.name_ar);
      END
    ''');

    db.execute('''
      CREATE TRIGGER foods_catalog_ad AFTER DELETE ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(foods_catalog_fts, rowid, name, name_fr, name_ar)
        VALUES('delete', old.id, old.name, old.name_fr, old.name_ar);
      END
    ''');

    db.execute('''
      CREATE TRIGGER foods_catalog_au AFTER UPDATE ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(foods_catalog_fts, rowid, name, name_fr, name_ar)
        VALUES('delete', old.id, old.name, old.name_fr, old.name_ar);
        INSERT INTO foods_catalog_fts(rowid, name, name_fr, name_ar)
        VALUES (new.id, new.name, new.name_fr, new.name_ar);
      END
    ''');

    final insert = db.prepare('''
      INSERT INTO foods_catalog (
        name, name_fr, name_ar,
        calories, carbs, protein, fats,
        quantity_en, quantity_fr, quantity_ar
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    var inserted = 0;
    var skipped = 0;
    final skippedRows = <Map<String, Object>>[];

    db.execute('BEGIN TRANSACTION');
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 10) {
        skipped++;
        skippedRows.add({
          'row': i + 1,
          'reason': 'row_has_less_than_10_columns',
        });
        continue;
      }

      // Refactored CSV columns:
      // 0=name_en, 1=name_fr, 2=name_ar,
      // 3=calories, 4=carbs, 5=protein, 6=fats,
      // 7=quantity_en, 8=quantity_fr, 9=quantity_ar
      final nameEn = _cell(row, 0);
      if (nameEn.isEmpty) {
        skipped++;
        skippedRows.add({'row': i + 1, 'reason': 'name_en_is_empty'});
        continue;
      }

      final nameFr = _cell(row, 1, fallback: nameEn);
      final nameAr = _cell(row, 2, fallback: nameEn);
      final calories = _num(_cell(row, 3));
      final carbs = _num(_cell(row, 4));
      final protein = _num(_cell(row, 5));
      final fats = _num(_cell(row, 6));
      final quantityEn = _cell(row, 7, fallback: '100 g');
      final quantityFr = _cell(row, 8, fallback: quantityEn);
      final quantityAr = _cell(row, 9, fallback: quantityEn);

      insert.execute([
        nameEn,
        nameFr,
        nameAr,
        calories,
        carbs,
        protein,
        fats,
        quantityEn,
        quantityFr,
        quantityAr,
      ]);
      inserted++;
    }
    db.execute('COMMIT');

    insert.dispose();

    // Mark popular / well-known food items
    db.execute('''
      UPDATE foods_catalog SET is_popular = 1 WHERE
        name LIKE '%Egg%' OR name LIKE '%Chicken%' OR name = 'Rice' OR
        name LIKE '%Bread%' OR name = 'Milk' OR name LIKE '%Beef%' OR
        name LIKE '%Lamb%' OR name LIKE '%Potato%' OR name LIKE '%Tomato%' OR
        name LIKE '%Pasta%' OR name LIKE '%Cheese%' OR name LIKE '%Yogurt%' OR
        name LIKE '%Olive Oil%' OR name LIKE '%Fish%' OR name LIKE '%Tuna%' OR
        name LIKE '%Banana%' OR name LIKE '%Lemon%' OR name LIKE '%Carrot%' OR
        name LIKE '%Honey%' OR name LIKE '%Coffee%' OR name LIKE '%Tea%' OR
        name LIKE '%Almond%' OR name LIKE '%Dates%' OR name LIKE '%Chocolate%' OR
        name LIKE '%Lentil%' OR name LIKE '%Chickpea%' OR name LIKE '%Butter%' OR
        name LIKE '%Smen%' OR name LIKE '%Couscous%' OR name LIKE '%Chorba%' OR
        name LIKE '%Orange%' OR name LIKE '%Onion%' OR name LIKE '%Cucumber%' OR
        name LIKE '%Salmon%' OR name LIKE '%Spinach%' OR name LIKE '%Oat%' OR
        name LIKE '%Walnut%' OR name LIKE '%Peanut%' OR name LIKE '%Avocado%' OR
        name LIKE '%Strawberry%' OR name LIKE '%Watermelon%' OR
        name LIKE '%Shrimp%' OR name LIKE '%Sardine%' OR name LIKE '%Cream%' OR
        name LIKE '%Mayonnaise%' OR name LIKE '%Ketchup%' OR name LIKE '%Mustard%' OR
        name LIKE '%Cookie%' OR name LIKE '%Biscuit%' OR name LIKE '%Croissant%' OR
        name LIKE '%Pancake%' OR name LIKE '%Waffle%' OR name LIKE '%Apple%' OR
        name LIKE '%Rice%' OR name LIKE '%Mango%' OR name LIKE '%Peach%' OR
        name LIKE '%Grape%' OR name LIKE '%Corn%'
    ''');

    db.execute(
      "INSERT INTO foods_catalog_fts(foods_catalog_fts) VALUES('rebuild')",
    );
    db.execute(
      'INSERT OR REPLACE INTO meta_entries(key, value) VALUES (?, ?)',
      ['catalog_version', _catalogVersion.toString()],
    );
    db.execute('PRAGMA user_version = $_driftSchemaVersion;');
    db.execute('VACUUM;');

    final reportFile = File(reportPath);
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'csvPath': csvPath,
        'outputPath': outputPath,
        'catalogVersion': _catalogVersion,
        'driftSchemaVersion': _driftSchemaVersion,
        'insertedRows': inserted,
        'skippedRows': skipped,
        'minimumExpectedRows': _minimumExpectedRows,
        'skippedDetails': skippedRows,
      }),
      flush: true,
    );

    if (inserted < _minimumExpectedRows) {
      stderr.writeln(
        'Inserted rows ($inserted) below expected minimum ($_minimumExpectedRows).',
      );
      stderr.writeln('See report: $reportPath');
      exitCode = 1;
      return;
    }

    stdout.writeln('Built local food db: $outputPath');
    stdout.writeln('Inserted rows: $inserted');
    stdout.writeln('Skipped rows: $skipped');
    stdout.writeln('Report: $reportPath');
  } finally {
    db.dispose();
  }
}

String _cell(List<dynamic> row, int index, {String fallback = ''}) {
  if (index >= row.length) return fallback;
  final value = row[index].toString().trim();
  return value.isEmpty ? fallback : value;
}

double _num(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
