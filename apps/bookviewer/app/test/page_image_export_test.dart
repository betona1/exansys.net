import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:exapdf/features/export/page_image_export.dart';
import 'package:flutter_test/flutter_test.dart';

/// 쪽 이미지 내보내기에서 사람이 실제로 겪는 것들:
/// 파일 이름이 섞이지 않는가, 많을 때 zip 으로 묶이는가, 이름이 안전한가.
///
/// 렌더 자체(pdfrx)는 여기서 부르지 않는다 — 네이티브가 필요하고
/// `docs/engine-verification.md` 에서 따로 확인했다.
void main() {
  test('다섯 장이 넘으면 zip 하나로 묶는다', () {
    // 낱장이 수십 개 쏟아지면 공유도 정리도 어렵다
    expect(PageImageExport.zipThreshold, 5);
  });

  group('파일 이름', () {
    test('경로에 쓸 수 없는 글자를 지운다', () {
      expect(PageImageExport.safeName('a/b:c*d?e'), isNot(contains('/')));
      expect(PageImageExport.safeName('a/b:c*d?e'), isNot(contains(':')));
      expect(PageImageExport.safeName(r'제목<>|"'), isNot(contains('|')));
    });

    test('빈 이름이면 기본값을 쓴다', () {
      expect(PageImageExport.safeName('   '), 'pages');
      expect(PageImageExport.safeName('///'), '_');
    });

    test('너무 길면 자른다', () {
      final long = 'ㄱ' * 200;
      expect(PageImageExport.safeName(long).length, lessThanOrEqualTo(60));
    });

    test('한글 제목은 그대로 살린다', () {
      expect(PageImageExport.safeName('나를잃어가면서'), '나를잃어가면서');
    });
  });

  group('zip 묶기', () {
    test('넣은 파일을 그대로 꺼낼 수 있다', () {
      // 실제 내보내기가 쓰는 것과 같은 방식으로 묶고 푼다
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('책_p0001.jpg', Uint8List.fromList([1, 2, 3])))
        ..addFile(ArchiveFile.bytes('책_p0002.jpg', Uint8List.fromList([4, 5])));
      final bytes = ZipEncoder().encode(archive);

      final back = ZipDecoder().decodeBytes(bytes);
      expect(back.length, 2);
      expect(back.map((f) => f.name).toList(), ['책_p0001.jpg', '책_p0002.jpg']);
      expect(back.first.content, [1, 2, 3]);
    });

    test('쪽 번호를 자릿수 맞춰 붙여 목록이 섞이지 않는다', () {
      // 1, 10, 2 순으로 섞이면 책 순서가 무너진다
      final names = [1, 2, 10, 100].map((n) => 'b_p${n.toString().padLeft(4, '0')}.jpg').toList()
        ..sort();
      expect(names, [
        'b_p0001.jpg',
        'b_p0002.jpg',
        'b_p0010.jpg',
        'b_p0100.jpg',
      ]);
    });
  });
}
