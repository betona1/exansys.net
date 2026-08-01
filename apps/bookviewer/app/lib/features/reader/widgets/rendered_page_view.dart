import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/crop_rect.dart';
import '../../../domain/entities/reader_settings.dart';
import '../page_tint.dart';

/// 쪽을 직접 그려 보여 주는 뷰어.
///
/// 두 가지를 위해 필요하다. `PdfViewer` 로는 둘 다 안 된다.
///
/// 1. **좌우 나눠 보기** — 책을 펼친 채 스캔하면 한 장에 두 쪽이 들어간다.
///    폰에서 그대로 보면 글자가 절반 크기가 되어 읽을 수 없다
/// 2. **여백 크롭** — 스캔 여백을 잘라 내면 같은 화면에서 글자가 훨씬 커진다
///
/// 잘라 내는 순서는 **크롭 먼저, 그다음 반 나누기**다. 반대로 하면 바깥 여백만
/// 잘리고 가운데 제본 여백이 남는다.
///
/// 대가: 이 모드에서는 **글자 선택·검색 하이라이트가 되지 않는다.**
/// 스캔본은 텍스트 레이어가 없어 손해가 거의 없지만, 텍스트 PDF 에서는
/// 기본으로 켜지 않는다.
class RenderedPageView extends StatefulWidget {
  const RenderedPageView({
    super.key,
    required this.document,
    required this.initialView,
    required this.onViewChanged,
    required this.cropFor,
    required this.settings,
    this.split = false,
    this.rightToLeft = false,
  });

  final PdfDocument document;

  /// 보기 번호 (0부터). 분할이면 한 쪽에 둘, 아니면 한 쪽에 하나
  final int initialView;
  final ValueChanged<int> onViewChanged;

  /// 쪽 번호(1부터) → 잘라 낼 여백
  final CropRect Function(int pageNumber) cropFor;

  /// 다크 리딩·밝기·대비를 여기서 읽는다
  final ReaderSettings settings;

  final bool split;

  /// 오른쪽 반쪽을 먼저 읽는 책(세로쓰기 등)
  final bool rightToLeft;

  @override
  State<RenderedPageView> createState() => RenderedPageViewState();
}

class RenderedPageViewState extends State<RenderedPageView> {
  late PageController _controller = PageController(initialPage: widget.initialView);

  /// 확대 중인가. 확대했을 때 좌우로 밀면 쪽이 넘어가 버리면 안 된다 —
  /// 그때는 밀기가 그림 이동이어야 한다
  bool _zoomed = false;

  int get _perPage => widget.split ? 2 : 1;
  int get viewCount => widget.document.pages.length * _perPage;

  @override
  void didUpdateWidget(RenderedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    // 분할을 켜고 끄면 보기 개수가 달라진다. 컨트롤러를 새로 만들지 않으면
    // 엉뚱한 위치로 튄다
    if (old.split != widget.split) {
      final page = _controller.hasClients ? _controller.page?.round() ?? 0 : widget.initialView;
      final pageIndex = page ~/ (old.split ? 2 : 1);
      _controller.dispose();
      _controller = PageController(initialPage: (pageIndex * _perPage).clamp(0, viewCount - 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 바깥(슬라이더·이전/다음 버튼)에서 특정 보기로 보낸다
  void goToView(int view) {
    if (!_controller.hasClients) return;
    _controller.jumpToPage(view.clamp(0, viewCount - 1));
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: viewCount,
      // 확대 중에는 쪽 넘김을 막는다. 밀기는 그림을 옮기는 데 쓴다
      physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
      onPageChanged: widget.onViewChanged,
      itemBuilder: (context, view) {
        final pageIndex = view ~/ _perPage;
        final page = widget.document.pages[pageIndex];
        final crop = widget.cropFor(page.pageNumber);

        int? half;
        if (widget.split) {
          final isLeft = widget.rightToLeft ? view.isOdd : view.isEven;
          half = isLeft ? 0 : 1;
        }
        return _PageSlice(
          key: ValueKey('\$view/\${crop.hashCode}/\${widget.settings.tintKey}'),
          page: page,
          crop: crop,
          settings: widget.settings,
          half: half,
          onZoomChanged: (z) {
            if (z != _zoomed && mounted) setState(() => _zoomed = z);
          },
        );
      },
    );
  }
}

/// 쪽의 한 조각(크롭 적용, 필요하면 좌·우 반쪽)을 그린다.
class _PageSlice extends StatefulWidget {
  const _PageSlice({
    super.key,
    required this.page,
    required this.crop,
    required this.settings,
    required this.onZoomChanged,
    this.half,
  });

  final PdfPage page;
  final CropRect crop;
  final ReaderSettings settings;

  /// 확대 여부가 바뀌면 알려 준다 (부모가 쪽 넘김을 막는다)
  final ValueChanged<bool> onZoomChanged;

  /// null 이면 통째로, 0 이면 왼쪽 반, 1 이면 오른쪽 반
  final int? half;

  @override
  State<_PageSlice> createState() => _PageSliceState();
}

class _PageSliceState extends State<_PageSlice> {
  final _transform = TransformationController();
  ui.Image? _image;
  Size? _renderedFor;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    _image?.dispose();
    super.dispose();
  }

  void _onTransform() {
    // 배율이 1 보다 크면 확대 중으로 본다
    widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01);
  }

  /// 두 번 두드리면 확대/원래대로. 폰에서 핀치보다 빠르다
  void _toggleZoom(TapDownDetails d) {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    final p = d.localPosition;
    _transform.value = Matrix4.identity()
      ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  bool _needsRender(Size target) {
    if (_image == null) return true;
    final prev = _renderedFor;
    if (prev == null) return true;
    // 세로를 기준으로 그리므로 세로가 바뀔 때 다시 그린다.
    // 조금씩 바뀔 때마다 다시 그리면 스크롤이 끊기니 여유를 둔다
    return (target.height - prev.height).abs() > prev.height * 0.15;
  }

  Future<void> _render(Size target) async {
    if (_loading) return;
    _loading = true;
    try {
      final page = widget.page;
      final dpr = MediaQuery.devicePixelRatioOf(context);

      // 1) 크롭 먼저 — 스캔 여백을 걷어 낸다
      final area = widget.crop.toPageRect(page.width, page.height);
      var x = area.x;
      var w = area.w;

      // 2) 그다음 반 나누기 — 남은 영역을 좌·우로
      if (widget.half != null) {
        w = area.w / 2;
        if (widget.half == 1) x = area.x + w;
      }
      final y = area.y;
      final h = area.h;

      // **세로를 화면에 꽉 맞춘다.** 책은 한 쪽이 통째로 보여야 읽힌다
      final scale = (target.height / h) * dpr;
      final full = Size(page.width * scale, page.height * scale);

      final img = await page.render(
        x: (x * scale).round(),
        y: (y * scale).round(),
        width: (w * scale).round().clamp(1, 20000),
        height: (h * scale).round().clamp(1, 20000),
        fullWidth: full.width,
        fullHeight: full.height,
        backgroundColor: 0xFFFFFFFF,
      );
      if (img == null) throw Exception('쪽을 그리지 못했습니다');

      // 다크 리딩·밝기·대비는 픽셀에서 직접 처리한다.
      // 색 행렬만으로는 "사진은 남기고 글자만 뒤집기"를 할 수 없다 (page_tint.dart)
      PdfImage source = img;
      PdfImage? tinted;
      try {
        if (widget.settings.tintsPage) {
          final bytes = await compute(
            tintPage,
            TintRequest(
              pixels: Uint8List.fromList(img.pixels),
              mode: widget.settings.darkImageMode,
              brightness: widget.settings.brightness,
              contrast: widget.settings.contrast,
            ),
          );
          tinted = PdfImage.createFromBgraData(bytes, width: img.width, height: img.height);
          source = tinted;
        }

        final ui.Image decoded;
        try {
          decoded = await source.createImage();
        } finally {
          tinted?.dispose();
        }
        if (!mounted) {
          decoded.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = decoded;
          _renderedFor = target;
          _error = null;
        });
      } finally {
        img.dispose();
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final target = Size(constraints.maxWidth, constraints.maxHeight);
        if (_needsRender(target)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _render(target);
          });
        }

        if (_error != null) {
          return Center(
            child: Text('이 쪽을 그리지 못했습니다', style: Theme.of(context).textTheme.bodySmall),
          );
        }
        if (_image == null) {
          // 스피너 대신 자리를 잡아 둔다 — 레이아웃이 튀지 않게 (techspec §17)
          return const ColoredBox(color: AppTokens.slot);
        }

        // 세로를 꽉 채운다. 확대하면 그 안에서 밀어 본다 (핀치·더블탭)
        return GestureDetector(
          onDoubleTapDown: _toggleZoom,
          onDoubleTap: () {},
          child: InteractiveViewer(
            transformationController: _transform,
            maxScale: 6,
            // 확대했을 때 화면 밖으로 밀어낼 수 있어야 아래쪽 글도 본다
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.hardEdge,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: RawImage(image: _image, filterQuality: FilterQuality.medium),
              ),
            ),
          ),
        );
      },
    );
  }
}
