import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 용어 (glossary_v2.enriched.json → import)
class Terms extends Table {
  TextColumn get id => text()(); // termId — 숙련도 저장 키 (TECHSPEC §13.1)
  TextColumn get termKo => text()();
  TextColumn get termEn => text()();
  TextColumn get def => text()();
  TextColumn get whyItMatters => text().withDefault(const Constant(''))();
  TextColumn get example => text().withDefault(const Constant(''))();
  TextColumn get category => text()(); // 표준 11개 도메인
  TextColumn get subcategory => text().withDefault(const Constant(''))();
  TextColumn get tracksJson => text().withDefault(const Constant('[]'))(); // 학습 트랙 A~E
  TextColumn get aliasesJson => text().withDefault(const Constant('[]'))();
  TextColumn get confusionJson => text().withDefault(const Constant('[]'))();
  IntColumn get difficulty => integer().withDefault(const Constant(2))(); // 1~4
  BoolColumn get vibeCore => boolean().withDefault(const Constant(false))();
  BoolColumn get volatileInfo => boolean().withDefault(const Constant(false))();
  BoolColumn get quizEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get retired => boolean().withDefault(const Constant(false))(); // 삭제 대신 은퇴 (§15.3)
  TextColumn get slug => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 용어별 사용자 숙련도 (§9.1~9.3, §13.3)
class TermStates extends Table {
  TextColumn get termId => text()();
  TextColumn get state => text().withDefault(const Constant('NEW'))(); // NEW/LEARNING/REVIEWING/MASTERED/LAPSED
  IntColumn get masteryScore => integer().withDefault(const Constant(0))(); // 0~100
  IntColumn get correctStreak => integer().withDefault(const Constant(0))();
  IntColumn get lapseCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  IntColumn get lastConfidence => integer().nullable()(); // 1낮음 2보통 3높음
  TextColumn get wrongReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {termId};
}

/// 학습 세션 기록 (§13.4)
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get mode => text()(); // DAILY_MISSION / QUICK_REVIEW / ...
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get newTerms => integer().withDefault(const Constant(0))();
  IntColumn get reviewTerms => integer().withDefault(const Constant(0))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  IntColumn get gemsEarned => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 키-값 메타 (contentVersion, 사용자 설정 등)
class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Terms, TermStates, Sessions, Meta])
class VqDatabase extends _$VqDatabase {
  VqDatabase() : super(_open());
  VqDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'vibequest',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ── 메타 ──
  Future<String?> getMeta(String k) async {
    final row = await (select(meta)..where((m) => m.key.equals(k))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String k, String v) =>
      into(meta).insertOnConflictUpdate(MetaCompanion.insert(key: k, value: v));

  // ── 용어 조회 ──
  Future<int> termCount() async {
    final c = terms.id.count();
    final q = selectOnly(terms)..addColumns([c])..where(terms.retired.equals(false));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  /// 만기 복습 개수 (nextReviewAt <= now)
  Future<int> dueReviewCount(DateTime now) async {
    final c = termStates.termId.count();
    final q = selectOnly(termStates)
      ..addColumns([c])
      ..where(termStates.nextReviewAt.isSmallerOrEqualValue(now));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  /// 도감 검색 — 한국어·영문·별칭 (FR-GLOSSARY-001)
  Future<List<Term>> searchTerms(String query, {int limit = 100}) {
    final q = select(terms)..where((t) => t.retired.equals(false));
    final s = query.trim();
    if (s.isNotEmpty) {
      final like = '%$s%';
      q.where((t) =>
          t.termKo.like(like) | t.termEn.like(like) | t.aliasesJson.like(like) | t.slug.like(like));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.termKo)]);
    q.limit(limit);
    return q.get();
  }

  Future<TermState?> stateOf(String termId) =>
      (select(termStates)..where((s) => s.termId.equals(termId))).getSingleOrNull();

  Future<void> upsertState(TermStatesCompanion c) => into(termStates).insertOnConflictUpdate(c);

  // ── 세션 구성용 (§5.1) ──

  /// 만기 복습 용어 — nextReviewAt 이 빠른 순
  Future<List<Term>> dueTerms(DateTime now, {int limit = 10}) async {
    final q = select(terms).join([
      innerJoin(termStates, termStates.termId.equalsExp(terms.id)),
    ])
      ..where(termStates.nextReviewAt.isSmallerOrEqualValue(now) &
          terms.retired.equals(false) &
          terms.quizEnabled.equals(true))
      ..orderBy([OrderingTerm.asc(termStates.nextReviewAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map((r) => r.readTable(terms)).toList();
  }

  /// 아직 만나지 않은 새 용어 — vibeCore·쉬운 난이도 우선 (§7.3 취지)
  Future<List<Term>> freshTerms({int limit = 10}) async {
    final sub = selectOnly(termStates)..addColumns([termStates.termId]);
    final q = select(terms)
      ..where((t) =>
          t.retired.equals(false) & t.quizEnabled.equals(true) & t.id.isNotInQuery(sub))
      ..orderBy([
        (t) => OrderingTerm.desc(t.vibeCore),
        (t) => OrderingTerm.asc(t.difficulty),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(limit);
    return q.get();
  }

  /// 문제 오답 풀 — 전체 활성 용어 (867개, 로컬이라 부담 없음)
  Future<List<Term>> activeTerms() =>
      (select(terms)..where((t) => t.retired.equals(false))).get();

  // ── 보석·XP 누계 (Meta) ──
  Future<int> metaInt(String k) async => int.tryParse(await getMeta(k) ?? '') ?? 0;

  Future<void> addMetaInt(String k, int delta) async {
    final cur = await metaInt(k);
    await setMeta(k, '${cur + delta}');
  }
}
