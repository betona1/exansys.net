import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/crop_rect.dart';
import '../../../domain/entities/fit_mode.dart';
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
    required this.onSlice,
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

  /// 지금 보이는 조각의 좌표 정보. 캡처가 화면 좌표를 쪽 좌표로 옮기는 데 쓴다
  final ValueChanged<SliceMapper> onSlice;

  @override
  State<RenderedPageView> createState() => RenderedPageViewState();
}

class RenderedPageViewState extends State<RenderedPageView> {
  // 컨트롤러는 하나로 끝까지 간다.
  // 모드가 바뀔 때마다 새로 만들어 갈아 끼우면, 아직 붙어 있는 것을 버리게 되어
  // 화면이 옛 위치에 멈춘 채 아무 일도 일어나지 않은 것처럼 보인다.
  late final PageController _controller = PageController(initialPage: widget.initialView);

  /// 확대 중인가. 확대했을 때 좌우로 밀면 쪽이 넘어가 버리면 안 된다 —
  /// 그때는 밀기가 그림 이동이어야 한다
  bool _zoomed = false;

  /// 마지막 확대·이동 상태.
  ///
  /// 쪽마다 변환이 따로 놀면 넘길 때마다 배율과 위치가 원래대로 돌아간다.
  /// 확대해 놓고 읽던 사람은 넘길 때마다 다시 맞춰야 한다.
  /// 여기 담아 두었다가 다음 쪽에 그대로 물려준다.
  Matrix4 _lastTransform = Matrix4.identity();

  int get _perPage => widget.split ? 2 : 1;
  int get viewCount => widget.document.pages.length * _perPage;

  @override
  void didUpdateWidget(RenderedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 분할을 켜고 끄면 한 쪽이 한 칸이 되었다가 두 칸이 된다.
    // 보고 있던 **쪽**을 유지해야 하므로 위치를 다시 계산해 옮긴다.
    if (oldWidget.split != widget.split) {
      final current = _controller.hasClients
          ? (_controller.page?.round() ?? widget.initialView)
          : widget.initialView;
      final pageIndex = current ~/ (oldWidget.split ? 2 : 1);
      final target = (pageIndex * _perPage).clamp(0, viewCount - 1);
      // 이 프레임에는 아직 옛 itemCount 로 그려져 있다. 다음 프레임에 옮긴다
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(target);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 지금 화면의 확대·이동. 잠금 버튼이 이 값을 굳힌다
  Matrix4 get currentTransform => _lastTransform;

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
          initialTransform: widget.settings.zoomLocked
              // 잠갔으면 저장해 둔 배율·좌우 위치로 시작한다.
              // 세로는 0 에서 — 새 쪽은 위부터 읽는다
              ? (Matrix4.identity()
                ..translateByDouble(widget.settings.panX, 0, 0, 1)
                ..scaleByDouble(
                  widget.settings.zoomLevel,
                  widget.settings.zoomLevel,
                  1,
                  1,
                ))
              : _lastTransform,
          locked: widget.settings.zoomLocked,
          onTransformChanged: (m) => _lastTransform = m,
          onSlice: widget.onSlice,
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
    required this.onSlice,
    required this.initialTransform,
    required this.onTransformChanged,
    required this.locked,
    this.half,
  });

  final PdfPage page;
  final CropRect crop;
  final ReaderSettings settings;

  /// 확대 여부가 바뀌면 알려 준다 (부모가 쪽 넘김을 막는다)
  final ValueChanged<bool> onZoomChanged;

  /// 이 조각의 좌표 정보를 위로 올린다
  final ValueChanged<SliceMapper> onSlice;

  /// 앞 쪽에서 쓰던 확대·이동. 넘겨도 배율과 위치가 이어지게 한다
  final Matrix4 initialTransform;
  final ValueChanged<Matrix4> onTransformChanged;

  /// 배율과 좌우 위치를 잠갔는가. 세로 밀기는 그대로 둔다
  final bool locked;

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
    // 앞 쪽에서 쓰던 배율·위치를 그대로 물려받는다
    _transform.value = widget.initialTransform.clone();
    _zoomedIn = _transform.value.getMaxScaleOnAxis() > 1.01;
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

  bool _zoomedIn = false;

  void _onTransform() {
    // 배율이 1 보다 크면 확대 중으로 본다
    final z = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (z != _zoomedIn && mounted) setState(() => _zoomedIn = z);
    widget.onZoomChanged(z);
    widget.onTransformChanged(_transform.value.clone());
    _publishSlice();
  }

  /// 지금 그려 놓은 조각이 쪽의 어디인지, 화면 어디에 놓였는지 알린다.
  /// 캡처는 이 정보로 화면에서 고른 사각형을 쪽 좌표로 되돌린다.
  void _publishSlice() {
    final img = _image;
    final area = _sliceArea;
    final box = _renderedFor;
    if (img == null || area == null || box == null) return;

    // FittedBox 는 좌측 위 정렬이므로 원점은 (0,0) 이다.
    // 맞춤 모드에 따라 어느 변이 화면을 채우는지가 달라진다
    final aspect = img.width / img.height;
    final byWidth = box.width / aspect;
    final byHeight = box.height * aspect;
    final (drawnWidth, drawnHeight) = switch (widget.settings.fitMode) {
      FitMode.width => (box.width, byWidth),
      FitMode.height => (byHeight, box.height),
      FitMode.page => byWidth <= box.height
          ? (box.width, byWidth)
          : (byHeight, box.height),
    };

    widget.onSlice(
      SliceMapper(
        pageNumber: widget.page.pageNumber,
        pageRect: area,
        imageRect: Rect.fromLTWH(0, 0, drawnWidth, drawnHeight),
        transform: _transform.value.clone(),
      ),
    );
  }

  /// 지금 그린 영역이 쪽의 어디인지 (PDF 포인트)
  Rect? _sliceArea;

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

  @override
  void didUpdateWidget(_PageSlice old) {
    super.didUpdateWidget(old);
    // 잠금을 켜면 저장해 둔 틀로 곧바로 맞춘다
    if (!old.locked && widget.locked) {
      _transform.value = widget.initialTransform.clone();
    }
  }

  bool _needsRender(Size target) {
    if (_image == null) return true;
    final prev = _renderedFor;
    if (prev == null) return true;
    // 맞춤 기준이 되는 변이 바뀌면 다시 그린다.
    // 조금씩 바뀔 때마다 다시 그리면 스크롤이 끊기니 여유를 둔다
    final (now, before) = widget.settings.fitMode == FitMode.height
        ? (target.height, prev.height)
        : (target.width, prev.width);
    return (now - before).abs() > before * 0.15;
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
      _sliceArea = Rect.fromLTWH(x, y, w, h);

      // 맞춤 모드대로 배율을 잡는다.
      //
      // 폰 세로 화면에서 세로 맞춤을 쓰면 **좌우가 잘린다** — 쪽이 화면보다
      // 가로로 길기 때문이다. 그래서 기본은 폭 맞춤이고, 세로로 넘치는 부분은
      // 밀어서 읽는다.
      final byWidth = target.width / w;
      final byHeight = target.height / h;
      final fit = switch (widget.settings.fitMode) {
        FitMode.width => byWidth,
        FitMode.height => byHeight,
        FitMode.page => byWidth < byHeight ? byWidth : byHeight,
      };
      final scale = fit * dpr;
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
        _publishSlice();
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

        // 맞춤 모드대로 그린다. **좌측 위부터** 보여 준다 —
        // 가운데 정렬로 두면 폭이 넘칠 때 좌우가 똑같이 잘려 첫 글자를 놓친다
        final fitBox = switch (widget.settings.fitMode) {
          FitMode.width => BoxFit.fitWidth,
          FitMode.height => BoxFit.fitHeight,
          FitMode.page => BoxFit.contain,
        };

        return GestureDetector(
          onDoubleTapDown: _toggleZoom,
          onDoubleTap: () {},
          child: InteractiveViewer(
            transformationController: _transform,
            maxScale: 6,
            minScale: 1,
            // 잠갔으면 배율을 바꾸지 못하게 한다
            scaleEnabled: !widget.locked,
            // 잠갔으면 세로로만. 확대하지 않았을 때도 세로로만 —
            // 좌우로도 밀리면 PageView 의 쪽 넘김과 싸운다
            panAxis: (widget.locked || !_zoomedIn) ? PanAxis.vertical : PanAxis.free,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            clipBehavior: Clip.hardEdge,
            child: SizedBox.expand(
              child: FittedBox(
                fit: fitBox,
                alignment: Alignment.topLeft,
                child: RawImage(image: _image, filterQuality: FilterQuality.medium),
              ),
            ),
          ),
        );
      },
    );
  }
}


/// 화면에서 고른 사각형을 쪽 좌표로 되돌리는 데 필요한 정보.
///
/// 직접 그리는 뷰어에는 pdfrx 의 `globalToDocument` 같은 것이 없다.
/// 지금 보이는 조각이 쪽의 어느 부분인지(pageRect), 그것이 화면 어디에 어떤 크기로
/// 놓였는지(imageRect + transform)를 알면 되돌릴 수 있다.
class SliceMapper {
  const SliceMapper({
    required this.pageNumber,
    required this.pageRect,
    required this.imageRect,
    required this.transform,
  });

  /// 1부터
  final int pageNumber;

  /// 이 조각이 차지하는 쪽 안의 영역 (PDF 포인트)
  final Rect pageRect;

  /// 변환 전 화면에 그려진 자리
  final Rect imageRect;

  /// 확대·이동 변환
  final Matrix4 transform;

  /// 쪽 좌표 → 화면(조각 로컬) 좌표. 하이라이트를 제자리에 그리는 데 쓴다.
  /// 이 조각에 걸치지 않으면 null
  Rect? toLocalRect(Rect page) {
    final inter = page.intersect(pageRect);
    if (inter.width <= 0 || inter.height <= 0) return null;

    final fx = (inter.left - pageRect.left) / pageRect.width;
    final fy = (inter.top - pageRect.top) / pageRect.height;
    final fw = inter.width / pageRect.width;
    final fh = inter.height / pageRect.height;

    final drawn = Rect.fromLTWH(
      imageRect.left + fx * imageRect.width,
      imageRect.top + fy * imageRect.height,
      fw * imageRect.width,
      fh * imageRect.height,
    );
    return MatrixUtils.transformRect(transform, drawn);
  }

  /// 화면(조각 로컬) 좌표의 사각형 → 쪽 좌표. 조각 밖이면 잘라 낸다
  Rect? toPageRect(Rect local) {
    final inv = Matrix4.tryInvert(transform);
    if (inv == null) return null;

    // Matrix4 의 2차원 점 변환. vector_math 를 직접 의존하지 않으려고 손으로 푼다
    Offset back(Offset p) => MatrixUtils.transformPoint(inv, p);

    final a = back(local.topLeft);
    final b = back(local.bottomRight);
    final drawn = Rect.fromPoints(a, b).intersect(imageRect);
    if (drawn.width <= 0 || drawn.height <= 0) return null;

    final fx = (drawn.left - imageRect.left) / imageRect.width;
    final fy = (drawn.top - imageRect.top) / imageRect.height;
    final fw = drawn.width / imageRect.width;
    final fh = drawn.height / imageRect.height;

    return Rect.fromLTWH(
      pageRect.left + fx * pageRect.width,
      pageRect.top + fy * pageRect.height,
      fw * pageRect.width,
      fh * pageRect.height,
    );
  }
}
