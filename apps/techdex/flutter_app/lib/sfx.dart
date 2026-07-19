import 'package:audioplayers/audioplayers.dart';

/// 짧은 효과음 재생 (저지연 모드). 파일: assets/sfx/*.wav
class Sfx {
  static bool muted = false;
  static final Map<String, AudioPlayer> _players = {};

  static AudioPlayer _get(String name) {
    return _players[name] ??= AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
  }

  static Future<void> _play(String name) async {
    if (muted) return;
    try {
      await _get(name).play(AssetSource('sfx/$name.wav'));
    } catch (_) {
      /* 무시 */
    }
  }

  static void correct() => _play('correct');
  static void wrong() => _play('wrong');
  static void tick() => _play('tick');
  static void urgent() => _play('urgent');
}
