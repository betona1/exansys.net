import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../providers.dart';
import '../theme.dart';

/// 용어 도감 — 검색 + 상세 (FR-GLOSSARY-001)
class GlossaryScreen extends ConsumerWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(glossaryResultsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('용어도감')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => ref.read(glossaryQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: '한국어·영문·약어로 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: vqCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
                ),
              ),
            ),
          ),
          // 필터 칩 (§11.5)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _filterChip(ref, GlossaryFilter.all, '전체'),
                _filterChip(ref, GlossaryFilter.notStarted, '학습 전'),
                _filterChip(ref, GlossaryFilter.learning, '학습 중'),
                _filterChip(ref, GlossaryFilter.mastered, '숙련'),
                _filterChip(ref, GlossaryFilter.wrong, '오답'),
                _filterChip(ref, GlossaryFilter.core, '⭐ 핵심'),
              ],
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('불러오지 못했어요: $e')),
              data: (entries) => entries.isEmpty
                  ? const Center(child: Text('검색 결과가 없어요.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: entries.length,
                      itemBuilder: (c, i) =>
                          _TermTile(term: entries[i].term, state: entries[i].state),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _filterChip(WidgetRef ref, GlossaryFilter f, String label) {
  final on = ref.watch(glossaryFilterProvider) == f;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      selected: on,
      showCheckmark: false,
      label: Text(label),
      selectedColor: vqGreen,
      labelStyle: TextStyle(
          color: on ? Colors.white : vqInk, fontWeight: FontWeight.w600, fontSize: 13),
      backgroundColor: vqCard,
      onSelected: (_) => ref.read(glossaryFilterProvider.notifier).state = f,
    ),
  );
}

class _TermTile extends StatelessWidget {
  final Term term;
  final TermState? state;
  const _TermTile({required this.term, this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Row(
          children: [
            Flexible(
              child: Text(term.termKo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            if (term.vibeCore) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: vqLime.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('핵심', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: vqGreenDeep)),
              ),
            ],
          ],
        ),
        subtitle: Text('${term.termEn} · ${term.category}',
            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _masteryBadge(),
            const SizedBox(height: 2),
            _diffBadge(term.difficulty),
          ],
        ),
        onTap: () => _showDetail(context, term),
      ),
    );
  }

  /// 숙련도 뱃지 — 학습 전/중/숙련/오답
  Widget _masteryBadge() {
    final (String label, Color color) = switch (state) {
      null => ('🌫 학습 전', Colors.black38),
      final s when s.state == 'MASTERED' => ('🏅 숙련', vqCorrect),
      final s when s.correctStreak == 0 => ('🔧 오답', vqWrong),
      _ => ('🌱 학습 중', vqGreen),
    };
    return Text(label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color));
  }

  Widget _diffBadge(int d) {
    const labels = {1: '초급', 2: '중급', 3: '고급', 4: '심화'};
    return Text(labels[d] ?? '중급', style: const TextStyle(fontSize: 12, color: Colors.black45));
  }

  void _showDetail(BuildContext context, Term t) {
    final confusion = (jsonDecode(t.confusionJson) as List).cast<String>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: vqPaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (c, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Text(t.termKo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(t.termEn, style: const TextStyle(color: Colors.black54, fontSize: 15)),
            const SizedBox(height: 16),
            _section('정의', t.def),
            if (t.whyItMatters.isNotEmpty) _section('왜 필요할까요?', t.whyItMatters),
            if (t.example.isNotEmpty) _section('예시', t.example),
            if (confusion.isNotEmpty) _section('헷갈리는 용어', confusion.join(' · ')),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: vqGreen)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 15.5, height: 1.5)),
        ],
      ),
    );
  }
}
