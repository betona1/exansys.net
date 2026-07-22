import 'package:audioplayers/audioplayers.dart';

/// 짧은 효과음. 파일: assets/sfx/*.wav
/// 안드로이드에서 매번 asset 재로드 시 누락되므로 미리 로드 후 stop→resume 재생
/// (TechDex에서 검증된 패턴). 소리는 끌 수 있다 (UX-06).
class Sfx {
  static bool muted = false;
  static final Map<String, AudioPlayer> _players = {};
  static const _names = ['correct', 'wrong', 'combo', 'complete', 'gem'];
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    for (final n in _names) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      try {
        await p.setSource(AssetSource('sfx/$n.wav'));
      } catch (_) {/* 무시 */}
      _players[n] = p;
    }
  }

  static Future<void> _play(String name) async {
    if (muted) return;
    if (!_ready) await init();
    final p = _players[name];
    if (p == null) return;
    try {
      await p.stop();
      await p.resume();
    } catch (_) {
      try {
        await p.play(AssetSource('sfx/$name.wav'));
      } catch (_) {/* 무시 */}
    }
  }

  static void correct() => _play('correct');
  static void wrong() => _play('wrong');
  static void combo() => _play('combo');
  static void complete() => _play('complete');
  static void gem() => _play('gem');
}
