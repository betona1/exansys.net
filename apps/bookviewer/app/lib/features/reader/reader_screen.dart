import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/book.dart';
import '../capture/capture_controller.dart';
import '../capture/widgets/capture_overlay.dart';
import '../search/indexer.dart';
import '../search/widgets/search_sheet.dart';
import 'widgets/reader_bottom_bar.dart';
import 'widgets/reader_top_bar.dart';

/// 읽기 화면 (techspec §4).
///
/// 기본 상태에서 페이지가 화면의 대부분을 차지한다. 툴바는 본문을 탭하면 사라진다.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.bookId, this.jumpToPage});

  final int bookId;

  /// 딥링크로 들어온 경우 갈 쪽. 없으면 읽던 자리
  final int? jumpToPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookProvider(bookId));
    return book.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ReaderError(message: '$e'),
      data: (b) => b == null
          ? const _ReaderError(message: '서재에 없는 책입니다')
          : _ReaderView(book: b, jumpToPage: jumpToPage),
    );
  }
}

class _ReaderView extends ConsumerStatefulWidget {
  const _ReaderView({required this.book, this.jumpToPage});

  final Book book;
  final int? jumpToPage;

  @override
  ConsumerState<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends ConsumerState<_ReaderView> {
  final _controller = PdfViewerController();
  final _viewerKey = GlobalKey();

  // 검색기는 문서가 열린 뒤에만 만들 수 있다.
  // PdfTextSearcher 의 생성자가 곧바로 controller!.document 를 참조하기 때문에,
  // 뷰어가 준비되기 전에 만들면 화면이 통째로 죽는다 (docs/engine-verification.md).
  PdfTextSearcher? _searcher;
  List<PdfViewerPagePaintCallback>? _paintCallbacks;

  PdfDocument? _doc;
  late int _page = widget.jumpToPage ?? widget.book.lastPage;
  late int _pageCount = widget.book.pageCount;
  bool _chrome = true;
  bool _search = false;
  bool _capture = false;
  Timer? _saveDebounce;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _searcher?.removeListener(_repaint);
    _searcher?.dispose();
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;
    setState(() => _page = page);
    // 쪽을 넘길 때마다 쓰지 않는다 — 잠깐 멈췄을 때 한 번만 저장한다
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  void _saveProgress() {
    unawaited(
      ref.read(libraryRepositoryProvider).saveProgress(
            widget.book.id,
            lastPage: _page,
            pageCount: _pageCount > 0 ? _pageCount : null,
          ),
    );
  }

  Future<void> _onViewerReady(PdfDocument doc, PdfViewerController controller) async {
    _doc = doc;
    if (!mounted) return;
    final searcher = _searcher ?? (PdfTextSearcher(_controller)..addListener(_repaint));
    setState(() {
      _pageCount = doc.pages.length;
      _searcher = searcher;
      // 목록을 매번 새로 만들면 PdfViewerParams 가 매 빌드마다 달라져 다시 배치된다
      _paintCallbacks ??= [searcher.pageTextMatchPaintCallback];
    });

    // 스캔본이면 검색이 되지 않는다. 사용자에게 알려야 하므로 여기서 판정해 저장한다
    // (모든 쪽을 로드해야 정확하다 — 점진 로드 함정, docs/engine-verification.md)
    await doc.loadPagesProgressively();
    final first = await doc.pages.first.loadText();
    final hasText = (first?.fullText.trim().isNotEmpty) ?? false;
    await ref.read(libraryRepositoryProvider).updateDocumentInfo(
          widget.book.id,
          pageCount: doc.pages.length,
          hasTextLayer: hasText,
        );
    _saveProgress();

    // 전체 검색용 색인을 뒤에서 만든다. 읽기를 막지 않는다
    unawaited(ref.read(indexerProvider).ensureIndexed(widget.book.id));
  }

  bool _onGeneralTap(BuildContext context, PdfViewerController c, PdfViewerGeneralTapHandlerDetails d) {
    // 본문을 한 번 탭하면 툴바를 접었다 편다 (몰입 모드).
    // 글자·링크 위를 누른 것은 뷰어가 처리하게 그대로 넘긴다
    if (d.type == PdfViewerGeneralTapType.tap && d.tapOn == PdfViewerPart.background) {
      setState(() => _chrome = !_chrome);
      return true;
    }
    return false;
  }

  Future<void> _handleCapture(Rect localRect) async {
    final doc = _doc;
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (doc == null || box == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final result = await ref.read(captureControllerProvider).capture(
          doc: doc,
          controller: _controller,
          viewerBox: box,
          localRect: localRect,
          book: widget.book,
        );
    if (!mounted) return;
    setState(() => _capture = false);
    result.when(
      ok: (c) => messenger
        ..clearSnackBars()
        ..showSnackBar(captureSavedSnackBar(c, widget.book)),
      failed: (message) => messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capturing = ref.watch(captureBusyProvider);

    return Scaffold(
      backgroundColor: AppTokens.ink,
      body: Stack(
        children: [
          Positioned.fill(
            key: _viewerKey,
            child: PdfViewer.file(
              widget.book.filePath,
              controller: _controller,
              initialPageNumber: _page,
              params: PdfViewerParams(
                backgroundColor: AppTokens.ink,
                margin: AppTokens.space2,
                // 세로 스크롤이 기본 — pdfrx 의 기본 배치가 세로 한 줄이다 (techspec §6.2)
                onViewerReady: (doc, c) => unawaited(_onViewerReady(doc, c)),
                onPageChanged: _onPageChanged,
                onGeneralTap: _onGeneralTap,
                textSelectionParams: const PdfTextSelectionParams(enabled: true),
                pagePaintCallbacks: _paintCallbacks,
                matchTextColor: AppTokens.amber.withValues(alpha: 0.35),
                activeMatchTextColor: AppTokens.amber.withValues(alpha: 0.7),
                loadingBannerBuilder: (_, _, _) => const Center(child: CircularProgressIndicator()),
                errorBannerBuilder: (_, error, _, _) => _ReaderError(message: '$error'),
              ),
            ),
          ),

          if (_capture)
            CaptureOverlay(
              busy: capturing,
              onCapture: _handleCapture,
              onCancel: () => setState(() => _capture = false),
            ),

          if (_chrome && !_capture)
            ReaderTopBar(
              title: widget.book.title,
              searchOpen: _search,
              canSearch: _searcher != null,
              canCapture: _doc != null,
              onBack: () {
                _saveProgress();
                context.go(AppRoutes.library);
              },
              onToggleSearch: () => setState(() {
                _search = !_search;
                if (!_search) _searcher?.resetTextSearch();
              }),
              onCapture: () => setState(() => _capture = true),
              searchSheet: _search && _searcher != null
                  ? SearchSheet(
                      searcher: _searcher!,
                      onClose: () => setState(() {
                        _search = false;
                        _searcher!.resetTextSearch();
                      }),
                    )
                  : null,
            ),

          if (_chrome && !_capture)
            ReaderBottomBar(
              page: _page,
              pageCount: _pageCount,
              onPageChanged: (v) => setState(() => _page = v),
              onPageSettled: (v) => unawaited(_controller.goToPage(pageNumber: v)),
            ),
        ],
      ),
    );
  }
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // "무엇이 실패 / 원인 / 다음 행동" 3요소 (techspec §17)
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: AppTokens.space3),
              const Text('이 PDF 를 열지 못했습니다', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppTokens.space2),
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppTokens.space5),
              FilledButton(
                onPressed: () => context.go(AppRoutes.library),
                child: const Text('서재로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
