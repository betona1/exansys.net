import 'package:flutter/material.dart';

/// 디자인 토큰 — `BRAND.md` 의 값을 그대로 옮긴 것.
///
/// **화면 코드에서 `Color(0xFF...)` 를 직접 쓰지 않는다** (CLAUDE.md §5).
/// 여기 없는 색·간격을 새로 만들지 않는다. 필요하면 BRAND.md 를 먼저 고친다.
abstract final class AppTokens {
  // ── 브랜드 코어 (BRAND.md §3.1) ─────────────────────────
  /// EXANSYS Ink — 바디, 다크 배경. 웹사이트 메인 컬러와 동일
  static const ink = Color(0xFF0D1117);

  /// Visor Slot — 바이저 내부. ink 보다 아주 조금 밝다
  static const slot = Color(0xFF151A22);

  /// EXANSYS Signal — 모회사 액센트
  static const signal = Color(0xFF4CC2FF);

  /// Paper — 라이트 배경
  static const paper = Color(0xFFF5F6F8);

  // ── ExaPDF 제품 색 (BRAND.md §3.2) ────────────────────────
  /// 브랜드 액센트. **누르는 것에는 쓰지 않는다** — 흰 배경 대비 1.8:1 로 WCAG 미달
  static const amber = Color(0xFFFFC24B);

  /// 라이트 배경 위 텍스트·아이콘용 앰버 (대비 확보)
  static const amberDeep = Color(0xFFC98A1E);

  /// UI 기능색 — 링크, 포커스 링, 선택, 체크박스. **누르는 것은 전부 이 색**
  static const action = Color(0xFF2F6BFF);

  // ── 하이라이트 5색 (BRAND.md §3.3) ──────────────────────
  /// 슬롯 번호(1~5)로 저장한다. 색상값을 저장하면 테마를 바꿔도 따라오지 않는다
  static const highlights = <Color>[
    Color(0xFFFFE082), // 1 중요
    Color(0xFFA5D6A7), // 2 이해함
    Color(0xFF90CAF9), // 3 인용 후보
    Color(0xFFF48FB1), // 4 의문
    Color(0xFFCE93D8), // 5 나중에
  ];

  static const highlightLabels = <String>['중요', '이해함', '인용 후보', '의문', '나중에'];

  // ── 시맨틱 (BRAND.md §3.4) ──────────────────────────────
  static const successLight = Color(0xFF1F9D55);
  static const successDark = Color(0xFF4ADE80);
  static const warningLight = Color(0xFFC98A1E);
  static const warningDark = Color(0xFFFFC24B);
  static const dangerLight = Color(0xFFD93636);
  static const dangerDark = Color(0xFFFF6B6B);

  static const textPrimaryLight = Color(0xFF1A1D23);
  static const textPrimaryDark = Color(0xFFE6E8EC);
  static const textSecondaryLight = Color(0xFF5B6270);
  static const textSecondaryDark = Color(0xFF9AA1AC);
  static const borderLight = Color(0xFFDFE3EA);
  static const borderDark = Color(0xFF2E333C);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E2127);

  /// 세피아 — SPEC §2.1 의 세 번째 리딩 테마
  static const sepiaSurface = Color(0xFFF4ECD8);
  static const sepiaText = Color(0xFF433422);

  // ── 간격 (BRAND.md §5) ──────────────────────────────────
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 24.0;
  static const space6 = 32.0;
  static const space7 = 48.0;

  // ── 모서리 (BRAND.md §5) ────────────────────────────────
  static const radiusButton = 10.0;
  static const radiusCard = 14.0;
  static const radiusSheet = 20.0;

  /// 최소 터치 타깃 (모바일) — 접근성 필수
  static const minTouchTarget = 48.0;

  /// 최소 클릭 타깃 (데스크톱)
  static const minClickTarget = 32.0;

  // ── 타이포 (BRAND.md §4) ────────────────────────────────
  /// 한글 본문 행간. 라틴보다 넓게 잡는다
  static const bodyHeight = 1.65;

  // ── 반응형 3분기 (techspec §2) ──────────────────────────
  //
  // 기기 종류가 아니라 **폭**으로 나눈다. 폴더블·분할화면에서 기기 판정은 반드시 틀린다.
  static const breakpointMedium = 600.0;
  static const breakpointExpanded = 1024.0;
}

/// 화면 폭 분기 (techspec §2)
enum Breakpoint {
  /// < 600dp — 폰. 전체화면 리더, 패널은 바텀시트
  compact,

  /// 600~1023dp — 태블릿 세로, 폴더블. 리더 + 접히는 좌측 레일
  medium,

  /// ≥ 1024dp — 태블릿 가로, 데스크톱. 좌우 패널 상주
  expanded;

  static Breakpoint of(double width) {
    if (width >= AppTokens.breakpointExpanded) return Breakpoint.expanded;
    if (width >= AppTokens.breakpointMedium) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  /// 두 페이지 펼침은 medium 이상에서만 (techspec §6.2)
  bool get allowsSpread => this != Breakpoint.compact;

  /// 좌우 분할은 expanded 전용
  bool get allowsSplit => this == Breakpoint.expanded;
}

/// 읽기 화면에서 조작을 어디에 둘지.
///
/// 화면 모양에 따라 귀한 방향이 다르다.
/// - 폰 세로: 세로가 넉넉하다 → 위아래 바
/// - 폰 가로: **세로가 귀하다** → 바를 없애고 가장자리에서 끌어당기는 레일
/// - 태블릿·폴드 펼침: 폭이 넉넉하다 → 좌측 레일 상주
enum ReaderChrome {
  /// 위·아래 바
  bars,

  /// 가장자리 드래그로 나오는 세로 레일
  drawer,

  /// 상주하는 세로 레일
  rail;

  /// 세로가 이보다 짧으면 위아래 바가 책을 너무 눌러버린다
  static const shortHeight = 500.0;

  static ReaderChrome of(Size size) {
    if (size.width >= AppTokens.breakpointMedium) return ReaderChrome.rail;
    if (size.height < shortHeight) return ReaderChrome.drawer;
    return ReaderChrome.bars;
  }
}
