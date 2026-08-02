import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import 'book_source.dart';

const _uuid = Uuid();

class WebBookSource implements BookSource {
  WebBookSource({required this.name, required this.bytes})
      : locator = 'web:${_uuid.v4()}';

  final String name;
  final Uint8List bytes;

  @override
  final String locator;

  @override
  int get size => bytes.length;

  @override
  String get displayName => name;

  @override
  Uint8List? get bytesToStore => bytes;
}

/// 브라우저는 경로를 주지 않는다. 바이트를 받아 온다
Future<BookSource?> pickBook() async {
  const pdf = XTypeGroup(label: 'PDF', extensions: ['pdf'], mimeTypes: ['application/pdf']);
  final file = await openFile(acceptedTypeGroups: const [pdf]);
  if (file == null) return null;
  return WebBookSource(name: file.name, bytes: await file.readAsBytes());
}

/// 담아 둔 바이트로 연다
Future<PdfDocument> openDocument(String locator, {Uint8List? bytes}) {
  if (bytes == null) {
    throw StateError('웹에서는 저장해 둔 바이트가 있어야 문서를 열 수 있습니다');
  }
  return PdfDocument.openData(bytes, sourceName: locator);
}

/// 바이트를 DB 에 들고 있으므로 사라질 일이 없다
bool sourceExists(String locator) => true;

bool get storesBytes => true;

/// 웹에서는 바이트를 이미 들고 있으므로 부를 일이 없다
Future<List<int>> readHead(String locator, int maxBytes) async => const [];
