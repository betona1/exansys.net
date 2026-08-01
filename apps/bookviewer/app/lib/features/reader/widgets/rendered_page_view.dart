import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/crop_rect.dart';

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
    this.split = false,
    this.rightToLeft = false,
  });

  final PdfDocument document;

  /// 보기 번호 (0부터). 분할이면 한 쪽에 둘, 아니면 한 쪽에 하나
  final int initialView;
  final ValueChanged<int> onViewChanged;

  /// 쪽 번호(1부터) → 잘라 낼 여백
  final CropRect Function(int pageNumber) cropFor;

  final bool split;

  /// 오른쪽 반쪽을 먼저 읽는 책(세로쓰기 등)
  final bool rightToLeft;

  @override
  State<RenderedPageView> createState() => RenderedPageViewState();
}

class RenderedPageViewState extends State<RenderedPageView> {
  late PageController _controller = PageController(initialPage: widget.initialView);

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
          key: ValueKey('$view/${crop.hashCode}'),
          page: page,
          crop: crop,
          half: half,
        );
      },
    );
  }
}

/// 쪽의 한 조각(크롭 적용, 필요하면 좌·우 반쪽)을 그린다.
class _PageSlice extends StatefulWidget {
  const _PageSlice({super.key, required this.page, required this.crop, this.half});

  final PdfPage page;
  final CropRect crop;

  /// null 이면 통째로, 0 이면 왼쪽 반, 1 이면 오른쪽 반
  final int? half;

  @override
  State<_PageSlice> createState() => _PageSliceState();
}

class _PageSliceState extends State<_PageSlice> {
  ui.Image? _image;
  Size? _renderedFor;
  bool _loading = false;
  Object? _error;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
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

      final ui.Image decoded;
      try {
        decoded = await img.createImage();
      } finally {
        img.dispose();
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

        // 세로를 꽉 채우고, 가로가 넘치면 좌우로 밀어 본다
        return InteractiveViewer(
          maxScale: 5,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: RawImage(image: _image, filterQuality: FilterQuality.medium),
            ),
          ),
        );
      },
    );
  }
}
