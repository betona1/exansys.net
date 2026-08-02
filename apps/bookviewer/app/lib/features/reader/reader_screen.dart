import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/providers.dart';
import '../../data/source/book_source.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/annotation.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/crop_rect.dart';
import '../../domain/entities/fit_mode.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/entities/reading_theme.dart';
import '../annotation/export.dart';
import '../export/page_image_export.dart';
import '../export/widgets/export_progress.dart';
import '../export/widgets/page_image_sheet.dart';
import '../annotation/export_controller.dart';
import '../annotation/widgets/highlight_bar.dart';
import '../annotation/widgets/highlight_layer.dart';
import '../annotation/widgets/marks_sheet.dart';
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

  /// 쪽 이미지 내보내기 진행 상태. null 이면 돌고 있지 않다
  ({int done, int total})? _exportProgress;
  ExportCancelToken? _exportCancel;

  /// 하이라이트 긋는 중인가. 켜져 있으면 드래그가 칠하기가 된다
  bool _highlighting = false;
  int _colorSlot = 1;

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
      // 웹은 경로가 없다. 담아 둔 바이트로 연다
      final bytes = await ref.read(libraryRepositoryProvider).bookBytes(widget.book.id);
      final doc = await openDocument(widget.book.filePath, bytes: bytes);
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

  /// 지금 보고 있는 배율·좌우 위치를 잠근다. 다시 누르면 푼다.
  ///
  /// 스캔본은 쪽마다 가장자리가 조금씩 달라서, 읽기 좋은 크기를 맞춰 놓아도
  /// 넘길 때마다 손이 간다. 잠가 두면 그 틀이 유지된다.
  /// **값은 책마다 저장되므로 앱을 껐다 켜도 그대로다.**
  Future<void> _toggleZoomLock() async {
    if (_settings.zoomLocked) {
      await _saveSettings(_settings.copyWith(zoomLocked: false));
      _toast('좌우 고정을 풀었습니다');
      return;
    }
    // 지금 화면의 배율과 좌우 위치를 그대로 굳힌다
    final m = _renderKey.currentState?.currentTransform ?? Matrix4.identity();
    final scale = m.getMaxScaleOnAxis();
    final panX = m.storage[12];
    await _saveSettings(
      _settings.copyWith(zoomLocked: true, zoomLevel: scale, panX: panX),
    );
    if (mounted) _toast('좌우와 크기를 고정했습니다 · 세로는 그대로 밀립니다');
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

    // 가로로 길다고 다 펼친 책은 아니다. 발표 자료·그림책도 가로로 길다.
    // 그래서 **여러 쪽을 보고** 대부분이 뚜렷하게 가로로 길 때만 권한다.
    // 1.2배는 너무 헐거워 오탐이 났다 — 책을 펼치면 대략 1.4배 안팎이 된다.
    const ratio = 1.4;
    final probe = doc.pages.length < 6 ? doc.pages.length : 6;
    var wide = 0;
    for (var i = 0; i < probe; i++) {
      final page = doc.pages[(doc.pages.length * i) ~/ probe];
      if (page.width >= page.height * ratio) wide++;
    }
    if (wide < probe) return; // 한 쪽이라도 아니면 권하지 않는다

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

    // 그냥 두면 읽는 내내 붙어 있다. 잠시 뒤 스스로 걷는다 —
    // 나눠 보기는 도구막대 아이콘으로 언제든 켤 수 있다
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (mounted) ScaffoldMessenger.of(context).clearMaterialBanners();
    });
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
    if (kIsWeb) {
      setState(() => _capture = false);
      _toast('웹에서는 아직 캡처 저장을 지원하지 않습니다');
      return;
    }
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

  // ── 하이라이트·북마크 ───────────────────────────────────

  Future<void> _addHighlight(Rect pageRect) async {
    final slice = _slice;
    if (slice == null) return;
    await ref.read(annotationRepositoryProvider).addHighlight(
      bookId: widget.book.id,
      pageNo: slice.pageNumber,
      rect: pageRect,
      colorSlot: _colorSlot,
      // 파일이 바뀌었는지 판정할 기준. 지금은 등록 당시 값을 쓴다
      documentChecksum: '',
    );
  }

  Future<void> _toggleBookmark() async {
    final added = await ref
        .read(annotationRepositoryProvider)
        .toggleBookmark(bookId: widget.book.id, pageNo: _page);
    if (!mounted) return;
    _toast(added ? '$_page쪽을 북마크했습니다' : '북마크를 뺐습니다');
  }

  /// 하이라이트를 누르면 색을 바꾸거나 지운다
  void _onTapHighlight(Highlight h) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Row(
                  children: [
                    for (var slot = 1; slot <= AppTokens.highlights.length; slot++)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            unawaited(
                              ref
                                  .read(annotationRepositoryProvider)
                                  .updateHighlight(h.id, colorSlot: slot),
                            );
                          },
                          child: Container(
                            height: 34,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: AppTokens.highlights[slot - 1],
                              borderRadius: BorderRadius.circular(6),
                              border: slot == h.colorSlot
                                  ? Border.all(color: Colors.black87, width: 2.5)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('메모'),
                subtitle: h.note == null ? null : Text(h.note!),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_editNote(h));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('삭제'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(ref.read(annotationRepositoryProvider).deleteHighlight(h.id));
                },
              ),
              const SizedBox(height: AppTokens.space2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNote(Highlight h) async {
    final controller = TextEditingController(text: h.note ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '이 자리에 남길 말'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null) return;
    await ref.read(annotationRepositoryProvider).updateHighlight(h.id, note: text);
  }

  void _openMarksSheet(List<Highlight> highlights, List<BookmarkEntry> bookmarks) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => MarksSheet(
          highlights: highlights,
          bookmarks: bookmarks,
          onGoToPage: _goToPage,
          onDeleteHighlight: (h) =>
              unawaited(ref.read(annotationRepositoryProvider).deleteHighlight(h.id)),
          onDeleteBookmark: (b) =>
              unawaited(ref.read(annotationRepositoryProvider).deleteBookmark(b.id)),
          onEditNote: (h) => unawaited(_editNote(h)),
          onExport: () {
            Navigator.pop(context);
            _openExportSheet();
          },
        ),
      ),
    );
  }

  /// 형식을 고르고 파일로 꺼낸다 (techspec §7)
  void _openExportSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('내보내기', style: Theme.of(ctx).textTheme.titleMedium),
                ),
              ),
              for (final f in ExportFormat.values)
                ListTile(
                  leading: Icon(switch (f) {
                    ExportFormat.markdown => Icons.description_outlined,
                    ExportFormat.obsidian => Icons.hexagon_outlined,
                    ExportFormat.json => Icons.data_object,
                    ExportFormat.csv => Icons.table_chart_outlined,
                  }),
                  title: Text(f.label),
                  subtitle: Text(switch (f) {
                    ExportFormat.markdown => '메모 앱에 붙여 넣기 좋습니다',
                    ExportFormat.obsidian => '앞머리 속성이 붙습니다',
                    ExportFormat.json => '다시 읽어 들일 수 있는 원시 데이터',
                    ExportFormat.csv => '표 계산기에서 열립니다',
                  }),
                  onTap: () {
                    Navigator.pop(ctx);
                    unawaited(_runExport(f));
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('쪽 이미지 (JPG)'),
                subtitle: const Text('다섯 장 넘으면 zip 하나로 묶습니다'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_exportPageImages());
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                enabled: false,
                title: const Text('주석 포함 PDF · 굽기'),
                subtitle: const Text('서버가 필요합니다 — 아직 준비되지 않았습니다'),
              ),
              const SizedBox(height: AppTokens.space2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runExport(ExportFormat format) async {
    if (kIsWeb) {
      _toast('웹에서는 아직 내보내기를 지원하지 않습니다');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(exportControllerProvider).export(
      book: widget.book,
      format: format,
      doc: _doc,
    );
    if (!mounted) return;
    result.when(
      ok: (file) => messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text('${format.label} 로 내보냈습니다'),
          ),
        ),
      failed: (m) => messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(m))),
    );
  }

  /// 쪽을 JPG 로 뽑는다. 다섯 장이 넘으면 zip 하나로 묶는다
  Future<void> _exportPageImages() async {
    final doc = _doc;
    if (doc == null) return;
    if (kIsWeb) {
      // 웹은 앱 전용 폴더가 없다. 브라우저 내려받기로 바꿔야 한다
      _toast('웹에서는 아직 쪽 이미지 내보내기를 지원하지 않습니다');
      return;
    }

    final hasCropOrSplit = _settings.cropEnabled || _settings.splitPages;
    final req = await showModalBottomSheet<PageImageRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PageImageSheet(
        pageCount: _pageCount,
        hasCropOrSplit: hasCropOrSplit,
      ),
    );
    if (req == null || !mounted) return;

    final pages = switch (req.range) {
      PageRange.current => [_page],
      PageRange.visible => [
        for (var p = _page - 10; p <= _page + 10; p++)
          if (p >= 1 && p <= _pageCount) p,
      ],
      PageRange.all => [for (var p = 1; p <= _pageCount; p++) p],
    };

    final messenger = ScaffoldMessenger.of(context);
    final cancel = ExportCancelToken();
    setState(() {
      _exportCancel = cancel;
      _exportProgress = (done: 0, total: pages.length);
    });
    try {
      final base = await getApplicationDocumentsDirectory();
      final files = await PageImageExport.exportPages(
        doc: doc,
        pageNumbers: pages,
        outDir: Directory('${base.path}${Platform.pathSeparator}exports'),
        baseName: widget.book.title,
        dpi: req.dpi,
        cropFor: req.asSeen ? _settings.cropFor : null,
        split: req.asSeen && _settings.splitPages,
        cancelToken: cancel,
        onProgress: (done, total) {
          if (mounted) setState(() => _exportProgress = (done: done, total: total));
        },
      );
      if (!mounted) return;
      if (cancel.isCancelled) {
        _toast('내보내기를 멈췄습니다');
        return;
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              files.length == 1 && files.first.path.endsWith('.zip')
                  ? 'zip 하나로 묶어 냈습니다'
                  : '${files.length}장을 냈습니다',
            ),
          ),
        );
    } on Object catch (e) {
      if (mounted) _toast('이미지를 내보내지 못했습니다 — $e');
    } finally {
      if (mounted) {
        setState(() {
          _exportProgress = null;
          _exportCancel = null;
        });
      }
    }
  }

  /// 스캔본에서 돋보기를 눌렀을 때 (techspec §11).
  ///
  /// "안 됩니다"로 끝내지 않는다. 왜 안 되는지와 무엇을 하면 되는지를 함께 준다.
  /// 글자로 바꾸는 일(OCR)은 서버가 맡는다 — 무거운 처리는 앱에 넣지 않는다
  /// (CLAUDE.md §4). 유료 기능으로 예정돼 있다 (SPEC §7).
  void _offerOcr() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('글자로 된 문서만 찾을 수 있습니다'),
          content: const Text(
            '이 책은 글자가 아니라 사진으로 된 스캔본입니다.\n'
            '글자로 바꾸면(OCR) 찾기와 복사가 됩니다.\n\n'
            '변환은 서버에서 처리하며, 준비되면 알려 드리겠습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _toast('OCR 변환은 아직 준비 중입니다');
              },
              child: const Text('글자로 바꾸기'),
            ),
          ],
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
        SingleActivator(LogicalKeyboardKey.enter): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown): _NextPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevPageIntent(),
        SingleActivator(LogicalKeyboardKey.pageUp): _PrevPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp): _PrevPageIntent(),
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

  ReaderRail _buildRail({
    VoidCallback? onClose,
    required bool bookmarked,
    required List<Highlight> highlights,
    required List<BookmarkEntry> bookmarks,
  }) => ReaderRail(
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
    onSearch: () {
      if (!_hasTextLayer) {
        _offerOcr();
        return;
      }
      setState(() => _search = true);
    },
    onViewSheet: _openViewSheet,
    onCapture: () => setState(() => _capture = true),
    splitOn: _settings.splitPages,
    onToggleSplit: () => unawaited(_toggleSplit()),
    zoomLocked: _settings.zoomLocked,
    onToggleZoomLock: () => unawaited(_toggleZoomLock()),
    highlighting: _highlighting,
    onToggleHighlight: () => setState(() => _highlighting = !_highlighting),
    bookmarked: bookmarked,
    onToggleBookmark: () => unawaited(_toggleBookmark()),
    onOpenMarks: () => _openMarksSheet(highlights, bookmarks),
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
    final highlights = ref.watch(highlightsProvider(widget.book.id)).valueOrNull ?? const [];
    final bookmarks = ref.watch(bookmarksProvider(widget.book.id)).valueOrNull ?? const [];
    final bookmarked = bookmarks.any((b) => b.pageNo == _page);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTokens.ink,
      // 가로 화면에서는 오른쪽 가장자리를 끌면 조작 레일이 나온다.
      // 끌어당기는 폭을 좁게 둔다 — 넓으면 쪽 넘김 탭과 겹친다
      endDrawer: chrome == ReaderChrome.drawer
          ? _buildRail(
              onClose: () => Navigator.of(context).maybePop(),
              bookmarked: bookmarked,
              highlights: highlights,
              bookmarks: bookmarks,
            )
          : null,
      drawerEdgeDragWidth: 28,
      body: Stack(
        children: [
          Positioned(
            left: chrome == ReaderChrome.rail ? ReaderRail.width : 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: doc == null
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                    // 키는 Positioned 가 아니라 여기에 단다.
                    // Positioned 는 RenderObject 를 만들지 않아 크기 조회가 어긋난다
                    key: _viewerKey,
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
                      onWheelTurn: (d) {
                        _step(d);
                        _flashZones();
                      },
                    ),
                  ),
          ),

          // 하이라이트는 책 바로 위에 얹는다
          if (doc != null && !_capture)
            HighlightLayer(
              slice: _slice,
              highlights: highlights,
              drawing: _highlighting,
              colorSlot: _colorSlot,
              onAdd: (r) => unawaited(_addHighlight(r)),
              onTapHighlight: _onTapHighlight,
            ),

          if (_exportProgress != null)
            ExportProgressOverlay(
              done: _exportProgress!.done,
              total: _exportProgress!.total,
              onCancel: () {
                _exportCancel?.cancel();
                _toast('멈추는 중… 이 쪽을 마치고 끝냅니다');
              },
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

          // 좌우 넘김 영역 — 늘 옅게, 넘길 때만 또렷하게.
          // 상주 레일 위에는 그리지 않는다 (화살표가 버튼을 덮는다)
          if (!_capture)
            Positioned(
              left: chrome == ReaderChrome.rail ? ReaderRail.width : 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: PageTurnZones(
                highlighted: _zonesVisible,
                canPrev: _canPrev,
                canNext: _canNext,
              ),
            ),

          // 큰 화면에서는 레일이 상주한다. 폭이 남으니 책을 가리지 않는다
          if (chrome == ReaderChrome.rail && !_capture)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildRail(
                bookmarked: bookmarked,
                highlights: highlights,
                bookmarks: bookmarks,
              ),
            ),

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
              // 버튼을 막지 않는다. 눌렀을 때 사정을 설명하는 편이 낫다 —
              // 비활성 버튼은 왜 안 되는지 알 길이 없다 (techspec §6.5)
              canSearch: true,
              searchDisabledReason: _hasTextLayer ? null : '이 책은 스캔본입니다',
              canCapture: doc != null,
              onBack: () {
                _saveProgress();
                context.go(AppRoutes.library);
              },
              onToggleSearch: () {
                if (!_hasTextLayer) {
                  _offerOcr();
                  return;
                }
                setState(() => _search = !_search);
              },
              onCapture: () => setState(() => _capture = true),
              splitOn: _settings.splitPages,
              onToggleSplit: () => unawaited(_toggleSplit()),
              zoomLocked: _settings.zoomLocked,
              onToggleZoomLock: () => unawaited(_toggleZoomLock()),
              highlighting: _highlighting,
              onToggleHighlight: () => setState(() => _highlighting = !_highlighting),
              bookmarked: bookmarked,
              onToggleBookmark: () => unawaited(_toggleBookmark()),
              onOpenMarks: () => _openMarksSheet(highlights, bookmarks),
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

          if (_highlighting && !_capture)
            HighlightBar(
              colorSlot: _colorSlot,
              onPick: (slot) => setState(() => _colorSlot = slot),
              onDone: () => setState(() => _highlighting = false),
            ),

          if (chrome == ReaderChrome.bars && _chrome && !_capture && !_highlighting)
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
