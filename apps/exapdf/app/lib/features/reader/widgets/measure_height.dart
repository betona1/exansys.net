import 'package:flutter/material.dart';

/// 자식이 실제로 차지한 높이를 재서 알려 준다.
///
/// 읽기 화면의 위아래 바는 높이가 고정이 아니다 — 아이콘이 한 줄에 안 들어가면
/// 두 줄이 되고, 검색을 열면 패널이 더 붙고, 기기마다 안전영역도 다르다.
/// 상수로 어림잡으면 그만큼 책이 덮이거나 빈 띠가 남는다. 그래서 재서 쓴다.
///
/// 값이 실제로 바뀔 때만 알린다. 매 프레임 알리면 부모가 계속 다시 그린다.
class MeasureHeight extends StatefulWidget {
  const MeasureHeight({super.key, required this.onHeight, required this.child});

  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  State<MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<MeasureHeight> {
  double _last = -1;

  void _report(Duration _) {
    if (!mounted) return;
    final h = context.size?.height;
    // 소수점 아래로 흔들리는 값에 반응하면 그리기가 끝나지 않는다
    if (h == null || (h - _last).abs() < 0.5) return;
    _last = h;
    widget.onHeight(h);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_report);
    return widget.child;
  }
}
