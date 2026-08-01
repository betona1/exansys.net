import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_entry.dart';

/// 책장 저장소. 기기 안에만 남는다 (TECHSPEC 7절 — 서버로 보내는 것 없음).
///
/// MVP 단계라 SharedPreferences 에 JSON 으로 담는다. 책갈피·하이라이트가
/// 들어오는 3단계에서 SQLite 로 옮긴다.
class LibraryStore {
  static const _key = 'bookviewer.library.v1';
  static const maxEntries = 50;

  Future<List<BookEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = BookEntry.decodeList(prefs.getString(_key));
    // 사용자가 파일을 지웠거나 옮겼을 수 있다. 없는 책은 책장에서 뺀다.
    final alive = items.where((e) => File(e.path).existsSync()).toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    if (alive.length != items.length) await _save(alive);
    return alive;
  }

  Future<void> _save(List<BookEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, BookEntry.encodeList(items.take(maxEntries).toList()));
  }

  /// 책을 열었을 때 — 없으면 새로 넣고, 있으면 연 시각만 올린다.
  Future<BookEntry> touch(String path, {String? title}) async {
    final items = await load();
    final now = DateTime.now();
    final idx = items.indexWhere((e) => e.path == path);
    final entry = idx >= 0
        ? items[idx].copyWith(openedAt: now)
        : BookEntry(path: path, title: title ?? _titleFromPath(path), openedAt: now);
    if (idx >= 0) {
      items[idx] = entry;
    } else {
      items.insert(0, entry);
    }
    await _save(items..sort((a, b) => b.openedAt.compareTo(a.openedAt)));
    return entry;
  }

  /// 읽던 자리 저장. 쪽을 넘길 때마다 불린다.
  Future<void> saveProgress(String path, {required int lastPage, int? pageCount}) async {
    final items = await load();
    final idx = items.indexWhere((e) => e.path == path);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(lastPage: lastPage, pageCount: pageCount);
    await _save(items);
  }

  Future<void> remove(String path) async {
    final items = await load()
      ..removeWhere((e) => e.path == path);
    await _save(items);
  }

  static String _titleFromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
