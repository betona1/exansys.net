import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:pdfrx/pdfrx.dart';

import 'book_source.dart';

class FileBookSource implements BookSource {
  FileBookSource(this.file);

  final File file;

  @override
  String get locator => file.path;

  @override
  int get size => file.lengthSync();

  @override
  String get displayName => file.uri.pathSegments.last;

  @override
  Uint8List? get bytesToStore => null; // 원본을 복사하지 않는다
}

/// 파일 하나를 고른다. 취소하면 null
Future<BookSource?> pickBook() async {
  const pdf = XTypeGroup(label: 'PDF', extensions: ['pdf'], uniformTypeIdentifiers: ['com.adobe.pdf']);
  final file = await openFile(acceptedTypeGroups: const [pdf]);
  if (file == null) return null;
  return FileBookSource(File(file.path));
}

/// 경로로 문서를 연다
Future<PdfDocument> openDocument(String locator, {Uint8List? bytes}) =>
    PdfDocument.openFile(locator);

/// 파일이 아직 그 자리에 있는가
bool sourceExists(String locator) => File(locator).existsSync();

/// 웹에서만 바이트를 DB 에 담는다
bool get storesBytes => false;

/// 파일 앞부분만 읽는다. 전체를 해싱하면 300MB PDF 에서 UI 가 멈춘다
Future<List<int>> readHead(String locator, int maxBytes) async {
  final raf = await File(locator).open();
  try {
    return await raf.read(maxBytes);
  } finally {
    await raf.close();
  }
}
