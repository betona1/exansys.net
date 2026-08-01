import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../page_image_export.dart';

/// 어느 쪽을 낼지
enum PageRange {
  current('이 쪽만'),
  visible('보이는 범위 앞뒤 10쪽'),
  all('전체');

  const PageRange(this.label);

  final String label;
}

class PageImageRequest {
  const PageImageRequest({required this.range, required this.dpi, required this.asSeen});

  final PageRange range;
  final int dpi;

  /// 화면에서 보던 대로(여백 잘라내기·좌우 나눠 보기 적용) 낼지
  final bool asSeen;
}

/// 쪽 이미지로 내보내기 시트 (techspec §7).
class PageImageSheet extends StatefulWidget {
  const PageImageSheet({
    super.key,
    required this.pageCount,
    required this.hasCropOrSplit,
  });

  final int pageCount;

  /// 여백 잘라내기나 좌우 나눠 보기를 쓰고 있는가
  final bool hasCropOrSplit;

  @override
  State<PageImageSheet> createState() => _PageImageSheetState();
}

class _PageImageSheetState extends State<PageImageSheet> {
  PageRange _range = PageRange.current;
  int _dpi = PageImageExport.defaultDpi;
  bool _asSeen = true;

  int get _estimatedCount => switch (_range) {
    PageRange.current => 1,
    PageRange.visible => 21 > widget.pageCount ? widget.pageCount : 21,
    PageRange.all => widget.pageCount,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final count = _estimatedCount * (_asSeen && widget.hasCropOrSplit ? 2 : 1);
    final zips = count >= PageImageExport.zipThreshold;

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
              Text('쪽 이미지로 내보내기', style: t.textTheme.titleMedium),
              const SizedBox(height: AppTokens.space3),

              for (final r in PageRange.values)
                RadioListTile<PageRange>(
                  value: r,
                  // ignore: deprecated_member_use
                  groupValue: _range,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setState(() => _range = v ?? _range),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.label),
                ),

              const SizedBox(height: AppTokens.space2),
              Text('해상도', style: t.textTheme.bodySmall),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 100, label: Text('보통')),
                  ButtonSegment(value: 150, label: Text('선명')),
                  ButtonSegment(value: 300, label: Text('인쇄')),
                ],
                selected: {_dpi},
                onSelectionChanged: (v) => setState(() => _dpi = v.first),
              ),

              if (widget.hasCropOrSplit) ...[
                const SizedBox(height: AppTokens.space2),
                SwitchListTile(
                  value: _asSeen,
                  onChanged: (v) => setState(() => _asSeen = v),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('화면에서 보던 대로'),
                  subtitle: const Text('여백 잘라내기·좌우 나눠 보기를 그대로 적용합니다'),
                ),
              ],

              const SizedBox(height: AppTokens.space3),
              Text(
                zips
                    ? '약 $count장 → zip 하나로 묶어 냅니다'
                    : '약 $count장을 낱장으로 냅니다',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: AppTokens.space3),
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
                        PageImageRequest(range: _range, dpi: _dpi, asSeen: _asSeen),
                      ),
                      child: const Text('내보내기'),
                    ),
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
