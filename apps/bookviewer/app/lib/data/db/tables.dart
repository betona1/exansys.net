import 'package:drift/drift.dart';

/// 테이블 정의 — `docs/BookViewer_DB스키마.xlsx` 의 02_필드정의를 그대로 옮긴 것.
///
/// 스키마를 바꿀 때는 **이 파일과 xlsx 를 함께** 고친다 (CLAUDE.md §7).
/// 규칙:
/// - 삭제는 `deletedAt` 소프트 삭제. 물리 삭제하면 동기화 시 다른 기기에서 되살아난다
/// - 동기화 기준 키는 `uuid`. AUTOINCREMENT `id` 는 기기마다 다르므로 절대 쓰지 않는다
/// - 일시는 ISO8601 UTC 문자열 (서버 MySQL 과 형식을 맞춘다)

/// 서재에 등록된 PDF 한 권.
/// 원본 파일은 절대 수정하지 않고 경로와 checksum 만 관리한다.
///
/// 행 클래스 이름을 `BookRow` 로 둔다 — 도메인의 `Book` 과 겹치면 안 된다.
/// DB 행과 화면이 쓰는 엔티티는 다른 것이다 (CLAUDE.md §4 의존 방향).
@DataClassName('BookRow')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 동기화 기준 전역 고유 ID
  TextColumn get uuid => text().unique()();

  /// 원본 PDF 경로 또는 SAF URI
  TextColumn get filePath => text()();

  /// SHA-256. 파일 변경 감지 · 주석 재부착 · 위치 재탐색 기준
  TextColumn get fileChecksum => text()();

  IntColumn get fileSize => integer().withDefault(const Constant(0))();

  /// 자동 메타데이터는 늘 부정확하므로 수동 편집 UI 가 필요하다
  TextColumn get title => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get publisher => text().nullable()();

  /// 출간일 (YYYY-MM-DD)
  TextColumn get publishedDate => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('ko'))();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  /// 표지 캐시 경로. 없으면 1페이지 렌더로 자동 생성
  TextColumn get coverPath => text().nullable()();

  /// 텍스트 레이어 존재 여부. false 면 스캔본 → OCR 대상
  BoolColumn get hasTextLayer => boolean().withDefault(const Constant(true))();

  /// 원본 PDF 에 이미 주석이 있는지. 있으면 회색으로 구분 렌더
  BoolColumn get hasSourceAnnots => boolean().withDefault(const Constant(false))();

  BoolColumn get isOcrDone => boolean().withDefault(const Constant(false))();
  BoolColumn get isIndexed => boolean().withDefault(const Constant(false))();

  /// 출처 유형 (pdf / video_book)
  TextColumn get sourceType => text().withDefault(const Constant('pdf'))();

  TextColumn get addedAt => text()();
  TextColumn get updatedAt => text()();

  /// 소프트 삭제
  TextColumn get deletedAt => text().nullable()();
}

/// 독서 진행 상태.
///
/// **마지막 위치와 가장 멀리 읽은 위치를 분리 저장한다.**
/// 검색·목차로 앞쪽으로 점프했다 돌아올 때 진도율이 망가지는 문제를 막는다.
class ReadingProgress extends Table {
  IntColumn get bookId => integer().references(Books, #id)();

  /// 마지막으로 보던 페이지
  IntColumn get lastPage => integer().withDefault(const Constant(1))();

  /// 페이지 내 위치 비율 (0.0~1.0)
  RealColumn get lastOffset => real().withDefault(const Constant(0))();

  /// **가장 멀리 읽은 페이지.** 진도율은 이 값 기준
  IntColumn get farthestPage => integer().withDefault(const Constant(1))();

  RealColumn get percent => real().withDefault(const Constant(0))();

  /// 독서 상태 (unread / reading / finished)
  TextColumn get status => text().withDefault(const Constant('unread'))();

  TextColumn get lastReadAt => text().nullable()();
  TextColumn get finishedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

/// 문서별 뷰어 설정.
/// 크롭/줌/테마를 책마다 기억한다. 없으면 열 때마다 재설정해야 해서 크롭 기능이 무용지물이 된다.
class BookSettings extends Table {
  IntColumn get bookId => integer().references(Books, #id)();

  /// 보기 모드 (single / continuous / spread) — 기본은 연속 스크롤
  TextColumn get viewMode => text().withDefault(const Constant('continuous'))();

  /// 맞춤 모드 (width / page / content)
  TextColumn get fitMode => text().withDefault(const Constant('width'))();

  RealColumn get zoomLevel => real().withDefault(const Constant(1))();

  /// 회전 각도. 뷰 한정이며 파일은 바뀌지 않는다
  IntColumn get rotation => integer().withDefault(const Constant(0))();

  /// 테마 (light / dark / sepia / system)
  TextColumn get theme => text().withDefault(const Constant('system'))();

  /// 다크모드 이미지 처리 (invert / preserve / dim)
  TextColumn get darkImageMode => text().withDefault(const Constant('preserve'))();

  /// 밝기·대비. 1.0 이 원래 값
  RealColumn get brightness => real().withDefault(const Constant(1))();
  RealColumn get contrast => real().withDefault(const Constant(1))();

  BoolColumn get cropEnabled => boolean().withDefault(const Constant(false))();

  /// 홀수/짝수 페이지 크롭 [l,t,r,b] 비율 JSON.
  /// 제본 여백 때문에 홀짝을 따로 계산해야 한다
  TextColumn get cropOdd => text().nullable()();
  TextColumn get cropEven => text().nullable()();

  /// 다단 순차 보기 컬럼 수 (0=사용 안 함)
  IntColumn get columnMode => integer().withDefault(const Constant(0))();

  /// **한 장에 든 두 쪽을 좌·우로 나눠 본다.**
  ///
  /// 책을 펼친 채 스캔하면 PDF 한 장에 두 쪽이 들어간다. 그대로 보면 폰에서
  /// 글자가 절반 크기가 되어 읽을 수 없다. `view_mode` 의 `spread`(두 장을 붙이는 것)와
  /// 반대 방향이라 별도 값으로 둔다.
  BoolColumn get splitPages => boolean().withDefault(const Constant(false))();

  /// 오른쪽 반쪽을 먼저 읽는가 (세로쓰기 등). 기본은 왼쪽 → 오른쪽
  BoolColumn get splitRightToLeft => boolean().withDefault(const Constant(false))();

  /// 좌우 분할을 권해 봤는가. 거절한 사람에게 매번 묻지 않기 위한 표시
  BoolColumn get splitPrompted => boolean().withDefault(const Constant(false))();

  /// 자동 여백 크롭을 권해 봤는가
  BoolColumn get cropPrompted => boolean().withDefault(const Constant(false))();

  BoolColumn get showSourceAnnots => boolean().withDefault(const Constant(true))();

  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

/// 앵커 — **주석과 캡처가 공유하는 위치 참조.**
///
/// 페이지 번호와 좌표만 저장하면 파일이 갱신될 때 전부 깨진다.
/// 원문·앞뒤 문맥·checksum 을 함께 보관해 파일이 바뀌어도 퍼지 재부착이 가능하게 한다 (ADR-0002).
class Anchors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();

  /// 앵커 종류 (text 텍스트범위 / area 사각영역 / point 지점)
  TextColumn get kind => text().withDefault(const Constant('text'))();

  IntColumn get pageNo => integer()();

  /// 좌표 JSON [[x0,y0,x1,y1],...] PDF 좌표계
  TextColumn get rects => text()();

  /// 선택된 원문. 파일이 바뀌었을 때 재부착 기준
  TextColumn get quoteText => text().nullable()();

  /// 앞뒤 문맥 각 40자 — 같은 문구가 여러 개일 때 구분한다
  TextColumn get prefixText => text().nullable()();
  TextColumn get suffixText => text().nullable()();

  /// 앵커 생성 당시의 books.fileChecksum. 불일치 시 재부착을 시도한다
  TextColumn get documentChecksum => text()();

  /// v2 영상북일 때 원본 영상 타임코드(ms)
  IntColumn get videoTimeMs => integer().nullable()();

  /// 재부착 실패로 위치를 잃음. 주석 목록 상단에 경고 그룹으로 노출한다
  BoolColumn get isOrphan => boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();
}

/// 캡처 기록.
/// **출처(책·페이지·좌표)를 절대 잃지 않는다** — anchorId 가 그 연결이다.
class Captures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get anchorId => integer().references(Anchors, #id)();

  TextColumn get imagePath => text().nullable()();

  /// 캡처 해상도 (150/300/600)
  IntColumn get dpi => integer().withDefault(const Constant(300))();

  /// 영역 OCR 결과 (서버 처리)
  TextColumn get ocrText => text().nullable()();

  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
}

/// 북마크 — 사용자 지정 위치
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get pageNo => integer()();
  TextColumn get label => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get deletedAt => text().nullable()();
}

/// 페이지 텍스트 캐시 (검색 색인의 원천).
///
/// 최초 1회만 추출해 보관한다. 매번 뽑으면 느리고 배터리를 태운다.
/// 한국어 정규화 4종을 함께 저장한다 — 질의가 어느 형태로 들어와도 걸리게 하기 위해서다 (ADR-0003).
///
/// 이 표는 **동기화하지 않는다.** 각 기기에서 로컬로 다시 만든다.
@DataClassName('PageTextRow')
class PageTexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id)();
  IntColumn get pageNo => integer()();

  /// 원문 — 스니펫을 사람이 읽을 수 있게 보여주려면 필요하다
  TextColumn get raw => text()();

  /// NFC + NFKC 정규화본
  TextColumn get norm => text()();

  /// 공백 제거 사본 — 한글 PDF 는 어절 공백이 실제 space 가 아닌 경우가 흔하다
  TextColumn get nospace => text()();

  /// bigram 그림자 텍스트 — 이 필드를 unicode61 FTS5 에 넣는다
  TextColumn get bigram => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookId, pageNo},
  ];
}

/// 앱 메타 — 스키마 버전 등
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
