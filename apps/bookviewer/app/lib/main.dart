// BookViewer(북뷰) — PDF 로 저장한 책을 책처럼 읽는 생산성 리더.
//
// MVP 범위: 열기 · 세로 스크롤로 넘겨 읽기 · 문서 전체 검색 · 글자 복사 · 영역 캡처.
// 자세한 내용은 `apps/bookviewer/TECHSPEC.md`.
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'models/book_entry.dart';
import 'screens/library_screen.dart';
import 'screens/reader_screen.dart';
import 'theme.dart';

/// 개발용 — 파일 고르기를 거치지 않고 바로 읽기 화면을 띄운다.
///
///     flutter run -d windows --dart-define=openPdf=E:\...\sample_book.pdf
///
/// 비어 있으면(= 보통의 실행) 책장으로 시작한다.
const _devOpenPdf = String.fromEnvironment('openPdf');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  runApp(const BookViewerApp());
}

class BookViewerApp extends StatelessWidget {
  const BookViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '북뷰',
      theme: bookViewerTheme(),
      debugShowCheckedModeBanner: false,
      home: _devOpenPdf.isEmpty
          ? const LibraryScreen()
          : ReaderScreen(
              book: BookEntry(
                path: _devOpenPdf,
                title: _devOpenPdf.split(RegExp(r'[/\\]')).last,
                openedAt: DateTime.now(),
              ),
            ),
    );
  }
}
