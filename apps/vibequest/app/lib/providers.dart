import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/content_importer.dart';
import 'db/database.dart';

final databaseProvider = Provider<VqDatabase>((ref) {
  final db = VqDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 앱 시작 시 콘텐츠 import (1회). 완료 후 true.
final contentReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  await ContentImporter(db).importIfNeeded();
  return true;
});

/// 홈 대시보드 수치
class HomeStats {
  final int totalTerms;
  final int dueReviews;
  final int learnedTerms;
  const HomeStats({required this.totalTerms, required this.dueReviews, required this.learnedTerms});
}

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  await ref.watch(contentReadyProvider.future);
  final db = ref.watch(databaseProvider);
  final total = await db.termCount();
  final due = await db.dueReviewCount(DateTime.now());
  final learned = (await db.select(db.termStates).get()).length;
  return HomeStats(totalTerms: total, dueReviews: due, learnedTerms: learned);
});

/// 도감 검색어
final glossaryQueryProvider = StateProvider<String>((ref) => '');

final glossaryResultsProvider = FutureProvider<List<Term>>((ref) async {
  await ref.watch(contentReadyProvider.future);
  final db = ref.watch(databaseProvider);
  final q = ref.watch(glossaryQueryProvider);
  return db.searchTerms(q, limit: 120);
});
