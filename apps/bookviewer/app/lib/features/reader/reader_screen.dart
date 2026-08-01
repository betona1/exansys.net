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
import '../../domain/entities/fit_mode.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/entities/reading_theme.dart';
import '../capture/capture_controller.dart';
import '../capture/widgets/capture_overlay.dart';
import '../search/indexer.dart';
import 'crop_detector.dart';
import 'widgets/crop_sheet.dart';
import 'widgets/in_book_search_sheet.dart';
import 'widgets/page_turn_zones.dart';
import 'widgets/reader_bottom_bar.dart';
import 'widgets/reader_rail.dart';
import 'widgets/reader_top_bar.dart';
import 'widgets/rendered_page_view.dart';
import 'widgets/theme_sheet.dart';
import 'widgets/view_sheet.dart';

/// 개발용 자가진단 — 화면을 손으로 누르지 않고 모드 전환을 확인한다.
///   flutter run -d windows --release --dart-define=selftest=split
const _selfTest = String.fromEnvironment('selftest');

/// 읽기 화면 (techspec §4).
///
/// **쪽은 우리가 직접 그린다.** pdfrx 의 `PdfViewer` 를 쓰지 않는다.
///
/// 예전에는 두 벌이었다 — 평소에는 `PdfViewer`, 여백 크롭·좌우 분할·다크 리딩을
/// 켜면 직접 그린 화면이 그 위를 덮었다. 그 구조가 문제를 계속 만들었다.
/// 설정 하나만 건드려도 조용히 렌더러가 갈아타 조작감과 기능이 달라졌고,
/// 그 사실이 화면에 드러나지 않아 "토글이 안 먹는다"로 보였다.
///
/// 대가: **글자 선택이 되지 않는다.** 대신 조작이 한 벌로 일관되고,
/// 검색은 색인 기반이라 그대로 된다 (스캔본은 어차피 글자 레이어가 없다).
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
      error: (e, _) => ReaderError(message: '$e'),
      data: (b) => b == null
          ? const ReaderError(message: '서재에 없는 책입니다')
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
  final _renderKey = GlobalKey<RenderedPageViewState>();
  final _viewerKey = GlobalKey();

  PdfDocument? _doc;
  Object? _openError;

  late int _page = widget.jumpToPage ?? widget.book.lastPage;
  late int _pageCount = widget.book.pageCount;

  /// 보기 번호 — 분할이면 반쪽 단위, 아니면 쪽 단위 (0부터)
  int _view = 0;

  ReaderSettings _settings = const ReaderSettings();

  bool _chrome = true;
  bool _search = false;
  bool _capture = false;
  bool _cropDetecting = false;

  /// 이 문서에 글자 레이어가 있는가. 없으면 검색이 성립하지 않는다
  bool _hasTextLayer = true;

  /// 지금 보이는 조각의 좌표 정보 (캡처가 쓴다)
  SliceMapper? _slice;

  bool _zonesVisible = false;
  Timer? _zonesTimer;
  Timer? _saveDebounce;

  int get _perPage => _settings.splitPages ? 2 : 1;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // 읽는 동안 시스템 바를 숨긴다.
    // 가로로 들면 위아래 검은 바가 책을 눌러 화면이 확 좁아진다
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    unawaited(_open());
    // 처음 열 때 한 번 알려 준다. 영역이 눈에 안 보이면 아무도 쓰지 않는다
    WidgetsBinding.instance.addPostFrameCallback((_) => _flashZones());
  }

  @override
  void dispose() {
    // 서재로 돌아가면 시스템 바를 되돌린다
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _saveDebounce?.cancel();
    _zonesTimer?.cancel();
    _doc?.dispose();
    super.dispose();
  }

  // ── 문서 열기 ───────────────────────────────────────────

  Future<void> _open() async {
    final settings = await ref.read(libraryRepositoryProvider).readerSettings(widget.book.id);
    if (mounted) setState(() => _settings = settings);

    try {
      final doc = await PdfDocument.openFile(widget.book.filePath);
      if (!mounted) {
        await doc.dispose();
        return;
      }
      setState(() {
        _doc = doc;
        _pageCount = doc.pages.length;
        _view = ((_page - 1) * _perPage).clamp(0, (doc.pages.length * _perPage) - 1);
      });
      await _inspect(doc);
    } on Object catch (e) {
      if (mounted) setState(() => _openError = e);
    }
  }

  /// 쪽 수·글자 레이어를 확인하고, 색인과 제안 배너를 건다
  Future<void> _inspect(PdfDocument doc) async {
    // 첫 쪽만 보면 속표지 때문에 잘못 판정한다. 여러 쪽을 훑는다
    var textPages = 0;
    final probe = doc.pages.length < 8 ? doc.pages.length : 8;
    for (var i = 0; i < probe; i++) {
      final at = (doc.pages.length * i) ~/ probe;
      final t = await doc.pages[at].loadText();
      if ((t?.fullText.trim().isNotEmpty) ?? false) textPages++;
    }
    final hasText = textPages > 0;
    if (!mounted) return;
    setState(() => _hasTextLayer = hasText);

    await ref.read(libraryRepositoryProvider).updateDocumentInfo(
      widget.book.id,
      pageCount: doc.pages.length,
      hasTextLayer: hasText,
    );
    _saveProgress();

    // 전체 검색용 색인을 뒤에서 만든다. 읽기를 막지 않는다
    unawaited(ref.read(indexerProvider).ensureIndexed(widget.book.id));

    if (!hasText) _notifyScanned();
    _maybeSuggestSplit(doc);
    if (_settings.splitPrompted || _settings.splitPages) {
      await _maybeSuggestCrop(doc);
      if (mounted) _maybeSuggestFitWidth();
    }
    // 배너가 겹치지 않게 살짝 뒤에
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) _maybeHintLandscape();
    });

    if (_selfTest == 'split') unawaited(_runSelfTest());
  }

  /// 스캔본이라 검색이 안 된다는 것을 알린다 (techspec §11).
  ///
  /// 알려 주지 않으면 사용자는 **검색 기능이 고장 났다고 생각한다.**
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

  // ── 진행 상태 ───────────────────────────────────────────

  void _saveProgress() {
    unawaited(
      ref.read(libraryRepositoryProvider).saveProgress(
        widget.book.id,
        lastPage: _page,
        pageCount: _pageCount > 0 ? _pageCount : null,
      ),
    );
  }

  void _onViewChanged(int view) {
    setState(() {
      _view = view;
      _page = (view ~/ _perPage) + 1;
    });
    // 쪽을 넘길 때마다 쓰지 않는다 — 잠깐 멈췄을 때 한 번만 저장한다
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  // ── 넘기기 ─────────────────────────────────────────────

  void _step(int delta) {
    final maxView = (_pageCount * _perPage) - 1;
    if (maxView < 0) return;
    final next = (_view + delta).clamp(0, maxView);
    if (next == _view) return;
    _renderKey.currentState?.goToView(next);
    _onViewChanged(next);
  }

  void _goToPage(int page) {
    if (_pageCount <= 0) return;
    final target = page.clamp(1, _pageCount);
    final view = ((target - 1) * _perPage).clamp(0, (_pageCount * _perPage) - 1);
    _renderKey.currentState?.goToView(view);
    _onViewChanged(view);
  }

  bool get _canPrev => _view > 0;
  bool get _canNext => _pageCount > 0 && _view < (_pageCount * _perPage) - 1;

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

  // ── 설정 ───────────────────────────────────────────────

  Future<void> _saveSettings(ReaderSettings next) async {
    final perPageBefore = _perPage;
    if (mounted) {
      setState(() {
        _settings = next;
        // 분할을 켜고 끄면 한 쪽이 한 칸이 되었다가 두 칸이 된다.
        // 보고 있던 쪽을 유지하도록 보기 번호를 다시 잡는다
        if (perPageBefore != _perPage) {
          _view = ((_page - 1) * _perPage).clamp(0, (_pageCount * _perPage) - 1);
        }
      });
    }
    await ref.read(libraryRepositoryProvider).saveReaderSettings(widget.book.id, next);
  }

  Future<void> _toggleSplit() =>
      _saveSettings(_settings.copyWith(splitPages: !_settings.splitPages, splitPrompted: true));

  void _openViewSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => ViewSheet(
          fitMode: _settings.fitMode,
          onFitMode: (m) => unawaited(_saveSettings(_settings.copyWith(fitMode: m))),
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

  Future<void> _openThemeSheet() async {
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

  // ── 여백 크롭 ───────────────────────────────────────────

  Future<void> _openCropSheet({bool detectFirst = false}) async {
    final doc = _doc;
    if (doc == null) return;

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

    final result = await showModalBottomSheet<CropSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CropSheet(
        document: doc,
        oddPage: _bodyPage(isOdd: true),
        evenPage: _bodyPage(isOdd: false),
        initialOdd: odd,
        initialEven: even,
        enabled: true,
      ),
    );
    if (result == null || !mounted) return;

    await _saveSettings(
      _settings.copyWith(
        cropEnabled: result.enabled,
        cropOdd: result.odd,
        cropEven: result.even,
        cropPrompted: true,
      ),
    );
  }

  /// 미리보기에 쓸 쪽 — 표지·간지를 피해 본문 쪽을 고른다
  int _bodyPage({required bool isOdd}) {
    for (var i = 3; i <= _pageCount; i++) {
      if (i.isOdd == isOdd) return i;
    }
    return isOdd ? 1 : (_pageCount >= 2 ? 2 : 1);
  }

  // ── 제안형 온보딩 (techspec §16) ────────────────────────

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
                unawaited(_saveSettings(_settings.copyWith(splitPrompted: true)));
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

  /// 좌우가 잘려 보이면 폭 맞춤을 권한다.
  ///
  /// 폰 세로 화면에서 가로로 긴 쪽을 세로 맞춤으로 보면 좌우가 통째로 잘린다.
  /// 잘린 줄 모르고 "화면이 이상하다"고 느끼는 게 제일 나쁘다.
  void _maybeSuggestFitWidth() {
    if (!mounted || _settings.fitMode == FitMode.width) return;
    final box = _viewerKey.currentContext?.size;
    final doc = _doc;
    if (box == null || doc == null) return;

    final page = doc.pages[(_page - 1).clamp(0, doc.pages.length - 1)];
    final crop = _settings.cropFor(page.pageNumber);
    final area = crop.toPageRect(page.width, page.height);
    final sliceWidth = _settings.splitPages ? area.w / 2 : area.w;

    // 세로에 맞췄을 때 가로가 화면을 넘는가
    final widthAtFitHeight = sliceWidth * (box.height / area.h);
    if (widthAtFitHeight <= box.width * 1.02) return;

    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: const Text('좌우가 화면을 넘어 잘려 보입니다.\n폭에 맞춰 볼까요?'),
          actions: [
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
              child: const Text('그대로'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
                unawaited(_saveSettings(_settings.copyWith(fitMode: FitMode.width)));
              },
              child: const Text('폭 맞춤'),
            ),
          ],
        ),
      );
  }

  /// 가로로 들면 훨씬 잘 보인다는 것을 한 번 알려 준다.
  ///
  /// 스캔 책은 쪽이 가로로 길어 폰 세로로는 글자가 작아진다.
  /// 한 번만 알리고 다시 띄우지 않는다.
  void _maybeHintLandscape() {
    if (!mounted || _settings.landscapeHintShown) return;
    final media = MediaQuery.of(context);
    if (media.size.width >= media.size.height) return; // 이미 가로다
    final doc = _doc;
    if (doc == null) return;

    final page = doc.pages.first;
    final sliceIsWide = _settings.splitPages
        ? (page.width / 2) > page.height * 0.8
        : page.width > page.height;
    if (!sliceIsWide) return;

    _toast('책은 폰을 가로로 들면 훨씬 잘 보입니다');
    unawaited(_saveSettings(_settings.copyWith(landscapeHintShown: true)));
  }

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

  // ── 캡처 ───────────────────────────────────────────────

  Future<void> _handleCapture(Rect localRect) async {
    final doc = _doc;
    final slice = _slice;
    if (doc == null || slice == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final pageRect = slice.toPageRect(localRect);
    if (pageRect == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('쪽 바깥은 잘라 낼 수 없습니다')));
      return;
    }

    final result = await ref.read(captureControllerProvider).captureRect(
      page: doc.pages[slice.pageNumber - 1],
      rect: pageRect,
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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 좌우 분할·그냥 보기 전환이 실제로 되는지 스스로 눌러 본다
  Future<void> _runSelfTest() async {
    void say(String tag) {
      // ignore: avoid_print
      print('SELFTEST | $tag | split=${_settings.splitPages} crop=${_settings.cropEnabled} '
          'view=$_view page=$_page/$_pageCount perPage=$_perPage');
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    say('시작');
    await _toggleSplit();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    say('분할 전환');
    _step(1);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    say('한 칸 넘김');
    await _toggleSplit();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    say('되돌림');
    // ignore: avoid_print
    print('SELFTEST | 끝');
  }

  // ── 화면 ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_openError != null) return ReaderError(message: '$_openError');

    // 데스크톱 키보드 (techspec §5)
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
              if (_hasTextLayer) setState(() => _search = true);
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
        child: Focus(autofocus: true, child: _scaffold(context)),
      ),
    );
  }

  ReaderRail _buildRail({VoidCallback? onClose}) => ReaderRail(
    title: widget.book.title,
    page: _page,
    pageCount: _pageCount,
    sideLabel: _settings.splitPages ? (_view.isEven ? '좌' : '우') : null,
    canSearch: _hasTextLayer,
    searchDisabledReason: _hasTextLayer ? null : '스캔본이라 글자를 찾을 수 없습니다',
    viewChanged: _settings.splitPages ||
        _settings.cropEnabled ||
        _settings.theme == ReadingTheme.dark,
    onBack: () {
      _saveProgress();
      context.go(AppRoutes.library);
    },
    onSearch: () => setState(() => _search = true),
    onViewSheet: _openViewSheet,
    onCapture: () => setState(() => _capture = true),
    onPrev: () => _step(-1),
    onNext: () => _step(1),
    canPrev: _canPrev,
    canNext: _canNext,
    onClose: onClose,
  );

  Widget _scaffold(BuildContext context) {
    final doc = _doc;
    final capturing = ref.watch(captureBusyProvider);
    final chrome = ReaderChrome.of(MediaQuery.sizeOf(context));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTokens.ink,
      // 가로 화면에서는 오른쪽 가장자리를 끌면 조작 레일이 나온다.
      // 끌어당기는 폭을 좁게 둔다 — 넓으면 쪽 넘김 탭과 겹친다
      endDrawer: chrome == ReaderChrome.drawer
          ? _buildRail(onClose: () => Navigator.of(context).maybePop())
          : null,
      drawerEdgeDragWidth: 28,
      body: Stack(
        children: [
          Positioned(
            left: chrome == ReaderChrome.rail ? ReaderRail.width : 0,
            top: 0,
            right: 0,
            bottom: 0,
            key: _viewerKey,
            child: doc == null
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (d) => _handleTapAt(
                      d.localPosition.dx,
                      _viewerKey.currentContext?.size?.width ?? 0,
                    ),
                    child: RenderedPageView(
                      key: _renderKey,
                      document: doc,
                      initialView: _view,
                      split: _settings.splitPages,
                      rightToLeft: _settings.splitRightToLeft,
                      cropFor: _settings.cropFor,
                      settings: _settings,
                      onViewChanged: _onViewChanged,
                      onSlice: (s) => _slice = s,
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

          // 큰 화면에서는 레일이 상주한다. 폭이 남으니 책을 가리지 않는다
          if (chrome == ReaderChrome.rail && !_capture)
            Positioned(left: 0, top: 0, bottom: 0, child: _buildRail()),

          // 가로 폰에서는 조작이 서랍에 있다. 여는 손잡이만 살짝 보인다
          if (chrome == ReaderChrome.drawer && !_capture && _chrome)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: Container(
                    width: 22,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppTokens.radiusButton),
                      ),
                    ),
                    child: const Icon(Icons.chevron_left, size: 18),
                  ),
                ),
              ),
            ),

          if (chrome == ReaderChrome.bars && _chrome && !_capture)
            ReaderTopBar(
              title: widget.book.title,
              searchOpen: _search,
              canSearch: _hasTextLayer,
              searchDisabledReason: _hasTextLayer ? null : '스캔본이라 글자를 찾을 수 없습니다',
              canCapture: doc != null,
              onBack: () {
                _saveProgress();
                context.go(AppRoutes.library);
              },
              onToggleSearch: () => setState(() => _search = !_search),
              onCapture: () => setState(() => _capture = true),
              viewChanged: _settings.splitPages ||
                  _settings.cropEnabled ||
                  _settings.theme == ReadingTheme.dark,
              onOpenViewSheet: doc == null ? null : _openViewSheet,
              searchSheet: _search
                  ? InBookSearchSheet(
                      bookId: widget.book.id,
                      onClose: () => setState(() => _search = false),
                      onGoToPage: (p) {
                        setState(() => _search = false);
                        _goToPage(p);
                      },
                    )
                  : null,
            ),

          if (chrome == ReaderChrome.bars && _chrome && !_capture)
            ReaderBottomBar(
              page: _page,
              pageCount: _pageCount,
              sideLabel: _settings.splitPages ? (_view.isEven ? '좌' : '우') : null,
              onPrev: () => _step(-1),
              onNext: () => _step(1),
              canPrev: _canPrev,
              canNext: _canNext,
              onPageChanged: (v) => setState(() => _page = v),
              onPageSettled: _goToPage,
            ),
          // 레일·서랍 모드에서는 검색 패널을 위에 따로 띄운다
          if (chrome != ReaderChrome.bars && _search && !_capture)
            Positioned(
              top: 0,
              left: chrome == ReaderChrome.rail ? ReaderRail.width : 0,
              right: 0,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  bottom: false,
                  child: InBookSearchSheet(
                    bookId: widget.book.id,
                    onClose: () => setState(() => _search = false),
                    onGoToPage: (p) {
                      setState(() => _search = false);
                      _goToPage(p);
                    },
                  ),
                ),
              ),
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

/// 문서를 열지 못했을 때 (techspec §17 — 무엇이 실패 / 원인 / 다음 행동)
class ReaderError extends StatelessWidget {
  const ReaderError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
