import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../models/book_entry.dart';
import '../services/capture_service.dart';
import '../services/library_store.dart';
import '../theme.dart';
import '../widgets/capture_overlay.dart';
import '../widgets/search_sheet.dart';

/// 읽기 화면 — 넘겨 읽기 · 검색 · 복사 · 캡처.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final BookEntry book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _controller = PdfViewerController();
  final _store = LibraryStore();
  final _viewerKey = GlobalKey();

  // 검색기는 문서가 열린 뒤에만 만들 수 있다.
  // PdfTextSearcher 의 생성자가 곧바로 controller!.document 를 참조하기 때문에,
  // 뷰어가 준비되기 전에 만들면 "Null check operator used on a null value" 로 터진다.
  PdfTextSearcher? _searcher;
  List<PdfViewerPagePaintCallback>? _paintCallbacks;

  PdfDocument? _doc;
  int _page = 1;
  int _pageCount = 0;
  bool _chrome = true;      // 상·하단 도구막대 표시
  bool _search = false;
  bool _capture = false;
  bool _capturing = false;
  bool _includeSource = true; // 캡처에 출처(책 이름·쪽) 붙이기
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _page = widget.book.lastPage;
    _pageCount = widget.book.pageCount;
  }

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
    // 쪽을 넘길 때마다 쓰지 않는다 — 잠깐 멈췄을 때 한 번만 저장한다.
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  void _saveProgress() {
    _store.saveProgress(
      widget.book.path,
      lastPage: _page,
      pageCount: _pageCount > 0 ? _pageCount : null,
    );
  }

  void _onViewerReady(PdfDocument doc, PdfViewerController controller) {
    _doc = doc;
    if (!mounted) return;
    final searcher = _searcher ?? (PdfTextSearcher(_controller)..addListener(_repaint));
    setState(() {
      _pageCount = doc.pages.length;
      _searcher = searcher;
      // 목록을 매번 새로 만들면 PdfViewerParams 가 매 빌드마다 달라져 다시 배치된다.
      // 한 번만 만들어 들고 있는다.
      _paintCallbacks ??= [searcher.pageTextMatchPaintCallback];
    });
    _saveProgress();
  }

  bool _onGeneralTap(BuildContext context, PdfViewerController controller, PdfViewerGeneralTapHandlerDetails d) {
    // 본문을 한 번 탭하면 도구막대를 접었다 편다. 글자를 고르는 중이거나
    // 링크·글자 위를 누른 것은 뷰어가 처리하게 그대로 넘긴다.
    if (d.type == PdfViewerGeneralTapType.tap && d.tapOn == PdfViewerPart.background) {
      setState(() => _chrome = !_chrome);
      return true;
    }
    return false;
  }

  // ── 캡처 ────────────────────────────────────────────────
  Future<void> _handleCapture(Rect localRect) async {
    final doc = _doc;
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (doc == null || box == null) return;

    setState(() => _capturing = true);
    try {
      // 화면 좌표 → 문서 좌표
      final topLeft = _controller.globalToDocument(box.localToGlobal(localRect.topLeft));
      final bottomRight = _controller.globalToDocument(box.localToGlobal(localRect.bottomRight));
      if (topLeft == null || bottomRight == null) {
        _toast('화면 위치를 문서 좌표로 옮기지 못했습니다');
        return;
      }
      final docRect = Rect.fromPoints(topLeft, bottomRight);

      // 걸친 쪽 가운데 가장 많이 겹치는 쪽 하나를 고른다.
      // (두 쪽에 걸친 캡처는 이번 범위 밖 — 겹친 넓이가 큰 쪽만 잘라 낸다)
      final layouts = _controller.layout.pageLayouts;
      var bestIndex = -1;
      var bestArea = 0.0;
      for (var i = 0; i < layouts.length; i++) {
        final inter = layouts[i].intersect(docRect);
        final area = inter.width <= 0 || inter.height <= 0 ? 0.0 : inter.width * inter.height;
        if (area > bestArea) {
          bestArea = area;
          bestIndex = i;
        }
      }
      if (bestIndex < 0) {
        _toast('쪽 바깥은 잘라 낼 수 없습니다');
        return;
      }

      final pageRect = layouts[bestIndex];
      final page = doc.pages[bestIndex];
      final local = docRect.intersect(pageRect).shift(-pageRect.topLeft);

      final result = await CaptureService.capture(
        page: page,
        rect: local,
        bookTitle: widget.book.title,
        sourceLabel: _includeSource ? '${widget.book.title} · ${page.pageNumber}쪽' : null,
      );
      if (!mounted) return;
      setState(() => _capture = false);
      _showCaptureResult(result);
    } on CaptureTooSmall {
      _toast('영역이 너무 작습니다. 조금 더 크게 드래그해 주세요');
    } catch (e) {
      _toast('캡처하지 못했습니다 — $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showCaptureResult(CaptureResult result) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(result.file, width: 40, height: 40, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('${result.pageNumber}쪽을 잘라 저장했습니다')),
            ],
          ),
          action: SnackBarAction(
            label: '공유',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile(result.file.path)],
                text: '${widget.book.title} · ${result.pageNumber}쪽',
              ),
            ),
          ),
        ),
      );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookViewerColors.navy,
      body: Stack(
        children: [
          Positioned.fill(
            key: _viewerKey,
            child: PdfViewer.file(
              widget.book.path,
              controller: _controller,
              initialPageNumber: widget.book.lastPage,
              params: PdfViewerParams(
                backgroundColor: BookViewerColors.navy,
                margin: 10,
                // 세로 스크롤이 기본 — pdfrx 의 기본 배치가 세로 한 줄이다 (확정 사항)
                onViewerReady: _onViewerReady,
                onPageChanged: _onPageChanged,
                onGeneralTap: _onGeneralTap,
                // 글자를 끌어 고르고 길게 눌러 복사한다 (기본 메뉴에 '복사'가 있다)
                textSelectionParams: const PdfTextSelectionParams(enabled: true),
                pagePaintCallbacks: _paintCallbacks,
                matchTextColor: BookViewerColors.cyan.withValues(alpha: 0.35),
                activeMatchTextColor: BookViewerColors.cyan.withValues(alpha: 0.65),
                loadingBannerBuilder: (context, downloaded, total) =>
                    const Center(child: CircularProgressIndicator()),
                errorBannerBuilder: (context, error, stack, ref) => _OpenError(
                  message: '$error',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),

          if (_capture)
            CaptureOverlay(
              busy: _capturing,
              onCapture: _handleCapture,
              onCancel: () => setState(() => _capture = false),
            ),

          if (_chrome && !_capture) _topBar(),
          if (_chrome && !_capture) _bottomBar(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: BookViewerColors.card.withValues(alpha: 0.96),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _saveProgress();
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '책장으로',
                  ),
                  Expanded(
                    child: Text(
                      widget.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    // 문서가 열리기 전에는 검색기가 없다
                    onPressed: _searcher == null
                        ? null
                        : () => setState(() {
                            _search = !_search;
                            if (!_search) _searcher!.resetTextSearch();
                          }),
                    icon: Icon(_search ? Icons.search_off : Icons.search),
                    tooltip: '이 책에서 찾기',
                  ),
                  IconButton(
                    onPressed: _doc == null ? null : () => setState(() => _capture = true),
                    icon: const Icon(Icons.crop_free),
                    tooltip: '영역 캡처',
                  ),
                  PopupMenuButton<String>(
                    tooltip: '더보기',
                    onSelected: (v) {
                      if (v == 'source') setState(() => _includeSource = !_includeSource);
                    },
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem(
                        value: 'source',
                        checked: _includeSource,
                        child: const Text('캡처에 출처 넣기'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_search && _searcher != null)
                SearchSheet(
                  searcher: _searcher!,
                  onClose: () => setState(() {
                    _search = false;
                    _searcher!.resetTextSearch();
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final count = _pageCount;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: BookViewerColors.card.withValues(alpha: 0.96),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  count > 0 ? '$_page / $count' : '$_page',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: count > 1
                      ? Slider(
                          value: _page.toDouble().clamp(1, count.toDouble()),
                          min: 1,
                          max: count.toDouble(),
                          divisions: count - 1,
                          label: '$_page쪽',
                          onChanged: (v) => setState(() => _page = v.round()),
                          onChangeEnd: (v) => _controller.goToPage(pageNumber: v.round()),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenError extends StatelessWidget {
  const _OpenError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.white38),
            const SizedBox(height: 12),
            const Text('이 PDF 를 열지 못했습니다', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onBack, child: const Text('책장으로')),
          ],
        ),
      ),
    );
  }
}
