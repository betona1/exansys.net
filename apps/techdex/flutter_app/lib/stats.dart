import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// KST 기준 날짜 (서버 /daily 와 일치)
String kstDate([DateTime? d]) {
  final n = (d ?? DateTime.now()).toUtc().add(const Duration(hours: 9));
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

int _daysBetween(String a, String b) =>
    DateTime.parse('${b}T00:00:00Z').difference(DateTime.parse('${a}T00:00:00Z')).inDays;

class ProgressResult {
  final int gainedXp;
  final String streakEvent;
  final List<String> newBadges;
  ProgressResult(this.gainedXp, this.streakEvent, this.newBadges);
}

/// 앱은 로그인이 없어 진행을 기기에 로컬 저장한다(서버 로직 미러링).
class Stats {
  int streak;
  int bestStreak;
  int freezes;
  int xp;
  int level;
  String? lastPlayDate;
  String? lastDailyDate;
  Set<String> badges;

  Stats({
    this.streak = 0,
    this.bestStreak = 0,
    this.freezes = 1,
    this.xp = 0,
    this.level = 1,
    this.lastPlayDate,
    this.lastDailyDate,
    Set<String>? badges,
  }) : badges = badges ?? {};

  static const _key = 'techdex_stats_v1';
  bool get dailyDoneToday => lastDailyDate == kstDate();

  static Future<Stats> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return Stats();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return Stats(
        streak: j['streak'] ?? 0,
        bestStreak: j['bestStreak'] ?? 0,
        freezes: j['freezes'] ?? 1,
        xp: j['xp'] ?? 0,
        level: j['level'] ?? 1,
        lastPlayDate: j['lastPlayDate'],
        lastDailyDate: j['lastDailyDate'],
        badges: ((j['badges'] as List?)?.map((e) => e as String).toSet()) ?? {},
      );
    } catch (_) {
      return Stats();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      jsonEncode({
        'streak': streak,
        'bestStreak': bestStreak,
        'freezes': freezes,
        'xp': xp,
        'level': level,
        'lastPlayDate': lastPlayDate,
        'lastDailyDate': lastDailyDate,
        'badges': badges.toList(),
      }),
    );
  }

  Future<ProgressResult> applyResult(int correct, int total, bool isDaily) async {
    final today = kstDate();
    final gained = correct * 10 + (isDaily ? 20 : 0);
    var event = 'same';
    if (lastPlayDate != today) {
      if (lastPlayDate == null) {
        streak = 1;
        event = 'start';
      } else {
        final gap = _daysBetween(lastPlayDate!, today);
        if (gap == 1) {
          streak += 1;
          event = 'inc';
        } else if (gap > 1) {
          final missed = gap - 1;
          if (freezes >= missed) {
            freezes -= missed;
            streak += 1;
            event = 'freeze';
          } else {
            streak = 1;
            event = 'reset';
          }
        }
      }
      lastPlayDate = today;
      if (streak > bestStreak) bestStreak = streak;
      if (streak % 7 == 0 && freezes < 2) freezes += 1;
    }
    if (isDaily) lastDailyDate = today;
    xp += gained;
    level = (xp / 100).floor() + 1;

    final newly = <String>[];
    void add(String code) {
      if (!badges.contains(code)) {
        badges.add(code);
        newly.add(code);
      }
    }

    add('onboard');
    if (correct > 0) add('first_correct');
    if (streak >= 3) add('streak3');
    if (streak >= 10) add('streak10');
    if (streak >= 30) add('streak30');
    if (streak >= 100) add('streak100');
    if (level >= 5) add('level5');
    if (level >= 10) add('level10');
    await _save();
    return ProgressResult(gained, event, newly);
  }
}

const badgeLabels = <String, (String, String)>{
  'onboard': ('🌱', '첫 발걸음'),
  'first_correct': ('✅', '첫 정답'),
  'streak3': ('🔥', '3일 연속'),
  'streak10': ('🔥', '10일 연속'),
  'streak30': ('🏅', '30일 연속'),
  'streak100': ('🏆', '100일 연속'),
  'level5': ('⭐', '레벨 5'),
  'level10': ('🌟', '레벨 10'),
};

const _levelTitles = ['뉴비', '프롬프트 유저', '컨텍스트 러너', '하네스 빌더', '에이전트 마스터'];
String levelTitle(int level) => _levelTitles[((level - 1) ~/ 3).clamp(0, _levelTitles.length - 1)];
