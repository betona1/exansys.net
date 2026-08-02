import 'package:flutter/material.dart';

import '../../../core/tokens.dart';
import '../ocr_client.dart';
import '../ocr_settings.dart';

/// 시트가 돌려주는 답 — 어떤 설정으로, 어디까지 돌릴지
class OcrStart {
  const OcrStart(this.settings, {this.onlyThisPage = false});

  final OcrSettings settings;

  /// 지금 보고 있는 쪽 하나만. 두 시간을 걸기 전에 시험해 보는 용도다
  final bool onlyThisPage;
}

/// 스캔본을 글자로 바꾸기 전에 뜨는 화면.
///
/// 여기서 하는 일은 셋이다 — 서버 주소를 받고, **정말 닿는지 먼저 확인하고**,
/// 얼마나 걸릴지 솔직히 알려 준다. 두 시간짜리 일을 주소 오타로 시작하게
/// 두면 안 된다.
class OcrSheet extends StatefulWidget {
  const OcrSheet({
    super.key,
    required this.settings,
    required this.pageCount,
    required this.remaining,
    required this.currentPage,
  });

  final OcrSettings settings;

  /// 전체 쪽 수 / 아직 글자가 없는 쪽 수
  final int pageCount;
  final int remaining;

  /// 지금 보고 있는 쪽. "이 쪽만" 이 가리키는 곳이다
  final int currentPage;

  @override
  State<OcrSheet> createState() => _OcrSheetState();
}

class _OcrSheetState extends State<OcrSheet> {
  late final _endpoint = TextEditingController(text: widget.settings.endpoint);
  late final _model = TextEditingController(text: widget.settings.model);

  bool _probing = false;
  String? _error;
  String? _okMessage;

  @override
  void dispose() {
    _endpoint.dispose();
    _model.dispose();
    super.dispose();
  }

  OcrSettings get _current => OcrSettings(
        endpoint: OcrSettings.normalizeEndpoint(_endpoint.text),
        model: _model.text.trim(),
      );

  Future<void> _probe() async {
    setState(() {
      _probing = true;
      _error = null;
      _okMessage = null;
    });
    final s = _current;
    final res = await OcrClient(endpoint: s.endpoint, model: s.model).probe();
    if (!mounted) return;
    setState(() {
      _probing = false;
      _error = res.ok ? null : res.message;
      _okMessage = res.ok ? '연결됐습니다 · 모델 ${res.models.length}개' : null;
    });
  }

  /// 실측 기준 반쪽당 약 33초. 두 쪽짜리 스캔본이면 쪽당 두 번 보낸다.
  /// 정확한 수치를 약속하지 않는다 — 서버와 판형에 따라 달라진다
  String get _estimate {
    final minutes = (widget.remaining * 2 * 33 / 60).round();
    if (minutes < 60) return '약 $minutes분';
    return '약 ${minutes ~/ 60}시간 ${minutes % 60}분';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTokens.space4,
          right: AppTokens.space4,
          top: AppTokens.space4,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppTokens.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('글자로 바꾸기', style: t.textTheme.titleLarge),
            const SizedBox(height: AppTokens.space2),
            Text(
              '이 책은 사진으로 된 스캔본이라 찾기와 복사가 되지 않습니다.\n'
              '서버가 그림을 읽어 글자로 바꾸면 그때부터 검색이 됩니다.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: AppTokens.space4),
            TextField(
              controller: _endpoint,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '서버 주소',
                hintText: '192.168.219.88',
                helperText: '포트를 안 적으면 11434 로 붙입니다',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _model,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '모델',
                hintText: OcrSettings.defaultModel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _probing ? null : _probe,
                  icon: _probing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('연결 확인'),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Text(
                    _error ?? _okMessage ?? '',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: _error != null ? t.colorScheme.error : t.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            // 걸리는 시간을 숨기지 않는다. 모르고 시작하면 "멈췄다"가 된다
            Container(
              padding: const EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: Text(
                      '남은 ${widget.remaining}쪽 · $_estimate 걸립니다.\n'
                      '중간에 멈춰도 한 쪽씩 저장되니 다음에 이어서 합니다.',
                      style: t.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            // **한 쪽만 먼저 돌려 볼 수 있게 한다.** 두 시간을 걸어 놓고
            // 결과가 엉망인 것을 알게 되는 것보다, 30초로 확인하는 편이 낫다
            OutlinedButton.icon(
              onPressed: _current.configured
                  ? () => Navigator.pop(context, OcrStart(_current, onlyThisPage: true))
                  : null,
              icon: const Icon(Icons.science_outlined),
              label: Text('먼저 이 쪽(${widget.currentPage}쪽)만 시험'),
            ),
            const SizedBox(height: AppTokens.space2),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _current.configured
                        ? () => Navigator.pop(context, OcrStart(_current))
                        : null,
                    child: const Text('남은 쪽 모두'),
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
