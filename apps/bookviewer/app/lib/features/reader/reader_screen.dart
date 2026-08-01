import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/crop_rect.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/entities/reading_theme.dart';
import '../capture/capture_controller.dart';
import '../capture/widgets/capture_overlay.dart';
import '../search/indexer.dart';
import '../search/widgets/search_sheet.dart';
import 'crop_detector.dart';
import 'widgets/crop_sheet.dart';
import 'widgets/reader_bottom_bar.dart';
import 'widgets/reader_top_bar.dart';
import 'widgets/theme_sheet.dart';
import 'widgets/view_sheet.dart';
import 'widgets/page_turn_zones.dart';
import 'widgets/rendered_page_view.dart';

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

/// 개발용 자가진단 — 화면을 손으로 누르지 않고 모드 전환을 확인한다.
///   flutter run -d windows --release --dart-define=selftest=split
const _selfTest = String.fromEnvironment('selftest');

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

  /// 좌우 분할 모드. 스캔 책은 한 장에 두 쪽이 들어 있어 그대로는 읽기 어렵다
  ReaderSettings _settings = const ReaderSettings();
  final _renderKey = GlobalKey<RenderedPageViewState>();

  /// 직접 그리는 모드(분할·크롭)에서 쓰는 별도 문서 핸들.
  /// PdfViewer 가 쥔 문서를 같이 쓰면 뷰어를 떼는 순간 닫혀 버린다
  PdfDocument? _renderDoc;
  bool _renderLoading = false;
  bool _cropDetecting = false;

  /// 보기 번호 — 분할이면 반쪽 단위, 아니면 쪽 단위 (0부터)
  int _view = 0;

  /// 이 문서에 글자 레이어가 있는가. 없으면 검색이 성립하지 않는다
  bool _hasTextLayer = true;

  /// 좌우 넘김 영역을 잠깐 드러내는 중인가
  bool _zonesVisible = false;
  Timer? _zonesTimer;

  /// PdfViewer 대신 직접 그려야 하는가
  /// PdfViewer 대신 직접 그려야 하는가.
  /// 다크 리딩은 픽셀을 직접 만져야 해서 여기 포함된다
  bool get _custom =>
      _settings.splitPages || _settings.cropEnabled || _settings.tintsPage;
  int get _perPage => _settings.splitPages ? 2 : 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
    // 처음 열 때 한 번 알려 준다. 영역이 눈에 안 보이면 아무도 쓰지 않는다
    WidgetsBinding.instance.addPostFrameCallback((_) => _flashZones());
  }

  /// 좌우 넘김 영역을 잠깐 드러낸다
  void _flashZones() {
    if (!mounted) return;
    setState(() => _zonesVisible = true);
    _zonesTimer?.cancel();
    _zonesTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _zonesVisible = false);
    });
  }

  /// 화면 어디를 눌렀는지에 따라 이전/다음/도구막대 (techspec §5)
  void _handleTapAt(double dx, double width) {
    switch (PageTurnZones.zoneOf(dx, width)) {
      case -1:
        _step(-1);
        _flashZones();
      case 1:
        _step(1);
        _flashZones();
      default:
        setState(() => _chrome = !_chrome);
    }
  }

  Future<void> _loadSettings() async {
    final s = await ref.read(libraryRepositoryProvider).readerSettings(widget.book.id);
    if (!mounted) return;
    setState(() => _settings = s);
    if (s.splitPages || s.cropEnabled) {
      await _ensureRenderDoc();
      if (mounted) setState(() => _view = (_page - 1) * (s.splitPages ? 2 : 1));
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _zonesTimer?.cancel();
    _renderDoc?.dispose();
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
    // 첫 쪽만 보면 속표지 때문에 잘못 판정한다. 여러 쪽을 훑는다
    var textPages = 0;
    final probe = doc.pages.length < 8 ? doc.pages.length : 8;
    for (var i = 0; i < probe; i++) {
      final at = (doc.pages.length * i) ~/ probe;
      final t = await doc.pages[at].loadText();
      if ((t?.fullText.trim().isNotEmpty) ?? false) textPages++;
    }
    final hasText = textPages > 0;
    if (mounted) setState(() => _hasTextLayer = hasText);
    await ref.read(libraryRepositoryProvider).updateDocumentInfo(
          widget.book.id,
          pageCount: doc.pages.length,
          hasTextLayer: hasText,
        );
    _saveProgress();

    // 전체 검색용 색인을 뒤에서 만든다. 읽기를 막지 않는다
    unawaited(ref.read(indexerProvider).ensureIndexed(widget.book.id));

    if (_selfTest == 'split') unawaited(_runSelfTest());

    if (!hasText) _notifyScanned();
    _maybeSuggestSplit(doc);
    if (_settings.splitPrompted || _settings.splitPages) {
      await _maybeSuggestCrop(doc);
    }
  }

  /// 스캔본이라 검색이 안 된다는 것을 알린다 (techspec §11).
  ///
  /// 알려 주지 않으면 사용자는 **검색 기능이 고장 났다고 생각한다.**
  /// 실제로 그랬다 — "검색은 왜 안 되는건가?"
  void _notifyScanned() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 7),
          content: Text(
            '이 책은 글자가 아니라 사진으로 된 스캔본입니다.\n'
            '찾기와 글자 복사가 되지 않습니다 (OCR 은 아직 준비 중).',
          ),
        ),
      );
  }

  /// 한 장에 두 쪽이 들어 있어 보이면 나눠 보기를 권한다 (techspec §16 제안형 온보딩).
  ///
  /// 기본으로 켜면 정상 문서에서 쪽이 반토막 나고, 기본으로 끄면 아무도 기능을 모른다.
  /// 그래서 감지해서 물어본다. 거절하면 다시 묻지 않는다.
  void _maybeSuggestSplit(PdfDocument doc) {
    if (!mounted || _settings.splitPages || _settings.splitPrompted) return;
    final first = doc.pages.first;
    // 가로가 세로보다 뚜렷하게 길면 펼쳐 스캔한 책으로 본다
    if (first.width < first.height * 1.2) return;

    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: const Text('이 책은 한 장에 두 쪽이 들어 있는 것 같습니다.\n좌우로 나눠 한 쪽씩 볼까요?'),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                unawaited(() async {
                  await _saveSettings(_settings.copyWith(splitPrompted: true));
                  final doc = _doc;
                  if (doc != null) await _maybeSuggestCrop(doc);
                }());
              },
              child: const Text('아니요'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                unawaited(_toggleSplit());
              },
              child: const Text('나눠 보기'),
            ),
          ],
        ),
      );
  }

  /// 좌우 분할·그냥 보기 전환이 실제로 되는지 스스로 눌러 본다
  Future<void> _runSelfTest() async {
    void say(String tag) {
      // ignore: avoid_print
      print('SELFTEST | $tag | split=${_settings.splitPages} crop=${_settings.cropEnabled} '
          'custom=$_custom renderDoc=${_renderDoc != null} view=$_view page=$_page/$_pageCount');
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    say('시작');

    await _toggleSplit();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    say('분할 켠 뒤');

    _step(1);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    say('한 칸 넘긴 뒤');

    await _toggleSplit();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    say('분할 끈 뒤');

    // ignore: avoid_print
    print('SELFTEST | 끝');
  }

  Future<void> _saveSettings(ReaderSettings next) async {
    if (mounted) setState(() => _settings = next);
    await ref.read(libraryRepositoryProvider).saveReaderSettings(widget.book.id, next);
  }

  /// 직접 그리는 모드에 쓸 문서를 연다 (분할·크롭 공용).
  Future<PdfDocument?> _ensureRenderDoc() async {
    if (_renderDoc != null) return _renderDoc;
    if (_renderLoading) return null;
    _renderLoading = true;
    try {
      final doc = await PdfDocument.openFile(widget.book.filePath);
      if (!mounted) {
        await doc.dispose();
        return null;
      }
      setState(() {
        _renderDoc = doc;
        _pageCount = doc.pages.length;
      });
      return doc;
    } on Object catch (e) {
      if (mounted) _toast('문서를 열지 못했습니다 — $e');
      return null;
    } finally {
      _renderLoading = false;
    }
  }

  Future<void> _applySettings(ReaderSettings next) async {
    final wasCustom = _custom;
    if (next.splitPages || next.cropEnabled) {
      if (await _ensureRenderDoc() == null) return;
    }
    await _saveSettings(next);
    if (!mounted) return;
    setState(() {
      // 모드가 바뀌면 보기 번호를 지금 쪽 기준으로 다시 잡는다
      _view = ((_page - 1) * (next.splitPages ? 2 : 1)).clamp(0, (_pageCount * 2) - 1);
    });
    if (wasCustom && !_custom) _saveProgress();
  }

  Future<void> _toggleSplit() =>
      _applySettings(_settings.copyWith(splitPages: !_settings.splitPages, splitPrompted: true));

  void _onViewChanged(int view) {
    setState(() {
      _view = view;
      _page = (view ~/ _perPage) + 1;
    });
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  /// 한 쪽(분할 모드면 반쪽) 이동. 책을 넘기는 가장 기본 동작이다 (techspec §6.1)
  void _step(int delta) {
    if (_custom) {
      final maxView = (_pageCount * _perPage) - 1;
      final next = (_view + delta).clamp(0, maxView);
      if (next == _view) return;
      _renderKey.currentState?.goToView(next);
      _onViewChanged(next);
    } else {
      final next = (_page + delta).clamp(1, _pageCount == 0 ? 1 : _pageCount);
      if (next == _page) return;
      unawaited(_controller.goToPage(pageNumber: next));
    }
  }

  /// 특정 쪽으로 (슬라이더·Home/End 가 쓴다)
  void _goToPage(int page) {
    if (_pageCount <= 0) return;
    final target = page.clamp(1, _pageCount);
    if (_custom) {
      final view = ((target - 1) * _perPage).clamp(0, (_pageCount * _perPage) - 1);
      setState(() => _view = view);
      _renderKey.currentState?.goToView(view);
      _onViewChanged(view);
    } else {
      unawaited(_controller.goToPage(pageNumber: target));
    }
  }

  bool get _canPrev => _custom ? _view > 0 : _page > 1;
  bool get _canNext => _custom
      ? _view < (_pageCount * _perPage) - 1
      : _pageCount > 0 && _page < _pageCount;

  // ── 여백 크롭 ───────────────────────────────────────────
  //
  // 자동 감지는 반드시 틀리는 쪽이 나온다. 그래서 감지 결과를 곧바로 적용하지 않고
  // 조정 시트를 함께 띄운다 (SPEC §2.1 — 수동 미세조정 UI 필수).

  Future<void> _openCropSheet({bool detectFirst = false}) async {
    final doc = await _ensureRenderDoc();
    if (doc == null || !mounted) return;

    var odd = _settings.cropOdd ?? CropRect.none;
    var even = _settings.cropEven ?? CropRect.none;

    if (detectFirst || (odd.isEmpty && even.isEmpty)) {
      setState(() => _cropDetecting = true);
      try {
        final found = await CropDetector.detect(doc);
        odd = found.odd;
        even = found.even;
      } on Object catch (e) {
        if (mounted) _toast('여백을 자동으로 찾지 못했습니다 — $e');
      } finally {
        if (mounted) setState(() => _cropDetecting = false);
      }
    }
    if (!mounted) return;

    final pages = doc.pages.length;
    final result = await showModalBottomSheet<CropSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CropSheet(
        document: doc,
        oddPage: _firstPageWith(isOdd: true, total: pages),
        evenPage: _firstPageWith(isOdd: false, total: pages),
        initialOdd: odd,
        initialEven: even,
        enabled: true,
      ),
    );
    if (result == null || !mounted) return;

    await _applySettings(
      _settings.copyWith(
        cropEnabled: result.enabled,
        cropOdd: result.odd,
        cropEven: result.even,
        cropPrompted: true,
      ),
    );
  }

  /// 보기 시트 — 나눠 보기·여백·테마를 한곳에서 (techspec §1 툴바 → 시트 → 실행)
  void _openViewSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => ViewSheet(
          splitOn: _settings.splitPages,
          cropOn: _settings.cropEnabled,
          darkOn: _settings.theme == ReadingTheme.dark,
          onToggleSplit: () => unawaited(_toggleSplit()),
          onCrop: () => unawaited(_openCropSheet()),
          onTheme: () => unawaited(_openThemeSheet()),
        ),
      ),
    );
  }

  /// 테마 시트 — 고르는 즉시 화면에 반영하고, 닫을 때 저장한다
  Future<void> _openThemeSheet() async {
    if (await _ensureRenderDoc() == null) return;
    if (!mounted) return;
    final before = _settings;
    final result = await showModalBottomSheet<ReaderSettings>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ThemeSheet(
        settings: _settings,
        onChanged: (s) => setState(() => _settings = s),
      ),
    );
    await _saveSettings(result ?? before);
  }

  /// 미리보기에 쓸 쪽 — 표지·간지를 피해 본문 쪽을 고른다
  int _firstPageWith({required bool isOdd, required int total}) {
    for (var i = 3; i <= total; i++) {
      if (i.isOdd == isOdd) return i;
    }
    return isOdd ? 1 : (total >= 2 ? 2 : 1);
  }

  /// 여백이 넉넉하면 잘라내기를 권한다 (techspec §16 제안형 온보딩).
  ///
  /// 기본 ON 이면 "페이지 번호가 잘렸다"는 불만이 나오고,
  /// 기본 OFF 면 아무도 기능이 있는 줄 모른다. 그래서 감지해서 물어본다.
  Future<void> _maybeSuggestCrop(PdfDocument doc) async {
    if (!mounted || _settings.cropEnabled || _settings.cropPrompted) return;
    final sample = await CropDetector.detectPage(doc.pages[doc.pages.length ~/ 2]);
    if (sample == null || !mounted) return;
    // 한 변이라도 5% 넘게 비어 있어야 권할 만하다
    final biggest = [sample.left, sample.top, sample.right, sample.bottom]
        .reduce((a, b) => a > b ? a : b);
    if (biggest < 0.05) return;

    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: const Text('여백이 넓습니다. 잘라내면 글자가 더 커집니다.'),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                unawaited(_saveSettings(_settings.copyWith(cropPrompted: true)));
              },
              child: const Text('안 볼래요'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                unawaited(_openCropSheet(detectFirst: true));
              },
              child: const Text('맞춰 보기'),
            ),
          ],
        ),
      );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _onGeneralTap(BuildContext context, PdfViewerController c, PdfViewerGeneralTapHandlerDetails d) {
    // 가장자리는 쪽 넘김, 가운데는 도구막대 토글 (techspec §5).
    // 글자·링크 위를 누른 것은 뷰어가 처리하게 그대로 넘긴다
    if (d.type == PdfViewerGeneralTapType.tap && d.tapOn == PdfViewerPart.background) {
      final width = _viewerKey.currentContext?.size?.width ?? 0;
      _handleTapAt(d.localPosition.dx, width);
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

    // 데스크톱 키보드 (techspec §5): ← → PgUp PgDn 로 넘기고 Esc 로 나간다
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.pageDown): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.space): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevPageIntent(),
        SingleActivator(LogicalKeyboardKey.pageUp): _PrevPageIntent(),
        SingleActivator(LogicalKeyboardKey.home): _FirstPageIntent(),
        SingleActivator(LogicalKeyboardKey.end): _LastPageIntent(),
        SingleActivator(LogicalKeyboardKey.keyF, control: true): _FindIntent(),
        SingleActivator(LogicalKeyboardKey.f11): _ToggleChromeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NextPageIntent: CallbackAction<_NextPageIntent>(
            onInvoke: (_) {
              _step(1);
              _flashZones();
              return null;
            },
          ),
          _PrevPageIntent: CallbackAction<_PrevPageIntent>(
            onInvoke: (_) {
              _step(-1);
              _flashZones();
              return null;
            },
          ),
          _FirstPageIntent: CallbackAction<_FirstPageIntent>(
            onInvoke: (_) {
              _goToPage(1);
              return null;
            },
          ),
          _LastPageIntent: CallbackAction<_LastPageIntent>(
            onInvoke: (_) {
              _goToPage(_pageCount);
              return null;
            },
          ),
          _FindIntent: CallbackAction<_FindIntent>(
            onInvoke: (_) {
              if (_searcher != null) setState(() => _search = true);
              return null;
            },
          ),
          _ToggleChromeIntent: CallbackAction<_ToggleChromeIntent>(
            onInvoke: (_) {
              setState(() => _chrome = !_chrome);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: _buildScaffold(context, capturing),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, bool capturing) {
    return Scaffold(
      backgroundColor: AppTokens.ink,
      body: Stack(
        children: [
          // 분할 모드에서도 PdfViewer 를 계속 띄워 둔다.
          // 검색기·색인·캡처가 그 문서에 붙어 있어 떼면 같이 죽는다.
          // 분할 화면이 그 위를 덮는 구조다.
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

          if (_custom && _renderDoc != null)
            Positioned.fill(
              child: ColoredBox(
                color: AppTokens.ink,
                child: GestureDetector(
                  // 직접 그린 화면이라 뷰어의 탭 처리가 닿지 않는다.
                  // 가장자리 넘김·도구막대 토글을 여기서 따로 받는다
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (d) => _handleTapAt(
                    d.localPosition.dx,
                    context.size?.width ?? 0,
                  ),
                  child: RenderedPageView(
                    key: _renderKey,
                    document: _renderDoc!,
                    initialView: _view,
                    split: _settings.splitPages,
                    rightToLeft: _settings.splitRightToLeft,
                    cropFor: _settings.cropFor,
                    settings: _settings,
                    onViewChanged: _onViewChanged,
                  ),
                ),
              ),
            ),

          if (_cropDetecting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCC0D1117),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          if (_capture)
            CaptureOverlay(
              busy: capturing,
              onCapture: _handleCapture,
              onCancel: () => setState(() => _capture = false),
            ),

          // 좌우 넘김 영역 — 늘 옅게, 넘길 때만 또렷하게
          if (!_capture)
            Positioned.fill(
              child: PageTurnZones(
                highlighted: _zonesVisible || _chrome,
                canPrev: _canPrev,
                canNext: _canNext,
              ),
            ),

          if (_chrome && !_capture)
            ReaderTopBar(
              title: widget.book.title,
              searchOpen: _search,
              canSearch: _searcher != null && _hasTextLayer,
              searchDisabledReason: _hasTextLayer
                  ? null
                  : '스캔본이라 글자를 찾을 수 없습니다',
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
              viewChanged: _settings.splitPages ||
                  _settings.cropEnabled ||
                  _settings.theme == ReadingTheme.dark,
              onOpenViewSheet: _doc == null ? null : _openViewSheet,
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
              // 분할 모드에서는 "12쪽 (좌)" 처럼 어느 반쪽인지 함께 보여준다
              sideLabel: _settings.splitPages ? (_view.isEven ? '좌' : '우') : null,
              onPageChanged: (v) => setState(() => _page = v),
              onPrev: () => _step(-1),
              onNext: () => _step(1),
              canPrev: _canPrev,
              canNext: _canNext,
              onPageSettled: (v) {
                if (_custom) {
                  final view = ((v - 1) * _perPage).clamp(0, (_pageCount * _perPage) - 1);
                  setState(() => _view = view);
                  _renderKey.currentState?.goToView(view);
                } else {
                  unawaited(_controller.goToPage(pageNumber: v));
                }
              },
            ),
        ],
      ),
    );
  }
}

class _NextPageIntent extends Intent {
  const _NextPageIntent();
}

class _PrevPageIntent extends Intent {
  const _PrevPageIntent();
}

class _FirstPageIntent extends Intent {
  const _FirstPageIntent();
}

class _LastPageIntent extends Intent {
  const _LastPageIntent();
}

class _FindIntent extends Intent {
  const _FindIntent();
}

class _ToggleChromeIntent extends Intent {
  const _ToggleChromeIntent();
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
