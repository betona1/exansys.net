// 색인 성능 실측 도구 (ADR-0003 이 요구하는 항목).
//
//   flutter run -t lib/benchmark_main.dart -d windows --release \
//     --dart-define=pdf="E:/경로/책.pdf"
//
// 재는 것: 문서 열기 · 전체 쪽 로드 · 쪽별 텍스트 추출 · 정규화 · bigram ·
// DB 적재 · 인덱스 크기 · 질의 지연.
//
// **PDF 는 저장소에 넣지 않는다** (CLAUDE.md §9 — 저작권 있는 책 금지).
// 경로만 받아 그 자리에서 읽고, 만든 DB 는 임시 폴더에 두었다가 지운다.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'core/korean.dart';
import 'data/db/database.dart';

const _pdfPath = String.fromEnvironment('pdf');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  runApp(const _BenchmarkApp());
}

class _BenchmarkApp extends StatefulWidget {
  const _BenchmarkApp();

  @override
  State<_BenchmarkApp> createState() => _BenchmarkAppState();
}

class _BenchmarkAppState extends State<_BenchmarkApp> {
  final _log = <String>[];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _say(String line) {
    // ignore: avoid_print
    print(line);
    if (mounted) setState(() => _log.add(line));
  }

  Future<void> _run() async {
    _say('===== INDEX-BENCH-START =====');
    if (_pdfPath.isEmpty) {
      _say('FAIL | --dart-define=pdf=<경로> 가 필요합니다');
      _say('===== INDEX-BENCH-END =====');
      return;
    }
    final file = File(_pdfPath);
    if (!file.existsSync()) {
      _say('FAIL | 파일 없음: $_pdfPath');
      _say('===== INDEX-BENCH-END =====');
      return;
    }
    _say('FILE | ${file.path.split(RegExp(r"[/\\]")).last} · ${_mb(file.lengthSync())}');

    final tmp = await Directory.systemTemp.createTemp('exapdf_bench');
    final dbFile = File('${tmp.path}${Platform.pathSeparator}bench.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    try {
      // 마이그레이션(FTS5 + 트리거)을 실제로 돌린다
      await db.customSelect('SELECT 1').get();

      final bookId = await db.into(db.books).insert(
            BooksCompanion.insert(
              uuid: 'bench',
              filePath: file.path,
              fileChecksum: 'bench',
              addedAt: DateTime.now().toUtc().toIso8601String(),
              updatedAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );

      final swOpen = Stopwatch()..start();
      final doc = await PdfDocument.openFile(file.path, useProgressiveLoading: false);
      swOpen.stop();
      _say('OPEN | ${doc.pages.length}쪽 · ${swOpen.elapsedMilliseconds}ms');

      var extractMs = 0;
      var normMs = 0;
      var bigramMs = 0;
      var insertMs = 0;
      var rawChars = 0;
      var bigramChars = 0;
      var emptyPages = 0;
      var hangulSum = 0.0;
      var textPages = 0;

      // 실제 색인과 같은 방식으로 묶어서 넣는다 (쪽마다 커밋하면 그것이 병목이 된다)
      const batchSize = 50;
      var pending = <PageTextsCompanion>[];

      final swTotal = Stopwatch()..start();
      for (final page in doc.pages) {
        final sw = Stopwatch()..start();
        final raw = (await page.loadText())?.fullText ?? '';
        extractMs += sw.elapsedMicroseconds;

        if (raw.trim().isEmpty) {
          emptyPages++;
          continue;
        }
        textPages++;
        rawChars += raw.length;
        hangulSum += Korean.hangulRatio(raw);

        sw.reset();
        final norm = Korean.normalize(raw);
        final nospace = Korean.stripSpaces(norm);
        normMs += sw.elapsedMicroseconds;

        sw.reset();
        final bigram = Korean.bigrams(norm);
        bigramMs += sw.elapsedMicroseconds;
        bigramChars += bigram.length;

        pending.add(
          PageTextsCompanion.insert(
            bookId: bookId,
            pageNo: page.pageNumber,
            raw: raw,
            norm: norm,
            nospace: nospace,
            bigram: bigram,
          ),
        );
        if (pending.length >= batchSize) {
          sw.reset();
          final rows = pending;
          pending = [];
          await db.batch((b) => b.insertAll(db.pageTexts, rows));
          insertMs += sw.elapsedMicroseconds;
        }
      }
      if (pending.isNotEmpty) {
        final sw = Stopwatch()..start();
        await db.batch((b) => b.insertAll(db.pageTexts, pending));
        insertMs += sw.elapsedMicroseconds;
      }
      swTotal.stop();
      await doc.dispose();

      _say('PAGES | 텍스트 $textPages쪽 · 빈쪽 $emptyPages');
      _say('HANGUL | 평균 한글 비율 ${textPages == 0 ? 0 : (hangulSum / textPages * 100).round()}%');
      _say('TOTAL | 색인 전체 ${swTotal.elapsedMilliseconds}ms '
          '(쪽당 ${textPages == 0 ? 0 : (swTotal.elapsedMilliseconds / textPages).toStringAsFixed(1)}ms)');
      _say('BREAK | 추출 ${extractMs ~/ 1000}ms · 정규화 ${normMs ~/ 1000}ms · '
          'bigram ${bigramMs ~/ 1000}ms · DB적재 ${insertMs ~/ 1000}ms');
      _say('CHARS | 원문 $rawChars자 → bigram $bigramChars자 '
          '(${rawChars == 0 ? 0 : (bigramChars / rawChars).toStringAsFixed(2)}배)');

      // 인덱스 크기 — 파일 크기와 FTS5 자체 크기를 따로 본다
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      _say('DBSIZE | ${_mb(dbFile.lengthSync())} (원본 PDF 대비 '
          '${(dbFile.lengthSync() / file.lengthSync() * 100).round()}%)');

      // 질의 지연 — 2글자·조사포함·없는낱말
      for (final q in ['관계', '사랑', '나를', '존재하지않는낱말입니다']) {
        final bigram = Korean.queryToBigram(q);
        final match = bigram.split(' ').map((t) => '"$t"').join(' AND ');
        final sw = Stopwatch()..start();
        final rows = await db.customSelect(
          '''
          SELECT pt.page_no FROM page_fts
            JOIN page_texts pt ON pt.id = page_fts.rowid
           WHERE page_fts MATCH ?1 ORDER BY bm25(page_fts) LIMIT 200
          ''',
          variables: [Variable<String>(match)],
        ).get();
        sw.stop();
        _say('QUERY | "$q" → ${rows.length}건 · ${sw.elapsedMilliseconds}ms');
      }
    } on Object catch (e, st) {
      _say('FAIL | $e');
      _say('$st');
    } finally {
      await db.close();
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      _say('===== INDEX-BENCH-END =====');
      if (mounted) setState(() => _done = true);
    }
  }

  static String _mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)}MB';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(title: Text(_done ? '측정 완료' : '측정 중…')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final line in _log)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(line, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
