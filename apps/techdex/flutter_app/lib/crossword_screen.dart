import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'sfx.dart';

const _cLevels = {'beginner': '초급', 'intermediate': '중급', 'hard': '고급'};

class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({super.key});
  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  String _collection = 'all';
  String _level = 'intermediate';
  String _dir = 'across';
  CrosswordPuzzle? _puzzle;
  bool _loading = false;
  bool _solved = false;
  String _error = '';
  final Map<String, String> _correct = {};
  final Map<String, int> _numAt = {};
  List<CrosswordEntry> _across = [];
  List<CrosswordEntry> _down = [];
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, FocusNode> _focus = {};
  final Map<String, bool?> _checked = {};
  int _ar = -1, _ac = -1; // 현재 활성 칸

  String _k(int r, int c) => '$r,$c';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeCells();
    super.dispose();
  }

  void _disposeCells() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _ctrl.clear();
    _focus.clear();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
      _solved = false;
      _puzzle = null;
      _ar = -1;
      _ac = -1;
    });
    try {
      final p = await TechdexApi.crossword(
        count: 10,
        collection: _collection == 'all' ? null : _collection,
        level: _level,
      );
      _disposeCells();
      _correct.clear();
      _numAt.clear();
      _checked.clear();
      for (final e in p.entries) {
        _numAt.putIfAbsent(_k(e.row, e.col), () => e.number);
        final dr = e.dir == 'down' ? 1 : 0;
        final dc = e.dir == 'across' ? 1 : 0;
        for (var i = 0; i < e.len; i++) {
          final key = _k(e.row + dr * i, e.col + dc * i);
          _correct[key] = e.answer[i];
          _ctrl.putIfAbsent(key, () => TextEditingController());
          _focus.putIfAbsent(key, () => FocusNode());
        }
      }
      _across = p.entries.where((e) => e.dir == 'across').toList()..sort((a, b) => a.number - b.number);
      _down = p.entries.where((e) => e.dir == 'down').toList()..sort((a, b) => a.number - b.number);
      // 첫 문제를 기본 선택
      final first = _across.isNotEmpty ? _across.first : (_down.isNotEmpty ? _down.first : null);
      setState(() {
        _puzzle = p;
        _loading = false;
        if (first != null) {
          _dir = first.dir;
          _ar = first.row;
          _ac = first.col;
        }
      });
    } catch (_) {
      setState(() {
        _error = '퍼즐을 만들지 못했습니다. 범위를 바꿔 다시 시도해 주세요.';
        _loading = false;
      });
    }
  }

  bool _has(int r, int c) => _correct.containsKey(_k(r, c));

  List<CrosswordEntry> get _ordered => [..._across, ..._down];

  bool _entryContains(CrosswordEntry e, int r, int c) {
    final dr = e.dir == 'down' ? 1 : 0;
    final dc = e.dir == 'across' ? 1 : 0;
    for (var i = 0; i < e.len; i++) {
      if (e.row + dr * i == r && e.col + dc * i == c) return true;
    }
    return false;
  }

  CrosswordEntry? get _activeEntry {
    if (_ar < 0) return null;
    final list = _dir == 'across' ? _across : _down;
    for (final e in list) {
      if (_entryContains(e, _ar, _ac)) return e;
    }
    final other = _dir == 'across' ? _down : _across;
    for (final e in other) {
      if (_entryContains(e, _ar, _ac)) return e;
    }
    return null;
  }

  void _gotoEntry(CrosswordEntry e) {
    setState(() {
      _dir = e.dir;
      _ar = e.row;
      _ac = e.col;
    });
    _focus[_k(e.row, e.col)]?.requestFocus();
  }

  void _stepEntry(int delta) {
    final list = _ordered;
    if (list.isEmpty) return;
    final cur = _activeEntry;
    final idx = cur == null ? -1 : list.indexWhere((e) => e.dir == cur.dir && e.number == cur.number);
    _gotoEntry(list[(idx + delta + list.length) % list.length]);
  }

  void _advance(int r, int c) {
    final dr = _dir == 'down' ? 1 : 0;
    final dc = _dir == 'across' ? 1 : 0;
    if (_has(r + dr, c + dc)) {
      setState(() {
        _ar = r + dr;
        _ac = c + dc;
      });
      _focus[_k(r + dr, c + dc)]!.requestFocus();
    }
  }

  void _onChanged(int r, int c, String v) {
    final key = _k(r, c);
    if (v.isEmpty) {
      setState(() => _checked.remove(key));
      return;
    }
    final ch = v.substring(v.length - 1).toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(ch)) {
      _ctrl[key]!.value = TextEditingValue(text: ch, selection: const TextSelection.collapsed(offset: 1));
      _checked[key] = null;
      _advance(r, c);
    } else {
      _ctrl[key]!.text = '';
    }
    setState(() {});
  }

  void _tapCell(int r, int c) {
    if (_ar == r && _ac == c) {
      setState(() => _dir = _dir == 'across' ? 'down' : 'across');
    } else {
      setState(() {
        _ar = r;
        _ac = c;
      });
    }
    _focus[_k(r, c)]!.requestFocus();
  }

  void _check() {
    var all = true;
    _correct.forEach((key, letter) {
      final ok = _ctrl[key]!.text.toUpperCase() == letter;
      _checked[key] = ok;
      if (!ok) all = false;
    });
    setState(() {
      if (all) {
        _solved = true;
        Sfx.correct();
      } else {
        Sfx.wrong();
      }
    });
  }

  void _reveal() {
    _correct.forEach((key, letter) {
      _ctrl[key]!.text = letter;
      _checked[key] = null;
    });
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = _puzzle;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 범위 선택
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final cc in ['all', 'ai', 'app', 'vibe'])
            _chip(cc == 'all' ? '전체' : collectionLabel[cc]!, _collection == cc, () {
              setState(() => _collection = cc);
            }),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          for (final lv in ['beginner', 'intermediate', 'hard'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(_cLevels[lv]!, _level == lv, () => setState(() => _level = lv)),
            ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ink, visualDensity: VisualDensity.compact),
            onPressed: _load,
            child: const Text('새 퍼즐'),
          ),
        ]),
        const SizedBox(height: 12),

        if (_error.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
            child: Text(_error, style: const TextStyle(color: Color(0xFFB4232A))),
          ),
        if (_loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),

        if (p != null && !_loading) ...[
          if (_solved)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🎉 완성! 잘하셨어요', style: TextStyle(fontWeight: FontWeight.w800, color: greenDeep))),
            ),

          // 현재 힌트 바 — 칸을 누르면 문제가 여기 크게 뜬다
          _clueBar(),
          const SizedBox(height: 12),

          // 그리드 — 화면 폭에 맞춰 칸 크기 자동
          LayoutBuilder(builder: (ctx, cons) {
            final size = math.min(40.0, cons.maxWidth / p.cols).clamp(20.0, 40.0);
            return Column(
              children: [
                for (var r = 0; r < p.rows; r++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [for (var c = 0; c < p.cols; c++) _cell(r, c, size)],
                  ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: green),
                onPressed: _check,
                child: const Text('정답 확인'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: _reveal, child: const Text('정답 보기')),
            ],
          ),
          const SizedBox(height: 20),
          _clues('가로 열쇠', _across),
          const SizedBox(height: 14),
          _clues('세로 열쇠', _down),
        ],
      ],
    );
  }

  Widget _clueBar() {
    final e = _activeEntry;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: green.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        _navBtn('‹', () => _stepEntry(-1)),
        Expanded(
          child: e == null
              ? const Text('칸을 눌러 문제를 확인하세요',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${e.dir == 'across' ? '가로' : '세로'} ${e.number} · ${e.len}글자',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: greenDeep)),
                    const SizedBox(height: 2),
                    Text(e.clue,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink)),
                  ],
                ),
        ),
        _navBtn('›', () => _stepEntry(1)),
      ]),
    );
  }

  Widget _navBtn(String s, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(12)),
          child: Text(s, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: greenDeep)),
        ),
      );

  Widget _cell(int r, int c, double size) {
    final key = _k(r, c);
    if (!_has(r, c)) return SizedBox(width: size, height: size);
    final chk = _checked[key];
    final active = _ar == r && _ac == c;
    final ae = _activeEntry;
    final inWord = ae != null && _entryContains(ae, r, c);

    Color border = const Color(0xFFE7EAF0);
    Color bg = Colors.white;
    if (chk == true) {
      border = green;
      bg = green.withValues(alpha: 0.12);
    } else if (chk == false) {
      border = Colors.red.shade400;
      bg = const Color(0xFFFDECEC);
    } else if (inWord) {
      bg = green.withValues(alpha: 0.06);
    }
    if (active) {
      border = ink;
      bg = lime.withValues(alpha: 0.30);
    }
    final num = _numAt[key];
    return Padding(
      padding: const EdgeInsets.all(1),
      child: SizedBox(
        width: size - 2,
        height: size - 2,
        child: Stack(
          children: [
            TextField(
              controller: _ctrl[key],
              focusNode: _focus[key],
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              showCursor: false,
              maxLength: 2,
              onTap: () => _tapCell(r, c),
              onChanged: (v) => _onChanged(r, c, v),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.46),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: bg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: border, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: border, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: border == ink ? ink : green, width: 2)),
              ),
            ),
            if (num != null)
              Positioned(
                left: 3,
                top: 1,
                child: Text('$num',
                    style: TextStyle(fontSize: size * 0.26, color: Colors.black45, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _clues(String title, List<CrosswordEntry> list) {
    final ae = _activeEntry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: green, fontSize: 14)),
        const SizedBox(height: 4),
        for (final e in list)
          InkWell(
            onTap: () => _gotoEntry(e),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: ae?.dir == e.dir && ae?.number == e.number ? green.withValues(alpha: 0.14) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 22,
                      child: Text('${e.number}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: greenDeep))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.clue, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
