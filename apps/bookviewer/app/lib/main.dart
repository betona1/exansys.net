// BookViewer(북뷰) — PDF 엔진 검증용 앱.
//
// 이 앱의 목적은 예쁜 화면이 아니라 "되는지 안 되는지"를 가리는 것이다.
// TECHSPEC 1단계에서 확인해야 할 것들을 화면에 결과로 찍는다.
//
//   1) 텍스트 추출  — 쪽에서 글자를 뽑아낼 수 있는가 (한글 포함)
//   2) 전체 검색    — 문서 전체에서 낱말을 찾아 쪽 번호를 알 수 있는가
//   3) 텍스트 선택  — 본문을 드래그해 복사할 수 있는가 (눈으로 확인)
//
// 여기서 막히면 검색·복사 기능이 성립하지 않으므로 엔진을 바꾸거나 범위를 다시 잡는다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  pdfrxFlutterInitialize();
  runApp(const VerifyApp());
}

class VerifyApp extends StatelessWidget {
  const VerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookViewer — PDF 엔진 검증',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const VerifyPage(),
    );
  }
}

/// 검증 항목 하나의 결과
class Check {
  Check(this.name, this.passed, this.detail);
  final String name;
  final bool passed;
  final String detail;
}

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _controller = PdfViewerController();
  final _checks = <Check>[];
  String _phase = '문서 여는 중…';
  bool _done = false;

  /// 표본 문서에 심어 둔 표식 — 쪽마다 하나씩 들어 있다
  static const _markers = {
    1: 'ALPHA-MARKER-001',
    2: 'BRAVO-MARKER-002',
    3: 'CHARLIE-MARKER-003',
    4: 'DELTA-MARKER-004',
  };

  Future<void> _runChecks(PdfDocument doc) async {
    if (_done) return; // onViewerReady 가 여러 번 불려도 한 번만
    final checks = <Check>[];

    // ── 0) 모든 쪽 로드 ─────────────────────────────────────
    //
    // pdfrx 는 점진 로드(useProgressiveLoading)를 쓴다. PdfViewer 가 뷰어를 띄우는
    // 시점에는 1쪽만 실제로 열려 있고 나머지는 껍데기라 loadText() 가 빈 값을 준다.
    // 문서 전체 검색 색인을 만들려면 반드시 모든 쪽을 먼저 로드해야 한다.
    setState(() => _phase = '모든 쪽 로드 중…');
    final loadStart = DateTime.now();
    await doc.loadPagesProgressively();
    final loadMs = DateTime.now().difference(loadStart).inMilliseconds;
    checks.add(Check(
      '전체 쪽 로드',
      doc.pages.length == 4,
      '${doc.pages.length}쪽 로드 · ${loadMs}ms',
    ));

    // ── 1) 텍스트 추출 ───────────────────────────────────────
    setState(() => _phase = '텍스트 추출 확인 중…');
    final buffers = <int, String>{};
    try {
      for (final page in doc.pages) {
        // loadText() 는 텍스트 레이어가 없으면 null 을 준다 (스캔본 PDF 등)
        final text = await page.loadText();
        buffers[page.pageNumber] = text?.fullText ?? '';
      }
    } catch (e) {
      checks.add(Check('텍스트 추출', false, '예외: $e'));
    }

    final first = buffers[1] ?? '';
    final hasKorean = RegExp(r'[가-힣]').hasMatch(first);
    final hasEnglish = RegExp(r'[A-Za-z]{4,}').hasMatch(first);
    checks.add(Check(
      '텍스트 추출',
      first.trim().isNotEmpty && hasKorean && hasEnglish,
      first.trim().isEmpty
          ? '1쪽에서 글자를 전혀 뽑지 못했다'
          : '1쪽 ${first.trim().length}자 추출 · 한글 ${hasKorean ? "O" : "X"} · 영문 ${hasEnglish ? "O" : "X"}',
    ));

    // ── 2) 쪽 단위 정확도 ───────────────────────────────────
    final wrong = <int>[];
    for (final e in _markers.entries) {
      if (!(buffers[e.key] ?? '').contains(e.value)) wrong.add(e.key);
    }
    checks.add(Check(
      '쪽 단위 정확도',
      wrong.isEmpty,
      wrong.isEmpty ? '4개 쪽의 표식이 모두 제자리' : '표식을 못 찾은 쪽: $wrong',
    ));

    // ── 3) 전체 검색 ────────────────────────────────────────
    setState(() => _phase = '전체 검색 확인 중…');
    final unique = _searchAll(buffers, 'CHARLIE-MARKER-003');
    checks.add(Check(
      '검색 — 한 곳에만 있는 낱말',
      unique.length == 1 && unique.first == 3,
      '찾은 쪽: $unique (기대: [3])',
    ));

    final many = _searchAll(buffers, '검색');
    checks.add(Check(
      '검색 — 여러 쪽에 걸친 한글 낱말',
      many.length >= 2,
      '"검색" 이 나온 쪽: $many',
    ));

    final none = _searchAll(buffers, '존재하지않는낱말ZZZ');
    checks.add(Check(
      '검색 — 없는 낱말',
      none.isEmpty,
      none.isEmpty ? '없다고 올바르게 답함' : '엉뚱하게 찾음: $none',
    ));

    // ── 4) 문서 정보 ────────────────────────────────────────
    checks.add(Check(
      '문서 열기 · 쪽 수',
      doc.pages.length == 4,
      '${doc.pages.length}쪽 (기대: 4쪽)',
    ));

    // ── 5) 색인 경로 ────────────────────────────────────────
    //
    // 실제 앱은 뷰어와 별개로 뒤에서 색인을 만든다. 뷰어 없이 문서를 직접 열어
    // 전체 텍스트를 뽑는 경로가 되는지 확인한다 (검색 기능의 실제 구현 경로).
    setState(() => _phase = '색인 경로 확인 중…');
    try {
      final t0 = DateTime.now();
      final idxDoc = await PdfDocument.openAsset(
        'assets/sample_book.pdf',
        useProgressiveLoading: false,
      );
      var total = 0;
      for (final page in idxDoc.pages) {
        total += ((await page.loadText())?.fullText ?? '').length;
      }
      final ms = DateTime.now().difference(t0).inMilliseconds;
      await idxDoc.dispose();
      checks.add(Check(
        '색인 경로 (뷰어 없이 전체 추출)',
        total > 400,
        '${idxDoc.pages.length}쪽 · 총 $total자 · ${ms}ms',
      ));
    } catch (e) {
      checks.add(Check('색인 경로 (뷰어 없이 전체 추출)', false, '예외: $e'));
    }

    // 콘솔로도 찍는다 — 창을 못 보는 환경(CI·원격)에서도 결과를 확인할 수 있어야 한다
    // ignore: avoid_print
    print('===== BOOKVIEWER-VERIFY-START =====');
    for (final c in checks) {
      // ignore: avoid_print
      print('${c.passed ? "PASS" : "FAIL"} | ${c.name} | ${c.detail}');
    }
    // ignore: avoid_print
    print('SUMMARY | ${checks.where((c) => c.passed).length}/${checks.length} 통과');
    final flat = (buffers[1] ?? '').replaceAll(RegExp(r'\s+'), ' ');
    // ignore: avoid_print
    print('PAGE1-TEXT | $flat');
    // ignore: avoid_print
    print('===== BOOKVIEWER-VERIFY-END =====');

    setState(() {
      _checks
        ..clear()
        ..addAll(checks);
      _done = true;
      _phase = '';
    });
  }

  /// 추출한 쪽별 텍스트에서 낱말이 나온 쪽 번호를 모은다
  List<int> _searchAll(Map<int, String> buffers, String needle) {
    final hits = <int>[];
    buffers.forEach((page, text) {
      if (text.toLowerCase().contains(needle.toLowerCase())) hits.add(page);
    });
    hits.sort();
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final passed = _checks.where((c) => c.passed).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookViewer — PDF 엔진 검증'),
        actions: [
          if (_done)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '$passed / ${_checks.length} 통과',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: passed == _checks.length
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // 왼쪽 — 실제 뷰어 (선택·복사를 손으로 확인)
          Expanded(
            flex: 3,
            child: PdfViewer.asset(
              'assets/sample_book.pdf',
              controller: _controller,
              params: PdfViewerParams(
                onViewerReady: (doc, _) => _runChecks(doc),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // 오른쪽 — 검증 결과
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0D1117),
              child: _done
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('검증 결과',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('본문을 드래그해 선택·복사도 직접 해보세요.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white54)),
                        const SizedBox(height: 12),
                        for (final c in _checks)
                          Card(
                            color: c.passed
                                ? const Color(0xFF10241B)
                                : const Color(0xFF2A1416),
                            child: ListTile(
                              leading: Icon(
                                c.passed ? Icons.check_circle : Icons.cancel,
                                color: c.passed
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(c.detail),
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () {
                            final report = _checks
                                .map((c) =>
                                    '${c.passed ? "PASS" : "FAIL"}\t${c.name}\t${c.detail}')
                                .join('\n');
                            Clipboard.setData(ClipboardData(text: report));
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('결과 복사'),
                        ),
                      ],
                    )
                  : Center(child: Text(_phase)),
            ),
          ),
        ],
      ),
    );
  }
}
