import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_food_db.g.dart';

const String _localFoodAssetDbPath = 'assets/database/local_food.db';
const int _localFoodCatalogVersion = 4;
const String _metaCatalogVersionKey = 'catalog_version';

class FoodsCatalog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get nameFr => text().nullable()();
  TextColumn get nameAr => text().nullable()();
  RealColumn get calories => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fats => real().withDefault(const Constant(0))();
  TextColumn get quantityEn => text()();
  TextColumn get quantityFr => text().nullable()();
  TextColumn get quantityAr => text().nullable()();
}

class UserFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mealType => text()();
  TextColumn get name => text()();
  TextColumn get quantity => text()();
  IntColumn get calories => integer().withDefault(const Constant(0))();
  IntColumn get carbs => integer().withDefault(const Constant(0))();
  IntColumn get protein => integer().withDefault(const Constant(0))();
  IntColumn get fats => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
}

class MetaEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class LocalFoodCatalogEntry {
  final int id;
  final String name;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;
  final String quantity;

  const LocalFoodCatalogEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.quantity,
  });
}

class LocalFoodUserEntry {
  final int id;
  final String mealType;
  final String name;
  final String quantity;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;

  const LocalFoodUserEntry({
    required this.id,
    required this.mealType,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
  });
}

@DriftDatabase(tables: [FoodsCatalog, UserFoods, MetaEntries])
class LocalFoodDb extends _$LocalFoodDb {
  LocalFoodDb._internal() : super(_openConnection());

  static final LocalFoodDb instance = LocalFoodDb._internal();

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createFtsObjects();
      await _setCatalogVersion(_localFoodCatalogVersion);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS meta_entries (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      }
      if (from < 3) {
        await customStatement(
          'ALTER TABLE foods_catalog ADD COLUMN is_popular INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
    beforeOpen: (details) async {
      await _createFtsObjects();
      await _refreshCatalogFromBundledDbIfNeeded();
      await _rebuildFtsIfNeeded();
    },
  );

  Future<void> _refreshCatalogFromBundledDbIfNeeded() async {
    final installedVersion = await _getCatalogVersion();
    if (installedVersion >= _localFoodCatalogVersion) return;

    final tempBundledPath = await _copyBundledDbToTemp();
    if (tempBundledPath == null) {
      return;
    }

    await customStatement('ATTACH DATABASE ? AS bundled_catalog', [
      tempBundledPath,
    ]);
    try {
      await transaction(() async {
        await customStatement('DELETE FROM foods_catalog');
        await customStatement('''
          INSERT INTO foods_catalog (
            id, name, name_fr, name_ar,
            calories, carbs, protein, fats,
            quantity_en, quantity_fr, quantity_ar,
            is_popular
          )
          SELECT
            id, name, name_fr, name_ar,
            calories, carbs, protein, fats,
            quantity_en, quantity_fr, quantity_ar,
            is_popular
          FROM bundled_catalog.foods_catalog
        ''');
        await customStatement(
          "INSERT INTO foods_catalog_fts(foods_catalog_fts) VALUES ('rebuild')",
        );
        await _setCatalogVersion(_localFoodCatalogVersion);
      });
    } finally {
      await customStatement('DETACH DATABASE bundled_catalog');
      try {
        await File(tempBundledPath).delete();
      } catch (_) {}
    }
  }

  Future<int> _getCatalogVersion() async {
    try {
      final row =
          await customSelect(
            'SELECT value FROM meta_entries WHERE key = ?',
            variables: [Variable.withString(_metaCatalogVersionKey)],
          ).getSingleOrNull();
      if (row == null) return 0;
      return int.tryParse((row.data['value'] as String?) ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setCatalogVersion(int version) async {
    await customStatement(
      '''
      INSERT INTO meta_entries (key, value)
      VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
      ''',
      [_metaCatalogVersionKey, version.toString()],
    );
  }

  Future<String?> _copyBundledDbToTemp() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final tmp = File(
        p.join(
          dir.path,
          'local_food_catalog_refresh_${DateTime.now().microsecondsSinceEpoch}.db',
        ),
      );
      final data = await rootBundle.load(_localFoodAssetDbPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await tmp.writeAsBytes(bytes, flush: true);
      return tmp.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createFtsObjects() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS foods_catalog_fts USING fts5(
        name,
        name_fr,
        name_ar,
        content='foods_catalog',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS foods_catalog_ai AFTER INSERT ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(rowid, name, name_fr, name_ar)
        VALUES (new.id, new.name, new.name_fr, new.name_ar);
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS foods_catalog_ad AFTER DELETE ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(foods_catalog_fts, rowid, name, name_fr, name_ar)
        VALUES('delete', old.id, old.name, old.name_fr, old.name_ar);
      END
    ''');

    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS foods_catalog_au AFTER UPDATE ON foods_catalog BEGIN
        INSERT INTO foods_catalog_fts(foods_catalog_fts, rowid, name, name_fr, name_ar)
        VALUES('delete', old.id, old.name, old.name_fr, old.name_ar);
        INSERT INTO foods_catalog_fts(rowid, name, name_fr, name_ar)
        VALUES (new.id, new.name, new.name_fr, new.name_ar);
      END
    ''');
  }

  Future<void> _rebuildFtsIfNeeded() async {
    final catalogCount =
        await customSelect(
          'SELECT COUNT(*) AS c FROM foods_catalog',
        ).getSingle();
    final ftsCount =
        await customSelect(
          'SELECT COUNT(*) AS c FROM foods_catalog_fts',
        ).getSingle();

    final catalogValue = (catalogCount.data['c'] as int?) ?? 0;
    final ftsValue = (ftsCount.data['c'] as int?) ?? 0;

    if (catalogValue > 0 && ftsValue == 0) {
      await customStatement(
        "INSERT INTO foods_catalog_fts(foods_catalog_fts) VALUES ('rebuild')",
      );
    }
  }

  Future<List<LocalFoodCatalogEntry>> searchCatalog({
    required String query,
    required String locale,
    int limit = 1000,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      final rows = await customSelect(
        'SELECT * FROM foods_catalog WHERE is_popular = 1 ORDER BY RANDOM() LIMIT ?',
        variables: [Variable.withInt(limit)],
      ).get();
      return rows.map((row) {
        final m = row.data;
        return LocalFoodCatalogEntry(
          id: (m['id'] as int?) ?? 0,
          name: _localizedName(m, locale),
          calories: ((m['calories'] as num?) ?? 0).round(),
          carbs: ((m['carbs'] as num?) ?? 0).round(),
          protein: ((m['protein'] as num?) ?? 0).round(),
          fats: ((m['fats'] as num?) ?? 0).round(),
          quantity: _localizedQuantity(m, locale),
        );
      }).toList();
    }

    final ftsQuery = _toFtsQuery(normalized);
    if (ftsQuery.isEmpty) return const [];

    final result =
        await customSelect(
          '''
      SELECT c.*
      FROM foods_catalog_fts f
      JOIN foods_catalog c ON c.id = f.rowid
      WHERE foods_catalog_fts MATCH ?
      ORDER BY bm25(foods_catalog_fts)
      LIMIT ?
      ''',
          variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
        ).get();

    return result.map((row) {
      final m = row.data;
      return LocalFoodCatalogEntry(
        id: (m['id'] as int?) ?? 0,
        name: _localizedName(m, locale),
        calories: ((m['calories'] as num?) ?? 0).round(),
        carbs: ((m['carbs'] as num?) ?? 0).round(),
        protein: ((m['protein'] as num?) ?? 0).round(),
        fats: ((m['fats'] as num?) ?? 0).round(),
        quantity: _localizedQuantity(m, locale),
      );
    }).toList();
  }

  Future<List<LocalFoodUserEntry>> getUserFoodsByMealType(
    String mealType,
  ) async {
    final rows =
        await (select(userFoods)
              ..where((t) => t.mealType.equals(mealType))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows
        .map(
          (row) => LocalFoodUserEntry(
            id: row.id,
            mealType: row.mealType,
            name: row.name,
            quantity: row.quantity,
            calories: row.calories,
            carbs: row.carbs,
            protein: row.protein,
            fats: row.fats,
          ),
        )
        .toList();
  }

  Future<List<LocalFoodUserEntry>> searchUserFoodsByMealType(
    String mealType,
    String query,
  ) async {
    final q = '%${query.trim().toLowerCase()}%';
    final rows =
        await customSelect(
          '''
      SELECT * FROM user_foods
      WHERE meal_type = ?
        AND LOWER(name) LIKE ?
      ORDER BY created_at DESC
      ''',
          variables: [Variable.withString(mealType), Variable.withString(q)],
        ).get();

    return rows
        .map(
          (row) => LocalFoodUserEntry(
            id: (row.data['id'] as int?) ?? 0,
            mealType: (row.data['meal_type'] as String?) ?? '',
            name: (row.data['name'] as String?) ?? '',
            quantity: (row.data['quantity'] as String?) ?? '',
            calories: (row.data['calories'] as int?) ?? 0,
            carbs: (row.data['carbs'] as int?) ?? 0,
            protein: (row.data['protein'] as int?) ?? 0,
            fats: (row.data['fats'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<int> insertUserFood({
    required String mealType,
    required LocalFoodUserEntry entry,
  }) {
    return into(userFoods).insert(
      UserFoodsCompanion.insert(
        mealType: mealType,
        name: entry.name,
        quantity: entry.quantity,
        calories: Value(entry.calories),
        carbs: Value(entry.carbs),
        protein: Value(entry.protein),
        fats: Value(entry.fats),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> updateUserFood({
    required int id,
    required LocalFoodUserEntry entry,
  }) async {
    await (update(userFoods)..where((t) => t.id.equals(id))).write(
      UserFoodsCompanion(
        name: Value(entry.name),
        quantity: Value(entry.quantity),
        calories: Value(entry.calories),
        carbs: Value(entry.carbs),
        protein: Value(entry.protein),
        fats: Value(entry.fats),
      ),
    );
  }

  Future<void> deleteUserFoodsByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    await (delete(userFoods)..where((t) => t.id.isIn(ids))).go();
  }

  String _localizedName(Map<String, Object?> row, String locale) {
    final en = (row['name'] as String?) ?? '';
    final fr = (row['name_fr'] as String?) ?? en;
    final ar = (row['name_ar'] as String?) ?? en;
    switch (locale) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  String _localizedQuantity(Map<String, Object?> row, String locale) {
    final en = (row['quantity_en'] as String?) ?? '100 g';
    final fr = (row['quantity_fr'] as String?) ?? en;
    final ar = (row['quantity_ar'] as String?) ?? en;
    switch (locale) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  String _toFtsQuery(String input) {
    final tokens =
        input
            .trim()
            .split(RegExp(r'\s+'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .map((t) => '"${t.replaceAll('"', '""')}"*')
            .toList();
    return tokens.join(' ');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final dbFile = File(p.join(dir.path, 'local_food.db'));
    if (!await dbFile.exists()) {
      await dbFile.parent.create(recursive: true);
      try {
        final tempPath = '${dbFile.path}.tmp';
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        final data = await rootBundle.load(_localFoodAssetDbPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await tempFile.writeAsBytes(bytes, flush: true);
        await tempFile.rename(dbFile.path);
      } catch (_) {
        // If no prebuilt db asset exists, Drift will create an empty db.
      }
    }
    return NativeDatabase.createInBackground(dbFile);
  });
}
