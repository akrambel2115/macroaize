// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_food_db.dart';

// ignore_for_file: type=lint
class $FoodsCatalogTable extends FoodsCatalog
    with TableInfo<$FoodsCatalogTable, FoodsCatalogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsCatalogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameFrMeta = const VerificationMeta('nameFr');
  @override
  late final GeneratedColumn<String> nameFr = GeneratedColumn<String>(
    'name_fr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatsMeta = const VerificationMeta('fats');
  @override
  late final GeneratedColumn<double> fats = GeneratedColumn<double>(
    'fats',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityEnMeta = const VerificationMeta(
    'quantityEn',
  );
  @override
  late final GeneratedColumn<String> quantityEn = GeneratedColumn<String>(
    'quantity_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityFrMeta = const VerificationMeta(
    'quantityFr',
  );
  @override
  late final GeneratedColumn<String> quantityFr = GeneratedColumn<String>(
    'quantity_fr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityArMeta = const VerificationMeta(
    'quantityAr',
  );
  @override
  late final GeneratedColumn<String> quantityAr = GeneratedColumn<String>(
    'quantity_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameFr,
    nameAr,
    calories,
    carbs,
    protein,
    fats,
    quantityEn,
    quantityFr,
    quantityAr,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods_catalog';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodsCatalogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_fr')) {
      context.handle(
        _nameFrMeta,
        nameFr.isAcceptableOrUnknown(data['name_fr']!, _nameFrMeta),
      );
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('fats')) {
      context.handle(
        _fatsMeta,
        fats.isAcceptableOrUnknown(data['fats']!, _fatsMeta),
      );
    }
    if (data.containsKey('quantity_en')) {
      context.handle(
        _quantityEnMeta,
        quantityEn.isAcceptableOrUnknown(data['quantity_en']!, _quantityEnMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityEnMeta);
    }
    if (data.containsKey('quantity_fr')) {
      context.handle(
        _quantityFrMeta,
        quantityFr.isAcceptableOrUnknown(data['quantity_fr']!, _quantityFrMeta),
      );
    }
    if (data.containsKey('quantity_ar')) {
      context.handle(
        _quantityArMeta,
        quantityAr.isAcceptableOrUnknown(data['quantity_ar']!, _quantityArMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodsCatalogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodsCatalogData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      nameFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_fr'],
      ),
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      calories:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}calories'],
          )!,
      carbs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}carbs'],
          )!,
      protein:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}protein'],
          )!,
      fats:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}fats'],
          )!,
      quantityEn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}quantity_en'],
          )!,
      quantityFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_fr'],
      ),
      quantityAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_ar'],
      ),
    );
  }

  @override
  $FoodsCatalogTable createAlias(String alias) {
    return $FoodsCatalogTable(attachedDatabase, alias);
  }
}

class FoodsCatalogData extends DataClass
    implements Insertable<FoodsCatalogData> {
  final int id;
  final String name;
  final String? nameFr;
  final String? nameAr;
  final double calories;
  final double carbs;
  final double protein;
  final double fats;
  final String quantityEn;
  final String? quantityFr;
  final String? quantityAr;
  const FoodsCatalogData({
    required this.id,
    required this.name,
    this.nameFr,
    this.nameAr,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.quantityEn,
    this.quantityFr,
    this.quantityAr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameFr != null) {
      map['name_fr'] = Variable<String>(nameFr);
    }
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    map['calories'] = Variable<double>(calories);
    map['carbs'] = Variable<double>(carbs);
    map['protein'] = Variable<double>(protein);
    map['fats'] = Variable<double>(fats);
    map['quantity_en'] = Variable<String>(quantityEn);
    if (!nullToAbsent || quantityFr != null) {
      map['quantity_fr'] = Variable<String>(quantityFr);
    }
    if (!nullToAbsent || quantityAr != null) {
      map['quantity_ar'] = Variable<String>(quantityAr);
    }
    return map;
  }

  FoodsCatalogCompanion toCompanion(bool nullToAbsent) {
    return FoodsCatalogCompanion(
      id: Value(id),
      name: Value(name),
      nameFr:
          nameFr == null && nullToAbsent ? const Value.absent() : Value(nameFr),
      nameAr:
          nameAr == null && nullToAbsent ? const Value.absent() : Value(nameAr),
      calories: Value(calories),
      carbs: Value(carbs),
      protein: Value(protein),
      fats: Value(fats),
      quantityEn: Value(quantityEn),
      quantityFr:
          quantityFr == null && nullToAbsent
              ? const Value.absent()
              : Value(quantityFr),
      quantityAr:
          quantityAr == null && nullToAbsent
              ? const Value.absent()
              : Value(quantityAr),
    );
  }

  factory FoodsCatalogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodsCatalogData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameFr: serializer.fromJson<String?>(json['nameFr']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      calories: serializer.fromJson<double>(json['calories']),
      carbs: serializer.fromJson<double>(json['carbs']),
      protein: serializer.fromJson<double>(json['protein']),
      fats: serializer.fromJson<double>(json['fats']),
      quantityEn: serializer.fromJson<String>(json['quantityEn']),
      quantityFr: serializer.fromJson<String?>(json['quantityFr']),
      quantityAr: serializer.fromJson<String?>(json['quantityAr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameFr': serializer.toJson<String?>(nameFr),
      'nameAr': serializer.toJson<String?>(nameAr),
      'calories': serializer.toJson<double>(calories),
      'carbs': serializer.toJson<double>(carbs),
      'protein': serializer.toJson<double>(protein),
      'fats': serializer.toJson<double>(fats),
      'quantityEn': serializer.toJson<String>(quantityEn),
      'quantityFr': serializer.toJson<String?>(quantityFr),
      'quantityAr': serializer.toJson<String?>(quantityAr),
    };
  }

  FoodsCatalogData copyWith({
    int? id,
    String? name,
    Value<String?> nameFr = const Value.absent(),
    Value<String?> nameAr = const Value.absent(),
    double? calories,
    double? carbs,
    double? protein,
    double? fats,
    String? quantityEn,
    Value<String?> quantityFr = const Value.absent(),
    Value<String?> quantityAr = const Value.absent(),
  }) => FoodsCatalogData(
    id: id ?? this.id,
    name: name ?? this.name,
    nameFr: nameFr.present ? nameFr.value : this.nameFr,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    calories: calories ?? this.calories,
    carbs: carbs ?? this.carbs,
    protein: protein ?? this.protein,
    fats: fats ?? this.fats,
    quantityEn: quantityEn ?? this.quantityEn,
    quantityFr: quantityFr.present ? quantityFr.value : this.quantityFr,
    quantityAr: quantityAr.present ? quantityAr.value : this.quantityAr,
  );
  FoodsCatalogData copyWithCompanion(FoodsCatalogCompanion data) {
    return FoodsCatalogData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameFr: data.nameFr.present ? data.nameFr.value : this.nameFr,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      calories: data.calories.present ? data.calories.value : this.calories,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      protein: data.protein.present ? data.protein.value : this.protein,
      fats: data.fats.present ? data.fats.value : this.fats,
      quantityEn:
          data.quantityEn.present ? data.quantityEn.value : this.quantityEn,
      quantityFr:
          data.quantityFr.present ? data.quantityFr.value : this.quantityFr,
      quantityAr:
          data.quantityAr.present ? data.quantityAr.value : this.quantityAr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCatalogData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('calories: $calories, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fats: $fats, ')
          ..write('quantityEn: $quantityEn, ')
          ..write('quantityFr: $quantityFr, ')
          ..write('quantityAr: $quantityAr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    nameFr,
    nameAr,
    calories,
    carbs,
    protein,
    fats,
    quantityEn,
    quantityFr,
    quantityAr,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodsCatalogData &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameFr == this.nameFr &&
          other.nameAr == this.nameAr &&
          other.calories == this.calories &&
          other.carbs == this.carbs &&
          other.protein == this.protein &&
          other.fats == this.fats &&
          other.quantityEn == this.quantityEn &&
          other.quantityFr == this.quantityFr &&
          other.quantityAr == this.quantityAr);
}

class FoodsCatalogCompanion extends UpdateCompanion<FoodsCatalogData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> nameFr;
  final Value<String?> nameAr;
  final Value<double> calories;
  final Value<double> carbs;
  final Value<double> protein;
  final Value<double> fats;
  final Value<String> quantityEn;
  final Value<String?> quantityFr;
  final Value<String?> quantityAr;
  const FoodsCatalogCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameFr = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.calories = const Value.absent(),
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fats = const Value.absent(),
    this.quantityEn = const Value.absent(),
    this.quantityFr = const Value.absent(),
    this.quantityAr = const Value.absent(),
  });
  FoodsCatalogCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.nameFr = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.calories = const Value.absent(),
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fats = const Value.absent(),
    required String quantityEn,
    this.quantityFr = const Value.absent(),
    this.quantityAr = const Value.absent(),
  }) : name = Value(name),
       quantityEn = Value(quantityEn);
  static Insertable<FoodsCatalogData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameFr,
    Expression<String>? nameAr,
    Expression<double>? calories,
    Expression<double>? carbs,
    Expression<double>? protein,
    Expression<double>? fats,
    Expression<String>? quantityEn,
    Expression<String>? quantityFr,
    Expression<String>? quantityAr,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameFr != null) 'name_fr': nameFr,
      if (nameAr != null) 'name_ar': nameAr,
      if (calories != null) 'calories': calories,
      if (carbs != null) 'carbs': carbs,
      if (protein != null) 'protein': protein,
      if (fats != null) 'fats': fats,
      if (quantityEn != null) 'quantity_en': quantityEn,
      if (quantityFr != null) 'quantity_fr': quantityFr,
      if (quantityAr != null) 'quantity_ar': quantityAr,
    });
  }

  FoodsCatalogCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? nameFr,
    Value<String?>? nameAr,
    Value<double>? calories,
    Value<double>? carbs,
    Value<double>? protein,
    Value<double>? fats,
    Value<String>? quantityEn,
    Value<String?>? quantityFr,
    Value<String?>? quantityAr,
  }) {
    return FoodsCatalogCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      quantityEn: quantityEn ?? this.quantityEn,
      quantityFr: quantityFr ?? this.quantityFr,
      quantityAr: quantityAr ?? this.quantityAr,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameFr.present) {
      map['name_fr'] = Variable<String>(nameFr.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fats.present) {
      map['fats'] = Variable<double>(fats.value);
    }
    if (quantityEn.present) {
      map['quantity_en'] = Variable<String>(quantityEn.value);
    }
    if (quantityFr.present) {
      map['quantity_fr'] = Variable<String>(quantityFr.value);
    }
    if (quantityAr.present) {
      map['quantity_ar'] = Variable<String>(quantityAr.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCatalogCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameFr: $nameFr, ')
          ..write('nameAr: $nameAr, ')
          ..write('calories: $calories, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fats: $fats, ')
          ..write('quantityEn: $quantityEn, ')
          ..write('quantityFr: $quantityFr, ')
          ..write('quantityAr: $quantityAr')
          ..write(')'))
        .toString();
  }
}

class $UserFoodsTable extends UserFoods
    with TableInfo<$UserFoodsTable, UserFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mealTypeMeta = const VerificationMeta(
    'mealType',
  );
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
    'meal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<int> carbs = GeneratedColumn<int>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<int> protein = GeneratedColumn<int>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatsMeta = const VerificationMeta('fats');
  @override
  late final GeneratedColumn<int> fats = GeneratedColumn<int>(
    'fats',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealType,
    name,
    quantity,
    calories,
    carbs,
    protein,
    fats,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_type')) {
      context.handle(
        _mealTypeMeta,
        mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('fats')) {
      context.handle(
        _fatsMeta,
        fats.isAcceptableOrUnknown(data['fats']!, _fatsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFood(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      mealType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}meal_type'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      quantity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}quantity'],
          )!,
      calories:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}calories'],
          )!,
      carbs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}carbs'],
          )!,
      protein:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}protein'],
          )!,
      fats:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}fats'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $UserFoodsTable createAlias(String alias) {
    return $UserFoodsTable(attachedDatabase, alias);
  }
}

class UserFood extends DataClass implements Insertable<UserFood> {
  final int id;
  final String mealType;
  final String name;
  final String quantity;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;
  final int createdAt;
  const UserFood({
    required this.id,
    required this.mealType,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_type'] = Variable<String>(mealType);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<String>(quantity);
    map['calories'] = Variable<int>(calories);
    map['carbs'] = Variable<int>(carbs);
    map['protein'] = Variable<int>(protein);
    map['fats'] = Variable<int>(fats);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UserFoodsCompanion toCompanion(bool nullToAbsent) {
    return UserFoodsCompanion(
      id: Value(id),
      mealType: Value(mealType),
      name: Value(name),
      quantity: Value(quantity),
      calories: Value(calories),
      carbs: Value(carbs),
      protein: Value(protein),
      fats: Value(fats),
      createdAt: Value(createdAt),
    );
  }

  factory UserFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFood(
      id: serializer.fromJson<int>(json['id']),
      mealType: serializer.fromJson<String>(json['mealType']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String>(json['quantity']),
      calories: serializer.fromJson<int>(json['calories']),
      carbs: serializer.fromJson<int>(json['carbs']),
      protein: serializer.fromJson<int>(json['protein']),
      fats: serializer.fromJson<int>(json['fats']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealType': serializer.toJson<String>(mealType),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String>(quantity),
      'calories': serializer.toJson<int>(calories),
      'carbs': serializer.toJson<int>(carbs),
      'protein': serializer.toJson<int>(protein),
      'fats': serializer.toJson<int>(fats),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UserFood copyWith({
    int? id,
    String? mealType,
    String? name,
    String? quantity,
    int? calories,
    int? carbs,
    int? protein,
    int? fats,
    int? createdAt,
  }) => UserFood(
    id: id ?? this.id,
    mealType: mealType ?? this.mealType,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    calories: calories ?? this.calories,
    carbs: carbs ?? this.carbs,
    protein: protein ?? this.protein,
    fats: fats ?? this.fats,
    createdAt: createdAt ?? this.createdAt,
  );
  UserFood copyWithCompanion(UserFoodsCompanion data) {
    return UserFood(
      id: data.id.present ? data.id.value : this.id,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      calories: data.calories.present ? data.calories.value : this.calories,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      protein: data.protein.present ? data.protein.value : this.protein,
      fats: data.fats.present ? data.fats.value : this.fats,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFood(')
          ..write('id: $id, ')
          ..write('mealType: $mealType, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('calories: $calories, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fats: $fats, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mealType,
    name,
    quantity,
    calories,
    carbs,
    protein,
    fats,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFood &&
          other.id == this.id &&
          other.mealType == this.mealType &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.calories == this.calories &&
          other.carbs == this.carbs &&
          other.protein == this.protein &&
          other.fats == this.fats &&
          other.createdAt == this.createdAt);
}

class UserFoodsCompanion extends UpdateCompanion<UserFood> {
  final Value<int> id;
  final Value<String> mealType;
  final Value<String> name;
  final Value<String> quantity;
  final Value<int> calories;
  final Value<int> carbs;
  final Value<int> protein;
  final Value<int> fats;
  final Value<int> createdAt;
  const UserFoodsCompanion({
    this.id = const Value.absent(),
    this.mealType = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.calories = const Value.absent(),
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fats = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String mealType,
    required String name,
    required String quantity,
    this.calories = const Value.absent(),
    this.carbs = const Value.absent(),
    this.protein = const Value.absent(),
    this.fats = const Value.absent(),
    required int createdAt,
  }) : mealType = Value(mealType),
       name = Value(name),
       quantity = Value(quantity),
       createdAt = Value(createdAt);
  static Insertable<UserFood> custom({
    Expression<int>? id,
    Expression<String>? mealType,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<int>? calories,
    Expression<int>? carbs,
    Expression<int>? protein,
    Expression<int>? fats,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealType != null) 'meal_type': mealType,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (calories != null) 'calories': calories,
      if (carbs != null) 'carbs': carbs,
      if (protein != null) 'protein': protein,
      if (fats != null) 'fats': fats,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserFoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? mealType,
    Value<String>? name,
    Value<String>? quantity,
    Value<int>? calories,
    Value<int>? carbs,
    Value<int>? protein,
    Value<int>? fats,
    Value<int>? createdAt,
  }) {
    return UserFoodsCompanion(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<int>(carbs.value);
    }
    if (protein.present) {
      map['protein'] = Variable<int>(protein.value);
    }
    if (fats.present) {
      map['fats'] = Variable<int>(fats.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFoodsCompanion(')
          ..write('id: $id, ')
          ..write('mealType: $mealType, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('calories: $calories, ')
          ..write('carbs: $carbs, ')
          ..write('protein: $protein, ')
          ..write('fats: $fats, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MetaEntriesTable extends MetaEntries
    with TableInfo<$MetaEntriesTable, MetaEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaEntry(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $MetaEntriesTable createAlias(String alias) {
    return $MetaEntriesTable(attachedDatabase, alias);
  }
}

class MetaEntry extends DataClass implements Insertable<MetaEntry> {
  final String key;
  final String value;
  const MetaEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaEntriesCompanion toCompanion(bool nullToAbsent) {
    return MetaEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory MetaEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaEntry copyWith({String? key, String? value}) =>
      MetaEntry(key: key ?? this.key, value: value ?? this.value);
  MetaEntry copyWithCompanion(MetaEntriesCompanion data) {
    return MetaEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class MetaEntriesCompanion extends UpdateCompanion<MetaEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalFoodDb extends GeneratedDatabase {
  _$LocalFoodDb(QueryExecutor e) : super(e);
  $LocalFoodDbManager get managers => $LocalFoodDbManager(this);
  late final $FoodsCatalogTable foodsCatalog = $FoodsCatalogTable(this);
  late final $UserFoodsTable userFoods = $UserFoodsTable(this);
  late final $MetaEntriesTable metaEntries = $MetaEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodsCatalog,
    userFoods,
    metaEntries,
  ];
}

typedef $$FoodsCatalogTableCreateCompanionBuilder =
    FoodsCatalogCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> nameFr,
      Value<String?> nameAr,
      Value<double> calories,
      Value<double> carbs,
      Value<double> protein,
      Value<double> fats,
      required String quantityEn,
      Value<String?> quantityFr,
      Value<String?> quantityAr,
    });
typedef $$FoodsCatalogTableUpdateCompanionBuilder =
    FoodsCatalogCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> nameFr,
      Value<String?> nameAr,
      Value<double> calories,
      Value<double> carbs,
      Value<double> protein,
      Value<double> fats,
      Value<String> quantityEn,
      Value<String?> quantityFr,
      Value<String?> quantityAr,
    });

class $$FoodsCatalogTableFilterComposer
    extends Composer<_$LocalFoodDb, $FoodsCatalogTable> {
  $$FoodsCatalogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityEn => $composableBuilder(
    column: $table.quantityEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityFr => $composableBuilder(
    column: $table.quantityFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityAr => $composableBuilder(
    column: $table.quantityAr,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodsCatalogTableOrderingComposer
    extends Composer<_$LocalFoodDb, $FoodsCatalogTable> {
  $$FoodsCatalogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameFr => $composableBuilder(
    column: $table.nameFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityEn => $composableBuilder(
    column: $table.quantityEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityFr => $composableBuilder(
    column: $table.quantityFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityAr => $composableBuilder(
    column: $table.quantityAr,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsCatalogTableAnnotationComposer
    extends Composer<_$LocalFoodDb, $FoodsCatalogTable> {
  $$FoodsCatalogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameFr =>
      $composableBuilder(column: $table.nameFr, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fats =>
      $composableBuilder(column: $table.fats, builder: (column) => column);

  GeneratedColumn<String> get quantityEn => $composableBuilder(
    column: $table.quantityEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityFr => $composableBuilder(
    column: $table.quantityFr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityAr => $composableBuilder(
    column: $table.quantityAr,
    builder: (column) => column,
  );
}

class $$FoodsCatalogTableTableManager
    extends
        RootTableManager<
          _$LocalFoodDb,
          $FoodsCatalogTable,
          FoodsCatalogData,
          $$FoodsCatalogTableFilterComposer,
          $$FoodsCatalogTableOrderingComposer,
          $$FoodsCatalogTableAnnotationComposer,
          $$FoodsCatalogTableCreateCompanionBuilder,
          $$FoodsCatalogTableUpdateCompanionBuilder,
          (
            FoodsCatalogData,
            BaseReferences<_$LocalFoodDb, $FoodsCatalogTable, FoodsCatalogData>,
          ),
          FoodsCatalogData,
          PrefetchHooks Function()
        > {
  $$FoodsCatalogTableTableManager(_$LocalFoodDb db, $FoodsCatalogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$FoodsCatalogTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$FoodsCatalogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$FoodsCatalogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameFr = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fats = const Value.absent(),
                Value<String> quantityEn = const Value.absent(),
                Value<String?> quantityFr = const Value.absent(),
                Value<String?> quantityAr = const Value.absent(),
              }) => FoodsCatalogCompanion(
                id: id,
                name: name,
                nameFr: nameFr,
                nameAr: nameAr,
                calories: calories,
                carbs: carbs,
                protein: protein,
                fats: fats,
                quantityEn: quantityEn,
                quantityFr: quantityFr,
                quantityAr: quantityAr,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> nameFr = const Value.absent(),
                Value<String?> nameAr = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fats = const Value.absent(),
                required String quantityEn,
                Value<String?> quantityFr = const Value.absent(),
                Value<String?> quantityAr = const Value.absent(),
              }) => FoodsCatalogCompanion.insert(
                id: id,
                name: name,
                nameFr: nameFr,
                nameAr: nameAr,
                calories: calories,
                carbs: carbs,
                protein: protein,
                fats: fats,
                quantityEn: quantityEn,
                quantityFr: quantityFr,
                quantityAr: quantityAr,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodsCatalogTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalFoodDb,
      $FoodsCatalogTable,
      FoodsCatalogData,
      $$FoodsCatalogTableFilterComposer,
      $$FoodsCatalogTableOrderingComposer,
      $$FoodsCatalogTableAnnotationComposer,
      $$FoodsCatalogTableCreateCompanionBuilder,
      $$FoodsCatalogTableUpdateCompanionBuilder,
      (
        FoodsCatalogData,
        BaseReferences<_$LocalFoodDb, $FoodsCatalogTable, FoodsCatalogData>,
      ),
      FoodsCatalogData,
      PrefetchHooks Function()
    >;
typedef $$UserFoodsTableCreateCompanionBuilder =
    UserFoodsCompanion Function({
      Value<int> id,
      required String mealType,
      required String name,
      required String quantity,
      Value<int> calories,
      Value<int> carbs,
      Value<int> protein,
      Value<int> fats,
      required int createdAt,
    });
typedef $$UserFoodsTableUpdateCompanionBuilder =
    UserFoodsCompanion Function({
      Value<int> id,
      Value<String> mealType,
      Value<String> name,
      Value<String> quantity,
      Value<int> calories,
      Value<int> carbs,
      Value<int> protein,
      Value<int> fats,
      Value<int> createdAt,
    });

class $$UserFoodsTableFilterComposer
    extends Composer<_$LocalFoodDb, $UserFoodsTable> {
  $$UserFoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserFoodsTableOrderingComposer
    extends Composer<_$LocalFoodDb, $UserFoodsTable> {
  $$UserFoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fats => $composableBuilder(
    column: $table.fats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserFoodsTableAnnotationComposer
    extends Composer<_$LocalFoodDb, $UserFoodsTable> {
  $$UserFoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<int> get fats =>
      $composableBuilder(column: $table.fats, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserFoodsTableTableManager
    extends
        RootTableManager<
          _$LocalFoodDb,
          $UserFoodsTable,
          UserFood,
          $$UserFoodsTableFilterComposer,
          $$UserFoodsTableOrderingComposer,
          $$UserFoodsTableAnnotationComposer,
          $$UserFoodsTableCreateCompanionBuilder,
          $$UserFoodsTableUpdateCompanionBuilder,
          (UserFood, BaseReferences<_$LocalFoodDb, $UserFoodsTable, UserFood>),
          UserFood,
          PrefetchHooks Function()
        > {
  $$UserFoodsTableTableManager(_$LocalFoodDb db, $UserFoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UserFoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UserFoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UserFoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mealType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<int> calories = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> fats = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => UserFoodsCompanion(
                id: id,
                mealType: mealType,
                name: name,
                quantity: quantity,
                calories: calories,
                carbs: carbs,
                protein: protein,
                fats: fats,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mealType,
                required String name,
                required String quantity,
                Value<int> calories = const Value.absent(),
                Value<int> carbs = const Value.absent(),
                Value<int> protein = const Value.absent(),
                Value<int> fats = const Value.absent(),
                required int createdAt,
              }) => UserFoodsCompanion.insert(
                id: id,
                mealType: mealType,
                name: name,
                quantity: quantity,
                calories: calories,
                carbs: carbs,
                protein: protein,
                fats: fats,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserFoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalFoodDb,
      $UserFoodsTable,
      UserFood,
      $$UserFoodsTableFilterComposer,
      $$UserFoodsTableOrderingComposer,
      $$UserFoodsTableAnnotationComposer,
      $$UserFoodsTableCreateCompanionBuilder,
      $$UserFoodsTableUpdateCompanionBuilder,
      (UserFood, BaseReferences<_$LocalFoodDb, $UserFoodsTable, UserFood>),
      UserFood,
      PrefetchHooks Function()
    >;
typedef $$MetaEntriesTableCreateCompanionBuilder =
    MetaEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaEntriesTableUpdateCompanionBuilder =
    MetaEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaEntriesTableFilterComposer
    extends Composer<_$LocalFoodDb, $MetaEntriesTable> {
  $$MetaEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaEntriesTableOrderingComposer
    extends Composer<_$LocalFoodDb, $MetaEntriesTable> {
  $$MetaEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaEntriesTableAnnotationComposer
    extends Composer<_$LocalFoodDb, $MetaEntriesTable> {
  $$MetaEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalFoodDb,
          $MetaEntriesTable,
          MetaEntry,
          $$MetaEntriesTableFilterComposer,
          $$MetaEntriesTableOrderingComposer,
          $$MetaEntriesTableAnnotationComposer,
          $$MetaEntriesTableCreateCompanionBuilder,
          $$MetaEntriesTableUpdateCompanionBuilder,
          (
            MetaEntry,
            BaseReferences<_$LocalFoodDb, $MetaEntriesTable, MetaEntry>,
          ),
          MetaEntry,
          PrefetchHooks Function()
        > {
  $$MetaEntriesTableTableManager(_$LocalFoodDb db, $MetaEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MetaEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MetaEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$MetaEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalFoodDb,
      $MetaEntriesTable,
      MetaEntry,
      $$MetaEntriesTableFilterComposer,
      $$MetaEntriesTableOrderingComposer,
      $$MetaEntriesTableAnnotationComposer,
      $$MetaEntriesTableCreateCompanionBuilder,
      $$MetaEntriesTableUpdateCompanionBuilder,
      (MetaEntry, BaseReferences<_$LocalFoodDb, $MetaEntriesTable, MetaEntry>),
      MetaEntry,
      PrefetchHooks Function()
    >;

class $LocalFoodDbManager {
  final _$LocalFoodDb _db;
  $LocalFoodDbManager(this._db);
  $$FoodsCatalogTableTableManager get foodsCatalog =>
      $$FoodsCatalogTableTableManager(_db, _db.foodsCatalog);
  $$UserFoodsTableTableManager get userFoods =>
      $$UserFoodsTableTableManager(_db, _db.userFoods);
  $$MetaEntriesTableTableManager get metaEntries =>
      $$MetaEntriesTableTableManager(_db, _db.metaEntries);
}
