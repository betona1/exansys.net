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
import '../../data/db/database.dart';
import '../../data/source/book_source.dart';
import '../../core/router.dart';
import '../../core/tokens.dart';
import '../../domain/entities/annotation.dart';
import '../../ui/vave.dart';
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
import '../account/account.dart';
import '../account/widgets/link_sheet.dart';
import '../capture/capture_controller.dart';
import '../help/help_settings.dart';
import '../help/widgets/reader_coach.dart';
import '../ocr/ocr_client.dart';
import '../ocr/ocr_controller.dart';
import '../ocr/ocr_server.dart';
import '../ocr/ocr_settings.dart';
import '../ocr/widgets/ocr_progress_bar.dart';
import '../ocr/widgets/ocr_sheet.dart';
import '../capture/widgets/capture_overlay.dart';
import '../search/indexer.dart';
import '../search/text_box.dart';
import '../search/widgets/match_layer.dart';
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

class _ReaderViewState extends ConsumerState<_ReaderView> with WidgetsBindingObserver {
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

  /// 지금 찾고 있는 말. 쪽 위에 칠하는 데 쓴다
  String _query = '';

  /// 쪽 번호 → 그 쪽의 줄과 좌표. 필요할 때만 읽어 담아 둔다
  final Map<int, List<TextBox>> _boxes = {};

  /// 지금 고른 하이라이트. 옆에 색·메모·휴지통 막대가 뜨고 Del 로 지운다
  int? _selectedHighlight;

  /// 처음 여는 사람에게 조작을 알려 주는 안내. 껐거나 이미 봤으면 뜨지 않는다
  HelpSettings _help = const HelpSettings(readerIntroSeen: true);
  bool _coach = false;

  /// 글자로 바꾸는 중인 진행 상태. null 이면 돌고 있지 않다
  ({int done, int total})? _ocrProgress;
  ExportCancelToken? _ocrCancel;
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
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
    // 처음 열 때 한 번 알려 준다. 영역이 눈에 안 보이면 아무도 쓰지 않는다
    WidgetsBinding.instance.addPostFrameCallback((_) => _flashZones());
  }

  /// 앱을 내리거나 브라우저 탭을 덮을 때 보던 자리를 남긴다.
  ///
  /// 저장은 700ms 미뤄 두는데, 그 사이에 앱이 내려가면 그대로 날아간다.
  /// 폰에서 홈으로 나가는 것도, 웹에서 탭을 닫는 것도 여기로 온다
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    _saveDebounce?.cancel();
    _saveProgress();
  }

  @override
  void dispose() {
    // 서재로 돌아가면 시스템 바를 되돌린다
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.removeObserver(this);
    // **미뤄 둔 저장을 버리지 않는다.** 넘기자마자 나가면 그 쪽을 잃는다
    _saveDebounce?.cancel();
    _saveProgress();
    _zonesTimer?.cancel();
    _doc?.dispose();
    super.dispose();
  }

  // ── 문서 열기 ───────────────────────────────────────────

  Future<void> _open() async {
    final settings = await ref.read(libraryRepositoryProvider).readerSettings(widget.book.id);
    final help = await HelpSettings.load(ref.read(databaseProvider));
    if (mounted) {
      setState(() {
        _settings = settings;
        _help = help;
        _coach = help.shouldShowReaderIntro;
      });
    }

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
      // 쪽을 넘기면 고른 것을 푼다. 안 보이는 것이 골라져 있으면 Del 이 엉뚱하게 먹는다
      _selectedHighlight = null;
    });
    if (_search && _query.isNotEmpty) unawaited(_loadBoxes(_page));
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

  Future<void> _toggleSplit() async {
    final next = !_settings.splitPages;
    await _saveSettings(_settings.copyWith(splitPages: next, splitPrompted: true));
    // 바뀐 것이 눈에 잘 안 띈다 — 특히 한 쪽짜리 책에서는 거의 그대로 보인다.
    // 무엇으로 바뀌었는지 말로 알려 준다
    if (mounted) _toast(next ? '좌우로 나눠 봅니다' : '한 장씩 봅니다');
  }

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

    _showBanner(
      message: '이 책은 한 장에 두 쪽이 들어 있는 것 같습니다.\n좌우로 나눠 한 쪽씩 볼까요?',
      onNo: () => unawaited(_saveSettings(_settings.copyWith(splitPrompted: true))),
      yes: '나눠 보기',
      onYes: () => unawaited(_toggleSplit()),
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

    _showBanner(
      message: '여백이 넓습니다. 잘라내면 글자가 더 커집니다.',
      no: '안 볼래요',
      onNo: () => unawaited(_saveSettings(_settings.copyWith(cropPrompted: true))),
      yes: '맞춰 보기',
      onYes: () => unawaited(_openCropSheet(detectFirst: true)),
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

  /// 고른 하이라이트를 지운다 — 옆에 뜬 휴지통, 또는 Del 키.
  ///
  /// 확인 대화상자로 막지 않는다. 한 번 더 묻는 것보다 **되돌리기**가 낫다 —
  /// 잘못 지웠을 때만 손이 가고, 제대로 지울 때는 걸리적거리지 않는다.
  void _deleteHighlight(Highlight h) {
    setState(() => _selectedHighlight = null);
    final repo = ref.read(annotationRepositoryProvider);
    unawaited(repo.deleteHighlight(h.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('칠한 것을 지웠습니다'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '되돌리기',
            onPressed: () => unawaited(_restoreHighlight(h)),
          ),
        ),
      );
  }

  /// 되돌리기 — 같은 자리·같은 색으로 다시 만든다.
  /// id 는 새로 붙지만 사용자가 보는 것은 그대로다. 메모가 있었으면 함께 살린다
  Future<void> _restoreHighlight(Highlight h) async {
    final repo = ref.read(annotationRepositoryProvider);
    final again = await repo.addHighlight(
      bookId: widget.book.id,
      pageNo: h.pageNo,
      rect: h.rect,
      colorSlot: h.colorSlot,
      documentChecksum: '',
    );
    if (h.note != null) await repo.updateHighlight(again.id, note: h.note);
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
  Future<void> _offerOcr() async {
    final doc = _doc;
    if (doc == null) return;
    // 글자로 바꾸는 일은 서버가 대신 계산한다. 그래서 Pro 기능이다
    if (!await _requirePro(ProFeature.ocr)) return;
    if (_ocrProgress != null) {
      _toast('이미 글자로 바꾸는 중입니다');
      return;
    }

    final db = ref.read(databaseProvider);
    final settings = await OcrSettings.load(db);
    final pending = await OcrController(db).pendingPages(widget.book.id, doc.pages.length);
    if (!mounted) return;

    // 서버 주소가 이미 있으면 설정 화면을 건너뛴다.
    // 쓸 때마다 주소를 다시 보게 하면 그것부터가 일이다
    if (settings.configured) {
      final go = await _confirmOcr(remaining: pending.length);
      if (go == null || !mounted) return;
      if (go == 'settings') {
        await _openOcrSettings(doc, db, settings, pending.length);
        return;
      }
      // 서버가 있으면 맡긴다 — 앱을 켜 둘 필요가 없어진다.
      // "이 쪽만" 은 30초면 끝나므로 앱이 직접 도는 편이 빠르다
      if (settings.useServer && go == 'all') {
        await _runOcrOnServer(settings);
      } else {
        await _runOcr(doc, settings, only: go == 'one' ? [_page] : null);
      }
      return;
    }

    await _openOcrSettings(doc, db, settings, pending.length);
  }

  /// Pro 사용자에게 한 번만 묻는다. 이 쪽만 볼지, 책 전체를 걸어 둘지
  Future<String?> _confirmOcr({required int remaining}) {
    // 실측 기준 반쪽당 약 33초. 두 쪽짜리 스캔본이면 쪽당 두 번 보낸다
    final minutes = (remaining * 2 * 33 / 60).round();
    final estimate = minutes < 60 ? '약 $minutes분' : '약 ${minutes ~/ 60}시간 ${minutes % 60}분';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('글자로 바꿔서 찾을까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 책은 사진으로 된 스캔본이라 지금은 찾을 수 없습니다.\n'
              '서버가 글자로 바꾸면 그때부터 찾기와 복사가 됩니다.',
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              '남은 $remaining쪽 · $estimate\n'
              '중간에 멈춰도 한 쪽씩 저장되니 다음에 이어서 합니다.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'settings'),
            child: const Text('서버 설정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'one'),
            child: Text('이 쪽만 ($_page쪽)'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: const Text('전체 변환'),
          ),
        ],
      ),
    );
  }

  /// 서버 주소를 손보는 화면. 처음이거나 주소를 바꿀 때만 연다
  Future<void> _openOcrSettings(
    PdfDocument doc,
    AppDatabase db,
    OcrSettings settings,
    int remaining,
  ) async {
    final chosen = await showModalBottomSheet<OcrStart>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => OcrSheet(
        settings: settings,
        pageCount: doc.pages.length,
        remaining: remaining,
        currentPage: _page,
      ),
    );
    if (chosen == null || !mounted) return;
    await chosen.settings.save(db);
    await _runOcr(doc, chosen.settings, only: chosen.onlyThisPage ? [_page] : null);
  }

  /// 서버에 맡겨 글자로 바꾼다.
  ///
  /// 올려 두고 나가면 된다. 앱을 껐다 켜도 맡겨 둔 일감에 다시 붙어
  /// 남은 결과만 받아 온다.
  Future<void> _runOcrOnServer(OcrSettings settings) async {
    final bytes = await ref.read(libraryRepositoryProvider).bookBytes(widget.book.id) ??
        await _readBookBytes();
    if (bytes == null) {
      _toast('책 파일을 읽지 못했습니다');
      return;
    }
    final cancel = ExportCancelToken();
    setState(() {
      _ocrCancel = cancel;
      _ocrProgress = (done: 0, total: _pageCount);
    });
    try {
      final stream = OcrController(ref.read(databaseProvider)).runOnServer(
        bookId: widget.book.id,
        bytes: bytes,
        filename: widget.book.title.isEmpty ? 'book.pdf' : '${widget.book.title}.pdf',
        server: OcrServerClient(baseUrl: settings.server, token: settings.serverToken),
        split: _settings.splitPages,
        cancel: cancel,
      );
      await for (final p in stream) {
        if (!mounted) return;
        setState(() => _ocrProgress = (done: p.done, total: p.total));
      }
      if (!mounted) return;
      setState(() => _hasTextLayer = true);
      _toast(cancel.isCancelled
          ? '멈췄습니다. 다음에 이어서 합니다'
          : '글자로 바꿨습니다. 이제 찾을 수 있습니다');
    } on Object catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) {
        setState(() {
          _ocrProgress = null;
          _ocrCancel = null;
        });
      }
    }
  }

  /// 네이티브에서는 경로로 읽는다 (웹은 위에서 바이트를 이미 담아 둔다)
  Future<Uint8List?> _readBookBytes() async {
    try {
      final file = File(widget.book.filePath);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    } on Object {
      return null;
    }
  }

  /// 스캔본을 글자로 바꾼다.
  ///
  /// 화면을 덮지 않는다 — 두 시간이 걸릴 수 있어서 그동안 책을 못 읽으면
  /// 안 된다. 한 쪽 끝날 때마다 DB 에 남으므로 중간에 멈춰도 잃는 것이 없다.
  Future<void> _runOcr(PdfDocument doc, OcrSettings settings, {List<int>? only}) async {
    final cancel = ExportCancelToken();
    setState(() {
      _ocrCancel = cancel;
      _ocrProgress = (done: 0, total: only?.length ?? doc.pages.length);
    });

    final client = OcrClient(endpoint: settings.endpoint, model: settings.model);
    try {
      final stream = OcrController(ref.read(databaseProvider)).run(
        bookId: widget.book.id,
        doc: doc,
        client: client,
        cropFor: _settings.cropFor,
        split: _settings.splitPages,
        cancel: cancel,
        only: only,
      );
      await for (final p in stream) {
        if (!mounted) return;
        setState(() => _ocrProgress = (done: p.done, total: p.total));
      }
      if (!mounted) return;
      setState(() => _hasTextLayer = true);
      if (cancel.isCancelled) {
        _toast('멈췄습니다. 다음에 이어서 합니다');
      } else if (only != null) {
        // 시험이니 결과를 바로 보여 준다. 잘 읽었는지는 눈으로 봐야 안다
        await _showOcrSample(only.first);
      } else {
        _toast('글자로 바꿨습니다. 이제 찾을 수 있습니다');
      }
    } on Object catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) {
        setState(() {
          _ocrProgress = null;
          _ocrCancel = null;
        });
      }
    }
  }

  /// 안내를 닫는다.
  ///
  /// [never] 면 앞으로 아예 띄우지 않는다. 그냥 닫으면 이 책에서는 봤다고만
  /// 적어 둔다 — 두 번 보여 주지 않으면서, 설정에서 다시 켤 길은 남긴다
  void _closeCoach({bool remember = false, bool never = false}) {
    setState(() => _coach = false);
    if (!remember) return;
    final next = _help.copyWith(readerIntroSeen: true, showTips: never ? false : null);
    _help = next;
    unawaited(next.save(ref.read(databaseProvider)));
  }

  /// 시험으로 읽은 한 쪽을 보여 준다.
  ///
  /// "됐습니다"만 띄우면 잘 읽었는지 알 수 없다. 글자를 직접 보고
  /// 나머지를 맡길지 정하게 한다
  Future<void> _showOcrSample(int pageNo) async {
    final db = ref.read(databaseProvider);
    final row = await (db.select(db.pageTexts)
          ..where((t) => t.bookId.equals(widget.book.id))
          ..where((t) => t.pageNo.equals(pageNo)))
        .getSingleOrNull();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$pageNo쪽을 이렇게 읽었습니다'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Text(
              (row?.raw.isNotEmpty ?? false) ? row!.raw : '글자를 찾지 못했습니다',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              unawaited(_offerOcr());
            },
            child: const Text('나머지도 진행'),
          ),
        ],
      ),
    );
  }

  /// 유료 기능인지 확인하고, 아니면 안내한다.
  ///
  /// 막기만 하면 "왜 안 되는지" 를 알 길이 없다. 무엇이 유료이고 왜 그런지,
  /// 무엇을 하면 되는지까지 한 화면에서 보여 준다.
  Future<bool> _requirePro(String feature) async {
    final service = ref.read(accountServiceProvider);
    final account = await service.fetchMe();
    if (account != null && account.can(feature)) return true;
    if (!mounted) return false;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pro 기능입니다'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '스캔본을 글자로 바꾸는 일은 서버가 대신 계산합니다.\n'
              '쪽마다 30초 안팎이 걸리고 그만큼 전기와 장비가 듭니다.\n\n'
              '읽는 데 필요한 기능은 전부 무료입니다.',
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              account == null ? '아직 로그인하지 않으셨습니다.' : '${account.name} 님 · 무료 요금제',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
          if (account == null)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'login'),
              child: const Text('로그인'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'plans'),
              child: const Text('요금 보기'),
            ),
        ],
      ),
    );

    if (action == 'login' && mounted) {
      final linked = await showModalBottomSheet<Account>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => LinkSheet(service: service),
      );
      if (linked != null) {
        ref.invalidate(accountProvider);
        if (linked.can(feature)) return true;
        if (mounted) _toast('${linked.name} 님으로 연결했습니다. Pro 는 아직 아닙니다');
      }
    } else if (action == 'plans' && mounted) {
      _toast('요금 안내는 exansys.net 에 있습니다');
    }
    return false;
  }

  /// 지금 글자를 치고 있는가.
  ///
  /// 읽기 화면은 스페이스·백스페이스·화살표를 쪽 넘김과 삭제에 쓴다.
  /// 그대로 두면 **검색창에서 글자를 지울 수도, 띄어쓸 수도 없다** —
  /// 백스페이스는 하이라이트를 지우려 들고 스페이스는 쪽을 넘긴다.
  /// 입력 중일 때는 단축키가 비켜나야 한다.
  bool get _isTyping {
    final focus = FocusManager.instance.primaryFocus;
    final widget = focus?.context?.widget;
    return widget is EditableText;
  }

  /// 지금 쪽의 줄·좌표를 읽어 둔다. 한 번 읽으면 담아 두고 다시 읽지 않는다
  Future<void> _loadBoxes(int pageNo) async {
    if (_boxes.containsKey(pageNo)) return;
    final db = ref.read(databaseProvider);
    final row = await (db.select(db.pageTexts)
          ..where((t) => t.bookId.equals(widget.book.id))
          ..where((t) => t.pageNo.equals(pageNo)))
        .getSingleOrNull();
    if (!mounted) return;
    setState(() => _boxes[pageNo] = TextBox.parse(row?.boxes));
  }

  /// 권유 배너. **반드시 스스로 걷힌다.**
  ///
  /// 예전에는 배너마다 따로 만들었는데 두 곳에 자동 닫힘을 빠뜨렸다.
  /// 그러면 누르기 전까지 화면 위를 계속 차지한다 — 가로모드에서는
  /// 그 자리가 특히 아깝다. 한곳에서 만들어 빠뜨릴 수 없게 한다.
  void _showBanner({
    required String message,
    required String yes,
    required VoidCallback onYes,
    String no = '아니요',
    VoidCallback? onNo,
    Duration life = const Duration(seconds: 8),
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                messenger.clearMaterialBanners();
                onNo?.call();
              },
              child: Text(no),
            ),
            FilledButton(
              onPressed: () {
                messenger.clearMaterialBanners();
                onYes();
              },
              child: Text(yes),
            ),
          ],
        ),
      );
    Future<void>.delayed(life, () {
      if (mounted) messenger.clearMaterialBanners();
    });
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
        // 고른 하이라이트 지우기. 맥 키보드에는 Del 이 없어 Backspace 도 받는다
        SingleActivator(LogicalKeyboardKey.delete): _DeleteMarkIntent(),
        SingleActivator(LogicalKeyboardKey.backspace): _DeleteMarkIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _DeselectIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DeleteMarkIntent: CallbackAction<_DeleteMarkIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              final id = _selectedHighlight;
              if (id == null) return null;
              final list = ref.read(highlightsProvider(widget.book.id)).valueOrNull;
              final h = list?.where((e) => e.id == id).firstOrNull;
              if (h != null) _deleteHighlight(h);
              return null;
            },
          ),
          _DeselectIntent: CallbackAction<_DeselectIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              if (_selectedHighlight != null) {
                setState(() => _selectedHighlight = null);
              }
              return null;
            },
          ),
          _NextPageIntent: CallbackAction<_NextPageIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              _step(1);
              _flashZones();
              return null;
            },
          ),
          _PrevPageIntent: CallbackAction<_PrevPageIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              _step(-1);
              _flashZones();
              return null;
            },
          ),
          _FirstPageIntent: CallbackAction<_FirstPageIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              _goToPage(1);
              return null;
            },
          ),
          _LastPageIntent: CallbackAction<_LastPageIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              _goToPage(_pageCount);
              return null;
            },
          ),
          _FindIntent: CallbackAction<_FindIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
              if (_hasTextLayer) setState(() => _search = true);
              return null;
            },
          ),
          _ToggleChromeIntent: CallbackAction<_ToggleChromeIntent>(
            onInvoke: (_) {
              if (_isTyping) return null;
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
    // 상단바와 같다 — 막지 않고, 눌렀을 때 사정을 설명하고 OCR 을 권한다.
    // 비활성 버튼은 왜 안 되는지 알 길이 없다
    canSearch: true,
    searchDisabledReason: _hasTextLayer ? null : '이 책은 스캔본입니다',
    viewChanged: _settings.splitPages ||
        _settings.cropEnabled ||
        _settings.theme == ReadingTheme.dark,
    onBack: () {
      _saveProgress();
      context.go(AppRoutes.library);
    },
    onSearch: () {
      if (!_hasTextLayer) {
        unawaited(_offerOcr());
        return;
      }
      setState(() => _search = true);
    },
    onViewSheet: _openViewSheet,
    onCapture: () => setState(() => _capture = true),
    // 글자가 없는 책에서만 보여 준다. 있는 책에는 필요 없는 단추다
    showOcr: !_hasTextLayer,
    onOcr: () => unawaited(_offerOcr()),
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

          // 찾은 줄을 형광펜처럼 칠한다. 좌표가 없는 책에서는 아무것도 안 그린다
          if (doc != null && _search && _query.isNotEmpty)
            MatchLayer(
              slice: _slice,
              boxes: _boxes,
              query: _query,
              currentPage: _page,
            ),

          // 하이라이트는 책 바로 위에 얹는다
          if (doc != null && !_capture)
            HighlightLayer(
              slice: _slice,
              highlights: highlights,
              drawing: _highlighting,
              colorSlot: _colorSlot,
              selectedId: _selectedHighlight,
              onAdd: (r) => unawaited(_addHighlight(r)),
              onSelect: (h) => setState(() => _selectedHighlight = h?.id),
              onRecolor: (h, slot) => unawaited(
                ref.read(annotationRepositoryProvider).updateHighlight(h.id, colorSlot: slot),
              ),
              onNote: (h) => unawaited(_editNote(h)),
              onDelete: _deleteHighlight,
            ),

          if (_coach)
            ReaderCoach(
              onClose: () => _closeCoach(remember: true),
              onNeverShow: () => _closeCoach(remember: true, never: true),
            ),

          if (_ocrProgress != null)
            OcrProgressBar(
              done: _ocrProgress!.done,
              total: _ocrProgress!.total,
              onStop: () {
                _ocrCancel?.cancel();
                _toast('이 쪽을 마치고 멈춥니다');
              },
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
                  unawaited(_offerOcr());
                  return;
                }
                setState(() => _search = !_search);
              },
              onCapture: () => setState(() => _capture = true),
              showOcr: !_hasTextLayer,
              onOcr: () => unawaited(_offerOcr()),
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
                      // **검색바를 닫지 않는다.** 닫아 버리면 다음 결과로
                      // 가려고 돋보기부터 다시 눌러야 한다
                      onGoToPage: _goToPage,
                      onQueryChanged: (q) {
                        setState(() => _query = q);
                        unawaited(_loadBoxes(_page));
                      },
                    )
                  : null,
            ),

          // **가로모드·태블릿에는 상단바가 없다.** 검색창이 상단바에만 붙어
          // 있어서 돋보기를 눌러도 아무 일이 일어나지 않았다. 따로 얹는다
          if (_search && chrome != ReaderChrome.bars)
            Positioned(
              top: 0,
              left: chrome == ReaderChrome.rail ? ReaderRail.width : 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
                  child: InBookSearchSheet(
                    bookId: widget.book.id,
                    onClose: () => setState(() => _search = false),
                    onGoToPage: _goToPage,
                    onQueryChanged: (q) {
                      setState(() => _query = q);
                      unawaited(_loadBoxes(_page));
                    },
                  ),
                ),
              ),
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
                    onGoToPage: _goToPage,
                    onQueryChanged: (q) {
                      setState(() => _query = q);
                      unawaited(_loadBoxes(_page));
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

class _DeleteMarkIntent extends Intent {
  const _DeleteMarkIntent();
}

class _DeselectIntent extends Intent {
  const _DeselectIntent();
}

/// 문서를 열지 못했을 때 (techspec §17 — 무엇이 실패 / 원인 / 다음 행동)
class ReaderError extends StatelessWidget {
  const ReaderError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VaveErrorView(
        title: '이 PDF 를 열지 못했습니다',
        message: message,
        actionLabel: '서재로',
        onAction: () => context.go(AppRoutes.library),
      ),
    );
  }
}
