import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// 검색 색인을 뒤에서 만든다.
///
/// **색인은 읽기 화면을 막지 않는다** (CLAUDE.md §14). 책을 열면 시작하고,
/// 진행 상황만 흘려보낸다. 사용자는 그동안 그냥 읽으면 된다.
///
/// 지금은 메인 아이솔레이트에서 돈다. 쪽마다 await 가 걸려 프레임을 완전히 막지는
/// 않지만, 300쪽·300MB 급 문서에서 실제로 버벅이는지는 아직 재지 않았다.
/// ADR-0003 이 요구하는 성능 실측(최초 인덱싱 시간·인덱스 크기)을 한 뒤
/// 필요하면 Isolate 로 옮긴다.
final indexerProvider = Provider<Indexer>(Indexer.new);

class Indexer {
  Indexer(this._ref);

  final Ref _ref;

  /// 이미 색인된 책은 건너뛴다. 같은 책을 두 번 걸지 않는다.
  final _running = <int>{};

  Future<void> ensureIndexed(int bookId, {bool force = false}) async {
    if (_running.contains(bookId)) return;
    _running.add(bookId);
    final progress = _ref.read(indexProgressProvider.notifier);
    try {
      await for (final p in _ref.read(searchRepositoryProvider).indexBook(bookId, force: force)) {
        progress.state = p.isFinished ? null : p;
      }
    } finally {
      _running.remove(bookId);
      if (progress.state?.bookId == bookId) progress.state = null;
    }
  }
}
