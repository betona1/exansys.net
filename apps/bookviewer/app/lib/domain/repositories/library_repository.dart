import '../entities/book.dart';

/// 서재 저장소 인터페이스.
///
/// 화면은 이 인터페이스만 안다. Drift 도 파일시스템도 모른다 (CLAUDE.md §4 의존 방향).
abstract interface class LibraryRepository {
  /// 최근 연 순서로 책 목록. 파일이 사라진 책도 `fileMissing` 으로 표시해 함께 준다
  Future<List<Book>> listBooks();

  /// 목록이 바뀔 때마다 흘려보낸다
  Stream<List<Book>> watchBooks();

  /// 경로의 PDF 를 서재에 넣는다. 이미 있으면 그 책을 돌려준다.
  ///
  /// checksum 으로 같은 파일을 알아보므로, 파일을 옮겼어도 새 책이 되지 않는다.
  Future<Book> addBook(String filePath);

  Future<Book?> findById(int id);

  /// 읽던 자리 저장.
  ///
  /// [farthestPage] 는 뒤로 가지 않는다 — 앞쪽으로 점프했다고 진도가 줄면 안 된다.
  Future<void> saveProgress(int bookId, {required int lastPage, int? pageCount});

  /// 문서를 열어 확인한 정보를 채운다 (쪽 수, 텍스트 레이어 유무)
  Future<void> updateDocumentInfo(int bookId, {required int pageCount, required bool hasTextLayer});

  /// 서재에서 뺀다. **원본 PDF 파일은 지우지 않는다.**
  Future<void> removeBook(int bookId);
}
