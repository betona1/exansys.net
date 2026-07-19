import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';

const _questionSeconds = 12;

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // setup
  String _collection = 'all';
  int _count = 10;
  bool _vibeCore = false;
  // play
  String _phase = 'setup'; // setup | loading | playing | result
  List<QuizQuestion> _qs = [];
  int _idx = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0, _combo = 0, _bestCombo = 0, _correct = 0;
  double _timeLeft = _questionSeconds.toDouble();
  Timer? _timer;
  final List<QuizQuestion> _wrong = [];
  String _error = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _phase = 'loading';
      _error = '';
    });
    try {
      final qs = await TechdexApi.quiz(
        count: _count,
        collection: _collection == 'all' ? null : _collection,
        vibeCore: _vibeCore,
      );
      if (qs.isEmpty) throw Exception('empty');
      setState(() {
        _qs = qs;
        _idx = 0;
        _selected = null;
        _answered = false;
        _score = 0;
        _combo = 0;
        _bestCombo = 0;
        _correct = 0;
        _wrong.clear();
        _timeLeft = _questionSeconds.toDouble();
        _phase = 'playing';
      });
      _startTimer();
    } catch (_) {
      setState(() {
        _error = '문제를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
        _phase = 'setup';
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          t.cancel();
          _choose(null);
        }
      });
    });
  }

  void _choose(int? i) {
    if (_answered) return;
    _timer?.cancel();
    final q = _qs[_idx];
    final correct = i != null && i == q.answerIndex;
    setState(() {
      _selected = i;
      _answered = true;
      if (correct) {
        _score += 10 + (_timeLeft.round() * 5) + _combo * 3;
        _combo += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;
        _correct += 1;
      } else {
        _combo = 0;
        _wrong.add(q);
      }
    });
  }

  // 사용자가 확인 후 직접 다음으로 (정답/오답을 충분히 볼 수 있게)
  void _next() {
    if (_idx + 1 < _qs.length) {
      setState(() {
        _idx += 1;
        _selected = null;
        _answered = false;
        _timeLeft = _questionSeconds.toDouble();
      });
      _startTimer();
    } else {
      setState(() => _phase = 'result');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case 'playing':
        return _buildPlaying();
      case 'result':
        return _buildResult();
      default:
        return _buildSetup();
    }
  }

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
            child: Text(_error, style: const TextStyle(color: Color(0xFFB4232A))),
          ),
        const Text('스피드 퀴즈', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('정의를 보고 알맞은 용어를 4개 중에 고르세요.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        const Text('분야', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in ['all', 'ai', 'app', 'vibe'])
            _chip(c == 'all' ? '전체' : collectionLabel[c]!, _collection == c, () => setState(() => _collection = c)),
        ]),
        const SizedBox(height: 16),
        const Text('문항 수', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final n in [5, 10, 15, 20]) _chip('$n문제', _count == n, () => setState(() => _count = n)),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _vibeCore,
          activeThumbColor: green,
          onChanged: (v) => setState(() => _vibeCore = v),
          title: const Text('바이브코딩 필수 용어만 (입문용)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(50)),
          onPressed: _phase == 'loading' ? null : _start,
          child: Text(_phase == 'loading' ? '문제 준비 중…' : '시작하기'),
        ),
      ],
    );
  }

  Widget _buildPlaying() {
    final q = _qs[_idx];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_idx + 1} / ${_qs.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
              Row(children: [
                if (_combo > 1) Text('🔥 $_combo콤보  ', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                Text('$_score점', style: const TextStyle(color: greenDeep, fontWeight: FontWeight.w800)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _timeLeft / _questionSeconds,
              minHeight: 6,
              backgroundColor: const Color(0xFFE7EAF0),
              color: _timeLeft / _questionSeconds > 0.33 ? green : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE7EAF0))),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이 설명에 맞는 용어는?', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(q.prompt, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < q.choices.length; i++) _choiceButton(q, i),
          if (_answered) ...[
            const SizedBox(height: 12),
            Builder(builder: (_) {
              final correct = _selected == q.answerIndex;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: correct ? const Color(0xFFE9F6EE) : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${correct ? "✅ 정답!" : "❌ 오답"} · 정답은 ${q.term}${q.sub != null ? " (${q.sub})" : ""}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: correct ? greenDeep : const Color(0xFFB4232A),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ink, minimumSize: const Size.fromHeight(48)),
              onPressed: _next,
              child: Text(_idx + 1 < _qs.length ? '다음 문제 →' : '결과 보기 →'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choiceButton(QuizQuestion q, int i) {
    Color border = const Color(0xFFE7EAF0);
    Color bg = Colors.white;
    Color fg = ink;
    if (_answered) {
      if (i == q.answerIndex) {
        border = green;
        bg = const Color(0xFFE9F6EE);
        fg = greenDeep;
      } else if (i == _selected) {
        border = Colors.red.shade200;
        bg = const Color(0xFFFDECEC);
        fg = Colors.red.shade700;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _answered ? null : () => _choose(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(6)),
                child: Text('ABCD'[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.choices[i], style: TextStyle(fontWeight: FontWeight.w600, color: fg))),
              if (_answered && i == q.answerIndex) const Text('✓', style: TextStyle(color: greenDeep)),
              if (_answered && i == _selected && i != q.answerIndex) const Text('✕', style: TextStyle(color: Colors.red)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final acc = _qs.isEmpty ? 0 : (_correct / _qs.length * 100).round();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Center(child: Text(acc >= 80 ? '🏆' : acc >= 50 ? '👍' : '📚', style: const TextStyle(fontSize: 56))),
        const Center(child: Text('결과', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        const SizedBox(height: 16),
        Row(children: [
          _tile('점수', '$_score', greenDeep),
          const SizedBox(width: 10),
          _tile('정답', '$_correct/${_qs.length}', ink),
          const SizedBox(width: 10),
          _tile('정확도', '$acc%', const Color(0xFF3A6EA5)),
        ]),
        const SizedBox(height: 8),
        Center(child: Text('최고 콤보 $_bestCombo연속', style: const TextStyle(color: Colors.black54))),
        if (_wrong.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('틀린 용어 복습 (${_wrong.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          for (final q in _wrong)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE7EAF0))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.term, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(q.prompt, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ]),
            ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(48)),
              onPressed: _start,
              child: const Text('같은 범위 다시'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => setState(() => _phase = 'setup'),
              child: const Text('범위 바꾸기'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _tile(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EAF0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          ]),
        ),
      );

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? ink : const Color(0xFFE7EAF0)),
          ),
          child: Text(label, style: TextStyle(color: on ? Colors.white : Colors.black54, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
}
