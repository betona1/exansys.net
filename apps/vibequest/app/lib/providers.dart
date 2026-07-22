import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/content_importer.dart';
import 'db/database.dart';
import 'sfx.dart';

final databaseProvider = Provider<VqDatabase>((ref) {
  final db = VqDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 앱 시작 시 콘텐츠 import (1회). 완료 후 true.
/// 원격 업데이트는 백그라운드로 확인 — 홈 표시를 막지 않는다 (FR-HOME-001).
final FutureProvider<bool> contentReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final importer = ContentImporter(db);
  await importer.importIfNeeded();
  Sfx.muted = (await db.getMeta('muted')) == '1'; // 소리 설정 복원 (UX-06)
  // 관리자가 웹에서 고친 용어 받아오기 (신고 → 수정 → 자동 반영)
  Future(() async {
    if (await importer.checkRemoteUpdate()) {
      ref.invalidate(glossaryResultsProvider);
      ref.invalidate(homeStatsProvider);
    }
  });
  return true;
});

/// 소리 켬/끔 (내 기록 > 설정)
final soundMutedProvider = StateProvider<bool>((ref) => Sfx.muted);

/// 홈 대시보드 수치
class HomeStats {
  final int totalTerms;
  final int dueReviews;
  final int learnedTerms;
  final int gems;
  final int xp;
  const HomeStats({
    required this.totalTerms,
    required this.dueReviews,
    required this.learnedTerms,
    required this.gems,
    required this.xp,
  });
}

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  await ref.watch(contentReadyProvider.future);
  final db = ref.watch(databaseProvider);
  final total = await db.termCount();
  final due = await db.dueReviewCount(DateTime.now());
  final learned = (await db.select(db.termStates).get()).length;
  final gems = await db.metaInt('gems');
  final xp = await db.metaInt('xp');
  return HomeStats(totalTerms: total, dueReviews: due, learnedTerms: learned, gems: gems, xp: xp);
});

/// 도감 검색어·필터 (§11.5)
final glossaryQueryProvider = StateProvider<String>((ref) => '');

enum GlossaryFilter { all, notStarted, learning, mastered, wrong, core }

final glossaryFilterProvider = StateProvider<GlossaryFilter>((ref) => GlossaryFilter.all);

class GlossaryEntry {
  final Term term;
  final TermState? state;
  const GlossaryEntry(this.term, this.state);
}

final glossaryResultsProvider = FutureProvider<List<GlossaryEntry>>((ref) async {
  await ref.watch(contentReadyProvider.future);
  final db = ref.watch(databaseProvider);
  final q = ref.watch(glossaryQueryProvider);
  final filter = ref.watch(glossaryFilterProvider);
  final terms = await db.searchTerms(q, limit: 900);
  final states = await db.allStates();
  final entries = terms.map((t) => GlossaryEntry(t, states[t.id]));
  final filtered = switch (filter) {
    GlossaryFilter.all => entries,
    GlossaryFilter.notStarted => entries.where((e) => e.state == null),
    GlossaryFilter.learning => entries.where((e) =>
        e.state != null && e.state!.state != 'MASTERED' && e.state!.correctStreak > 0),
    GlossaryFilter.mastered => entries.where((e) => e.state?.state == 'MASTERED'),
    GlossaryFilter.wrong =>
      entries.where((e) => e.state != null && e.state!.correctStreak == 0),
    GlossaryFilter.core => entries.where((e) => e.term.vibeCore),
  };
  return filtered.take(150).toList();
});

/// 내 기록 (§11.6)
class ProfileStats {
  final int weeklyDays; // 최근 7일 중 학습한 날
  final List<bool> weekDots; // 오늘 포함 7일 (과거→오늘)
  final int metTerms;
  final int masteredTerms;
  final int streak; // 연속 학습일
  final int gems;
  final int xp;
  final Map<String, ({int count, double avg})> categoryMastery;
  const ProfileStats({
    required this.weeklyDays,
    required this.weekDots,
    required this.metTerms,
    required this.masteredTerms,
    required this.streak,
    required this.gems,
    required this.xp,
    required this.categoryMastery,
  });

  int get level => xp ~/ 100 + 1;
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  await ref.watch(contentReadyProvider.future);
  final db = ref.watch(databaseProvider);
  final sessions = await db.recentSessions();
  final days = sessions
      .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
      .toSet();
  final today = DateTime.now();
  final todayD = DateTime(today.year, today.month, today.day);
  final dots = [
    for (var i = 6; i >= 0; i--) days.contains(todayD.subtract(Duration(days: i))),
  ];
  // 연속 학습일 — 오늘 또는 어제부터 거슬러 계산
  var streak = 0;
  var cursor = days.contains(todayD) ? todayD : todayD.subtract(const Duration(days: 1));
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  final states = await db.allStates();
  final mastered = states.values.where((s) => s.state == 'MASTERED').length;
  return ProfileStats(
    weeklyDays: dots.where((d) => d).length,
    weekDots: dots,
    metTerms: states.length,
    masteredTerms: mastered,
    streak: streak,
    gems: await db.metaInt('gems'),
    xp: await db.metaInt('xp'),
    categoryMastery: await db.categoryMastery(),
  );
});
