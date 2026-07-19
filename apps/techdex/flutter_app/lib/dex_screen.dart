import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});
  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  String _q = '';
  String _collection = 'all';
  List<Term> _terms = [];
  int _total = 0;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _q = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await TechdexApi.terms(
        q: _q,
        collection: _collection == 'all' ? null : _collection,
        limit: 120,
      );
      if (!mounted) return;
      setState(() {
        _terms = page.terms;
        _total = page.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _badge(String c) {
    switch (c) {
      case 'ai':
        return greenDeep;
      case 'app':
        return const Color(0xFF3A6EA5);
      case 'vibe':
        return const Color(0xFFB7791F);
      default:
        return green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: '용어 검색… (예: 토큰, 에이전트, diff)',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7EAF0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: Color(0xFFE7EAF0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: green)),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final c in ['all', 'ai', 'app', 'vibe', 'user'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _chip(c == 'all' ? '전체' : collectionLabel[c]!, _collection == c, () {
                        setState(() => _collection = c);
                        _load();
                      }),
                    ),
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(_loading ? '불러오는 중…' : '$_total개', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
        ),
        Expanded(
          child: _loading && _terms.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _terms.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _terms.length,
                      itemBuilder: (ctx, i) {
                        final t = _terms[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE7EAF0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _badge(t.collection).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                                child: Text(t.category, style: TextStyle(color: _badge(t.collection), fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 8),
                              Row(children: [
                                Flexible(child: Text(t.term, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                                if (t.vibeCore) const Text('  ★필수', style: TextStyle(color: Colors.orange, fontSize: 11)),
                              ]),
                              if (t.sub != null) Text(t.sub!, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(t.def, style: const TextStyle(fontSize: 14, height: 1.4)),
                            ],
                          ),
                        );
                      },
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
