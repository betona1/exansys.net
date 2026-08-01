import 'package:flutter/material.dart';

import '../../../core/reading_filter.dart';
import '../../../core/tokens.dart';
import '../../../domain/entities/reader_settings.dart';
import '../../../domain/entities/reading_theme.dart';

/// 리딩 테마 시트 (techspec §8).
///
/// 다크에서 사진을 어떻게 다룰지가 핵심이다. 단순 반전은 사진을 네거티브로
/// 만들어 버리는데, 조사한 뷰어들의 **최대 불만 지점**이자 우리 차별화다.
class ThemeSheet extends StatefulWidget {
  const ThemeSheet({super.key, required this.settings, required this.onChanged});

  final ReaderSettings settings;

  /// 고르는 즉시 뒤 화면에 반영한다. 시트를 닫아야 결과가 보이면 고를 수가 없다
  final ValueChanged<ReaderSettings> onChanged;

  @override
  State<ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<ThemeSheet> {
  late var _s = widget.settings;

  void _set(ReaderSettings next) {
    setState(() => _s = next);
    // 시트를 열어 둔 채로 결과가 바로 보여야 고를 수 있다
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = _s.theme == ReadingTheme.dark;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
              Text('테마', style: t.textTheme.titleMedium),
              const SizedBox(height: AppTokens.space3),
              SegmentedButton<ReadingTheme>(
                segments: const [
                  ButtonSegment(value: ReadingTheme.light, label: Text('라이트')),
                  ButtonSegment(value: ReadingTheme.dark, label: Text('다크')),
                  ButtonSegment(value: ReadingTheme.sepia, label: Text('세피아')),
                ],
                selected: {_s.theme == ReadingTheme.system ? ReadingTheme.light : _s.theme},
                onSelectionChanged: (v) => _set(_s.copyWith(theme: v.first)),
              ),

              if (isDark) ...[
                const SizedBox(height: AppTokens.space4),
                Text('다크에서 사진·그림', style: t.textTheme.titleMedium),
                const SizedBox(height: AppTokens.space1),
                Text(
                  '흰 종이만 검게 뒤집고 색은 남깁니다.\n어디가 사진인지는 색이 뚜렷한 부분으로 가려냅니다.',
                  style: t.textTheme.bodySmall,
                ),
                const SizedBox(height: AppTokens.space2),
                _ImageModeTile(
                  mode: DarkImageMode.preserve,
                  groupValue: _s.darkImageMode,
                  title: '이미지 원본 유지',
                  subtitle: '사진은 그대로, 글자만 뒤집습니다 (권장)',
                  onChanged: (v) => _set(_s.copyWith(darkImageMode: v)),
                ),
                _ImageModeTile(
                  mode: DarkImageMode.invert,
                  groupValue: _s.darkImageMode,
                  title: '전체 반전',
                  subtitle: '사진도 함께 뒤집힙니다',
                  onChanged: (v) => _set(_s.copyWith(darkImageMode: v)),
                ),
                _ImageModeTile(
                  mode: DarkImageMode.dim,
                  groupValue: _s.darkImageMode,
                  title: '어둡게만',
                  subtitle: '뒤집지 않고 밝기만 낮춥니다',
                  onChanged: (v) => _set(_s.copyWith(darkImageMode: v)),
                ),
              ],

              const SizedBox(height: AppTokens.space4),
              _Slider(
                label: '밝기',
                value: _s.brightness,
                onChanged: (v) => _set(_s.copyWith(brightness: v)),
              ),
              _Slider(
                label: '대비',
                value: _s.contrast,
                onChanged: (v) => _set(_s.copyWith(contrast: v)),
              ),

              const SizedBox(height: AppTokens.space3),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _set(
                      _s.copyWith(
                        theme: ReadingTheme.light,
                        darkImageMode: DarkImageMode.preserve,
                        brightness: 1,
                        contrast: 1,
                      ),
                    ),
                    child: const Text('되돌리기'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _s),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageModeTile extends StatelessWidget {
  const _ImageModeTile({
    required this.mode,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final DarkImageMode mode;
  final DarkImageMode groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<DarkImageMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<DarkImageMode>(
      value: mode,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      // ignore: deprecated_member_use
      onChanged: (v) => v == null ? null : onChanged(v),
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
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
        SizedBox(width: 40, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(
          child: Slider(
            value: value.clamp(0.5, 1.5),
            min: 0.5,
            max: 1.5,
            divisions: 20,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
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
