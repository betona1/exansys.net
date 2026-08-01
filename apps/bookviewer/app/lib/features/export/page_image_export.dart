import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../domain/entities/crop_rect.dart';

/// 쪽 이미지로 내보내기 (techspec §7 `페이지 이미지 추출…`).
///
/// **다섯 쪽 이상이면 zip 하나로 묶는다.** 낱장이 수십 개 쏟아지면
/// 공유도 정리도 어렵다.
///
/// 라이선스: `image`(MIT) 로 JPG 인코딩, `archive`(MIT) 로 압축.
/// PyMuPDF 계열은 AGPL 이라 쓸 수 없다 (CLAUDE.md 절대 규칙 1).
/// 오래 걸리는 일은 반드시 멈출 수 있어야 한다 (CLAUDE.md §18 금지사항).
/// 102쪽을 300dpi 로 뽑으면 한참 걸리는데 취소가 없으면 갇힌다.
class ExportCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// 아이솔레이트로 넘길 JPG 인코딩 거리.
///
/// 인코딩은 순수 CPU 라 메인에서 돌리면 화면이 멈춘다 —
/// 진행률 막대조차 갱신되지 않아 "멈춘 것"으로 보인다 (CLAUDE.md §5).
class JpegJob {
  const JpegJob({
    required this.bgra,
    required this.width,
    required this.height,
    required this.quality,
  });

  final Uint8List bgra;
  final int width;
  final int height;
  final int quality;
}

/// `compute()` 에 넘기려면 최상위 함수여야 한다
Uint8List encodeJpegJob(JpegJob job) {
  final frame = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.bgra.buffer,
    numChannels: 4,
    order: img.ChannelOrder.bgra,
  );
  return img.encodeJpg(frame, quality: job.quality);
}

abstract final class PageImageExport {
  /// 이 수 이상이면 zip 으로 묶는다
  static const zipThreshold = 5;

  /// 기본 해상도. 150 이면 A4 한 쪽이 대략 1240×1754
  static const defaultDpi = 150;

  /// JPG 품질 (0~100). 88 이면 눈에 띄는 손실 없이 크기가 절반쯤 된다
  static const jpegQuality = 88;

  /// 쪽 하나를 JPG 바이트로.
  ///
  /// [crop] 을 주면 그 여백을 잘라 내고, [half] 가 0/1 이면 좌·우 반쪽만 낸다.
  /// 화면에서 보던 모양 그대로 뽑으려면 읽기 설정을 그대로 넘긴다.
  static Future<Uint8List> renderPageJpeg(
    PdfPage page, {
    int dpi = defaultDpi,
    CropRect crop = CropRect.none,
    int? half,
    int quality = jpegQuality,
  }) async {
    final area = crop.toPageRect(page.width, page.height);
    var x = area.x;
    var w = area.w;
    if (half != null) {
      w = area.w / 2;
      if (half == 1) x = area.x + w;
    }

    // PDF 좌표는 72dpi 기준이다
    final scale = dpi / 72;
    final rendered = await page.render(
      x: (x * scale).round(),
      y: (area.y * scale).round(),
      width: (w * scale).round().clamp(1, 20000),
      height: (area.h * scale).round().clamp(1, 20000),
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) throw Exception('${page.pageNumber}쪽을 그리지 못했습니다');

    try {
      // 인코딩은 아이솔레이트에서. 메인에서 돌리면 진행률조차 갱신되지 않는다
      return await compute(
        encodeJpegJob,
        JpegJob(
          bgra: Uint8List.fromList(rendered.pixels),
          width: rendered.width,
          height: rendered.height,
          quality: quality,
        ),
      );
    } finally {
      rendered.dispose();
    }
  }

  /// 여러 쪽을 파일로 떨어뜨린다.
  ///
  /// 다섯 쪽 이상이면 zip 하나, 아니면 낱장 JPG 들을 돌려준다.
  static Future<List<File>> exportPages({
    required PdfDocument doc,
    required List<int> pageNumbers,
    required Directory outDir,
    required String baseName,
    int dpi = defaultDpi,
    CropRect Function(int pageNumber)? cropFor,
    bool split = false,
    void Function(int done, int total)? onProgress,
    ExportCancelToken? cancelToken,
  }) async {
    if (pageNumbers.isEmpty) return const [];
    if (!outDir.existsSync()) await outDir.create(recursive: true);

    final safe = safeName(baseName);
    final entries = <({String name, Uint8List bytes})>[];

    for (var i = 0; i < pageNumbers.length; i++) {
      final no = pageNumbers[i];
      if (no < 1 || no > doc.pages.length) continue;
      final page = doc.pages[no - 1];
      final crop = cropFor?.call(no) ?? CropRect.none;

      // 좌우 나눠 보기를 쓰고 있으면 반쪽씩 따로 낸다.
      // 화면에서 본 것과 같은 단위로 나와야 헷갈리지 않는다
      final halves = split ? [0, 1] : [null];
      for (final half in halves) {
        final bytes = await renderPageJpeg(page, dpi: dpi, crop: crop, half: half);
        final suffix = half == null ? '' : (half == 0 ? '_L' : '_R');
        entries.add((name: '${safe}_p${_pad(no)}$suffix.jpg', bytes: bytes));
      }
      onProgress?.call(i + 1, pageNumbers.length);
      // 멈추라고 했으면 쓰기 전에 그만둔다. 반쯤 만든 파일을 남기지 않는다
      if (cancelToken?.isCancelled ?? false) return const [];
    }

    if (entries.length >= zipThreshold) {
      final archive = Archive();
      for (final e in entries) {
        archive.addFile(ArchiveFile.bytes(e.name, e.bytes));
      }
      final zipped = ZipEncoder().encode(archive);
      final file = File('${outDir.path}${Platform.pathSeparator}$safe.zip');
      await file.writeAsBytes(zipped, flush: true);
      return [file];
    }

    final files = <File>[];
    for (final e in entries) {
      final file = File('${outDir.path}${Platform.pathSeparator}${e.name}');
      await file.writeAsBytes(e.bytes, flush: true);
      files.add(file);
    }
    return files;
  }

  /// 쪽 번호를 자릿수 맞춰 채운다. 안 그러면 파일 목록이 1, 10, 2 순으로 섞인다
  static String _pad(int n) => n.toString().padLeft(4, '0');

  static String safeName(String s) {
    final cleaned = s.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
    if (cleaned.isEmpty) return 'pages';
    return cleaned.length <= 60 ? cleaned : cleaned.substring(0, 60);
  }
}
