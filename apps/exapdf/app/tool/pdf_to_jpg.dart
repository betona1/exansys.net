// PDF 를 쪽별 JPG 로 뽑는 명령줄 도구.
//
//   dart run tool/pdf_to_jpg.dart <PDF경로> [-o 출력폴더] [--dpi 150] [--from 1] [--to 20] [-q 88]
//
// 앱을 켜지 않고 여러 책을 한꺼번에 처리할 때 쓴다.
// **다섯 장 이상이면 zip 하나로 묶는다** — 앱과 같은 규칙이다.
//
// 라이선스: pdfrx_engine(MIT / PDFium BSD) · image(MIT) · archive(MIT).
// PyMuPDF 계열은 AGPL 이라 쓰지 않는다 (CLAUDE.md 절대 규칙 1).
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx_engine/pdfrx_engine.dart';

const _zipThreshold = 5;

Future<int> main(List<String> args) async {
  if (args.isEmpty || args.first == '-h' || args.first == '--help') {
    stdout.writeln('''
PDF 를 쪽별 JPG 로 뽑습니다.

  dart run tool/pdf_to_jpg.dart <PDF경로> [옵션]

옵션
  -o, --out <폴더>   출력 폴더 (기본: PDF 옆에 <이름>_jpg)
      --dpi <수>     해상도 (기본 150. 인쇄는 300)
      --from <쪽>    시작 쪽 (기본 1)
      --to <쪽>      끝 쪽 (기본 마지막)
  -q, --quality <수> JPG 품질 0~100 (기본 88)

$_zipThreshold 장 이상이면 zip 하나로 묶습니다.
''');
    return args.isEmpty ? 1 : 0;
  }

  final path = args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('파일을 찾을 수 없습니다: $path');
    return 1;
  }

  String? opt(List<String> names) {
    for (final n in names) {
      final i = args.indexOf(n);
      if (i >= 0 && i + 1 < args.length) return args[i + 1];
    }
    return null;
  }

  final dpi = int.tryParse(opt(['--dpi']) ?? '') ?? 150;
  final quality = int.tryParse(opt(['-q', '--quality']) ?? '') ?? 88;
  final baseName = _safeName(_stem(path));
  final outDir = Directory(
    opt(['-o', '--out']) ?? '${file.parent.path}${Platform.pathSeparator}${baseName}_jpg',
  );

  // 순수 Dart 에서 PDFium 을 쓰려면 먼저 초기화한다
  await pdfrxInitialize();
  final doc = await PdfDocument.openFile(path, useProgressiveLoading: false);

  final from = (int.tryParse(opt(['--from']) ?? '') ?? 1).clamp(1, doc.pages.length);
  final to = (int.tryParse(opt(['--to']) ?? '') ?? doc.pages.length).clamp(from, doc.pages.length);

  stdout.writeln('${doc.pages.length}쪽 중 $from~$to 쪽 · ${dpi}dpi');

  final entries = <({String name, List<int> bytes})>[];
  final scale = dpi / 72;

  for (var no = from; no <= to; no++) {
    final page = doc.pages[no - 1];
    final rendered = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) {
      stderr.writeln('$no쪽을 그리지 못했습니다 — 건너뜁니다');
      continue;
    }
    try {
      // pdfrx 는 BGRA 로 준다
      final frame = img.Image.fromBytes(
        width: rendered.width,
        height: rendered.height,
        bytes: rendered.pixels.buffer,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      );
      entries.add((
        name: '${baseName}_p${no.toString().padLeft(4, '0')}.jpg',
        bytes: img.encodeJpg(frame, quality: quality),
      ));
    } finally {
      rendered.dispose();
    }
    stdout.write('\r  ${no - from + 1}/${to - from + 1}');
  }
  stdout.writeln();
  await doc.dispose();

  if (entries.isEmpty) {
    stderr.writeln('만들어진 이미지가 없습니다');
    return 1;
  }
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  if (entries.length >= _zipThreshold) {
    final archive = Archive();
    for (final e in entries) {
      archive.addFile(ArchiveFile.bytes(e.name, e.bytes));
    }
    final zipPath = '${outDir.path}${Platform.pathSeparator}$baseName.zip';
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));
    stdout.writeln('zip 하나로 묶었습니다: $zipPath (${entries.length}장)');
  } else {
    for (final e in entries) {
      File('${outDir.path}${Platform.pathSeparator}${e.name}').writeAsBytesSync(e.bytes);
    }
    stdout.writeln('${entries.length}장을 냈습니다: ${outDir.path}');
  }
  return 0;
}

String _stem(String path) {
  final name = path.split(RegExp(r'[/\\]')).last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

String _safeName(String s) {
  final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
  if (cleaned.isEmpty) return 'pages';
  return cleaned.length <= 60 ? cleaned : cleaned.substring(0, 60);
}
