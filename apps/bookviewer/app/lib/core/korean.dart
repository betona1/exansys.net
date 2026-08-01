import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// 한국어 텍스트 처리.
///
/// PDF 에서 뽑은 글자를 다룰 때 **반드시 여기를 거친다**. 안 그러면 거의 확실히
/// 버그가 난다 (CLAUDE.md §6). 실패 방식이 조용해서 더 위험하다 —
/// 검색이 "결과 없음"으로 보일 뿐 오류가 뜨지 않는다.
///
/// 검색 파이프라인 (ADR-0003):
///
///     원문 → normalize → nospace 사본 → bigram 그림자 텍스트 → FTS5(unicode61)
///     질의 → normalize → bigram → MATCH
abstract final class Korean {
  /// 정규화 — 이것을 건너뛰면 검색이 **아예** 안 된다.
  ///
  /// 1. NFC: macOS/iOS 유래 텍스트는 "한글"이 자모로 분해(NFD)돼 있다.
  ///    눈으로는 같아 보이지만 코드포인트가 달라 문자열 비교가 실패한다
  /// 2. NFKC: 라틴 리가처(ﬁ ﬂ)가 U+FB01 같은 한 글자로 들어와 검색·복사가 실패한다
  /// 3. 제어문자·이상한 공백 정리
  ///
  /// NFKC 는 NFC 를 포함하므로 한 번만 돌린다.
  static String normalize(String input) {
    if (input.isEmpty) return input;
    // 보이지 않는 문자는 반드시 이스케이프로 적는다.
    // 소스에 그대로 넣으면 편집기·인코딩을 거치며 조용히 사라져 규칙이 무력화된다.
    final composed = unorm.nfkc(input);
    return composed
        // 제로폭·BOM — 눈에 안 보이면서 검색만 깨뜨린다
        .replaceAll(RegExp('[\u200B-\u200D\uFEFF]'), '')
        // 줄바꿈·탭을 뺀 제어문자
        .replaceAll(RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '')
        // NBSP·전각공백 등 별종 공백을 보통 공백으로
        .replaceAll(RegExp('[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]'), ' ');
  }

  /// 공백을 모두 뺀 사본.
  ///
  /// 한글 PDF 는 어절 공백이 실제 space 가 아니라 **글자 간격**인 경우가 흔하다.
  /// 그래서 "머신 러닝"으로 뽑히기도 하고 "머신러닝"으로 뽑히기도 한다.
  /// 양쪽을 다 인덱싱해 두고 질의도 같은 방식으로 폴백한다.
  static String stripSpaces(String input) => input.replaceAll(RegExp(r'\s+'), '');

  /// bigram 그림자 텍스트.
  ///
  /// FTS5 기본 토크나이저 `unicode61` 은 공백 기준이라 한국어에서 무용지물이다.
  /// 조사 때문에 "머신러닝을"과 "머신러닝이"가 별개 토큰이 되어 "머신러닝" 검색이 실패한다.
  /// `trigram` 은 3글자 미만을 인덱싱하지 못해 "인공"·"학습" 같은 흔한 2글자 질의가 죽는다.
  ///
  /// 그래서 한글·한자 구간만 2글자씩 겹쳐 쪼개 공백으로 이어 붙인다.
  ///
  ///     "머신러닝을 배운다" → "머신 신러 러닝 닝을 배운 운다"
  ///
  /// 라틴 문자·숫자 구간은 **쪼개지 않는다.** 영어 검색 품질을 유지하기 위해서다.
  static String bigrams(String input) {
    final out = StringBuffer();
    var i = 0;
    while (i < input.length) {
      final c = input.codeUnitAt(i);
      if (_isCjk(c)) {
        final start = i;
        while (i < input.length && _isCjk(input.codeUnitAt(i))) {
          i++;
        }
        _emitBigrams(out, input.substring(start, i));
      } else if (_isWordChar(c)) {
        final start = i;
        while (i < input.length && _isWordChar(input.codeUnitAt(i))) {
          i++;
        }
        _append(out, input.substring(start, i).toLowerCase());
      } else {
        i++; // 공백·구두점은 버린다
      }
    }
    return out.toString();
  }

  static void _emitBigrams(StringBuffer out, String run) {
    if (run.length == 1) {
      // 한 글자짜리 구간도 넣어 둔다. 없으면 "물" 같은 단독 글자를 못 찾는다
      _append(out, run);
      return;
    }
    for (var i = 0; i + 1 < run.length; i++) {
      _append(out, run.substring(i, i + 2));
    }
  }

  static void _append(StringBuffer out, String token) {
    if (token.isEmpty) return;
    if (out.isNotEmpty) out.write(' ');
    out.write(token);
  }

  /// 질의를 인덱스와 같은 모양으로 바꾼다.
  ///
  /// 인덱싱과 질의가 **같은 변환**을 거쳐야 한다. 한쪽만 바꾸면 아무것도 안 걸린다.
  static String queryToBigram(String query) => bigrams(normalize(query));

  /// 한 글자 질의인가 — bigram 으로는 못 찾으므로 `LIKE` 폴백이 필요하다.
  static bool needsLikeFallback(String query) {
    final n = stripSpaces(normalize(query));
    return n.length < 2;
  }

  /// 줄바꿈 결합.
  ///
  /// **영어는 공백으로 잇고, 한글은 공백 없이 붙인다.**
  /// `\n` → `' '` 로 단순 치환하면 한글 문장 사이에 없던 공백이 생겨
  /// 복사한 글이 어색해지고 검색도 어긋난다.
  ///
  /// 줄 끝 하이픈(영문 하이프네이션)은 하이픈을 지우고 붙인다.
  static String joinLines(String input) {
    final text = normalize(input);
    final out = StringBuffer();
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        // 빈 줄은 문단 구분으로 살린다
        if (out.isNotEmpty && !out.toString().endsWith('\n\n')) out.write('\n\n');
        continue;
      }
      if (out.isEmpty || out.toString().endsWith('\n\n')) {
        out.write(line);
        continue;
      }

      final prev = out.toString();
      final prevChar = prev.substring(prev.length - 1);
      final nextChar = line.substring(0, 1);

      if (prevChar == '-' && _isLatin(nextChar.codeUnitAt(0))) {
        // 영문 하이프네이션: "informa-\ntion" → "information"
        out.clear();
        out.write(prev.substring(0, prev.length - 1) + line);
      } else if (_isCjk(prevChar.codeUnitAt(0)) && _isCjk(nextChar.codeUnitAt(0))) {
        out.write(line); // 한글끼리는 붙인다
      } else {
        out
          ..write(' ')
          ..write(line);
      }
    }
    return out.toString().trim();
  }

  /// 스마트 복사 — 사용자가 고른 글을 읽을 만한 모양으로 정리한다 (techspec §10).
  static String smartCopy(String selection) =>
      joinLines(selection).replaceAll(RegExp(r'[ \t]{2,}'), ' ');

  /// 인용 복사 — `"본문" — 책제목, p.128`
  static String quote(String selection, {required String bookTitle, required int page}) =>
      '"${smartCopy(selection)}" — $bookTitle, p.$page';

  /// 한글 비율. 낮으면 텍스트 레이어가 깨진 것으로 보고 OCR 을 권한다 (CLAUDE.md §6-5)
  static double hangulRatio(String text) {
    if (text.isEmpty) return 0;
    var hangul = 0;
    var letters = 0;
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (_isHangul(c)) {
        hangul++;
        letters++;
      } else if (_isLatin(c)) {
        letters++;
      }
    }
    return letters == 0 ? 0 : hangul / letters;
  }

  // ── 문자 판정 ──────────────────────────────────────────
  //
  // 서로게이트 페어(BMP 밖 한자)는 여기서 다루지 않는다. 한국어 책에서는 거의 없고,
  // 들어와도 _isWordChar 로 떨어져 통째로 한 토큰이 될 뿐 깨지지는 않는다.

  static bool _isHangul(int c) =>
      (c >= 0xAC00 && c <= 0xD7A3) || // 완성형 음절
      (c >= 0x1100 && c <= 0x11FF) || // 자모
      (c >= 0x3130 && c <= 0x318F) || // 호환 자모
      (c >= 0xA960 && c <= 0xA97F) ||
      (c >= 0xD7B0 && c <= 0xD7FF);

  /// bigram 으로 쪼갤 구간 — 한글과 한자·가나.
  /// 이들은 공백 없이 이어 쓰므로 어절 토크나이저가 통하지 않는다.
  static bool _isCjk(int c) =>
      _isHangul(c) ||
      (c >= 0x4E00 && c <= 0x9FFF) || // 한자
      (c >= 0x3400 && c <= 0x4DBF) ||
      (c >= 0x3040 && c <= 0x30FF); // 가나

  static bool _isLatin(int c) =>
      (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || (c >= 0xC0 && c <= 0x24F);

  static bool _isWordChar(int c) => _isLatin(c) || (c >= 0x30 && c <= 0x39); // 숫자 포함
}
