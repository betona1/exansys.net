// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileChecksumMeta = const VerificationMeta(
    'fileChecksum',
  );
  @override
  late final GeneratedColumn<String> fileChecksum = GeneratedColumn<String>(
    'file_checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedDateMeta = const VerificationMeta(
    'publishedDate',
  );
  @override
  late final GeneratedColumn<String> publishedDate = GeneratedColumn<String>(
    'published_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ko'),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasTextLayerMeta = const VerificationMeta(
    'hasTextLayer',
  );
  @override
  late final GeneratedColumn<bool> hasTextLayer = GeneratedColumn<bool>(
    'has_text_layer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_text_layer" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _hasSourceAnnotsMeta = const VerificationMeta(
    'hasSourceAnnots',
  );
  @override
  late final GeneratedColumn<bool> hasSourceAnnots = GeneratedColumn<bool>(
    'has_source_annots',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_source_annots" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOcrDoneMeta = const VerificationMeta(
    'isOcrDone',
  );
  @override
  late final GeneratedColumn<bool> isOcrDone = GeneratedColumn<bool>(
    'is_ocr_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ocr_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isIndexedMeta = const VerificationMeta(
    'isIndexed',
  );
  @override
  late final GeneratedColumn<bool> isIndexed = GeneratedColumn<bool>(
    'is_indexed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_indexed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pdf'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<String> addedAt = GeneratedColumn<String>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    filePath,
    fileChecksum,
    fileSize,
    title,
    author,
    publisher,
    publishedDate,
    language,
    pageCount,
    coverPath,
    hasTextLayer,
    hasSourceAnnots,
    isOcrDone,
    isIndexed,
    sourceType,
    addedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_checksum')) {
      context.handle(
        _fileChecksumMeta,
        fileChecksum.isAcceptableOrUnknown(
          data['file_checksum']!,
          _fileChecksumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileChecksumMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('published_date')) {
      context.handle(
        _publishedDateMeta,
        publishedDate.isAcceptableOrUnknown(
          data['published_date']!,
          _publishedDateMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('has_text_layer')) {
      context.handle(
        _hasTextLayerMeta,
        hasTextLayer.isAcceptableOrUnknown(
          data['has_text_layer']!,
          _hasTextLayerMeta,
        ),
      );
    }
    if (data.containsKey('has_source_annots')) {
      context.handle(
        _hasSourceAnnotsMeta,
        hasSourceAnnots.isAcceptableOrUnknown(
          data['has_source_annots']!,
          _hasSourceAnnotsMeta,
        ),
      );
    }
    if (data.containsKey('is_ocr_done')) {
      context.handle(
        _isOcrDoneMeta,
        isOcrDone.isAcceptableOrUnknown(data['is_ocr_done']!, _isOcrDoneMeta),
      );
    }
    if (data.containsKey('is_indexed')) {
      context.handle(
        _isIndexedMeta,
        isIndexed.isAcceptableOrUnknown(data['is_indexed']!, _isIndexedMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_checksum'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      publishedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_date'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      hasTextLayer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_text_layer'],
      )!,
      hasSourceAnnots: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_source_annots'],
      )!,
      isOcrDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ocr_done'],
      )!,
      isIndexed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_indexed'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final int id;

  /// 동기화 기준 전역 고유 ID
  final String uuid;

  /// 원본 PDF 경로 또는 SAF URI
  final String filePath;

  /// SHA-256. 파일 변경 감지 · 주석 재부착 · 위치 재탐색 기준
  final String fileChecksum;
  final int fileSize;

  /// 자동 메타데이터는 늘 부정확하므로 수동 편집 UI 가 필요하다
  final String? title;
  final String? author;
  final String? publisher;

  /// 출간일 (YYYY-MM-DD)
  final String? publishedDate;
  final String language;
  final int pageCount;

  /// 표지 캐시 경로. 없으면 1페이지 렌더로 자동 생성
  final String? coverPath;

  /// 텍스트 레이어 존재 여부. false 면 스캔본 → OCR 대상
  final bool hasTextLayer;

  /// 원본 PDF 에 이미 주석이 있는지. 있으면 회색으로 구분 렌더
  final bool hasSourceAnnots;
  final bool isOcrDone;
  final bool isIndexed;

  /// 출처 유형 (pdf / video_book)
  final String sourceType;
  final String addedAt;
  final String updatedAt;

  /// 소프트 삭제
  final String? deletedAt;
  const BookRow({
    required this.id,
    required this.uuid,
    required this.filePath,
    required this.fileChecksum,
    required this.fileSize,
    this.title,
    this.author,
    this.publisher,
    this.publishedDate,
    required this.language,
    required this.pageCount,
    this.coverPath,
    required this.hasTextLayer,
    required this.hasSourceAnnots,
    required this.isOcrDone,
    required this.isIndexed,
    required this.sourceType,
    required this.addedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['file_path'] = Variable<String>(filePath);
    map['file_checksum'] = Variable<String>(fileChecksum);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || publishedDate != null) {
      map['published_date'] = Variable<String>(publishedDate);
    }
    map['language'] = Variable<String>(language);
    map['page_count'] = Variable<int>(pageCount);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['has_text_layer'] = Variable<bool>(hasTextLayer);
    map['has_source_annots'] = Variable<bool>(hasSourceAnnots);
    map['is_ocr_done'] = Variable<bool>(isOcrDone);
    map['is_indexed'] = Variable<bool>(isIndexed);
    map['source_type'] = Variable<String>(sourceType);
    map['added_at'] = Variable<String>(addedAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      filePath: Value(filePath),
      fileChecksum: Value(fileChecksum),
      fileSize: Value(fileSize),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      publishedDate: publishedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedDate),
      language: Value(language),
      pageCount: Value(pageCount),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      hasTextLayer: Value(hasTextLayer),
      hasSourceAnnots: Value(hasSourceAnnots),
      isOcrDone: Value(isOcrDone),
      isIndexed: Value(isIndexed),
      sourceType: Value(sourceType),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileChecksum: serializer.fromJson<String>(json['fileChecksum']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      title: serializer.fromJson<String?>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      publishedDate: serializer.fromJson<String?>(json['publishedDate']),
      language: serializer.fromJson<String>(json['language']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      hasTextLayer: serializer.fromJson<bool>(json['hasTextLayer']),
      hasSourceAnnots: serializer.fromJson<bool>(json['hasSourceAnnots']),
      isOcrDone: serializer.fromJson<bool>(json['isOcrDone']),
      isIndexed: serializer.fromJson<bool>(json['isIndexed']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      addedAt: serializer.fromJson<String>(json['addedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'filePath': serializer.toJson<String>(filePath),
      'fileChecksum': serializer.toJson<String>(fileChecksum),
      'fileSize': serializer.toJson<int>(fileSize),
      'title': serializer.toJson<String?>(title),
      'author': serializer.toJson<String?>(author),
      'publisher': serializer.toJson<String?>(publisher),
      'publishedDate': serializer.toJson<String?>(publishedDate),
      'language': serializer.toJson<String>(language),
      'pageCount': serializer.toJson<int>(pageCount),
      'coverPath': serializer.toJson<String?>(coverPath),
      'hasTextLayer': serializer.toJson<bool>(hasTextLayer),
      'hasSourceAnnots': serializer.toJson<bool>(hasSourceAnnots),
      'isOcrDone': serializer.toJson<bool>(isOcrDone),
      'isIndexed': serializer.toJson<bool>(isIndexed),
      'sourceType': serializer.toJson<String>(sourceType),
      'addedAt': serializer.toJson<String>(addedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  BookRow copyWith({
    int? id,
    String? uuid,
    String? filePath,
    String? fileChecksum,
    int? fileSize,
    Value<String?> title = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> publishedDate = const Value.absent(),
    String? language,
    int? pageCount,
    Value<String?> coverPath = const Value.absent(),
    bool? hasTextLayer,
    bool? hasSourceAnnots,
    bool? isOcrDone,
    bool? isIndexed,
    String? sourceType,
    String? addedAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => BookRow(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    filePath: filePath ?? this.filePath,
    fileChecksum: fileChecksum ?? this.fileChecksum,
    fileSize: fileSize ?? this.fileSize,
    title: title.present ? title.value : this.title,
    author: author.present ? author.value : this.author,
    publisher: publisher.present ? publisher.value : this.publisher,
    publishedDate: publishedDate.present
        ? publishedDate.value
        : this.publishedDate,
    language: language ?? this.language,
    pageCount: pageCount ?? this.pageCount,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    hasTextLayer: hasTextLayer ?? this.hasTextLayer,
    hasSourceAnnots: hasSourceAnnots ?? this.hasSourceAnnots,
    isOcrDone: isOcrDone ?? this.isOcrDone,
    isIndexed: isIndexed ?? this.isIndexed,
    sourceType: sourceType ?? this.sourceType,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileChecksum: data.fileChecksum.present
          ? data.fileChecksum.value
          : this.fileChecksum,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      publishedDate: data.publishedDate.present
          ? data.publishedDate.value
          : this.publishedDate,
      language: data.language.present ? data.language.value : this.language,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      hasTextLayer: data.hasTextLayer.present
          ? data.hasTextLayer.value
          : this.hasTextLayer,
      hasSourceAnnots: data.hasSourceAnnots.present
          ? data.hasSourceAnnots.value
          : this.hasSourceAnnots,
      isOcrDone: data.isOcrDone.present ? data.isOcrDone.value : this.isOcrDone,
      isIndexed: data.isIndexed.present ? data.isIndexed.value : this.isIndexed,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('filePath: $filePath, ')
          ..write('fileChecksum: $fileChecksum, ')
          ..write('fileSize: $fileSize, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverPath: $coverPath, ')
          ..write('hasTextLayer: $hasTextLayer, ')
          ..write('hasSourceAnnots: $hasSourceAnnots, ')
          ..write('isOcrDone: $isOcrDone, ')
          ..write('isIndexed: $isIndexed, ')
          ..write('sourceType: $sourceType, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    filePath,
    fileChecksum,
    fileSize,
    title,
    author,
    publisher,
    publishedDate,
    language,
    pageCount,
    coverPath,
    hasTextLayer,
    hasSourceAnnots,
    isOcrDone,
    isIndexed,
    sourceType,
    addedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.filePath == this.filePath &&
          other.fileChecksum == this.fileChecksum &&
          other.fileSize == this.fileSize &&
          other.title == this.title &&
          other.author == this.author &&
          other.publisher == this.publisher &&
          other.publishedDate == this.publishedDate &&
          other.language == this.language &&
          other.pageCount == this.pageCount &&
          other.coverPath == this.coverPath &&
          other.hasTextLayer == this.hasTextLayer &&
          other.hasSourceAnnots == this.hasSourceAnnots &&
          other.isOcrDone == this.isOcrDone &&
          other.isIndexed == this.isIndexed &&
          other.sourceType == this.sourceType &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> filePath;
  final Value<String> fileChecksum;
  final Value<int> fileSize;
  final Value<String?> title;
  final Value<String?> author;
  final Value<String?> publisher;
  final Value<String?> publishedDate;
  final Value<String> language;
  final Value<int> pageCount;
  final Value<String?> coverPath;
  final Value<bool> hasTextLayer;
  final Value<bool> hasSourceAnnots;
  final Value<bool> isOcrDone;
  final Value<bool> isIndexed;
  final Value<String> sourceType;
  final Value<String> addedAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileChecksum = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.hasTextLayer = const Value.absent(),
    this.hasSourceAnnots = const Value.absent(),
    this.isOcrDone = const Value.absent(),
    this.isIndexed = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required String filePath,
    required String fileChecksum,
    this.fileSize = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.hasTextLayer = const Value.absent(),
    this.hasSourceAnnots = const Value.absent(),
    this.isOcrDone = const Value.absent(),
    this.isIndexed = const Value.absent(),
    this.sourceType = const Value.absent(),
    required String addedAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       filePath = Value(filePath),
       fileChecksum = Value(fileChecksum),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt);
  static Insertable<BookRow> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? filePath,
    Expression<String>? fileChecksum,
    Expression<int>? fileSize,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? publisher,
    Expression<String>? publishedDate,
    Expression<String>? language,
    Expression<int>? pageCount,
    Expression<String>? coverPath,
    Expression<bool>? hasTextLayer,
    Expression<bool>? hasSourceAnnots,
    Expression<bool>? isOcrDone,
    Expression<bool>? isIndexed,
    Expression<String>? sourceType,
    Expression<String>? addedAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (filePath != null) 'file_path': filePath,
      if (fileChecksum != null) 'file_checksum': fileChecksum,
      if (fileSize != null) 'file_size': fileSize,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (publisher != null) 'publisher': publisher,
      if (publishedDate != null) 'published_date': publishedDate,
      if (language != null) 'language': language,
      if (pageCount != null) 'page_count': pageCount,
      if (coverPath != null) 'cover_path': coverPath,
      if (hasTextLayer != null) 'has_text_layer': hasTextLayer,
      if (hasSourceAnnots != null) 'has_source_annots': hasSourceAnnots,
      if (isOcrDone != null) 'is_ocr_done': isOcrDone,
      if (isIndexed != null) 'is_indexed': isIndexed,
      if (sourceType != null) 'source_type': sourceType,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? filePath,
    Value<String>? fileChecksum,
    Value<int>? fileSize,
    Value<String?>? title,
    Value<String?>? author,
    Value<String?>? publisher,
    Value<String?>? publishedDate,
    Value<String>? language,
    Value<int>? pageCount,
    Value<String?>? coverPath,
    Value<bool>? hasTextLayer,
    Value<bool>? hasSourceAnnots,
    Value<bool>? isOcrDone,
    Value<bool>? isIndexed,
    Value<String>? sourceType,
    Value<String>? addedAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      filePath: filePath ?? this.filePath,
      fileChecksum: fileChecksum ?? this.fileChecksum,
      fileSize: fileSize ?? this.fileSize,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      coverPath: coverPath ?? this.coverPath,
      hasTextLayer: hasTextLayer ?? this.hasTextLayer,
      hasSourceAnnots: hasSourceAnnots ?? this.hasSourceAnnots,
      isOcrDone: isOcrDone ?? this.isOcrDone,
      isIndexed: isIndexed ?? this.isIndexed,
      sourceType: sourceType ?? this.sourceType,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileChecksum.present) {
      map['file_checksum'] = Variable<String>(fileChecksum.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (publishedDate.present) {
      map['published_date'] = Variable<String>(publishedDate.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (hasTextLayer.present) {
      map['has_text_layer'] = Variable<bool>(hasTextLayer.value);
    }
    if (hasSourceAnnots.present) {
      map['has_source_annots'] = Variable<bool>(hasSourceAnnots.value);
    }
    if (isOcrDone.present) {
      map['is_ocr_done'] = Variable<bool>(isOcrDone.value);
    }
    if (isIndexed.present) {
      map['is_indexed'] = Variable<bool>(isIndexed.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<String>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('filePath: $filePath, ')
          ..write('fileChecksum: $fileChecksum, ')
          ..write('fileSize: $fileSize, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverPath: $coverPath, ')
          ..write('hasTextLayer: $hasTextLayer, ')
          ..write('hasSourceAnnots: $hasSourceAnnots, ')
          ..write('isOcrDone: $isOcrDone, ')
          ..write('isIndexed: $isIndexed, ')
          ..write('sourceType: $sourceType, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _lastPageMeta = const VerificationMeta(
    'lastPage',
  );
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
    'last_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastOffsetMeta = const VerificationMeta(
    'lastOffset',
  );
  @override
  late final GeneratedColumn<double> lastOffset = GeneratedColumn<double>(
    'last_offset',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _farthestPageMeta = const VerificationMeta(
    'farthestPage',
  );
  @override
  late final GeneratedColumn<int> farthestPage = GeneratedColumn<int>(
    'farthest_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unread'),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<String> lastReadAt = GeneratedColumn<String>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<String> finishedAt = GeneratedColumn<String>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    lastPage,
    lastOffset,
    farthestPage,
    percent,
    status,
    lastReadAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('last_page')) {
      context.handle(
        _lastPageMeta,
        lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta),
      );
    }
    if (data.containsKey('last_offset')) {
      context.handle(
        _lastOffsetMeta,
        lastOffset.isAcceptableOrUnknown(data['last_offset']!, _lastOffsetMeta),
      );
    }
    if (data.containsKey('farthest_page')) {
      context.handle(
        _farthestPageMeta,
        farthestPage.isAcceptableOrUnknown(
          data['farthest_page']!,
          _farthestPageMeta,
        ),
      );
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  ReadingProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressData(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      lastPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page'],
      )!,
      lastOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_offset'],
      )!,
      farthestPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}farthest_page'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressData extends DataClass
    implements Insertable<ReadingProgressData> {
  final int bookId;

  /// 마지막으로 보던 페이지
  final int lastPage;

  /// 페이지 내 위치 비율 (0.0~1.0)
  final double lastOffset;

  /// **가장 멀리 읽은 페이지.** 진도율은 이 값 기준
  final int farthestPage;
  final double percent;

  /// 독서 상태 (unread / reading / finished)
  final String status;
  final String? lastReadAt;
  final String? finishedAt;
  const ReadingProgressData({
    required this.bookId,
    required this.lastPage,
    required this.lastOffset,
    required this.farthestPage,
    required this.percent,
    required this.status,
    this.lastReadAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['last_page'] = Variable<int>(lastPage);
    map['last_offset'] = Variable<double>(lastOffset);
    map['farthest_page'] = Variable<int>(farthestPage);
    map['percent'] = Variable<double>(percent);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(lastReadAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(finishedAt);
    }
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      bookId: Value(bookId),
      lastPage: Value(lastPage),
      lastOffset: Value(lastOffset),
      farthestPage: Value(farthestPage),
      percent: Value(percent),
      status: Value(status),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory ReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressData(
      bookId: serializer.fromJson<int>(json['bookId']),
      lastPage: serializer.fromJson<int>(json['lastPage']),
      lastOffset: serializer.fromJson<double>(json['lastOffset']),
      farthestPage: serializer.fromJson<int>(json['farthestPage']),
      percent: serializer.fromJson<double>(json['percent']),
      status: serializer.fromJson<String>(json['status']),
      lastReadAt: serializer.fromJson<String?>(json['lastReadAt']),
      finishedAt: serializer.fromJson<String?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'lastPage': serializer.toJson<int>(lastPage),
      'lastOffset': serializer.toJson<double>(lastOffset),
      'farthestPage': serializer.toJson<int>(farthestPage),
      'percent': serializer.toJson<double>(percent),
      'status': serializer.toJson<String>(status),
      'lastReadAt': serializer.toJson<String?>(lastReadAt),
      'finishedAt': serializer.toJson<String?>(finishedAt),
    };
  }

  ReadingProgressData copyWith({
    int? bookId,
    int? lastPage,
    double? lastOffset,
    int? farthestPage,
    double? percent,
    String? status,
    Value<String?> lastReadAt = const Value.absent(),
    Value<String?> finishedAt = const Value.absent(),
  }) => ReadingProgressData(
    bookId: bookId ?? this.bookId,
    lastPage: lastPage ?? this.lastPage,
    lastOffset: lastOffset ?? this.lastOffset,
    farthestPage: farthestPage ?? this.farthestPage,
    percent: percent ?? this.percent,
    status: status ?? this.status,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  ReadingProgressData copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressData(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      lastOffset: data.lastOffset.present
          ? data.lastOffset.value
          : this.lastOffset,
      farthestPage: data.farthestPage.present
          ? data.farthestPage.value
          : this.farthestPage,
      percent: data.percent.present ? data.percent.value : this.percent,
      status: data.status.present ? data.status.value : this.status,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressData(')
          ..write('bookId: $bookId, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastOffset: $lastOffset, ')
          ..write('farthestPage: $farthestPage, ')
          ..write('percent: $percent, ')
          ..write('status: $status, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    lastPage,
    lastOffset,
    farthestPage,
    percent,
    status,
    lastReadAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressData &&
          other.bookId == this.bookId &&
          other.lastPage == this.lastPage &&
          other.lastOffset == this.lastOffset &&
          other.farthestPage == this.farthestPage &&
          other.percent == this.percent &&
          other.status == this.status &&
          other.lastReadAt == this.lastReadAt &&
          other.finishedAt == this.finishedAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressData> {
  final Value<int> bookId;
  final Value<int> lastPage;
  final Value<double> lastOffset;
  final Value<int> farthestPage;
  final Value<double> percent;
  final Value<String> status;
  final Value<String?> lastReadAt;
  final Value<String?> finishedAt;
  const ReadingProgressCompanion({
    this.bookId = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.lastOffset = const Value.absent(),
    this.farthestPage = const Value.absent(),
    this.percent = const Value.absent(),
    this.status = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    this.bookId = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.lastOffset = const Value.absent(),
    this.farthestPage = const Value.absent(),
    this.percent = const Value.absent(),
    this.status = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
  });
  static Insertable<ReadingProgressData> custom({
    Expression<int>? bookId,
    Expression<int>? lastPage,
    Expression<double>? lastOffset,
    Expression<int>? farthestPage,
    Expression<double>? percent,
    Expression<String>? status,
    Expression<String>? lastReadAt,
    Expression<String>? finishedAt,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (lastPage != null) 'last_page': lastPage,
      if (lastOffset != null) 'last_offset': lastOffset,
      if (farthestPage != null) 'farthest_page': farthestPage,
      if (percent != null) 'percent': percent,
      if (status != null) 'status': status,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (finishedAt != null) 'finished_at': finishedAt,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<int>? bookId,
    Value<int>? lastPage,
    Value<double>? lastOffset,
    Value<int>? farthestPage,
    Value<double>? percent,
    Value<String>? status,
    Value<String?>? lastReadAt,
    Value<String?>? finishedAt,
  }) {
    return ReadingProgressCompanion(
      bookId: bookId ?? this.bookId,
      lastPage: lastPage ?? this.lastPage,
      lastOffset: lastOffset ?? this.lastOffset,
      farthestPage: farthestPage ?? this.farthestPage,
      percent: percent ?? this.percent,
      status: status ?? this.status,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (lastOffset.present) {
      map['last_offset'] = Variable<double>(lastOffset.value);
    }
    if (farthestPage.present) {
      map['farthest_page'] = Variable<int>(farthestPage.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(lastReadAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(finishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('bookId: $bookId, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastOffset: $lastOffset, ')
          ..write('farthestPage: $farthestPage, ')
          ..write('percent: $percent, ')
          ..write('status: $status, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }
}

class $BookSettingsTable extends BookSettings
    with TableInfo<$BookSettingsTable, BookSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _viewModeMeta = const VerificationMeta(
    'viewMode',
  );
  @override
  late final GeneratedColumn<String> viewMode = GeneratedColumn<String>(
    'view_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('continuous'),
  );
  static const VerificationMeta _fitModeMeta = const VerificationMeta(
    'fitMode',
  );
  @override
  late final GeneratedColumn<String> fitMode = GeneratedColumn<String>(
    'fit_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('width'),
  );
  static const VerificationMeta _zoomLevelMeta = const VerificationMeta(
    'zoomLevel',
  );
  @override
  late final GeneratedColumn<double> zoomLevel = GeneratedColumn<double>(
    'zoom_level',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<int> rotation = GeneratedColumn<int>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _darkImageModeMeta = const VerificationMeta(
    'darkImageMode',
  );
  @override
  late final GeneratedColumn<String> darkImageMode = GeneratedColumn<String>(
    'dark_image_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('preserve'),
  );
  static const VerificationMeta _cropEnabledMeta = const VerificationMeta(
    'cropEnabled',
  );
  @override
  late final GeneratedColumn<bool> cropEnabled = GeneratedColumn<bool>(
    'crop_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("crop_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cropOddMeta = const VerificationMeta(
    'cropOdd',
  );
  @override
  late final GeneratedColumn<String> cropOdd = GeneratedColumn<String>(
    'crop_odd',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropEvenMeta = const VerificationMeta(
    'cropEven',
  );
  @override
  late final GeneratedColumn<String> cropEven = GeneratedColumn<String>(
    'crop_even',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _columnModeMeta = const VerificationMeta(
    'columnMode',
  );
  @override
  late final GeneratedColumn<int> columnMode = GeneratedColumn<int>(
    'column_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _showSourceAnnotsMeta = const VerificationMeta(
    'showSourceAnnots',
  );
  @override
  late final GeneratedColumn<bool> showSourceAnnots = GeneratedColumn<bool>(
    'show_source_annots',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_source_annots" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    viewMode,
    fitMode,
    zoomLevel,
    rotation,
    theme,
    darkImageMode,
    cropEnabled,
    cropOdd,
    cropEven,
    columnMode,
    showSourceAnnots,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('view_mode')) {
      context.handle(
        _viewModeMeta,
        viewMode.isAcceptableOrUnknown(data['view_mode']!, _viewModeMeta),
      );
    }
    if (data.containsKey('fit_mode')) {
      context.handle(
        _fitModeMeta,
        fitMode.isAcceptableOrUnknown(data['fit_mode']!, _fitModeMeta),
      );
    }
    if (data.containsKey('zoom_level')) {
      context.handle(
        _zoomLevelMeta,
        zoomLevel.isAcceptableOrUnknown(data['zoom_level']!, _zoomLevelMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('dark_image_mode')) {
      context.handle(
        _darkImageModeMeta,
        darkImageMode.isAcceptableOrUnknown(
          data['dark_image_mode']!,
          _darkImageModeMeta,
        ),
      );
    }
    if (data.containsKey('crop_enabled')) {
      context.handle(
        _cropEnabledMeta,
        cropEnabled.isAcceptableOrUnknown(
          data['crop_enabled']!,
          _cropEnabledMeta,
        ),
      );
    }
    if (data.containsKey('crop_odd')) {
      context.handle(
        _cropOddMeta,
        cropOdd.isAcceptableOrUnknown(data['crop_odd']!, _cropOddMeta),
      );
    }
    if (data.containsKey('crop_even')) {
      context.handle(
        _cropEvenMeta,
        cropEven.isAcceptableOrUnknown(data['crop_even']!, _cropEvenMeta),
      );
    }
    if (data.containsKey('column_mode')) {
      context.handle(
        _columnModeMeta,
        columnMode.isAcceptableOrUnknown(data['column_mode']!, _columnModeMeta),
      );
    }
    if (data.containsKey('show_source_annots')) {
      context.handle(
        _showSourceAnnotsMeta,
        showSourceAnnots.isAcceptableOrUnknown(
          data['show_source_annots']!,
          _showSourceAnnotsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  BookSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookSetting(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      viewMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_mode'],
      )!,
      fitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fit_mode'],
      )!,
      zoomLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zoom_level'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      darkImageMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dark_image_mode'],
      )!,
      cropEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}crop_enabled'],
      )!,
      cropOdd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_odd'],
      ),
      cropEven: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_even'],
      ),
      columnMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}column_mode'],
      )!,
      showSourceAnnots: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_source_annots'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BookSettingsTable createAlias(String alias) {
    return $BookSettingsTable(attachedDatabase, alias);
  }
}

class BookSetting extends DataClass implements Insertable<BookSetting> {
  final int bookId;

  /// 보기 모드 (single / continuous / spread) — 기본은 연속 스크롤
  final String viewMode;

  /// 맞춤 모드 (width / page / content)
  final String fitMode;
  final double zoomLevel;

  /// 회전 각도. 뷰 한정이며 파일은 바뀌지 않는다
  final int rotation;

  /// 테마 (light / dark / sepia / system)
  final String theme;

  /// 다크모드 이미지 처리 (invert / preserve / dim)
  final String darkImageMode;
  final bool cropEnabled;

  /// 홀수/짝수 페이지 크롭 [l,t,r,b] 비율 JSON.
  /// 제본 여백 때문에 홀짝을 따로 계산해야 한다
  final String? cropOdd;
  final String? cropEven;

  /// 다단 순차 보기 컬럼 수 (0=사용 안 함)
  final int columnMode;
  final bool showSourceAnnots;
  final String updatedAt;
  const BookSetting({
    required this.bookId,
    required this.viewMode,
    required this.fitMode,
    required this.zoomLevel,
    required this.rotation,
    required this.theme,
    required this.darkImageMode,
    required this.cropEnabled,
    this.cropOdd,
    this.cropEven,
    required this.columnMode,
    required this.showSourceAnnots,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['view_mode'] = Variable<String>(viewMode);
    map['fit_mode'] = Variable<String>(fitMode);
    map['zoom_level'] = Variable<double>(zoomLevel);
    map['rotation'] = Variable<int>(rotation);
    map['theme'] = Variable<String>(theme);
    map['dark_image_mode'] = Variable<String>(darkImageMode);
    map['crop_enabled'] = Variable<bool>(cropEnabled);
    if (!nullToAbsent || cropOdd != null) {
      map['crop_odd'] = Variable<String>(cropOdd);
    }
    if (!nullToAbsent || cropEven != null) {
      map['crop_even'] = Variable<String>(cropEven);
    }
    map['column_mode'] = Variable<int>(columnMode);
    map['show_source_annots'] = Variable<bool>(showSourceAnnots);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BookSettingsCompanion toCompanion(bool nullToAbsent) {
    return BookSettingsCompanion(
      bookId: Value(bookId),
      viewMode: Value(viewMode),
      fitMode: Value(fitMode),
      zoomLevel: Value(zoomLevel),
      rotation: Value(rotation),
      theme: Value(theme),
      darkImageMode: Value(darkImageMode),
      cropEnabled: Value(cropEnabled),
      cropOdd: cropOdd == null && nullToAbsent
          ? const Value.absent()
          : Value(cropOdd),
      cropEven: cropEven == null && nullToAbsent
          ? const Value.absent()
          : Value(cropEven),
      columnMode: Value(columnMode),
      showSourceAnnots: Value(showSourceAnnots),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookSetting(
      bookId: serializer.fromJson<int>(json['bookId']),
      viewMode: serializer.fromJson<String>(json['viewMode']),
      fitMode: serializer.fromJson<String>(json['fitMode']),
      zoomLevel: serializer.fromJson<double>(json['zoomLevel']),
      rotation: serializer.fromJson<int>(json['rotation']),
      theme: serializer.fromJson<String>(json['theme']),
      darkImageMode: serializer.fromJson<String>(json['darkImageMode']),
      cropEnabled: serializer.fromJson<bool>(json['cropEnabled']),
      cropOdd: serializer.fromJson<String?>(json['cropOdd']),
      cropEven: serializer.fromJson<String?>(json['cropEven']),
      columnMode: serializer.fromJson<int>(json['columnMode']),
      showSourceAnnots: serializer.fromJson<bool>(json['showSourceAnnots']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'viewMode': serializer.toJson<String>(viewMode),
      'fitMode': serializer.toJson<String>(fitMode),
      'zoomLevel': serializer.toJson<double>(zoomLevel),
      'rotation': serializer.toJson<int>(rotation),
      'theme': serializer.toJson<String>(theme),
      'darkImageMode': serializer.toJson<String>(darkImageMode),
      'cropEnabled': serializer.toJson<bool>(cropEnabled),
      'cropOdd': serializer.toJson<String?>(cropOdd),
      'cropEven': serializer.toJson<String?>(cropEven),
      'columnMode': serializer.toJson<int>(columnMode),
      'showSourceAnnots': serializer.toJson<bool>(showSourceAnnots),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BookSetting copyWith({
    int? bookId,
    String? viewMode,
    String? fitMode,
    double? zoomLevel,
    int? rotation,
    String? theme,
    String? darkImageMode,
    bool? cropEnabled,
    Value<String?> cropOdd = const Value.absent(),
    Value<String?> cropEven = const Value.absent(),
    int? columnMode,
    bool? showSourceAnnots,
    String? updatedAt,
  }) => BookSetting(
    bookId: bookId ?? this.bookId,
    viewMode: viewMode ?? this.viewMode,
    fitMode: fitMode ?? this.fitMode,
    zoomLevel: zoomLevel ?? this.zoomLevel,
    rotation: rotation ?? this.rotation,
    theme: theme ?? this.theme,
    darkImageMode: darkImageMode ?? this.darkImageMode,
    cropEnabled: cropEnabled ?? this.cropEnabled,
    cropOdd: cropOdd.present ? cropOdd.value : this.cropOdd,
    cropEven: cropEven.present ? cropEven.value : this.cropEven,
    columnMode: columnMode ?? this.columnMode,
    showSourceAnnots: showSourceAnnots ?? this.showSourceAnnots,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookSetting copyWithCompanion(BookSettingsCompanion data) {
    return BookSetting(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      viewMode: data.viewMode.present ? data.viewMode.value : this.viewMode,
      fitMode: data.fitMode.present ? data.fitMode.value : this.fitMode,
      zoomLevel: data.zoomLevel.present ? data.zoomLevel.value : this.zoomLevel,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      theme: data.theme.present ? data.theme.value : this.theme,
      darkImageMode: data.darkImageMode.present
          ? data.darkImageMode.value
          : this.darkImageMode,
      cropEnabled: data.cropEnabled.present
          ? data.cropEnabled.value
          : this.cropEnabled,
      cropOdd: data.cropOdd.present ? data.cropOdd.value : this.cropOdd,
      cropEven: data.cropEven.present ? data.cropEven.value : this.cropEven,
      columnMode: data.columnMode.present
          ? data.columnMode.value
          : this.columnMode,
      showSourceAnnots: data.showSourceAnnots.present
          ? data.showSourceAnnots.value
          : this.showSourceAnnots,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookSetting(')
          ..write('bookId: $bookId, ')
          ..write('viewMode: $viewMode, ')
          ..write('fitMode: $fitMode, ')
          ..write('zoomLevel: $zoomLevel, ')
          ..write('rotation: $rotation, ')
          ..write('theme: $theme, ')
          ..write('darkImageMode: $darkImageMode, ')
          ..write('cropEnabled: $cropEnabled, ')
          ..write('cropOdd: $cropOdd, ')
          ..write('cropEven: $cropEven, ')
          ..write('columnMode: $columnMode, ')
          ..write('showSourceAnnots: $showSourceAnnots, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    viewMode,
    fitMode,
    zoomLevel,
    rotation,
    theme,
    darkImageMode,
    cropEnabled,
    cropOdd,
    cropEven,
    columnMode,
    showSourceAnnots,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookSetting &&
          other.bookId == this.bookId &&
          other.viewMode == this.viewMode &&
          other.fitMode == this.fitMode &&
          other.zoomLevel == this.zoomLevel &&
          other.rotation == this.rotation &&
          other.theme == this.theme &&
          other.darkImageMode == this.darkImageMode &&
          other.cropEnabled == this.cropEnabled &&
          other.cropOdd == this.cropOdd &&
          other.cropEven == this.cropEven &&
          other.columnMode == this.columnMode &&
          other.showSourceAnnots == this.showSourceAnnots &&
          other.updatedAt == this.updatedAt);
}

class BookSettingsCompanion extends UpdateCompanion<BookSetting> {
  final Value<int> bookId;
  final Value<String> viewMode;
  final Value<String> fitMode;
  final Value<double> zoomLevel;
  final Value<int> rotation;
  final Value<String> theme;
  final Value<String> darkImageMode;
  final Value<bool> cropEnabled;
  final Value<String?> cropOdd;
  final Value<String?> cropEven;
  final Value<int> columnMode;
  final Value<bool> showSourceAnnots;
  final Value<String> updatedAt;
  const BookSettingsCompanion({
    this.bookId = const Value.absent(),
    this.viewMode = const Value.absent(),
    this.fitMode = const Value.absent(),
    this.zoomLevel = const Value.absent(),
    this.rotation = const Value.absent(),
    this.theme = const Value.absent(),
    this.darkImageMode = const Value.absent(),
    this.cropEnabled = const Value.absent(),
    this.cropOdd = const Value.absent(),
    this.cropEven = const Value.absent(),
    this.columnMode = const Value.absent(),
    this.showSourceAnnots = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BookSettingsCompanion.insert({
    this.bookId = const Value.absent(),
    this.viewMode = const Value.absent(),
    this.fitMode = const Value.absent(),
    this.zoomLevel = const Value.absent(),
    this.rotation = const Value.absent(),
    this.theme = const Value.absent(),
    this.darkImageMode = const Value.absent(),
    this.cropEnabled = const Value.absent(),
    this.cropOdd = const Value.absent(),
    this.cropEven = const Value.absent(),
    this.columnMode = const Value.absent(),
    this.showSourceAnnots = const Value.absent(),
    required String updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<BookSetting> custom({
    Expression<int>? bookId,
    Expression<String>? viewMode,
    Expression<String>? fitMode,
    Expression<double>? zoomLevel,
    Expression<int>? rotation,
    Expression<String>? theme,
    Expression<String>? darkImageMode,
    Expression<bool>? cropEnabled,
    Expression<String>? cropOdd,
    Expression<String>? cropEven,
    Expression<int>? columnMode,
    Expression<bool>? showSourceAnnots,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (viewMode != null) 'view_mode': viewMode,
      if (fitMode != null) 'fit_mode': fitMode,
      if (zoomLevel != null) 'zoom_level': zoomLevel,
      if (rotation != null) 'rotation': rotation,
      if (theme != null) 'theme': theme,
      if (darkImageMode != null) 'dark_image_mode': darkImageMode,
      if (cropEnabled != null) 'crop_enabled': cropEnabled,
      if (cropOdd != null) 'crop_odd': cropOdd,
      if (cropEven != null) 'crop_even': cropEven,
      if (columnMode != null) 'column_mode': columnMode,
      if (showSourceAnnots != null) 'show_source_annots': showSourceAnnots,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BookSettingsCompanion copyWith({
    Value<int>? bookId,
    Value<String>? viewMode,
    Value<String>? fitMode,
    Value<double>? zoomLevel,
    Value<int>? rotation,
    Value<String>? theme,
    Value<String>? darkImageMode,
    Value<bool>? cropEnabled,
    Value<String?>? cropOdd,
    Value<String?>? cropEven,
    Value<int>? columnMode,
    Value<bool>? showSourceAnnots,
    Value<String>? updatedAt,
  }) {
    return BookSettingsCompanion(
      bookId: bookId ?? this.bookId,
      viewMode: viewMode ?? this.viewMode,
      fitMode: fitMode ?? this.fitMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      rotation: rotation ?? this.rotation,
      theme: theme ?? this.theme,
      darkImageMode: darkImageMode ?? this.darkImageMode,
      cropEnabled: cropEnabled ?? this.cropEnabled,
      cropOdd: cropOdd ?? this.cropOdd,
      cropEven: cropEven ?? this.cropEven,
      columnMode: columnMode ?? this.columnMode,
      showSourceAnnots: showSourceAnnots ?? this.showSourceAnnots,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (viewMode.present) {
      map['view_mode'] = Variable<String>(viewMode.value);
    }
    if (fitMode.present) {
      map['fit_mode'] = Variable<String>(fitMode.value);
    }
    if (zoomLevel.present) {
      map['zoom_level'] = Variable<double>(zoomLevel.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<int>(rotation.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (darkImageMode.present) {
      map['dark_image_mode'] = Variable<String>(darkImageMode.value);
    }
    if (cropEnabled.present) {
      map['crop_enabled'] = Variable<bool>(cropEnabled.value);
    }
    if (cropOdd.present) {
      map['crop_odd'] = Variable<String>(cropOdd.value);
    }
    if (cropEven.present) {
      map['crop_even'] = Variable<String>(cropEven.value);
    }
    if (columnMode.present) {
      map['column_mode'] = Variable<int>(columnMode.value);
    }
    if (showSourceAnnots.present) {
      map['show_source_annots'] = Variable<bool>(showSourceAnnots.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookSettingsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('viewMode: $viewMode, ')
          ..write('fitMode: $fitMode, ')
          ..write('zoomLevel: $zoomLevel, ')
          ..write('rotation: $rotation, ')
          ..write('theme: $theme, ')
          ..write('darkImageMode: $darkImageMode, ')
          ..write('cropEnabled: $cropEnabled, ')
          ..write('cropOdd: $cropOdd, ')
          ..write('cropEven: $cropEven, ')
          ..write('columnMode: $columnMode, ')
          ..write('showSourceAnnots: $showSourceAnnots, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AnchorsTable extends Anchors with TableInfo<$AnchorsTable, Anchor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnchorsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _pageNoMeta = const VerificationMeta('pageNo');
  @override
  late final GeneratedColumn<int> pageNo = GeneratedColumn<int>(
    'page_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rectsMeta = const VerificationMeta('rects');
  @override
  late final GeneratedColumn<String> rects = GeneratedColumn<String>(
    'rects',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteTextMeta = const VerificationMeta(
    'quoteText',
  );
  @override
  late final GeneratedColumn<String> quoteText = GeneratedColumn<String>(
    'quote_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefixTextMeta = const VerificationMeta(
    'prefixText',
  );
  @override
  late final GeneratedColumn<String> prefixText = GeneratedColumn<String>(
    'prefix_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suffixTextMeta = const VerificationMeta(
    'suffixText',
  );
  @override
  late final GeneratedColumn<String> suffixText = GeneratedColumn<String>(
    'suffix_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentChecksumMeta = const VerificationMeta(
    'documentChecksum',
  );
  @override
  late final GeneratedColumn<String> documentChecksum = GeneratedColumn<String>(
    'document_checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoTimeMsMeta = const VerificationMeta(
    'videoTimeMs',
  );
  @override
  late final GeneratedColumn<int> videoTimeMs = GeneratedColumn<int>(
    'video_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOrphanMeta = const VerificationMeta(
    'isOrphan',
  );
  @override
  late final GeneratedColumn<bool> isOrphan = GeneratedColumn<bool>(
    'is_orphan',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_orphan" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    bookId,
    kind,
    pageNo,
    rects,
    quoteText,
    prefixText,
    suffixText,
    documentChecksum,
    videoTimeMs,
    isOrphan,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anchors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Anchor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('page_no')) {
      context.handle(
        _pageNoMeta,
        pageNo.isAcceptableOrUnknown(data['page_no']!, _pageNoMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNoMeta);
    }
    if (data.containsKey('rects')) {
      context.handle(
        _rectsMeta,
        rects.isAcceptableOrUnknown(data['rects']!, _rectsMeta),
      );
    } else if (isInserting) {
      context.missing(_rectsMeta);
    }
    if (data.containsKey('quote_text')) {
      context.handle(
        _quoteTextMeta,
        quoteText.isAcceptableOrUnknown(data['quote_text']!, _quoteTextMeta),
      );
    }
    if (data.containsKey('prefix_text')) {
      context.handle(
        _prefixTextMeta,
        prefixText.isAcceptableOrUnknown(data['prefix_text']!, _prefixTextMeta),
      );
    }
    if (data.containsKey('suffix_text')) {
      context.handle(
        _suffixTextMeta,
        suffixText.isAcceptableOrUnknown(data['suffix_text']!, _suffixTextMeta),
      );
    }
    if (data.containsKey('document_checksum')) {
      context.handle(
        _documentChecksumMeta,
        documentChecksum.isAcceptableOrUnknown(
          data['document_checksum']!,
          _documentChecksumMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentChecksumMeta);
    }
    if (data.containsKey('video_time_ms')) {
      context.handle(
        _videoTimeMsMeta,
        videoTimeMs.isAcceptableOrUnknown(
          data['video_time_ms']!,
          _videoTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('is_orphan')) {
      context.handle(
        _isOrphanMeta,
        isOrphan.isAcceptableOrUnknown(data['is_orphan']!, _isOrphanMeta),
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
  Anchor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Anchor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      pageNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_no'],
      )!,
      rects: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rects'],
      )!,
      quoteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_text'],
      ),
      prefixText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix_text'],
      ),
      suffixText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suffix_text'],
      ),
      documentChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_checksum'],
      )!,
      videoTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}video_time_ms'],
      ),
      isOrphan: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_orphan'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnchorsTable createAlias(String alias) {
    return $AnchorsTable(attachedDatabase, alias);
  }
}

class Anchor extends DataClass implements Insertable<Anchor> {
  final int id;
  final String uuid;
  final int bookId;

  /// 앵커 종류 (text 텍스트범위 / area 사각영역 / point 지점)
  final String kind;
  final int pageNo;

  /// 좌표 JSON [[x0,y0,x1,y1],...] PDF 좌표계
  final String rects;

  /// 선택된 원문. 파일이 바뀌었을 때 재부착 기준
  final String? quoteText;

  /// 앞뒤 문맥 각 40자 — 같은 문구가 여러 개일 때 구분한다
  final String? prefixText;
  final String? suffixText;

  /// 앵커 생성 당시의 books.fileChecksum. 불일치 시 재부착을 시도한다
  final String documentChecksum;

  /// v2 영상북일 때 원본 영상 타임코드(ms)
  final int? videoTimeMs;

  /// 재부착 실패로 위치를 잃음. 주석 목록 상단에 경고 그룹으로 노출한다
  final bool isOrphan;
  final String createdAt;
  const Anchor({
    required this.id,
    required this.uuid,
    required this.bookId,
    required this.kind,
    required this.pageNo,
    required this.rects,
    this.quoteText,
    this.prefixText,
    this.suffixText,
    required this.documentChecksum,
    this.videoTimeMs,
    required this.isOrphan,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['book_id'] = Variable<int>(bookId);
    map['kind'] = Variable<String>(kind);
    map['page_no'] = Variable<int>(pageNo);
    map['rects'] = Variable<String>(rects);
    if (!nullToAbsent || quoteText != null) {
      map['quote_text'] = Variable<String>(quoteText);
    }
    if (!nullToAbsent || prefixText != null) {
      map['prefix_text'] = Variable<String>(prefixText);
    }
    if (!nullToAbsent || suffixText != null) {
      map['suffix_text'] = Variable<String>(suffixText);
    }
    map['document_checksum'] = Variable<String>(documentChecksum);
    if (!nullToAbsent || videoTimeMs != null) {
      map['video_time_ms'] = Variable<int>(videoTimeMs);
    }
    map['is_orphan'] = Variable<bool>(isOrphan);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  AnchorsCompanion toCompanion(bool nullToAbsent) {
    return AnchorsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      bookId: Value(bookId),
      kind: Value(kind),
      pageNo: Value(pageNo),
      rects: Value(rects),
      quoteText: quoteText == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteText),
      prefixText: prefixText == null && nullToAbsent
          ? const Value.absent()
          : Value(prefixText),
      suffixText: suffixText == null && nullToAbsent
          ? const Value.absent()
          : Value(suffixText),
      documentChecksum: Value(documentChecksum),
      videoTimeMs: videoTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(videoTimeMs),
      isOrphan: Value(isOrphan),
      createdAt: Value(createdAt),
    );
  }

  factory Anchor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Anchor(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      bookId: serializer.fromJson<int>(json['bookId']),
      kind: serializer.fromJson<String>(json['kind']),
      pageNo: serializer.fromJson<int>(json['pageNo']),
      rects: serializer.fromJson<String>(json['rects']),
      quoteText: serializer.fromJson<String?>(json['quoteText']),
      prefixText: serializer.fromJson<String?>(json['prefixText']),
      suffixText: serializer.fromJson<String?>(json['suffixText']),
      documentChecksum: serializer.fromJson<String>(json['documentChecksum']),
      videoTimeMs: serializer.fromJson<int?>(json['videoTimeMs']),
      isOrphan: serializer.fromJson<bool>(json['isOrphan']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'bookId': serializer.toJson<int>(bookId),
      'kind': serializer.toJson<String>(kind),
      'pageNo': serializer.toJson<int>(pageNo),
      'rects': serializer.toJson<String>(rects),
      'quoteText': serializer.toJson<String?>(quoteText),
      'prefixText': serializer.toJson<String?>(prefixText),
      'suffixText': serializer.toJson<String?>(suffixText),
      'documentChecksum': serializer.toJson<String>(documentChecksum),
      'videoTimeMs': serializer.toJson<int?>(videoTimeMs),
      'isOrphan': serializer.toJson<bool>(isOrphan),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Anchor copyWith({
    int? id,
    String? uuid,
    int? bookId,
    String? kind,
    int? pageNo,
    String? rects,
    Value<String?> quoteText = const Value.absent(),
    Value<String?> prefixText = const Value.absent(),
    Value<String?> suffixText = const Value.absent(),
    String? documentChecksum,
    Value<int?> videoTimeMs = const Value.absent(),
    bool? isOrphan,
    String? createdAt,
  }) => Anchor(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    bookId: bookId ?? this.bookId,
    kind: kind ?? this.kind,
    pageNo: pageNo ?? this.pageNo,
    rects: rects ?? this.rects,
    quoteText: quoteText.present ? quoteText.value : this.quoteText,
    prefixText: prefixText.present ? prefixText.value : this.prefixText,
    suffixText: suffixText.present ? suffixText.value : this.suffixText,
    documentChecksum: documentChecksum ?? this.documentChecksum,
    videoTimeMs: videoTimeMs.present ? videoTimeMs.value : this.videoTimeMs,
    isOrphan: isOrphan ?? this.isOrphan,
    createdAt: createdAt ?? this.createdAt,
  );
  Anchor copyWithCompanion(AnchorsCompanion data) {
    return Anchor(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      kind: data.kind.present ? data.kind.value : this.kind,
      pageNo: data.pageNo.present ? data.pageNo.value : this.pageNo,
      rects: data.rects.present ? data.rects.value : this.rects,
      quoteText: data.quoteText.present ? data.quoteText.value : this.quoteText,
      prefixText: data.prefixText.present
          ? data.prefixText.value
          : this.prefixText,
      suffixText: data.suffixText.present
          ? data.suffixText.value
          : this.suffixText,
      documentChecksum: data.documentChecksum.present
          ? data.documentChecksum.value
          : this.documentChecksum,
      videoTimeMs: data.videoTimeMs.present
          ? data.videoTimeMs.value
          : this.videoTimeMs,
      isOrphan: data.isOrphan.present ? data.isOrphan.value : this.isOrphan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Anchor(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('pageNo: $pageNo, ')
          ..write('rects: $rects, ')
          ..write('quoteText: $quoteText, ')
          ..write('prefixText: $prefixText, ')
          ..write('suffixText: $suffixText, ')
          ..write('documentChecksum: $documentChecksum, ')
          ..write('videoTimeMs: $videoTimeMs, ')
          ..write('isOrphan: $isOrphan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    bookId,
    kind,
    pageNo,
    rects,
    quoteText,
    prefixText,
    suffixText,
    documentChecksum,
    videoTimeMs,
    isOrphan,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Anchor &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.bookId == this.bookId &&
          other.kind == this.kind &&
          other.pageNo == this.pageNo &&
          other.rects == this.rects &&
          other.quoteText == this.quoteText &&
          other.prefixText == this.prefixText &&
          other.suffixText == this.suffixText &&
          other.documentChecksum == this.documentChecksum &&
          other.videoTimeMs == this.videoTimeMs &&
          other.isOrphan == this.isOrphan &&
          other.createdAt == this.createdAt);
}

class AnchorsCompanion extends UpdateCompanion<Anchor> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> bookId;
  final Value<String> kind;
  final Value<int> pageNo;
  final Value<String> rects;
  final Value<String?> quoteText;
  final Value<String?> prefixText;
  final Value<String?> suffixText;
  final Value<String> documentChecksum;
  final Value<int?> videoTimeMs;
  final Value<bool> isOrphan;
  final Value<String> createdAt;
  const AnchorsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.bookId = const Value.absent(),
    this.kind = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.rects = const Value.absent(),
    this.quoteText = const Value.absent(),
    this.prefixText = const Value.absent(),
    this.suffixText = const Value.absent(),
    this.documentChecksum = const Value.absent(),
    this.videoTimeMs = const Value.absent(),
    this.isOrphan = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnchorsCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int bookId,
    this.kind = const Value.absent(),
    required int pageNo,
    required String rects,
    this.quoteText = const Value.absent(),
    this.prefixText = const Value.absent(),
    this.suffixText = const Value.absent(),
    required String documentChecksum,
    this.videoTimeMs = const Value.absent(),
    this.isOrphan = const Value.absent(),
    required String createdAt,
  }) : uuid = Value(uuid),
       bookId = Value(bookId),
       pageNo = Value(pageNo),
       rects = Value(rects),
       documentChecksum = Value(documentChecksum),
       createdAt = Value(createdAt);
  static Insertable<Anchor> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? bookId,
    Expression<String>? kind,
    Expression<int>? pageNo,
    Expression<String>? rects,
    Expression<String>? quoteText,
    Expression<String>? prefixText,
    Expression<String>? suffixText,
    Expression<String>? documentChecksum,
    Expression<int>? videoTimeMs,
    Expression<bool>? isOrphan,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (bookId != null) 'book_id': bookId,
      if (kind != null) 'kind': kind,
      if (pageNo != null) 'page_no': pageNo,
      if (rects != null) 'rects': rects,
      if (quoteText != null) 'quote_text': quoteText,
      if (prefixText != null) 'prefix_text': prefixText,
      if (suffixText != null) 'suffix_text': suffixText,
      if (documentChecksum != null) 'document_checksum': documentChecksum,
      if (videoTimeMs != null) 'video_time_ms': videoTimeMs,
      if (isOrphan != null) 'is_orphan': isOrphan,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnchorsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? bookId,
    Value<String>? kind,
    Value<int>? pageNo,
    Value<String>? rects,
    Value<String?>? quoteText,
    Value<String?>? prefixText,
    Value<String?>? suffixText,
    Value<String>? documentChecksum,
    Value<int?>? videoTimeMs,
    Value<bool>? isOrphan,
    Value<String>? createdAt,
  }) {
    return AnchorsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      kind: kind ?? this.kind,
      pageNo: pageNo ?? this.pageNo,
      rects: rects ?? this.rects,
      quoteText: quoteText ?? this.quoteText,
      prefixText: prefixText ?? this.prefixText,
      suffixText: suffixText ?? this.suffixText,
      documentChecksum: documentChecksum ?? this.documentChecksum,
      videoTimeMs: videoTimeMs ?? this.videoTimeMs,
      isOrphan: isOrphan ?? this.isOrphan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (pageNo.present) {
      map['page_no'] = Variable<int>(pageNo.value);
    }
    if (rects.present) {
      map['rects'] = Variable<String>(rects.value);
    }
    if (quoteText.present) {
      map['quote_text'] = Variable<String>(quoteText.value);
    }
    if (prefixText.present) {
      map['prefix_text'] = Variable<String>(prefixText.value);
    }
    if (suffixText.present) {
      map['suffix_text'] = Variable<String>(suffixText.value);
    }
    if (documentChecksum.present) {
      map['document_checksum'] = Variable<String>(documentChecksum.value);
    }
    if (videoTimeMs.present) {
      map['video_time_ms'] = Variable<int>(videoTimeMs.value);
    }
    if (isOrphan.present) {
      map['is_orphan'] = Variable<bool>(isOrphan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnchorsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('pageNo: $pageNo, ')
          ..write('rects: $rects, ')
          ..write('quoteText: $quoteText, ')
          ..write('prefixText: $prefixText, ')
          ..write('suffixText: $suffixText, ')
          ..write('documentChecksum: $documentChecksum, ')
          ..write('videoTimeMs: $videoTimeMs, ')
          ..write('isOrphan: $isOrphan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CapturesTable extends Captures with TableInfo<$CapturesTable, Capture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _anchorIdMeta = const VerificationMeta(
    'anchorId',
  );
  @override
  late final GeneratedColumn<int> anchorId = GeneratedColumn<int>(
    'anchor_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anchors (id)',
    ),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dpiMeta = const VerificationMeta('dpi');
  @override
  late final GeneratedColumn<int> dpi = GeneratedColumn<int>(
    'dpi',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(300),
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    bookId,
    anchorId,
    imagePath,
    dpi,
    ocrText,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<Capture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('anchor_id')) {
      context.handle(
        _anchorIdMeta,
        anchorId.isAcceptableOrUnknown(data['anchor_id']!, _anchorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('dpi')) {
      context.handle(
        _dpiMeta,
        dpi.isAcceptableOrUnknown(data['dpi']!, _dpiMeta),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  Capture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Capture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      anchorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      dpi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dpi'],
      )!,
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CapturesTable createAlias(String alias) {
    return $CapturesTable(attachedDatabase, alias);
  }
}

class Capture extends DataClass implements Insertable<Capture> {
  final int id;
  final String uuid;
  final int bookId;
  final int anchorId;
  final String? imagePath;

  /// 캡처 해상도 (150/300/600)
  final int dpi;

  /// 영역 OCR 결과 (서버 처리)
  final String? ocrText;
  final String? note;
  final String createdAt;
  const Capture({
    required this.id,
    required this.uuid,
    required this.bookId,
    required this.anchorId,
    this.imagePath,
    required this.dpi,
    this.ocrText,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['book_id'] = Variable<int>(bookId);
    map['anchor_id'] = Variable<int>(anchorId);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['dpi'] = Variable<int>(dpi);
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  CapturesCompanion toCompanion(bool nullToAbsent) {
    return CapturesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      bookId: Value(bookId),
      anchorId: Value(anchorId),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      dpi: Value(dpi),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Capture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Capture(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      bookId: serializer.fromJson<int>(json['bookId']),
      anchorId: serializer.fromJson<int>(json['anchorId']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      dpi: serializer.fromJson<int>(json['dpi']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'bookId': serializer.toJson<int>(bookId),
      'anchorId': serializer.toJson<int>(anchorId),
      'imagePath': serializer.toJson<String?>(imagePath),
      'dpi': serializer.toJson<int>(dpi),
      'ocrText': serializer.toJson<String?>(ocrText),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Capture copyWith({
    int? id,
    String? uuid,
    int? bookId,
    int? anchorId,
    Value<String?> imagePath = const Value.absent(),
    int? dpi,
    Value<String?> ocrText = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => Capture(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    bookId: bookId ?? this.bookId,
    anchorId: anchorId ?? this.anchorId,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    dpi: dpi ?? this.dpi,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Capture copyWithCompanion(CapturesCompanion data) {
    return Capture(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      anchorId: data.anchorId.present ? data.anchorId.value : this.anchorId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      dpi: data.dpi.present ? data.dpi.value : this.dpi,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Capture(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('anchorId: $anchorId, ')
          ..write('imagePath: $imagePath, ')
          ..write('dpi: $dpi, ')
          ..write('ocrText: $ocrText, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    bookId,
    anchorId,
    imagePath,
    dpi,
    ocrText,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Capture &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.bookId == this.bookId &&
          other.anchorId == this.anchorId &&
          other.imagePath == this.imagePath &&
          other.dpi == this.dpi &&
          other.ocrText == this.ocrText &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class CapturesCompanion extends UpdateCompanion<Capture> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> bookId;
  final Value<int> anchorId;
  final Value<String?> imagePath;
  final Value<int> dpi;
  final Value<String?> ocrText;
  final Value<String?> note;
  final Value<String> createdAt;
  const CapturesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.bookId = const Value.absent(),
    this.anchorId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.dpi = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CapturesCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int bookId,
    required int anchorId,
    this.imagePath = const Value.absent(),
    this.dpi = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
  }) : uuid = Value(uuid),
       bookId = Value(bookId),
       anchorId = Value(anchorId),
       createdAt = Value(createdAt);
  static Insertable<Capture> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? bookId,
    Expression<int>? anchorId,
    Expression<String>? imagePath,
    Expression<int>? dpi,
    Expression<String>? ocrText,
    Expression<String>? note,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (bookId != null) 'book_id': bookId,
      if (anchorId != null) 'anchor_id': anchorId,
      if (imagePath != null) 'image_path': imagePath,
      if (dpi != null) 'dpi': dpi,
      if (ocrText != null) 'ocr_text': ocrText,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CapturesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? bookId,
    Value<int>? anchorId,
    Value<String?>? imagePath,
    Value<int>? dpi,
    Value<String?>? ocrText,
    Value<String?>? note,
    Value<String>? createdAt,
  }) {
    return CapturesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      anchorId: anchorId ?? this.anchorId,
      imagePath: imagePath ?? this.imagePath,
      dpi: dpi ?? this.dpi,
      ocrText: ocrText ?? this.ocrText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (anchorId.present) {
      map['anchor_id'] = Variable<int>(anchorId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (dpi.present) {
      map['dpi'] = Variable<int>(dpi.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('anchorId: $anchorId, ')
          ..write('imagePath: $imagePath, ')
          ..write('dpi: $dpi, ')
          ..write('ocrText: $ocrText, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _pageNoMeta = const VerificationMeta('pageNo');
  @override
  late final GeneratedColumn<int> pageNo = GeneratedColumn<int>(
    'page_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    bookId,
    pageNo,
    label,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page_no')) {
      context.handle(
        _pageNoMeta,
        pageNo.isAcceptableOrUnknown(data['page_no']!, _pageNoMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNoMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      pageNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_no'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final String uuid;
  final int bookId;
  final int pageNo;
  final String? label;
  final String createdAt;
  final String? deletedAt;
  const Bookmark({
    required this.id,
    required this.uuid,
    required this.bookId,
    required this.pageNo,
    this.label,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['book_id'] = Variable<int>(bookId);
    map['page_no'] = Variable<int>(pageNo);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      uuid: Value(uuid),
      bookId: Value(bookId),
      pageNo: Value(pageNo),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      bookId: serializer.fromJson<int>(json['bookId']),
      pageNo: serializer.fromJson<int>(json['pageNo']),
      label: serializer.fromJson<String?>(json['label']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'bookId': serializer.toJson<int>(bookId),
      'pageNo': serializer.toJson<int>(pageNo),
      'label': serializer.toJson<String?>(label),
      'createdAt': serializer.toJson<String>(createdAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Bookmark copyWith({
    int? id,
    String? uuid,
    int? bookId,
    int? pageNo,
    Value<String?> label = const Value.absent(),
    String? createdAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    bookId: bookId ?? this.bookId,
    pageNo: pageNo ?? this.pageNo,
    label: label.present ? label.value : this.label,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageNo: data.pageNo.present ? data.pageNo.value : this.pageNo,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('pageNo: $pageNo, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uuid, bookId, pageNo, label, createdAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.bookId == this.bookId &&
          other.pageNo == this.pageNo &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> bookId;
  final Value<int> pageNo;
  final Value<String?> label;
  final Value<String> createdAt;
  final Value<String?> deletedAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String uuid,
    required int bookId,
    required int pageNo,
    this.label = const Value.absent(),
    required String createdAt,
    this.deletedAt = const Value.absent(),
  }) : uuid = Value(uuid),
       bookId = Value(bookId),
       pageNo = Value(pageNo),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? bookId,
    Expression<int>? pageNo,
    Expression<String>? label,
    Expression<String>? createdAt,
    Expression<String>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (bookId != null) 'book_id': bookId,
      if (pageNo != null) 'page_no': pageNo,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? bookId,
    Value<int>? pageNo,
    Value<String?>? label,
    Value<String>? createdAt,
    Value<String?>? deletedAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookId: bookId ?? this.bookId,
      pageNo: pageNo ?? this.pageNo,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (pageNo.present) {
      map['page_no'] = Variable<int>(pageNo.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('bookId: $bookId, ')
          ..write('pageNo: $pageNo, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $PageTextsTable extends PageTexts
    with TableInfo<$PageTextsTable, PageTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PageTextsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id)',
    ),
  );
  static const VerificationMeta _pageNoMeta = const VerificationMeta('pageNo');
  @override
  late final GeneratedColumn<int> pageNo = GeneratedColumn<int>(
    'page_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
    'raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normMeta = const VerificationMeta('norm');
  @override
  late final GeneratedColumn<String> norm = GeneratedColumn<String>(
    'norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nospaceMeta = const VerificationMeta(
    'nospace',
  );
  @override
  late final GeneratedColumn<String> nospace = GeneratedColumn<String>(
    'nospace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bigramMeta = const VerificationMeta('bigram');
  @override
  late final GeneratedColumn<String> bigram = GeneratedColumn<String>(
    'bigram',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    pageNo,
    raw,
    norm,
    nospace,
    bigram,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'page_texts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PageTextRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page_no')) {
      context.handle(
        _pageNoMeta,
        pageNo.isAcceptableOrUnknown(data['page_no']!, _pageNoMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNoMeta);
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMeta);
    }
    if (data.containsKey('norm')) {
      context.handle(
        _normMeta,
        norm.isAcceptableOrUnknown(data['norm']!, _normMeta),
      );
    } else if (isInserting) {
      context.missing(_normMeta);
    }
    if (data.containsKey('nospace')) {
      context.handle(
        _nospaceMeta,
        nospace.isAcceptableOrUnknown(data['nospace']!, _nospaceMeta),
      );
    } else if (isInserting) {
      context.missing(_nospaceMeta);
    }
    if (data.containsKey('bigram')) {
      context.handle(
        _bigramMeta,
        bigram.isAcceptableOrUnknown(data['bigram']!, _bigramMeta),
      );
    } else if (isInserting) {
      context.missing(_bigramMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookId, pageNo},
  ];
  @override
  PageTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PageTextRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      pageNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_no'],
      )!,
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw'],
      )!,
      norm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}norm'],
      )!,
      nospace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nospace'],
      )!,
      bigram: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bigram'],
      )!,
    );
  }

  @override
  $PageTextsTable createAlias(String alias) {
    return $PageTextsTable(attachedDatabase, alias);
  }
}

class PageTextRow extends DataClass implements Insertable<PageTextRow> {
  final int id;
  final int bookId;
  final int pageNo;

  /// 원문 — 스니펫을 사람이 읽을 수 있게 보여주려면 필요하다
  final String raw;

  /// NFC + NFKC 정규화본
  final String norm;

  /// 공백 제거 사본 — 한글 PDF 는 어절 공백이 실제 space 가 아닌 경우가 흔하다
  final String nospace;

  /// bigram 그림자 텍스트 — 이 필드를 unicode61 FTS5 에 넣는다
  final String bigram;
  const PageTextRow({
    required this.id,
    required this.bookId,
    required this.pageNo,
    required this.raw,
    required this.norm,
    required this.nospace,
    required this.bigram,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['page_no'] = Variable<int>(pageNo);
    map['raw'] = Variable<String>(raw);
    map['norm'] = Variable<String>(norm);
    map['nospace'] = Variable<String>(nospace);
    map['bigram'] = Variable<String>(bigram);
    return map;
  }

  PageTextsCompanion toCompanion(bool nullToAbsent) {
    return PageTextsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      pageNo: Value(pageNo),
      raw: Value(raw),
      norm: Value(norm),
      nospace: Value(nospace),
      bigram: Value(bigram),
    );
  }

  factory PageTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PageTextRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      pageNo: serializer.fromJson<int>(json['pageNo']),
      raw: serializer.fromJson<String>(json['raw']),
      norm: serializer.fromJson<String>(json['norm']),
      nospace: serializer.fromJson<String>(json['nospace']),
      bigram: serializer.fromJson<String>(json['bigram']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'pageNo': serializer.toJson<int>(pageNo),
      'raw': serializer.toJson<String>(raw),
      'norm': serializer.toJson<String>(norm),
      'nospace': serializer.toJson<String>(nospace),
      'bigram': serializer.toJson<String>(bigram),
    };
  }

  PageTextRow copyWith({
    int? id,
    int? bookId,
    int? pageNo,
    String? raw,
    String? norm,
    String? nospace,
    String? bigram,
  }) => PageTextRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    pageNo: pageNo ?? this.pageNo,
    raw: raw ?? this.raw,
    norm: norm ?? this.norm,
    nospace: nospace ?? this.nospace,
    bigram: bigram ?? this.bigram,
  );
  PageTextRow copyWithCompanion(PageTextsCompanion data) {
    return PageTextRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageNo: data.pageNo.present ? data.pageNo.value : this.pageNo,
      raw: data.raw.present ? data.raw.value : this.raw,
      norm: data.norm.present ? data.norm.value : this.norm,
      nospace: data.nospace.present ? data.nospace.value : this.nospace,
      bigram: data.bigram.present ? data.bigram.value : this.bigram,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PageTextRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageNo: $pageNo, ')
          ..write('raw: $raw, ')
          ..write('norm: $norm, ')
          ..write('nospace: $nospace, ')
          ..write('bigram: $bigram')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, pageNo, raw, norm, nospace, bigram);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageTextRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.pageNo == this.pageNo &&
          other.raw == this.raw &&
          other.norm == this.norm &&
          other.nospace == this.nospace &&
          other.bigram == this.bigram);
}

class PageTextsCompanion extends UpdateCompanion<PageTextRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int> pageNo;
  final Value<String> raw;
  final Value<String> norm;
  final Value<String> nospace;
  final Value<String> bigram;
  const PageTextsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.raw = const Value.absent(),
    this.norm = const Value.absent(),
    this.nospace = const Value.absent(),
    this.bigram = const Value.absent(),
  });
  PageTextsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required int pageNo,
    required String raw,
    required String norm,
    required String nospace,
    required String bigram,
  }) : bookId = Value(bookId),
       pageNo = Value(pageNo),
       raw = Value(raw),
       norm = Value(norm),
       nospace = Value(nospace),
       bigram = Value(bigram);
  static Insertable<PageTextRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? pageNo,
    Expression<String>? raw,
    Expression<String>? norm,
    Expression<String>? nospace,
    Expression<String>? bigram,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (pageNo != null) 'page_no': pageNo,
      if (raw != null) 'raw': raw,
      if (norm != null) 'norm': norm,
      if (nospace != null) 'nospace': nospace,
      if (bigram != null) 'bigram': bigram,
    });
  }

  PageTextsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int>? pageNo,
    Value<String>? raw,
    Value<String>? norm,
    Value<String>? nospace,
    Value<String>? bigram,
  }) {
    return PageTextsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNo: pageNo ?? this.pageNo,
      raw: raw ?? this.raw,
      norm: norm ?? this.norm,
      nospace: nospace ?? this.nospace,
      bigram: bigram ?? this.bigram,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (pageNo.present) {
      map['page_no'] = Variable<int>(pageNo.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (norm.present) {
      map['norm'] = Variable<String>(norm.value);
    }
    if (nospace.present) {
      map['nospace'] = Variable<String>(nospace.value);
    }
    if (bigram.present) {
      map['bigram'] = Variable<String>(bigram.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PageTextsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageNo: $pageNo, ')
          ..write('raw: $raw, ')
          ..write('norm: $norm, ')
          ..write('nospace: $nospace, ')
          ..write('bigram: $bigram')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
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
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
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
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
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

  AppMetaData copyWith({String? key, String? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
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
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
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

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
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
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $BookSettingsTable bookSettings = $BookSettingsTable(this);
  late final $AnchorsTable anchors = $AnchorsTable(this);
  late final $CapturesTable captures = $CapturesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $PageTextsTable pageTexts = $PageTextsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    readingProgress,
    bookSettings,
    anchors,
    captures,
    bookmarks,
    pageTexts,
    appMeta,
  ];
}

typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      required String uuid,
      required String filePath,
      required String fileChecksum,
      Value<int> fileSize,
      Value<String?> title,
      Value<String?> author,
      Value<String?> publisher,
      Value<String?> publishedDate,
      Value<String> language,
      Value<int> pageCount,
      Value<String?> coverPath,
      Value<bool> hasTextLayer,
      Value<bool> hasSourceAnnots,
      Value<bool> isOcrDone,
      Value<bool> isIndexed,
      Value<String> sourceType,
      required String addedAt,
      required String updatedAt,
      Value<String?> deletedAt,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<String> filePath,
      Value<String> fileChecksum,
      Value<int> fileSize,
      Value<String?> title,
      Value<String?> author,
      Value<String?> publisher,
      Value<String?> publishedDate,
      Value<String> language,
      Value<int> pageCount,
      Value<String?> coverPath,
      Value<bool> hasTextLayer,
      Value<bool> hasSourceAnnots,
      Value<bool> isOcrDone,
      Value<bool> isIndexed,
      Value<String> sourceType,
      Value<String> addedAt,
      Value<String> updatedAt,
      Value<String?> deletedAt,
    });

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, BookRow> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReadingProgressTable, List<ReadingProgressData>>
  _readingProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingProgress,
    aliasName: 'books__id__reading_progress__book_id',
  );

  $$ReadingProgressTableProcessedTableManager get readingProgressRefs {
    final manager = $$ReadingProgressTableTableManager(
      $_db,
      $_db.readingProgress,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookSettingsTable, List<BookSetting>>
  _bookSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookSettings,
    aliasName: 'books__id__book_settings__book_id',
  );

  $$BookSettingsTableProcessedTableManager get bookSettingsRefs {
    final manager = $$BookSettingsTableTableManager(
      $_db,
      $_db.bookSettings,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnchorsTable, List<Anchor>> _anchorsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.anchors,
    aliasName: 'books__id__anchors__book_id',
  );

  $$AnchorsTableProcessedTableManager get anchorsRefs {
    final manager = $$AnchorsTableTableManager(
      $_db,
      $_db.anchors,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_anchorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CapturesTable, List<Capture>> _capturesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.captures,
    aliasName: 'books__id__captures__book_id',
  );

  $$CapturesTableProcessedTableManager get capturesRefs {
    final manager = $$CapturesTableTableManager(
      $_db,
      $_db.captures,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_capturesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'books__id__bookmarks__book_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PageTextsTable, List<PageTextRow>>
  _pageTextsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pageTexts,
    aliasName: 'books__id__page_texts__book_id',
  );

  $$PageTextsTableProcessedTableManager get pageTextsRefs {
    final manager = $$PageTextsTableTableManager(
      $_db,
      $_db.pageTexts,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pageTextsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileChecksum => $composableBuilder(
    column: $table.fileChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSourceAnnots => $composableBuilder(
    column: $table.hasSourceAnnots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOcrDone => $composableBuilder(
    column: $table.isOcrDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isIndexed => $composableBuilder(
    column: $table.isIndexed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingProgressRefs(
    Expression<bool> Function($$ReadingProgressTableFilterComposer f) f,
  ) {
    final $$ReadingProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableFilterComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookSettingsRefs(
    Expression<bool> Function($$BookSettingsTableFilterComposer f) f,
  ) {
    final $$BookSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookSettings,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSettingsTableFilterComposer(
            $db: $db,
            $table: $db.bookSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> anchorsRefs(
    Expression<bool> Function($$AnchorsTableFilterComposer f) f,
  ) {
    final $$AnchorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.anchors,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnchorsTableFilterComposer(
            $db: $db,
            $table: $db.anchors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> capturesRefs(
    Expression<bool> Function($$CapturesTableFilterComposer f) f,
  ) {
    final $$CapturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captures,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturesTableFilterComposer(
            $db: $db,
            $table: $db.captures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pageTextsRefs(
    Expression<bool> Function($$PageTextsTableFilterComposer f) f,
  ) {
    final $$PageTextsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageTexts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageTextsTableFilterComposer(
            $db: $db,
            $table: $db.pageTexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileChecksum => $composableBuilder(
    column: $table.fileChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSourceAnnots => $composableBuilder(
    column: $table.hasSourceAnnots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOcrDone => $composableBuilder(
    column: $table.isOcrDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isIndexed => $composableBuilder(
    column: $table.isIndexed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileChecksum => $composableBuilder(
    column: $table.fileChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasSourceAnnots => $composableBuilder(
    column: $table.hasSourceAnnots,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOcrDone =>
      $composableBuilder(column: $table.isOcrDone, builder: (column) => column);

  GeneratedColumn<bool> get isIndexed =>
      $composableBuilder(column: $table.isIndexed, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> readingProgressRefs<T extends Object>(
    Expression<T> Function($$ReadingProgressTableAnnotationComposer a) f,
  ) {
    final $$ReadingProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookSettingsRefs<T extends Object>(
    Expression<T> Function($$BookSettingsTableAnnotationComposer a) f,
  ) {
    final $$BookSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookSettings,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.bookSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> anchorsRefs<T extends Object>(
    Expression<T> Function($$AnchorsTableAnnotationComposer a) f,
  ) {
    final $$AnchorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.anchors,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnchorsTableAnnotationComposer(
            $db: $db,
            $table: $db.anchors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> capturesRefs<T extends Object>(
    Expression<T> Function($$CapturesTableAnnotationComposer a) f,
  ) {
    final $$CapturesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captures,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturesTableAnnotationComposer(
            $db: $db,
            $table: $db.captures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pageTextsRefs<T extends Object>(
    Expression<T> Function($$PageTextsTableAnnotationComposer a) f,
  ) {
    final $$PageTextsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pageTexts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PageTextsTableAnnotationComposer(
            $db: $db,
            $table: $db.pageTexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, $$BooksTableReferences),
          BookRow,
          PrefetchHooks Function({
            bool readingProgressRefs,
            bool bookSettingsRefs,
            bool anchorsRefs,
            bool capturesRefs,
            bool bookmarksRefs,
            bool pageTextsRefs,
          })
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileChecksum = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<bool> hasTextLayer = const Value.absent(),
                Value<bool> hasSourceAnnots = const Value.absent(),
                Value<bool> isOcrDone = const Value.absent(),
                Value<bool> isIndexed = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> addedAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                uuid: uuid,
                filePath: filePath,
                fileChecksum: fileChecksum,
                fileSize: fileSize,
                title: title,
                author: author,
                publisher: publisher,
                publishedDate: publishedDate,
                language: language,
                pageCount: pageCount,
                coverPath: coverPath,
                hasTextLayer: hasTextLayer,
                hasSourceAnnots: hasSourceAnnots,
                isOcrDone: isOcrDone,
                isIndexed: isIndexed,
                sourceType: sourceType,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required String filePath,
                required String fileChecksum,
                Value<int> fileSize = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<bool> hasTextLayer = const Value.absent(),
                Value<bool> hasSourceAnnots = const Value.absent(),
                Value<bool> isOcrDone = const Value.absent(),
                Value<bool> isIndexed = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                required String addedAt,
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                uuid: uuid,
                filePath: filePath,
                fileChecksum: fileChecksum,
                fileSize: fileSize,
                title: title,
                author: author,
                publisher: publisher,
                publishedDate: publishedDate,
                language: language,
                pageCount: pageCount,
                coverPath: coverPath,
                hasTextLayer: hasTextLayer,
                hasSourceAnnots: hasSourceAnnots,
                isOcrDone: isOcrDone,
                isIndexed: isIndexed,
                sourceType: sourceType,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BooksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                readingProgressRefs = false,
                bookSettingsRefs = false,
                anchorsRefs = false,
                capturesRefs = false,
                bookmarksRefs = false,
                pageTextsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (readingProgressRefs) db.readingProgress,
                    if (bookSettingsRefs) db.bookSettings,
                    if (anchorsRefs) db.anchors,
                    if (capturesRefs) db.captures,
                    if (bookmarksRefs) db.bookmarks,
                    if (pageTextsRefs) db.pageTexts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (readingProgressRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          ReadingProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._readingProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).readingProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookSettingsRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          BookSetting
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (anchorsRefs)
                        await $_getPrefetchedData<BookRow, $BooksTable, Anchor>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._anchorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(db, table, p0).anchorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (capturesRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          Capture
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._capturesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).capturesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pageTextsRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          PageTextRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._pageTextsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).pageTextsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, $$BooksTableReferences),
      BookRow,
      PrefetchHooks Function({
        bool readingProgressRefs,
        bool bookSettingsRefs,
        bool anchorsRefs,
        bool capturesRefs,
        bool bookmarksRefs,
        bool pageTextsRefs,
      })
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<int> bookId,
      Value<int> lastPage,
      Value<double> lastOffset,
      Value<int> farthestPage,
      Value<double> percent,
      Value<String> status,
      Value<String?> lastReadAt,
      Value<String?> finishedAt,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<int> bookId,
      Value<int> lastPage,
      Value<double> lastOffset,
      Value<int> farthestPage,
      Value<double> percent,
      Value<String> status,
      Value<String?> lastReadAt,
      Value<String?> finishedAt,
    });

final class $$ReadingProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressData
        > {
  $$ReadingProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('reading_progress__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get farthestPage => $composableBuilder(
    column: $table.farthestPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get farthestPage => $composableBuilder(
    column: $table.farthestPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<double> get lastOffset => $composableBuilder(
    column: $table.lastOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get farthestPage => $composableBuilder(
    column: $table.farthestPage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressData,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (ReadingProgressData, $$ReadingProgressTableReferences),
          ReadingProgressData,
          PrefetchHooks Function({bool bookId})
        > {
  $$ReadingProgressTableTableManager(
    _$AppDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> lastPage = const Value.absent(),
                Value<double> lastOffset = const Value.absent(),
                Value<int> farthestPage = const Value.absent(),
                Value<double> percent = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
              }) => ReadingProgressCompanion(
                bookId: bookId,
                lastPage: lastPage,
                lastOffset: lastOffset,
                farthestPage: farthestPage,
                percent: percent,
                status: status,
                lastReadAt: lastReadAt,
                finishedAt: finishedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> lastPage = const Value.absent(),
                Value<double> lastOffset = const Value.absent(),
                Value<int> farthestPage = const Value.absent(),
                Value<double> percent = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                bookId: bookId,
                lastPage: lastPage,
                lastOffset: lastOffset,
                farthestPage: farthestPage,
                percent: percent,
                status: status,
                lastReadAt: lastReadAt,
                finishedAt: finishedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable:
                                    $$ReadingProgressTableReferences
                                        ._bookIdTable(db),
                                referencedColumn:
                                    $$ReadingProgressTableReferences
                                        ._bookIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressTable,
      ReadingProgressData,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (ReadingProgressData, $$ReadingProgressTableReferences),
      ReadingProgressData,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$BookSettingsTableCreateCompanionBuilder =
    BookSettingsCompanion Function({
      Value<int> bookId,
      Value<String> viewMode,
      Value<String> fitMode,
      Value<double> zoomLevel,
      Value<int> rotation,
      Value<String> theme,
      Value<String> darkImageMode,
      Value<bool> cropEnabled,
      Value<String?> cropOdd,
      Value<String?> cropEven,
      Value<int> columnMode,
      Value<bool> showSourceAnnots,
      required String updatedAt,
    });
typedef $$BookSettingsTableUpdateCompanionBuilder =
    BookSettingsCompanion Function({
      Value<int> bookId,
      Value<String> viewMode,
      Value<String> fitMode,
      Value<double> zoomLevel,
      Value<int> rotation,
      Value<String> theme,
      Value<String> darkImageMode,
      Value<bool> cropEnabled,
      Value<String?> cropOdd,
      Value<String?> cropEven,
      Value<int> columnMode,
      Value<bool> showSourceAnnots,
      Value<String> updatedAt,
    });

final class $$BookSettingsTableReferences
    extends BaseReferences<_$AppDatabase, $BookSettingsTable, BookSetting> {
  $$BookSettingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('book_settings__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BookSettingsTable> {
  $$BookSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get viewMode => $composableBuilder(
    column: $table.viewMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitMode => $composableBuilder(
    column: $table.fitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zoomLevel => $composableBuilder(
    column: $table.zoomLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get darkImageMode => $composableBuilder(
    column: $table.darkImageMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cropEnabled => $composableBuilder(
    column: $table.cropEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropOdd => $composableBuilder(
    column: $table.cropOdd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropEven => $composableBuilder(
    column: $table.cropEven,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columnMode => $composableBuilder(
    column: $table.columnMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showSourceAnnots => $composableBuilder(
    column: $table.showSourceAnnots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookSettingsTable> {
  $$BookSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get viewMode => $composableBuilder(
    column: $table.viewMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitMode => $composableBuilder(
    column: $table.fitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zoomLevel => $composableBuilder(
    column: $table.zoomLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get darkImageMode => $composableBuilder(
    column: $table.darkImageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cropEnabled => $composableBuilder(
    column: $table.cropEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropOdd => $composableBuilder(
    column: $table.cropOdd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropEven => $composableBuilder(
    column: $table.cropEven,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columnMode => $composableBuilder(
    column: $table.columnMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showSourceAnnots => $composableBuilder(
    column: $table.showSourceAnnots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookSettingsTable> {
  $$BookSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get viewMode =>
      $composableBuilder(column: $table.viewMode, builder: (column) => column);

  GeneratedColumn<String> get fitMode =>
      $composableBuilder(column: $table.fitMode, builder: (column) => column);

  GeneratedColumn<double> get zoomLevel =>
      $composableBuilder(column: $table.zoomLevel, builder: (column) => column);

  GeneratedColumn<int> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get darkImageMode => $composableBuilder(
    column: $table.darkImageMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cropEnabled => $composableBuilder(
    column: $table.cropEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropOdd =>
      $composableBuilder(column: $table.cropOdd, builder: (column) => column);

  GeneratedColumn<String> get cropEven =>
      $composableBuilder(column: $table.cropEven, builder: (column) => column);

  GeneratedColumn<int> get columnMode => $composableBuilder(
    column: $table.columnMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showSourceAnnots => $composableBuilder(
    column: $table.showSourceAnnots,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookSettingsTable,
          BookSetting,
          $$BookSettingsTableFilterComposer,
          $$BookSettingsTableOrderingComposer,
          $$BookSettingsTableAnnotationComposer,
          $$BookSettingsTableCreateCompanionBuilder,
          $$BookSettingsTableUpdateCompanionBuilder,
          (BookSetting, $$BookSettingsTableReferences),
          BookSetting,
          PrefetchHooks Function({bool bookId})
        > {
  $$BookSettingsTableTableManager(_$AppDatabase db, $BookSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<String> viewMode = const Value.absent(),
                Value<String> fitMode = const Value.absent(),
                Value<double> zoomLevel = const Value.absent(),
                Value<int> rotation = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> darkImageMode = const Value.absent(),
                Value<bool> cropEnabled = const Value.absent(),
                Value<String?> cropOdd = const Value.absent(),
                Value<String?> cropEven = const Value.absent(),
                Value<int> columnMode = const Value.absent(),
                Value<bool> showSourceAnnots = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => BookSettingsCompanion(
                bookId: bookId,
                viewMode: viewMode,
                fitMode: fitMode,
                zoomLevel: zoomLevel,
                rotation: rotation,
                theme: theme,
                darkImageMode: darkImageMode,
                cropEnabled: cropEnabled,
                cropOdd: cropOdd,
                cropEven: cropEven,
                columnMode: columnMode,
                showSourceAnnots: showSourceAnnots,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<String> viewMode = const Value.absent(),
                Value<String> fitMode = const Value.absent(),
                Value<double> zoomLevel = const Value.absent(),
                Value<int> rotation = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> darkImageMode = const Value.absent(),
                Value<bool> cropEnabled = const Value.absent(),
                Value<String?> cropOdd = const Value.absent(),
                Value<String?> cropEven = const Value.absent(),
                Value<int> columnMode = const Value.absent(),
                Value<bool> showSourceAnnots = const Value.absent(),
                required String updatedAt,
              }) => BookSettingsCompanion.insert(
                bookId: bookId,
                viewMode: viewMode,
                fitMode: fitMode,
                zoomLevel: zoomLevel,
                rotation: rotation,
                theme: theme,
                darkImageMode: darkImageMode,
                cropEnabled: cropEnabled,
                cropOdd: cropOdd,
                cropEven: cropEven,
                columnMode: columnMode,
                showSourceAnnots: showSourceAnnots,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$BookSettingsTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$BookSettingsTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookSettingsTable,
      BookSetting,
      $$BookSettingsTableFilterComposer,
      $$BookSettingsTableOrderingComposer,
      $$BookSettingsTableAnnotationComposer,
      $$BookSettingsTableCreateCompanionBuilder,
      $$BookSettingsTableUpdateCompanionBuilder,
      (BookSetting, $$BookSettingsTableReferences),
      BookSetting,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$AnchorsTableCreateCompanionBuilder =
    AnchorsCompanion Function({
      Value<int> id,
      required String uuid,
      required int bookId,
      Value<String> kind,
      required int pageNo,
      required String rects,
      Value<String?> quoteText,
      Value<String?> prefixText,
      Value<String?> suffixText,
      required String documentChecksum,
      Value<int?> videoTimeMs,
      Value<bool> isOrphan,
      required String createdAt,
    });
typedef $$AnchorsTableUpdateCompanionBuilder =
    AnchorsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> bookId,
      Value<String> kind,
      Value<int> pageNo,
      Value<String> rects,
      Value<String?> quoteText,
      Value<String?> prefixText,
      Value<String?> suffixText,
      Value<String> documentChecksum,
      Value<int?> videoTimeMs,
      Value<bool> isOrphan,
      Value<String> createdAt,
    });

final class $$AnchorsTableReferences
    extends BaseReferences<_$AppDatabase, $AnchorsTable, Anchor> {
  $$AnchorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('anchors__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CapturesTable, List<Capture>> _capturesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.captures,
    aliasName: 'anchors__id__captures__anchor_id',
  );

  $$CapturesTableProcessedTableManager get capturesRefs {
    final manager = $$CapturesTableTableManager(
      $_db,
      $_db.captures,
    ).filter((f) => f.anchorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_capturesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnchorsTableFilterComposer
    extends Composer<_$AppDatabase, $AnchorsTable> {
  $$AnchorsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefixText => $composableBuilder(
    column: $table.prefixText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suffixText => $composableBuilder(
    column: $table.suffixText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentChecksum => $composableBuilder(
    column: $table.documentChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get videoTimeMs => $composableBuilder(
    column: $table.videoTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOrphan => $composableBuilder(
    column: $table.isOrphan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> capturesRefs(
    Expression<bool> Function($$CapturesTableFilterComposer f) f,
  ) {
    final $$CapturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captures,
      getReferencedColumn: (t) => t.anchorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturesTableFilterComposer(
            $db: $db,
            $table: $db.captures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnchorsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnchorsTable> {
  $$AnchorsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefixText => $composableBuilder(
    column: $table.prefixText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suffixText => $composableBuilder(
    column: $table.suffixText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentChecksum => $composableBuilder(
    column: $table.documentChecksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get videoTimeMs => $composableBuilder(
    column: $table.videoTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOrphan => $composableBuilder(
    column: $table.isOrphan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnchorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnchorsTable> {
  $$AnchorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get pageNo =>
      $composableBuilder(column: $table.pageNo, builder: (column) => column);

  GeneratedColumn<String> get rects =>
      $composableBuilder(column: $table.rects, builder: (column) => column);

  GeneratedColumn<String> get quoteText =>
      $composableBuilder(column: $table.quoteText, builder: (column) => column);

  GeneratedColumn<String> get prefixText => $composableBuilder(
    column: $table.prefixText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suffixText => $composableBuilder(
    column: $table.suffixText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentChecksum => $composableBuilder(
    column: $table.documentChecksum,
    builder: (column) => column,
  );

  GeneratedColumn<int> get videoTimeMs => $composableBuilder(
    column: $table.videoTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOrphan =>
      $composableBuilder(column: $table.isOrphan, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> capturesRefs<T extends Object>(
    Expression<T> Function($$CapturesTableAnnotationComposer a) f,
  ) {
    final $$CapturesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captures,
      getReferencedColumn: (t) => t.anchorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CapturesTableAnnotationComposer(
            $db: $db,
            $table: $db.captures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnchorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnchorsTable,
          Anchor,
          $$AnchorsTableFilterComposer,
          $$AnchorsTableOrderingComposer,
          $$AnchorsTableAnnotationComposer,
          $$AnchorsTableCreateCompanionBuilder,
          $$AnchorsTableUpdateCompanionBuilder,
          (Anchor, $$AnchorsTableReferences),
          Anchor,
          PrefetchHooks Function({bool bookId, bool capturesRefs})
        > {
  $$AnchorsTableTableManager(_$AppDatabase db, $AnchorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnchorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnchorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnchorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String> rects = const Value.absent(),
                Value<String?> quoteText = const Value.absent(),
                Value<String?> prefixText = const Value.absent(),
                Value<String?> suffixText = const Value.absent(),
                Value<String> documentChecksum = const Value.absent(),
                Value<int?> videoTimeMs = const Value.absent(),
                Value<bool> isOrphan = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => AnchorsCompanion(
                id: id,
                uuid: uuid,
                bookId: bookId,
                kind: kind,
                pageNo: pageNo,
                rects: rects,
                quoteText: quoteText,
                prefixText: prefixText,
                suffixText: suffixText,
                documentChecksum: documentChecksum,
                videoTimeMs: videoTimeMs,
                isOrphan: isOrphan,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int bookId,
                Value<String> kind = const Value.absent(),
                required int pageNo,
                required String rects,
                Value<String?> quoteText = const Value.absent(),
                Value<String?> prefixText = const Value.absent(),
                Value<String?> suffixText = const Value.absent(),
                required String documentChecksum,
                Value<int?> videoTimeMs = const Value.absent(),
                Value<bool> isOrphan = const Value.absent(),
                required String createdAt,
              }) => AnchorsCompanion.insert(
                id: id,
                uuid: uuid,
                bookId: bookId,
                kind: kind,
                pageNo: pageNo,
                rects: rects,
                quoteText: quoteText,
                prefixText: prefixText,
                suffixText: suffixText,
                documentChecksum: documentChecksum,
                videoTimeMs: videoTimeMs,
                isOrphan: isOrphan,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnchorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, capturesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (capturesRefs) db.captures],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$AnchorsTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$AnchorsTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (capturesRefs)
                    await $_getPrefetchedData<Anchor, $AnchorsTable, Capture>(
                      currentTable: table,
                      referencedTable: $$AnchorsTableReferences
                          ._capturesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AnchorsTableReferences(db, table, p0).capturesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.anchorId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AnchorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnchorsTable,
      Anchor,
      $$AnchorsTableFilterComposer,
      $$AnchorsTableOrderingComposer,
      $$AnchorsTableAnnotationComposer,
      $$AnchorsTableCreateCompanionBuilder,
      $$AnchorsTableUpdateCompanionBuilder,
      (Anchor, $$AnchorsTableReferences),
      Anchor,
      PrefetchHooks Function({bool bookId, bool capturesRefs})
    >;
typedef $$CapturesTableCreateCompanionBuilder =
    CapturesCompanion Function({
      Value<int> id,
      required String uuid,
      required int bookId,
      required int anchorId,
      Value<String?> imagePath,
      Value<int> dpi,
      Value<String?> ocrText,
      Value<String?> note,
      required String createdAt,
    });
typedef $$CapturesTableUpdateCompanionBuilder =
    CapturesCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> bookId,
      Value<int> anchorId,
      Value<String?> imagePath,
      Value<int> dpi,
      Value<String?> ocrText,
      Value<String?> note,
      Value<String> createdAt,
    });

final class $$CapturesTableReferences
    extends BaseReferences<_$AppDatabase, $CapturesTable, Capture> {
  $$CapturesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('captures__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnchorsTable _anchorIdTable(_$AppDatabase db) =>
      db.anchors.createAlias('captures__anchor_id__anchors__id');

  $$AnchorsTableProcessedTableManager get anchorId {
    final $_column = $_itemColumn<int>('anchor_id')!;

    final manager = $$AnchorsTableTableManager(
      $_db,
      $_db.anchors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_anchorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CapturesTableFilterComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dpi => $composableBuilder(
    column: $table.dpi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnchorsTableFilterComposer get anchorId {
    final $$AnchorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.anchorId,
      referencedTable: $db.anchors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnchorsTableFilterComposer(
            $db: $db,
            $table: $db.anchors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dpi => $composableBuilder(
    column: $table.dpi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnchorsTableOrderingComposer get anchorId {
    final $$AnchorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.anchorId,
      referencedTable: $db.anchors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnchorsTableOrderingComposer(
            $db: $db,
            $table: $db.anchors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get dpi =>
      $composableBuilder(column: $table.dpi, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnchorsTableAnnotationComposer get anchorId {
    final $$AnchorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.anchorId,
      referencedTable: $db.anchors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnchorsTableAnnotationComposer(
            $db: $db,
            $table: $db.anchors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapturesTable,
          Capture,
          $$CapturesTableFilterComposer,
          $$CapturesTableOrderingComposer,
          $$CapturesTableAnnotationComposer,
          $$CapturesTableCreateCompanionBuilder,
          $$CapturesTableUpdateCompanionBuilder,
          (Capture, $$CapturesTableReferences),
          Capture,
          PrefetchHooks Function({bool bookId, bool anchorId})
        > {
  $$CapturesTableTableManager(_$AppDatabase db, $CapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> anchorId = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> dpi = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => CapturesCompanion(
                id: id,
                uuid: uuid,
                bookId: bookId,
                anchorId: anchorId,
                imagePath: imagePath,
                dpi: dpi,
                ocrText: ocrText,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int bookId,
                required int anchorId,
                Value<String?> imagePath = const Value.absent(),
                Value<int> dpi = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
              }) => CapturesCompanion.insert(
                id: id,
                uuid: uuid,
                bookId: bookId,
                anchorId: anchorId,
                imagePath: imagePath,
                dpi: dpi,
                ocrText: ocrText,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CapturesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, anchorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$CapturesTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$CapturesTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (anchorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.anchorId,
                                referencedTable: $$CapturesTableReferences
                                    ._anchorIdTable(db),
                                referencedColumn: $$CapturesTableReferences
                                    ._anchorIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapturesTable,
      Capture,
      $$CapturesTableFilterComposer,
      $$CapturesTableOrderingComposer,
      $$CapturesTableAnnotationComposer,
      $$CapturesTableCreateCompanionBuilder,
      $$CapturesTableUpdateCompanionBuilder,
      (Capture, $$CapturesTableReferences),
      Capture,
      PrefetchHooks Function({bool bookId, bool anchorId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required String uuid,
      required int bookId,
      required int pageNo,
      Value<String?> label,
      required String createdAt,
      Value<String?> deletedAt,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> bookId,
      Value<int> pageNo,
      Value<String?> label,
      Value<String> createdAt,
      Value<String?> deletedAt,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('bookmarks__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get pageNo =>
      $composableBuilder(column: $table.pageNo, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool bookId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                uuid: uuid,
                bookId: bookId,
                pageNo: pageNo,
                label: label,
                createdAt: createdAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String uuid,
                required int bookId,
                required int pageNo,
                Value<String?> label = const Value.absent(),
                required String createdAt,
                Value<String?> deletedAt = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                uuid: uuid,
                bookId: bookId,
                pageNo: pageNo,
                label: label,
                createdAt: createdAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$BookmarksTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$PageTextsTableCreateCompanionBuilder =
    PageTextsCompanion Function({
      Value<int> id,
      required int bookId,
      required int pageNo,
      required String raw,
      required String norm,
      required String nospace,
      required String bigram,
    });
typedef $$PageTextsTableUpdateCompanionBuilder =
    PageTextsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<int> pageNo,
      Value<String> raw,
      Value<String> norm,
      Value<String> nospace,
      Value<String> bigram,
    });

final class $$PageTextsTableReferences
    extends BaseReferences<_$AppDatabase, $PageTextsTable, PageTextRow> {
  $$PageTextsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('page_texts__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PageTextsTableFilterComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableFilterComposer({
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

  ColumnFilters<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get norm => $composableBuilder(
    column: $table.norm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nospace => $composableBuilder(
    column: $table.nospace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bigram => $composableBuilder(
    column: $table.bigram,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageTextsTableOrderingComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableOrderingComposer({
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

  ColumnOrderings<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get norm => $composableBuilder(
    column: $table.norm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nospace => $composableBuilder(
    column: $table.nospace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bigram => $composableBuilder(
    column: $table.bigram,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageTextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PageTextsTable> {
  $$PageTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageNo =>
      $composableBuilder(column: $table.pageNo, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<String> get norm =>
      $composableBuilder(column: $table.norm, builder: (column) => column);

  GeneratedColumn<String> get nospace =>
      $composableBuilder(column: $table.nospace, builder: (column) => column);

  GeneratedColumn<String> get bigram =>
      $composableBuilder(column: $table.bigram, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PageTextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PageTextsTable,
          PageTextRow,
          $$PageTextsTableFilterComposer,
          $$PageTextsTableOrderingComposer,
          $$PageTextsTableAnnotationComposer,
          $$PageTextsTableCreateCompanionBuilder,
          $$PageTextsTableUpdateCompanionBuilder,
          (PageTextRow, $$PageTextsTableReferences),
          PageTextRow,
          PrefetchHooks Function({bool bookId})
        > {
  $$PageTextsTableTableManager(_$AppDatabase db, $PageTextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PageTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PageTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PageTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String> raw = const Value.absent(),
                Value<String> norm = const Value.absent(),
                Value<String> nospace = const Value.absent(),
                Value<String> bigram = const Value.absent(),
              }) => PageTextsCompanion(
                id: id,
                bookId: bookId,
                pageNo: pageNo,
                raw: raw,
                norm: norm,
                nospace: nospace,
                bigram: bigram,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required int pageNo,
                required String raw,
                required String norm,
                required String nospace,
                required String bigram,
              }) => PageTextsCompanion.insert(
                id: id,
                bookId: bookId,
                pageNo: pageNo,
                raw: raw,
                norm: norm,
                nospace: nospace,
                bigram: bigram,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PageTextsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$PageTextsTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$PageTextsTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PageTextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PageTextsTable,
      PageTextRow,
      $$PageTextsTableFilterComposer,
      $$PageTextsTableOrderingComposer,
      $$PageTextsTableAnnotationComposer,
      $$PageTextsTableCreateCompanionBuilder,
      $$PageTextsTableUpdateCompanionBuilder,
      (PageTextRow, $$PageTextsTableReferences),
      PageTextRow,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
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

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
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

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
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

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$BookSettingsTableTableManager get bookSettings =>
      $$BookSettingsTableTableManager(_db, _db.bookSettings);
  $$AnchorsTableTableManager get anchors =>
      $$AnchorsTableTableManager(_db, _db.anchors);
  $$CapturesTableTableManager get captures =>
      $$CapturesTableTableManager(_db, _db.captures);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$PageTextsTableTableManager get pageTexts =>
      $$PageTextsTableTableManager(_db, _db.pageTexts);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
