import 'package:bookviewer/core/korean.dart';
import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md §9 가 **반드시 테스트하라**고 지정한 항목: 한국어 정규화·bigram 변환,
/// 스마트 복사 한영 분기.
///
/// 이 로직들은 실패해도 예외가 나지 않는다. 검색이 조용히 "결과 없음"이 될 뿐이라
/// 테스트가 없으면 깨진 줄도 모른다.
void main() {
  group('정규화', () {
    test('NFD 로 자모 분리된 한글을 NFC 로 합친다', () {
      // macOS/iOS 유래 텍스트에서 실제로 들어오는 모양.
      // 눈으로는 "한글"과 같아 보이지만 코드포인트가 다르다
      // 자모를 이스케이프로 고정한다 — 파일에 NFD 를 그대로 두면 편집기가
      // 정규화해 버려 테스트가 조용히 무의미해진다
      const nfd = '\u1112\u1161\u11AB\u1100\u1173\u11AF'; // 'ㅎㅏㄴㄱㅡㄹ' 분해형
      const nfc = '한글';
      expect(nfd == nfc, isFalse, reason: '정규화 전에는 다른 문자열이다');
      expect(Korean.normalize(nfd), nfc);
      expect(Korean.normalize(nfd).length, 2);
    });

    test('라틴 리가처를 풀어 준다', () {
      expect(Korean.normalize('\uFB01nd'), 'find'); // U+FB01 = ﬁ
      expect(Korean.normalize('\uFB02ow'), 'flow'); // U+FB02 = ﬂ
    });

    test('제로폭 문자와 별종 공백을 정리한다', () {
      expect(Korean.normalize('머신\u200B러닝'), '머신러닝');
      expect(Korean.normalize('a b'), 'a b');
      expect(Korean.normalize('가\u3000나'), '가 나');
    });

    test('빈 문자열을 그대로 돌려준다', () {
      expect(Korean.normalize(''), '');
    });
  });

  group('bigram', () {
    test('한글을 2글자씩 겹쳐 쪼갠다', () {
      expect(Korean.bigrams('머신러닝'), '머신 신러 러닝');
    });

    test('조사가 붙어도 어간이 걸린다', () {
      // 이것이 unicode61 토크나이저로는 안 되는 이유다
      final indexed = Korean.bigrams('머신러닝을 배운다');
      final query = Korean.queryToBigram('머신러닝');
      expect(query.split(' ').every(indexed.contains), isTrue);
    });

    test('2글자 검색어가 동작한다 — 한국어에서 매우 흔하다', () {
      final indexed = Korean.bigrams('인공지능과 기계학습');
      for (final q in ['인공', '지능', '학습']) {
        expect(indexed.contains(Korean.queryToBigram(q)), isTrue, reason: '"$q" 가 걸려야 한다');
      }
    });

    test('라틴 문자와 숫자는 쪼개지 않는다 — 영어 검색 품질 유지', () {
      expect(Korean.bigrams('machine learning'), 'machine learning');
      expect(Korean.bigrams('GPT-4 모델'), 'gpt 4 모델');
    });

    test('한 글자 구간도 넣는다', () {
      expect(Korean.bigrams('물'), '물');
    });

    test('구두점과 공백은 버린다', () {
      expect(Korean.bigrams('가나, 다라!'), '가나 다라');
    });

    test('한 글자 질의는 LIKE 폴백이 필요하다', () {
      expect(Korean.needsLikeFallback('물'), isTrue);
      expect(Korean.needsLikeFallback('인공'), isFalse);
      expect(Korean.needsLikeFallback('  가 '), isTrue, reason: '공백을 뺀 길이로 센다');
    });
  });

  group('줄바꿈 결합 — 한영 분기', () {
    test('한글끼리는 공백 없이 붙인다', () {
      expect(Korean.joinLines('한국어를 제대로\n처리하는 앱'), '한국어를 제대로처리하는 앱');
    });

    test('영문은 공백으로 잇는다', () {
      expect(Korean.joinLines('machine\nlearning'), 'machine learning');
    });

    test('영문 하이프네이션은 하이픈을 지우고 붙인다', () {
      expect(Korean.joinLines('informa-\ntion'), 'information');
    });

    test('한글과 영문이 만나면 공백을 넣는다', () {
      expect(Korean.joinLines('모델은\nGPT 이다'), '모델은 GPT 이다');
    });

    test('빈 줄은 문단 구분으로 살린다', () {
      expect(Korean.joinLines('첫 문단\n\n둘째 문단'), '첫 문단\n\n둘째 문단');
    });
  });

  group('복사', () {
    test('인용 복사는 출처를 붙인다', () {
      expect(
        Korean.quote('중요한 문장', bookTitle: '딥러닝입문', page: 128),
        '"중요한 문장" — 딥러닝입문, p.128',
      );
    });

    test('스마트 복사는 겹친 공백을 줄인다', () {
      expect(Korean.smartCopy('가나   다라'), '가나 다라');
    });
  });

  group('한글 비율', () {
    test('한글이 거의 없으면 텍스트 레이어가 깨진 것으로 본다', () {
      expect(Korean.hangulRatio('한국어 문장이다'), greaterThan(0.9));
      expect(Korean.hangulRatio('abcdefg'), 0.0);
      expect(Korean.hangulRatio(''), 0.0);
      expect(Korean.hangulRatio('!!! ???'), 0.0, reason: '글자가 없으면 0');
    });
  });
}
