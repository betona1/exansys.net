import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/tokens.dart';
import '../../../domain/entities/crop_rect.dart';
import 'crop_preview.dart';

/// 여백 크롭 조정 시트 (techspec §6.4 `btn.crop`).
///
/// **수동 조정이 없으면 안 된다.** 자동 감지는 반드시 틀리는 쪽이 나오고,
/// 그때 "페이지 번호가 잘렸다"는 불만으로 직행한다 (SPEC §2.1).
///
/// 홀·짝을 따로 조정한다. 제본 여백이 좌우로 번갈아 나오기 때문이다.
class CropSheet extends StatefulWidget {
  const CropSheet({
    super.key,
    required this.document,
    required this.oddPage,
    required this.evenPage,
    required this.initialOdd,
    required this.initialEven,
    required this.enabled,
  });

  final PdfDocument document;

  /// 미리보기에 쓸 홀수·짝수 쪽 번호
  final int oddPage;
  final int evenPage;

  final CropRect initialOdd;
  final CropRect initialEven;
  final bool enabled;

  @override
  State<CropSheet> createState() => _CropSheetState();
}

/// 시트가 돌려주는 결과
class CropSheetResult {
  const CropSheetResult({required this.enabled, required this.odd, required this.even});

  final bool enabled;
  final CropRect odd;
  final CropRect even;
}

class _CropSheetState extends State<CropSheet> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  late var _odd = widget.initialOdd;
  late var _even = widget.initialEven;
  late var _enabled = widget.enabled;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  CropRect get _current => _tabs.index == 0 ? _odd : _even;
  int get _currentPage => _tabs.index == 0 ? widget.oddPage : widget.evenPage;

  void _update(CropRect next) {
    setState(() {
      if (_tabs.index == 0) {
        _odd = next;
      } else {
        _even = next;
      }
    });
  }

  /// 한쪽을 반대쪽에 좌우 뒤집어 복사한다.
  /// 제본 여백은 좌우가 대칭이라 이렇게 하면 손이 절반으로 준다
  void _mirrorToOther() {
    final from = _current;
    final mirrored = CropRect(
      left: from.right,
      top: from.top,
      right: from.left,
      bottom: from.bottom,
    );
    setState(() {
      if (_tabs.index == 0) {
        _even = mirrored;
      } else {
        _odd = mirrored;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space4,
          AppTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('여백 잘라내기', style: t.textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
            Text(
              '스캔 여백을 걷어 내면 같은 화면에서 글자가 커집니다.\n홀수·짝수 쪽은 제본 여백이 반대라 따로 맞춥니다.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space3),
            TabBar(
              controller: _tabs,
              onTap: (_) => setState(() {}),
              tabs: const [Tab(text: '홀수 쪽'), Tab(text: '짝수 쪽')],
            ),
            const SizedBox(height: AppTokens.space3),
            SizedBox(
              height: 200,
              child: CropPreview(
                document: widget.document,
                pageNumber: _currentPage,
                crop: _current,
                showGuides: _enabled,
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            _Slider(
              label: '왼쪽',
              value: _current.left,
              onChanged: (v) => _update(_current.copyWith(left: v)),
            ),
            _Slider(
              label: '오른쪽',
              value: _current.right,
              onChanged: (v) => _update(_current.copyWith(right: v)),
            ),
            _Slider(
              label: '위',
              value: _current.top,
              onChanged: (v) => _update(_current.copyWith(top: v)),
            ),
            _Slider(
              label: '아래',
              value: _current.bottom,
              onChanged: (v) => _update(_current.copyWith(bottom: v)),
            ),
            const SizedBox(height: AppTokens.space2),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _mirrorToOther,
                  icon: const Icon(Icons.flip, size: 18),
                  label: Text(_tabs.index == 0 ? '짝수 쪽에 좌우 반전 복사' : '홀수 쪽에 좌우 반전 복사'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _update(CropRect.none),
                  child: const Text('되돌리기'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      CropSheetResult(enabled: _enabled, odd: _odd, even: _even),
                    ),
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 0.45),
            max: 0.45,
            divisions: 90,
            label: '${(value * 100).toStringAsFixed(1)}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
