// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TermsTable extends Terms with TableInfo<$TermsTable, Term> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termKoMeta = const VerificationMeta('termKo');
  @override
  late final GeneratedColumn<String> termKo = GeneratedColumn<String>(
    'term_ko',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termEnMeta = const VerificationMeta('termEn');
  @override
  late final GeneratedColumn<String> termEn = GeneratedColumn<String>(
    'term_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defMeta = const VerificationMeta('def');
  @override
  late final GeneratedColumn<String> def = GeneratedColumn<String>(
    'def',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whyItMattersMeta = const VerificationMeta(
    'whyItMatters',
  );
  @override
  late final GeneratedColumn<String> whyItMatters = GeneratedColumn<String>(
    'why_it_matters',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subcategoryMeta = const VerificationMeta(
    'subcategory',
  );
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
    'subcategory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tracksJsonMeta = const VerificationMeta(
    'tracksJson',
  );
  @override
  late final GeneratedColumn<String> tracksJson = GeneratedColumn<String>(
    'tracks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _aliasesJsonMeta = const VerificationMeta(
    'aliasesJson',
  );
  @override
  late final GeneratedColumn<String> aliasesJson = GeneratedColumn<String>(
    'aliases_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _confusionJsonMeta = const VerificationMeta(
    'confusionJson',
  );
  @override
  late final GeneratedColumn<String> confusionJson = GeneratedColumn<String>(
    'confusion_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _vibeCoreMeta = const VerificationMeta(
    'vibeCore',
  );
  @override
  late final GeneratedColumn<bool> vibeCore = GeneratedColumn<bool>(
    'vibe_core',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vibe_core" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _volatileInfoMeta = const VerificationMeta(
    'volatileInfo',
  );
  @override
  late final GeneratedColumn<bool> volatileInfo = GeneratedColumn<bool>(
    'volatile_info',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("volatile_info" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quizEnabledMeta = const VerificationMeta(
    'quizEnabled',
  );
  @override
  late final GeneratedColumn<bool> quizEnabled = GeneratedColumn<bool>(
    'quiz_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quiz_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta(
    'retired',
  );
  @override
  late final GeneratedColumn<bool> retired = GeneratedColumn<bool>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    termKo,
    termEn,
    def,
    whyItMatters,
    example,
    category,
    subcategory,
    tracksJson,
    aliasesJson,
    confusionJson,
    difficulty,
    vibeCore,
    volatileInfo,
    quizEnabled,
    retired,
    slug,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'terms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Term> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('term_ko')) {
      context.handle(
        _termKoMeta,
        termKo.isAcceptableOrUnknown(data['term_ko']!, _termKoMeta),
      );
    } else if (isInserting) {
      context.missing(_termKoMeta);
    }
    if (data.containsKey('term_en')) {
      context.handle(
        _termEnMeta,
        termEn.isAcceptableOrUnknown(data['term_en']!, _termEnMeta),
      );
    } else if (isInserting) {
      context.missing(_termEnMeta);
    }
    if (data.containsKey('def')) {
      context.handle(
        _defMeta,
        def.isAcceptableOrUnknown(data['def']!, _defMeta),
      );
    } else if (isInserting) {
      context.missing(_defMeta);
    }
    if (data.containsKey('why_it_matters')) {
      context.handle(
        _whyItMattersMeta,
        whyItMatters.isAcceptableOrUnknown(
          data['why_it_matters']!,
          _whyItMattersMeta,
        ),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subcategory')) {
      context.handle(
        _subcategoryMeta,
        subcategory.isAcceptableOrUnknown(
          data['subcategory']!,
          _subcategoryMeta,
        ),
      );
    }
    if (data.containsKey('tracks_json')) {
      context.handle(
        _tracksJsonMeta,
        tracksJson.isAcceptableOrUnknown(data['tracks_json']!, _tracksJsonMeta),
      );
    }
    if (data.containsKey('aliases_json')) {
      context.handle(
        _aliasesJsonMeta,
        aliasesJson.isAcceptableOrUnknown(
          data['aliases_json']!,
          _aliasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('confusion_json')) {
      context.handle(
        _confusionJsonMeta,
        confusionJson.isAcceptableOrUnknown(
          data['confusion_json']!,
          _confusionJsonMeta,
        ),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('vibe_core')) {
      context.handle(
        _vibeCoreMeta,
        vibeCore.isAcceptableOrUnknown(data['vibe_core']!, _vibeCoreMeta),
      );
    }
    if (data.containsKey('volatile_info')) {
      context.handle(
        _volatileInfoMeta,
        volatileInfo.isAcceptableOrUnknown(
          data['volatile_info']!,
          _volatileInfoMeta,
        ),
      );
    }
    if (data.containsKey('quiz_enabled')) {
      context.handle(
        _quizEnabledMeta,
        quizEnabled.isAcceptableOrUnknown(
          data['quiz_enabled']!,
          _quizEnabledMeta,
        ),
      );
    }
    if (data.containsKey('retired')) {
      context.handle(
        _retiredMeta,
        retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Term map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Term(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      termKo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_ko'],
      )!,
      termEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_en'],
      )!,
      def: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}def'],
      )!,
      whyItMatters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why_it_matters'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory'],
      )!,
      tracksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracks_json'],
      )!,
      aliasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases_json'],
      )!,
      confusionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confusion_json'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      vibeCore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vibe_core'],
      )!,
      volatileInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}volatile_info'],
      )!,
      quizEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quiz_enabled'],
      )!,
      retired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retired'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
    );
  }

  @override
  $TermsTable createAlias(String alias) {
    return $TermsTable(attachedDatabase, alias);
  }
}

class Term extends DataClass implements Insertable<Term> {
  final String id;
  final String termKo;
  final String termEn;
  final String def;
  final String whyItMatters;
  final String example;
  final String category;
  final String subcategory;
  final String tracksJson;
  final String aliasesJson;
  final String confusionJson;
  final int difficulty;
  final bool vibeCore;
  final bool volatileInfo;
  final bool quizEnabled;
  final bool retired;
  final String slug;
  const Term({
    required this.id,
    required this.termKo,
    required this.termEn,
    required this.def,
    required this.whyItMatters,
    required this.example,
    required this.category,
    required this.subcategory,
    required this.tracksJson,
    required this.aliasesJson,
    required this.confusionJson,
    required this.difficulty,
    required this.vibeCore,
    required this.volatileInfo,
    required this.quizEnabled,
    required this.retired,
    required this.slug,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['term_ko'] = Variable<String>(termKo);
    map['term_en'] = Variable<String>(termEn);
    map['def'] = Variable<String>(def);
    map['why_it_matters'] = Variable<String>(whyItMatters);
    map['example'] = Variable<String>(example);
    map['category'] = Variable<String>(category);
    map['subcategory'] = Variable<String>(subcategory);
    map['tracks_json'] = Variable<String>(tracksJson);
    map['aliases_json'] = Variable<String>(aliasesJson);
    map['confusion_json'] = Variable<String>(confusionJson);
    map['difficulty'] = Variable<int>(difficulty);
    map['vibe_core'] = Variable<bool>(vibeCore);
    map['volatile_info'] = Variable<bool>(volatileInfo);
    map['quiz_enabled'] = Variable<bool>(quizEnabled);
    map['retired'] = Variable<bool>(retired);
    map['slug'] = Variable<String>(slug);
    return map;
  }

  TermsCompanion toCompanion(bool nullToAbsent) {
    return TermsCompanion(
      id: Value(id),
      termKo: Value(termKo),
      termEn: Value(termEn),
      def: Value(def),
      whyItMatters: Value(whyItMatters),
      example: Value(example),
      category: Value(category),
      subcategory: Value(subcategory),
      tracksJson: Value(tracksJson),
      aliasesJson: Value(aliasesJson),
      confusionJson: Value(confusionJson),
      difficulty: Value(difficulty),
      vibeCore: Value(vibeCore),
      volatileInfo: Value(volatileInfo),
      quizEnabled: Value(quizEnabled),
      retired: Value(retired),
      slug: Value(slug),
    );
  }

  factory Term.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Term(
      id: serializer.fromJson<String>(json['id']),
      termKo: serializer.fromJson<String>(json['termKo']),
      termEn: serializer.fromJson<String>(json['termEn']),
      def: serializer.fromJson<String>(json['def']),
      whyItMatters: serializer.fromJson<String>(json['whyItMatters']),
      example: serializer.fromJson<String>(json['example']),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<String>(json['subcategory']),
      tracksJson: serializer.fromJson<String>(json['tracksJson']),
      aliasesJson: serializer.fromJson<String>(json['aliasesJson']),
      confusionJson: serializer.fromJson<String>(json['confusionJson']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      vibeCore: serializer.fromJson<bool>(json['vibeCore']),
      volatileInfo: serializer.fromJson<bool>(json['volatileInfo']),
      quizEnabled: serializer.fromJson<bool>(json['quizEnabled']),
      retired: serializer.fromJson<bool>(json['retired']),
      slug: serializer.fromJson<String>(json['slug']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'termKo': serializer.toJson<String>(termKo),
      'termEn': serializer.toJson<String>(termEn),
      'def': serializer.toJson<String>(def),
      'whyItMatters': serializer.toJson<String>(whyItMatters),
      'example': serializer.toJson<String>(example),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<String>(subcategory),
      'tracksJson': serializer.toJson<String>(tracksJson),
      'aliasesJson': serializer.toJson<String>(aliasesJson),
      'confusionJson': serializer.toJson<String>(confusionJson),
      'difficulty': serializer.toJson<int>(difficulty),
      'vibeCore': serializer.toJson<bool>(vibeCore),
      'volatileInfo': serializer.toJson<bool>(volatileInfo),
      'quizEnabled': serializer.toJson<bool>(quizEnabled),
      'retired': serializer.toJson<bool>(retired),
      'slug': serializer.toJson<String>(slug),
    };
  }

  Term copyWith({
    String? id,
    String? termKo,
    String? termEn,
    String? def,
    String? whyItMatters,
    String? example,
    String? category,
    String? subcategory,
    String? tracksJson,
    String? aliasesJson,
    String? confusionJson,
    int? difficulty,
    bool? vibeCore,
    bool? volatileInfo,
    bool? quizEnabled,
    bool? retired,
    String? slug,
  }) => Term(
    id: id ?? this.id,
    termKo: termKo ?? this.termKo,
    termEn: termEn ?? this.termEn,
    def: def ?? this.def,
    whyItMatters: whyItMatters ?? this.whyItMatters,
    example: example ?? this.example,
    category: category ?? this.category,
    subcategory: subcategory ?? this.subcategory,
    tracksJson: tracksJson ?? this.tracksJson,
    aliasesJson: aliasesJson ?? this.aliasesJson,
    confusionJson: confusionJson ?? this.confusionJson,
    difficulty: difficulty ?? this.difficulty,
    vibeCore: vibeCore ?? this.vibeCore,
    volatileInfo: volatileInfo ?? this.volatileInfo,
    quizEnabled: quizEnabled ?? this.quizEnabled,
    retired: retired ?? this.retired,
    slug: slug ?? this.slug,
  );
  Term copyWithCompanion(TermsCompanion data) {
    return Term(
      id: data.id.present ? data.id.value : this.id,
      termKo: data.termKo.present ? data.termKo.value : this.termKo,
      termEn: data.termEn.present ? data.termEn.value : this.termEn,
      def: data.def.present ? data.def.value : this.def,
      whyItMatters: data.whyItMatters.present
          ? data.whyItMatters.value
          : this.whyItMatters,
      example: data.example.present ? data.example.value : this.example,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      tracksJson: data.tracksJson.present
          ? data.tracksJson.value
          : this.tracksJson,
      aliasesJson: data.aliasesJson.present
          ? data.aliasesJson.value
          : this.aliasesJson,
      confusionJson: data.confusionJson.present
          ? data.confusionJson.value
          : this.confusionJson,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      vibeCore: data.vibeCore.present ? data.vibeCore.value : this.vibeCore,
      volatileInfo: data.volatileInfo.present
          ? data.volatileInfo.value
          : this.volatileInfo,
      quizEnabled: data.quizEnabled.present
          ? data.quizEnabled.value
          : this.quizEnabled,
      retired: data.retired.present ? data.retired.value : this.retired,
      slug: data.slug.present ? data.slug.value : this.slug,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Term(')
          ..write('id: $id, ')
          ..write('termKo: $termKo, ')
          ..write('termEn: $termEn, ')
          ..write('def: $def, ')
          ..write('whyItMatters: $whyItMatters, ')
          ..write('example: $example, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('tracksJson: $tracksJson, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('confusionJson: $confusionJson, ')
          ..write('difficulty: $difficulty, ')
          ..write('vibeCore: $vibeCore, ')
          ..write('volatileInfo: $volatileInfo, ')
          ..write('quizEnabled: $quizEnabled, ')
          ..write('retired: $retired, ')
          ..write('slug: $slug')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    termKo,
    termEn,
    def,
    whyItMatters,
    example,
    category,
    subcategory,
    tracksJson,
    aliasesJson,
    confusionJson,
    difficulty,
    vibeCore,
    volatileInfo,
    quizEnabled,
    retired,
    slug,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Term &&
          other.id == this.id &&
          other.termKo == this.termKo &&
          other.termEn == this.termEn &&
          other.def == this.def &&
          other.whyItMatters == this.whyItMatters &&
          other.example == this.example &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.tracksJson == this.tracksJson &&
          other.aliasesJson == this.aliasesJson &&
          other.confusionJson == this.confusionJson &&
          other.difficulty == this.difficulty &&
          other.vibeCore == this.vibeCore &&
          other.volatileInfo == this.volatileInfo &&
          other.quizEnabled == this.quizEnabled &&
          other.retired == this.retired &&
          other.slug == this.slug);
}

class TermsCompanion extends UpdateCompanion<Term> {
  final Value<String> id;
  final Value<String> termKo;
  final Value<String> termEn;
  final Value<String> def;
  final Value<String> whyItMatters;
  final Value<String> example;
  final Value<String> category;
  final Value<String> subcategory;
  final Value<String> tracksJson;
  final Value<String> aliasesJson;
  final Value<String> confusionJson;
  final Value<int> difficulty;
  final Value<bool> vibeCore;
  final Value<bool> volatileInfo;
  final Value<bool> quizEnabled;
  final Value<bool> retired;
  final Value<String> slug;
  final Value<int> rowid;
  const TermsCompanion({
    this.id = const Value.absent(),
    this.termKo = const Value.absent(),
    this.termEn = const Value.absent(),
    this.def = const Value.absent(),
    this.whyItMatters = const Value.absent(),
    this.example = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.tracksJson = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.confusionJson = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.vibeCore = const Value.absent(),
    this.volatileInfo = const Value.absent(),
    this.quizEnabled = const Value.absent(),
    this.retired = const Value.absent(),
    this.slug = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TermsCompanion.insert({
    required String id,
    required String termKo,
    required String termEn,
    required String def,
    this.whyItMatters = const Value.absent(),
    this.example = const Value.absent(),
    required String category,
    this.subcategory = const Value.absent(),
    this.tracksJson = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.confusionJson = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.vibeCore = const Value.absent(),
    this.volatileInfo = const Value.absent(),
    this.quizEnabled = const Value.absent(),
    this.retired = const Value.absent(),
    required String slug,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       termKo = Value(termKo),
       termEn = Value(termEn),
       def = Value(def),
       category = Value(category),
       slug = Value(slug);
  static Insertable<Term> custom({
    Expression<String>? id,
    Expression<String>? termKo,
    Expression<String>? termEn,
    Expression<String>? def,
    Expression<String>? whyItMatters,
    Expression<String>? example,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? tracksJson,
    Expression<String>? aliasesJson,
    Expression<String>? confusionJson,
    Expression<int>? difficulty,
    Expression<bool>? vibeCore,
    Expression<bool>? volatileInfo,
    Expression<bool>? quizEnabled,
    Expression<bool>? retired,
    Expression<String>? slug,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (termKo != null) 'term_ko': termKo,
      if (termEn != null) 'term_en': termEn,
      if (def != null) 'def': def,
      if (whyItMatters != null) 'why_it_matters': whyItMatters,
      if (example != null) 'example': example,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (tracksJson != null) 'tracks_json': tracksJson,
      if (aliasesJson != null) 'aliases_json': aliasesJson,
      if (confusionJson != null) 'confusion_json': confusionJson,
      if (difficulty != null) 'difficulty': difficulty,
      if (vibeCore != null) 'vibe_core': vibeCore,
      if (volatileInfo != null) 'volatile_info': volatileInfo,
      if (quizEnabled != null) 'quiz_enabled': quizEnabled,
      if (retired != null) 'retired': retired,
      if (slug != null) 'slug': slug,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TermsCompanion copyWith({
    Value<String>? id,
    Value<String>? termKo,
    Value<String>? termEn,
    Value<String>? def,
    Value<String>? whyItMatters,
    Value<String>? example,
    Value<String>? category,
    Value<String>? subcategory,
    Value<String>? tracksJson,
    Value<String>? aliasesJson,
    Value<String>? confusionJson,
    Value<int>? difficulty,
    Value<bool>? vibeCore,
    Value<bool>? volatileInfo,
    Value<bool>? quizEnabled,
    Value<bool>? retired,
    Value<String>? slug,
    Value<int>? rowid,
  }) {
    return TermsCompanion(
      id: id ?? this.id,
      termKo: termKo ?? this.termKo,
      termEn: termEn ?? this.termEn,
      def: def ?? this.def,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      example: example ?? this.example,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      tracksJson: tracksJson ?? this.tracksJson,
      aliasesJson: aliasesJson ?? this.aliasesJson,
      confusionJson: confusionJson ?? this.confusionJson,
      difficulty: difficulty ?? this.difficulty,
      vibeCore: vibeCore ?? this.vibeCore,
      volatileInfo: volatileInfo ?? this.volatileInfo,
      quizEnabled: quizEnabled ?? this.quizEnabled,
      retired: retired ?? this.retired,
      slug: slug ?? this.slug,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (termKo.present) {
      map['term_ko'] = Variable<String>(termKo.value);
    }
    if (termEn.present) {
      map['term_en'] = Variable<String>(termEn.value);
    }
    if (def.present) {
      map['def'] = Variable<String>(def.value);
    }
    if (whyItMatters.present) {
      map['why_it_matters'] = Variable<String>(whyItMatters.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (tracksJson.present) {
      map['tracks_json'] = Variable<String>(tracksJson.value);
    }
    if (aliasesJson.present) {
      map['aliases_json'] = Variable<String>(aliasesJson.value);
    }
    if (confusionJson.present) {
      map['confusion_json'] = Variable<String>(confusionJson.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (vibeCore.present) {
      map['vibe_core'] = Variable<bool>(vibeCore.value);
    }
    if (volatileInfo.present) {
      map['volatile_info'] = Variable<bool>(volatileInfo.value);
    }
    if (quizEnabled.present) {
      map['quiz_enabled'] = Variable<bool>(quizEnabled.value);
    }
    if (retired.present) {
      map['retired'] = Variable<bool>(retired.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermsCompanion(')
          ..write('id: $id, ')
          ..write('termKo: $termKo, ')
          ..write('termEn: $termEn, ')
          ..write('def: $def, ')
          ..write('whyItMatters: $whyItMatters, ')
          ..write('example: $example, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('tracksJson: $tracksJson, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('confusionJson: $confusionJson, ')
          ..write('difficulty: $difficulty, ')
          ..write('vibeCore: $vibeCore, ')
          ..write('volatileInfo: $volatileInfo, ')
          ..write('quizEnabled: $quizEnabled, ')
          ..write('retired: $retired, ')
          ..write('slug: $slug, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TermStatesTable extends TermStates
    with TableInfo<$TermStatesTable, TermState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _termIdMeta = const VerificationMeta('termId');
  @override
  late final GeneratedColumn<String> termId = GeneratedColumn<String>(
    'term_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NEW'),
  );
  static const VerificationMeta _masteryScoreMeta = const VerificationMeta(
    'masteryScore',
  );
  @override
  late final GeneratedColumn<int> masteryScore = GeneratedColumn<int>(
    'mastery_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctStreakMeta = const VerificationMeta(
    'correctStreak',
  );
  @override
  late final GeneratedColumn<int> correctStreak = GeneratedColumn<int>(
    'correct_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapseCountMeta = const VerificationMeta(
    'lapseCount',
  );
  @override
  late final GeneratedColumn<int> lapseCount = GeneratedColumn<int>(
    'lapse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastConfidenceMeta = const VerificationMeta(
    'lastConfidence',
  );
  @override
  late final GeneratedColumn<int> lastConfidence = GeneratedColumn<int>(
    'last_confidence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wrongReasonMeta = const VerificationMeta(
    'wrongReason',
  );
  @override
  late final GeneratedColumn<String> wrongReason = GeneratedColumn<String>(
    'wrong_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    termId,
    state,
    masteryScore,
    correctStreak,
    lapseCount,
    lastSeenAt,
    nextReviewAt,
    lastConfidence,
    wrongReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'term_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<TermState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('term_id')) {
      context.handle(
        _termIdMeta,
        termId.isAcceptableOrUnknown(data['term_id']!, _termIdMeta),
      );
    } else if (isInserting) {
      context.missing(_termIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('mastery_score')) {
      context.handle(
        _masteryScoreMeta,
        masteryScore.isAcceptableOrUnknown(
          data['mastery_score']!,
          _masteryScoreMeta,
        ),
      );
    }
    if (data.containsKey('correct_streak')) {
      context.handle(
        _correctStreakMeta,
        correctStreak.isAcceptableOrUnknown(
          data['correct_streak']!,
          _correctStreakMeta,
        ),
      );
    }
    if (data.containsKey('lapse_count')) {
      context.handle(
        _lapseCountMeta,
        lapseCount.isAcceptableOrUnknown(data['lapse_count']!, _lapseCountMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('last_confidence')) {
      context.handle(
        _lastConfidenceMeta,
        lastConfidence.isAcceptableOrUnknown(
          data['last_confidence']!,
          _lastConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('wrong_reason')) {
      context.handle(
        _wrongReasonMeta,
        wrongReason.isAcceptableOrUnknown(
          data['wrong_reason']!,
          _wrongReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {termId};
  @override
  TermState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TermState(
      termId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      masteryScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_score'],
      )!,
      correctStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_streak'],
      )!,
      lapseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapse_count'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      lastConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_confidence'],
      ),
      wrongReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wrong_reason'],
      ),
    );
  }

  @override
  $TermStatesTable createAlias(String alias) {
    return $TermStatesTable(attachedDatabase, alias);
  }
}

class TermState extends DataClass implements Insertable<TermState> {
  final String termId;
  final String state;
  final int masteryScore;
  final int correctStreak;
  final int lapseCount;
  final DateTime? lastSeenAt;
  final DateTime? nextReviewAt;
  final int? lastConfidence;
  final String? wrongReason;
  const TermState({
    required this.termId,
    required this.state,
    required this.masteryScore,
    required this.correctStreak,
    required this.lapseCount,
    this.lastSeenAt,
    this.nextReviewAt,
    this.lastConfidence,
    this.wrongReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['term_id'] = Variable<String>(termId);
    map['state'] = Variable<String>(state);
    map['mastery_score'] = Variable<int>(masteryScore);
    map['correct_streak'] = Variable<int>(correctStreak);
    map['lapse_count'] = Variable<int>(lapseCount);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    if (!nullToAbsent || lastConfidence != null) {
      map['last_confidence'] = Variable<int>(lastConfidence);
    }
    if (!nullToAbsent || wrongReason != null) {
      map['wrong_reason'] = Variable<String>(wrongReason);
    }
    return map;
  }

  TermStatesCompanion toCompanion(bool nullToAbsent) {
    return TermStatesCompanion(
      termId: Value(termId),
      state: Value(state),
      masteryScore: Value(masteryScore),
      correctStreak: Value(correctStreak),
      lapseCount: Value(lapseCount),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      lastConfidence: lastConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConfidence),
      wrongReason: wrongReason == null && nullToAbsent
          ? const Value.absent()
          : Value(wrongReason),
    );
  }

  factory TermState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TermState(
      termId: serializer.fromJson<String>(json['termId']),
      state: serializer.fromJson<String>(json['state']),
      masteryScore: serializer.fromJson<int>(json['masteryScore']),
      correctStreak: serializer.fromJson<int>(json['correctStreak']),
      lapseCount: serializer.fromJson<int>(json['lapseCount']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      lastConfidence: serializer.fromJson<int?>(json['lastConfidence']),
      wrongReason: serializer.fromJson<String?>(json['wrongReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'termId': serializer.toJson<String>(termId),
      'state': serializer.toJson<String>(state),
      'masteryScore': serializer.toJson<int>(masteryScore),
      'correctStreak': serializer.toJson<int>(correctStreak),
      'lapseCount': serializer.toJson<int>(lapseCount),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'lastConfidence': serializer.toJson<int?>(lastConfidence),
      'wrongReason': serializer.toJson<String?>(wrongReason),
    };
  }

  TermState copyWith({
    String? termId,
    String? state,
    int? masteryScore,
    int? correctStreak,
    int? lapseCount,
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<DateTime?> nextReviewAt = const Value.absent(),
    Value<int?> lastConfidence = const Value.absent(),
    Value<String?> wrongReason = const Value.absent(),
  }) => TermState(
    termId: termId ?? this.termId,
    state: state ?? this.state,
    masteryScore: masteryScore ?? this.masteryScore,
    correctStreak: correctStreak ?? this.correctStreak,
    lapseCount: lapseCount ?? this.lapseCount,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    lastConfidence: lastConfidence.present
        ? lastConfidence.value
        : this.lastConfidence,
    wrongReason: wrongReason.present ? wrongReason.value : this.wrongReason,
  );
  TermState copyWithCompanion(TermStatesCompanion data) {
    return TermState(
      termId: data.termId.present ? data.termId.value : this.termId,
      state: data.state.present ? data.state.value : this.state,
      masteryScore: data.masteryScore.present
          ? data.masteryScore.value
          : this.masteryScore,
      correctStreak: data.correctStreak.present
          ? data.correctStreak.value
          : this.correctStreak,
      lapseCount: data.lapseCount.present
          ? data.lapseCount.value
          : this.lapseCount,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      lastConfidence: data.lastConfidence.present
          ? data.lastConfidence.value
          : this.lastConfidence,
      wrongReason: data.wrongReason.present
          ? data.wrongReason.value
          : this.wrongReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TermState(')
          ..write('termId: $termId, ')
          ..write('state: $state, ')
          ..write('masteryScore: $masteryScore, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastConfidence: $lastConfidence, ')
          ..write('wrongReason: $wrongReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    termId,
    state,
    masteryScore,
    correctStreak,
    lapseCount,
    lastSeenAt,
    nextReviewAt,
    lastConfidence,
    wrongReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TermState &&
          other.termId == this.termId &&
          other.state == this.state &&
          other.masteryScore == this.masteryScore &&
          other.correctStreak == this.correctStreak &&
          other.lapseCount == this.lapseCount &&
          other.lastSeenAt == this.lastSeenAt &&
          other.nextReviewAt == this.nextReviewAt &&
          other.lastConfidence == this.lastConfidence &&
          other.wrongReason == this.wrongReason);
}

class TermStatesCompanion extends UpdateCompanion<TermState> {
  final Value<String> termId;
  final Value<String> state;
  final Value<int> masteryScore;
  final Value<int> correctStreak;
  final Value<int> lapseCount;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime?> nextReviewAt;
  final Value<int?> lastConfidence;
  final Value<String?> wrongReason;
  final Value<int> rowid;
  const TermStatesCompanion({
    this.termId = const Value.absent(),
    this.state = const Value.absent(),
    this.masteryScore = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastConfidence = const Value.absent(),
    this.wrongReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TermStatesCompanion.insert({
    required String termId,
    this.state = const Value.absent(),
    this.masteryScore = const Value.absent(),
    this.correctStreak = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastConfidence = const Value.absent(),
    this.wrongReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : termId = Value(termId);
  static Insertable<TermState> custom({
    Expression<String>? termId,
    Expression<String>? state,
    Expression<int>? masteryScore,
    Expression<int>? correctStreak,
    Expression<int>? lapseCount,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? nextReviewAt,
    Expression<int>? lastConfidence,
    Expression<String>? wrongReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (termId != null) 'term_id': termId,
      if (state != null) 'state': state,
      if (masteryScore != null) 'mastery_score': masteryScore,
      if (correctStreak != null) 'correct_streak': correctStreak,
      if (lapseCount != null) 'lapse_count': lapseCount,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (lastConfidence != null) 'last_confidence': lastConfidence,
      if (wrongReason != null) 'wrong_reason': wrongReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TermStatesCompanion copyWith({
    Value<String>? termId,
    Value<String>? state,
    Value<int>? masteryScore,
    Value<int>? correctStreak,
    Value<int>? lapseCount,
    Value<DateTime?>? lastSeenAt,
    Value<DateTime?>? nextReviewAt,
    Value<int?>? lastConfidence,
    Value<String?>? wrongReason,
    Value<int>? rowid,
  }) {
    return TermStatesCompanion(
      termId: termId ?? this.termId,
      state: state ?? this.state,
      masteryScore: masteryScore ?? this.masteryScore,
      correctStreak: correctStreak ?? this.correctStreak,
      lapseCount: lapseCount ?? this.lapseCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      wrongReason: wrongReason ?? this.wrongReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (termId.present) {
      map['term_id'] = Variable<String>(termId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (masteryScore.present) {
      map['mastery_score'] = Variable<int>(masteryScore.value);
    }
    if (correctStreak.present) {
      map['correct_streak'] = Variable<int>(correctStreak.value);
    }
    if (lapseCount.present) {
      map['lapse_count'] = Variable<int>(lapseCount.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (lastConfidence.present) {
      map['last_confidence'] = Variable<int>(lastConfidence.value);
    }
    if (wrongReason.present) {
      map['wrong_reason'] = Variable<String>(wrongReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermStatesCompanion(')
          ..write('termId: $termId, ')
          ..write('state: $state, ')
          ..write('masteryScore: $masteryScore, ')
          ..write('correctStreak: $correctStreak, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastConfidence: $lastConfidence, ')
          ..write('wrongReason: $wrongReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newTermsMeta = const VerificationMeta(
    'newTerms',
  );
  @override
  late final GeneratedColumn<int> newTerms = GeneratedColumn<int>(
    'new_terms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewTermsMeta = const VerificationMeta(
    'reviewTerms',
  );
  @override
  late final GeneratedColumn<int> reviewTerms = GeneratedColumn<int>(
    'review_terms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gemsEarnedMeta = const VerificationMeta(
    'gemsEarned',
  );
  @override
  late final GeneratedColumn<int> gemsEarned = GeneratedColumn<int>(
    'gems_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    startedAt,
    endedAt,
    correctCount,
    newTerms,
    reviewTerms,
    xpEarned,
    gemsEarned,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('new_terms')) {
      context.handle(
        _newTermsMeta,
        newTerms.isAcceptableOrUnknown(data['new_terms']!, _newTermsMeta),
      );
    }
    if (data.containsKey('review_terms')) {
      context.handle(
        _reviewTermsMeta,
        reviewTerms.isAcceptableOrUnknown(
          data['review_terms']!,
          _reviewTermsMeta,
        ),
      );
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    }
    if (data.containsKey('gems_earned')) {
      context.handle(
        _gemsEarnedMeta,
        gemsEarned.isAcceptableOrUnknown(data['gems_earned']!, _gemsEarnedMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      newTerms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_terms'],
      )!,
      reviewTerms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_terms'],
      )!,
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      gemsEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gems_earned'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int correctCount;
  final int newTerms;
  final int reviewTerms;
  final int xpEarned;
  final int gemsEarned;
  final bool completed;
  const Session({
    required this.id,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    required this.correctCount,
    required this.newTerms,
    required this.reviewTerms,
    required this.xpEarned,
    required this.gemsEarned,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mode'] = Variable<String>(mode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['correct_count'] = Variable<int>(correctCount);
    map['new_terms'] = Variable<int>(newTerms);
    map['review_terms'] = Variable<int>(reviewTerms);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['gems_earned'] = Variable<int>(gemsEarned);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      correctCount: Value(correctCount),
      newTerms: Value(newTerms),
      reviewTerms: Value(reviewTerms),
      xpEarned: Value(xpEarned),
      gemsEarned: Value(gemsEarned),
      completed: Value(completed),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      newTerms: serializer.fromJson<int>(json['newTerms']),
      reviewTerms: serializer.fromJson<int>(json['reviewTerms']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      gemsEarned: serializer.fromJson<int>(json['gemsEarned']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mode': serializer.toJson<String>(mode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'correctCount': serializer.toJson<int>(correctCount),
      'newTerms': serializer.toJson<int>(newTerms),
      'reviewTerms': serializer.toJson<int>(reviewTerms),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'gemsEarned': serializer.toJson<int>(gemsEarned),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  Session copyWith({
    String? id,
    String? mode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? correctCount,
    int? newTerms,
    int? reviewTerms,
    int? xpEarned,
    int? gemsEarned,
    bool? completed,
  }) => Session(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    correctCount: correctCount ?? this.correctCount,
    newTerms: newTerms ?? this.newTerms,
    reviewTerms: reviewTerms ?? this.reviewTerms,
    xpEarned: xpEarned ?? this.xpEarned,
    gemsEarned: gemsEarned ?? this.gemsEarned,
    completed: completed ?? this.completed,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      newTerms: data.newTerms.present ? data.newTerms.value : this.newTerms,
      reviewTerms: data.reviewTerms.present
          ? data.reviewTerms.value
          : this.reviewTerms,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      gemsEarned: data.gemsEarned.present
          ? data.gemsEarned.value
          : this.gemsEarned,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('correctCount: $correctCount, ')
          ..write('newTerms: $newTerms, ')
          ..write('reviewTerms: $reviewTerms, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('gemsEarned: $gemsEarned, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    startedAt,
    endedAt,
    correctCount,
    newTerms,
    reviewTerms,
    xpEarned,
    gemsEarned,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.correctCount == this.correctCount &&
          other.newTerms == this.newTerms &&
          other.reviewTerms == this.reviewTerms &&
          other.xpEarned == this.xpEarned &&
          other.gemsEarned == this.gemsEarned &&
          other.completed == this.completed);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> mode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> correctCount;
  final Value<int> newTerms;
  final Value<int> reviewTerms;
  final Value<int> xpEarned;
  final Value<int> gemsEarned;
  final Value<bool> completed;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.newTerms = const Value.absent(),
    this.reviewTerms = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.gemsEarned = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String mode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.newTerms = const Value.absent(),
    this.reviewTerms = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.gemsEarned = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? mode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? correctCount,
    Expression<int>? newTerms,
    Expression<int>? reviewTerms,
    Expression<int>? xpEarned,
    Expression<int>? gemsEarned,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (correctCount != null) 'correct_count': correctCount,
      if (newTerms != null) 'new_terms': newTerms,
      if (reviewTerms != null) 'review_terms': reviewTerms,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (gemsEarned != null) 'gems_earned': gemsEarned,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? mode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? correctCount,
    Value<int>? newTerms,
    Value<int>? reviewTerms,
    Value<int>? xpEarned,
    Value<int>? gemsEarned,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      correctCount: correctCount ?? this.correctCount,
      newTerms: newTerms ?? this.newTerms,
      reviewTerms: reviewTerms ?? this.reviewTerms,
      xpEarned: xpEarned ?? this.xpEarned,
      gemsEarned: gemsEarned ?? this.gemsEarned,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (newTerms.present) {
      map['new_terms'] = Variable<int>(newTerms.value);
    }
    if (reviewTerms.present) {
      map['review_terms'] = Variable<int>(reviewTerms.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (gemsEarned.present) {
      map['gems_earned'] = Variable<int>(gemsEarned.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('correctCount: $correctCount, ')
          ..write('newTerms: $newTerms, ')
          ..write('reviewTerms: $reviewTerms, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('gemsEarned: $gemsEarned, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaTable extends Meta with TableInfo<$MetaTable, MetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaData> instance, {
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
  MetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaTable createAlias(String alias) {
    return $MetaTable(attachedDatabase, alias);
  }
}

class MetaData extends DataClass implements Insertable<MetaData> {
  final String key;
  final String value;
  const MetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaCompanion toCompanion(bool nullToAbsent) {
    return MetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaData(
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

  MetaData copyWith({String? key, String? value}) =>
      MetaData(key: key ?? this.key, value: value ?? this.value);
  MetaData copyWithCompanion(MetaCompanion data) {
    return MetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaData(')
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
      (other is MetaData && other.key == this.key && other.value == this.value);
}

class MetaCompanion extends UpdateCompanion<MetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaData> custom({
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

  MetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaCompanion(
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
    return (StringBuffer('MetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VqDatabase extends GeneratedDatabase {
  _$VqDatabase(QueryExecutor e) : super(e);
  $VqDatabaseManager get managers => $VqDatabaseManager(this);
  late final $TermsTable terms = $TermsTable(this);
  late final $TermStatesTable termStates = $TermStatesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MetaTable meta = $MetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    terms,
    termStates,
    sessions,
    meta,
  ];
}

typedef $$TermsTableCreateCompanionBuilder =
    TermsCompanion Function({
      required String id,
      required String termKo,
      required String termEn,
      required String def,
      Value<String> whyItMatters,
      Value<String> example,
      required String category,
      Value<String> subcategory,
      Value<String> tracksJson,
      Value<String> aliasesJson,
      Value<String> confusionJson,
      Value<int> difficulty,
      Value<bool> vibeCore,
      Value<bool> volatileInfo,
      Value<bool> quizEnabled,
      Value<bool> retired,
      required String slug,
      Value<int> rowid,
    });
typedef $$TermsTableUpdateCompanionBuilder =
    TermsCompanion Function({
      Value<String> id,
      Value<String> termKo,
      Value<String> termEn,
      Value<String> def,
      Value<String> whyItMatters,
      Value<String> example,
      Value<String> category,
      Value<String> subcategory,
      Value<String> tracksJson,
      Value<String> aliasesJson,
      Value<String> confusionJson,
      Value<int> difficulty,
      Value<bool> vibeCore,
      Value<bool> volatileInfo,
      Value<bool> quizEnabled,
      Value<bool> retired,
      Value<String> slug,
      Value<int> rowid,
    });

class $$TermsTableFilterComposer extends Composer<_$VqDatabase, $TermsTable> {
  $$TermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termKo => $composableBuilder(
    column: $table.termKo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termEn => $composableBuilder(
    column: $table.termEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get def => $composableBuilder(
    column: $table.def,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tracksJson => $composableBuilder(
    column: $table.tracksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confusionJson => $composableBuilder(
    column: $table.confusionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vibeCore => $composableBuilder(
    column: $table.vibeCore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get volatileInfo => $composableBuilder(
    column: $table.volatileInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quizEnabled => $composableBuilder(
    column: $table.quizEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TermsTableOrderingComposer extends Composer<_$VqDatabase, $TermsTable> {
  $$TermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termKo => $composableBuilder(
    column: $table.termKo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termEn => $composableBuilder(
    column: $table.termEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get def => $composableBuilder(
    column: $table.def,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracksJson => $composableBuilder(
    column: $table.tracksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confusionJson => $composableBuilder(
    column: $table.confusionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vibeCore => $composableBuilder(
    column: $table.vibeCore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get volatileInfo => $composableBuilder(
    column: $table.volatileInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quizEnabled => $composableBuilder(
    column: $table.quizEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TermsTableAnnotationComposer
    extends Composer<_$VqDatabase, $TermsTable> {
  $$TermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get termKo =>
      $composableBuilder(column: $table.termKo, builder: (column) => column);

  GeneratedColumn<String> get termEn =>
      $composableBuilder(column: $table.termEn, builder: (column) => column);

  GeneratedColumn<String> get def =>
      $composableBuilder(column: $table.def, builder: (column) => column);

  GeneratedColumn<String> get whyItMatters => $composableBuilder(
    column: $table.whyItMatters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tracksJson => $composableBuilder(
    column: $table.tracksJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aliasesJson => $composableBuilder(
    column: $table.aliasesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confusionJson => $composableBuilder(
    column: $table.confusionJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vibeCore =>
      $composableBuilder(column: $table.vibeCore, builder: (column) => column);

  GeneratedColumn<bool> get volatileInfo => $composableBuilder(
    column: $table.volatileInfo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quizEnabled => $composableBuilder(
    column: $table.quizEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);
}

class $$TermsTableTableManager
    extends
        RootTableManager<
          _$VqDatabase,
          $TermsTable,
          Term,
          $$TermsTableFilterComposer,
          $$TermsTableOrderingComposer,
          $$TermsTableAnnotationComposer,
          $$TermsTableCreateCompanionBuilder,
          $$TermsTableUpdateCompanionBuilder,
          (Term, BaseReferences<_$VqDatabase, $TermsTable, Term>),
          Term,
          PrefetchHooks Function()
        > {
  $$TermsTableTableManager(_$VqDatabase db, $TermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> termKo = const Value.absent(),
                Value<String> termEn = const Value.absent(),
                Value<String> def = const Value.absent(),
                Value<String> whyItMatters = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subcategory = const Value.absent(),
                Value<String> tracksJson = const Value.absent(),
                Value<String> aliasesJson = const Value.absent(),
                Value<String> confusionJson = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> vibeCore = const Value.absent(),
                Value<bool> volatileInfo = const Value.absent(),
                Value<bool> quizEnabled = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TermsCompanion(
                id: id,
                termKo: termKo,
                termEn: termEn,
                def: def,
                whyItMatters: whyItMatters,
                example: example,
                category: category,
                subcategory: subcategory,
                tracksJson: tracksJson,
                aliasesJson: aliasesJson,
                confusionJson: confusionJson,
                difficulty: difficulty,
                vibeCore: vibeCore,
                volatileInfo: volatileInfo,
                quizEnabled: quizEnabled,
                retired: retired,
                slug: slug,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String termKo,
                required String termEn,
                required String def,
                Value<String> whyItMatters = const Value.absent(),
                Value<String> example = const Value.absent(),
                required String category,
                Value<String> subcategory = const Value.absent(),
                Value<String> tracksJson = const Value.absent(),
                Value<String> aliasesJson = const Value.absent(),
                Value<String> confusionJson = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> vibeCore = const Value.absent(),
                Value<bool> volatileInfo = const Value.absent(),
                Value<bool> quizEnabled = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                required String slug,
                Value<int> rowid = const Value.absent(),
              }) => TermsCompanion.insert(
                id: id,
                termKo: termKo,
                termEn: termEn,
                def: def,
                whyItMatters: whyItMatters,
                example: example,
                category: category,
                subcategory: subcategory,
                tracksJson: tracksJson,
                aliasesJson: aliasesJson,
                confusionJson: confusionJson,
                difficulty: difficulty,
                vibeCore: vibeCore,
                volatileInfo: volatileInfo,
                quizEnabled: quizEnabled,
                retired: retired,
                slug: slug,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TermsTableProcessedTableManager =
    ProcessedTableManager<
      _$VqDatabase,
      $TermsTable,
      Term,
      $$TermsTableFilterComposer,
      $$TermsTableOrderingComposer,
      $$TermsTableAnnotationComposer,
      $$TermsTableCreateCompanionBuilder,
      $$TermsTableUpdateCompanionBuilder,
      (Term, BaseReferences<_$VqDatabase, $TermsTable, Term>),
      Term,
      PrefetchHooks Function()
    >;
typedef $$TermStatesTableCreateCompanionBuilder =
    TermStatesCompanion Function({
      required String termId,
      Value<String> state,
      Value<int> masteryScore,
      Value<int> correctStreak,
      Value<int> lapseCount,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> nextReviewAt,
      Value<int?> lastConfidence,
      Value<String?> wrongReason,
      Value<int> rowid,
    });
typedef $$TermStatesTableUpdateCompanionBuilder =
    TermStatesCompanion Function({
      Value<String> termId,
      Value<String> state,
      Value<int> masteryScore,
      Value<int> correctStreak,
      Value<int> lapseCount,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> nextReviewAt,
      Value<int?> lastConfidence,
      Value<String?> wrongReason,
      Value<int> rowid,
    });

class $$TermStatesTableFilterComposer
    extends Composer<_$VqDatabase, $TermStatesTable> {
  $$TermStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get termId => $composableBuilder(
    column: $table.termId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryScore => $composableBuilder(
    column: $table.masteryScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastConfidence => $composableBuilder(
    column: $table.lastConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wrongReason => $composableBuilder(
    column: $table.wrongReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TermStatesTableOrderingComposer
    extends Composer<_$VqDatabase, $TermStatesTable> {
  $$TermStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get termId => $composableBuilder(
    column: $table.termId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryScore => $composableBuilder(
    column: $table.masteryScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastConfidence => $composableBuilder(
    column: $table.lastConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wrongReason => $composableBuilder(
    column: $table.wrongReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TermStatesTableAnnotationComposer
    extends Composer<_$VqDatabase, $TermStatesTable> {
  $$TermStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get termId =>
      $composableBuilder(column: $table.termId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get masteryScore => $composableBuilder(
    column: $table.masteryScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctStreak => $composableBuilder(
    column: $table.correctStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastConfidence => $composableBuilder(
    column: $table.lastConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wrongReason => $composableBuilder(
    column: $table.wrongReason,
    builder: (column) => column,
  );
}

class $$TermStatesTableTableManager
    extends
        RootTableManager<
          _$VqDatabase,
          $TermStatesTable,
          TermState,
          $$TermStatesTableFilterComposer,
          $$TermStatesTableOrderingComposer,
          $$TermStatesTableAnnotationComposer,
          $$TermStatesTableCreateCompanionBuilder,
          $$TermStatesTableUpdateCompanionBuilder,
          (
            TermState,
            BaseReferences<_$VqDatabase, $TermStatesTable, TermState>,
          ),
          TermState,
          PrefetchHooks Function()
        > {
  $$TermStatesTableTableManager(_$VqDatabase db, $TermStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> termId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> masteryScore = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<int?> lastConfidence = const Value.absent(),
                Value<String?> wrongReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TermStatesCompanion(
                termId: termId,
                state: state,
                masteryScore: masteryScore,
                correctStreak: correctStreak,
                lapseCount: lapseCount,
                lastSeenAt: lastSeenAt,
                nextReviewAt: nextReviewAt,
                lastConfidence: lastConfidence,
                wrongReason: wrongReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String termId,
                Value<String> state = const Value.absent(),
                Value<int> masteryScore = const Value.absent(),
                Value<int> correctStreak = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<int?> lastConfidence = const Value.absent(),
                Value<String?> wrongReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TermStatesCompanion.insert(
                termId: termId,
                state: state,
                masteryScore: masteryScore,
                correctStreak: correctStreak,
                lapseCount: lapseCount,
                lastSeenAt: lastSeenAt,
                nextReviewAt: nextReviewAt,
                lastConfidence: lastConfidence,
                wrongReason: wrongReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TermStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$VqDatabase,
      $TermStatesTable,
      TermState,
      $$TermStatesTableFilterComposer,
      $$TermStatesTableOrderingComposer,
      $$TermStatesTableAnnotationComposer,
      $$TermStatesTableCreateCompanionBuilder,
      $$TermStatesTableUpdateCompanionBuilder,
      (TermState, BaseReferences<_$VqDatabase, $TermStatesTable, TermState>),
      TermState,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String mode,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> correctCount,
      Value<int> newTerms,
      Value<int> reviewTerms,
      Value<int> xpEarned,
      Value<int> gemsEarned,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> mode,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> correctCount,
      Value<int> newTerms,
      Value<int> reviewTerms,
      Value<int> xpEarned,
      Value<int> gemsEarned,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$VqDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newTerms => $composableBuilder(
    column: $table.newTerms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewTerms => $composableBuilder(
    column: $table.reviewTerms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gemsEarned => $composableBuilder(
    column: $table.gemsEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$VqDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newTerms => $composableBuilder(
    column: $table.newTerms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewTerms => $composableBuilder(
    column: $table.reviewTerms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gemsEarned => $composableBuilder(
    column: $table.gemsEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$VqDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newTerms =>
      $composableBuilder(column: $table.newTerms, builder: (column) => column);

  GeneratedColumn<int> get reviewTerms => $composableBuilder(
    column: $table.reviewTerms,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<int> get gemsEarned => $composableBuilder(
    column: $table.gemsEarned,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$VqDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$VqDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$VqDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> newTerms = const Value.absent(),
                Value<int> reviewTerms = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<int> gemsEarned = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                correctCount: correctCount,
                newTerms: newTerms,
                reviewTerms: reviewTerms,
                xpEarned: xpEarned,
                gemsEarned: gemsEarned,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mode,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> newTerms = const Value.absent(),
                Value<int> reviewTerms = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<int> gemsEarned = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                correctCount: correctCount,
                newTerms: newTerms,
                reviewTerms: reviewTerms,
                xpEarned: xpEarned,
                gemsEarned: gemsEarned,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VqDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$VqDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$MetaTableCreateCompanionBuilder =
    MetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetaTableUpdateCompanionBuilder =
    MetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetaTableFilterComposer extends Composer<_$VqDatabase, $MetaTable> {
  $$MetaTableFilterComposer({
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

class $$MetaTableOrderingComposer extends Composer<_$VqDatabase, $MetaTable> {
  $$MetaTableOrderingComposer({
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

class $$MetaTableAnnotationComposer extends Composer<_$VqDatabase, $MetaTable> {
  $$MetaTableAnnotationComposer({
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

class $$MetaTableTableManager
    extends
        RootTableManager<
          _$VqDatabase,
          $MetaTable,
          MetaData,
          $$MetaTableFilterComposer,
          $$MetaTableOrderingComposer,
          $$MetaTableAnnotationComposer,
          $$MetaTableCreateCompanionBuilder,
          $$MetaTableUpdateCompanionBuilder,
          (MetaData, BaseReferences<_$VqDatabase, $MetaTable, MetaData>),
          MetaData,
          PrefetchHooks Function()
        > {
  $$MetaTableTableManager(_$VqDatabase db, $MetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaTableProcessedTableManager =
    ProcessedTableManager<
      _$VqDatabase,
      $MetaTable,
      MetaData,
      $$MetaTableFilterComposer,
      $$MetaTableOrderingComposer,
      $$MetaTableAnnotationComposer,
      $$MetaTableCreateCompanionBuilder,
      $$MetaTableUpdateCompanionBuilder,
      (MetaData, BaseReferences<_$VqDatabase, $MetaTable, MetaData>),
      MetaData,
      PrefetchHooks Function()
    >;

class $VqDatabaseManager {
  final _$VqDatabase _db;
  $VqDatabaseManager(this._db);
  $$TermsTableTableManager get terms =>
      $$TermsTableTableManager(_db, _db.terms);
  $$TermStatesTableTableManager get termStates =>
      $$TermStatesTableTableManager(_db, _db.termStates);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MetaTableTableManager get meta => $$MetaTableTableManager(_db, _db.meta);
}
