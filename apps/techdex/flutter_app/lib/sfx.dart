import 'package:audioplayers/audioplayers.dart';

/// 짧은 효과음 재생. 파일: assets/sfx/*.wav
/// 안드로이드에서 매번 asset을 재로드하면 소리가 누락되므로, 미리 로드해두고
/// stop → resume 으로 처음부터 다시 재생한다(빠른 반복 재생에 안정적).
class Sfx {
  static bool muted = false;
  static final Map<String, AudioPlayer> _players = {};
  static const _names = ['correct', 'wrong', 'tick', 'urgent'];
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    for (final n in _names) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      try {
        await p.setSource(AssetSource('sfx/$n.wav'));
      } catch (_) {
        /* 무시 */
      }
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
      await p.resume(); // 소스가 로드돼 있으면 처음부터 재생
    } catch (_) {
      // 폴백: 소스 재설정 후 재생
      try {
        await p.play(AssetSource('sfx/$name.wav'));
      } catch (_) {
        /* 무시 */
      }
    }
  }

  static void correct() => _play('correct');
  static void wrong() => _play('wrong');
  static void tick() => _play('tick');
  static void urgent() => _play('urgent');
}
