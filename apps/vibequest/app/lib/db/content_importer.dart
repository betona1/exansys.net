import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'database.dart';

/// 번들 콘텐츠 버전 — glossary 교체 시 올린다.
/// 사용자 숙련도(TermStates)는 termId 기준으로 보존된다 (§15.3).
const kBundledContentVersion = 1;
const _kAssetPath = 'assets/glossary/glossary_v2.json';
const _kMetaKey = 'contentVersion';

class ContentImporter {
  final VqDatabase db;
  ContentImporter(this.db);

  /// 앱 시작 시 호출. 버전이 같으면 건너뛴다.
  Future<bool> importIfNeeded() async {
    final current = int.tryParse(await db.getMeta(_kMetaKey) ?? '') ?? 0;
    if (current >= kBundledContentVersion) return false;

    final raw = await rootBundle.loadString(_kAssetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    await db.transaction(() async {
      final bundledIds = <String>{};
      await db.batch((b) {
        for (final t in list) {
          final id = t['id'] as String;
          bundledIds.add(id);
          b.insert(
            db.terms,
            TermsCompanion.insert(
              id: id,
              termKo: t['termKo'] as String,
              termEn: (t['termEn'] as String?) ?? '',
              def: t['def'] as String,
              whyItMatters: Value((t['whyItMatters'] as String?) ?? ''),
              example: Value((t['example'] as String?) ?? ''),
              category: t['category'] as String,
              subcategory: Value((t['subcategory'] as String?) ?? ''),
              tracksJson: Value(jsonEncode(t['tracks'] ?? [])),
              aliasesJson: Value(jsonEncode(t['aliases'] ?? [])),
              confusionJson: Value(jsonEncode(t['confusionSet'] ?? [])),
              difficulty: Value((t['difficulty'] as num?)?.toInt() ?? 2),
              vibeCore: Value(t['vibeCore'] == true),
              volatileInfo: Value(t['volatile'] == true),
              quizEnabled: Value(t['quizEnabled'] != false),
              retired: const Value(false),
              slug: t['slug'] as String,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      // 번들에서 빠진 기존 용어는 삭제하지 않고 은퇴 처리 (§15.3)
      final existing = await db.select(db.terms).get();
      for (final row in existing) {
        if (!bundledIds.contains(row.id) && !row.retired) {
          await (db.update(db.terms)..where((t) => t.id.equals(row.id)))
              .write(const TermsCompanion(retired: Value(true)));
        }
      }

      await db.setMeta(_kMetaKey, '$kBundledContentVersion');
    });
    return true;
  }
}
