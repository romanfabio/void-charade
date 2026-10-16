import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SoundEffect {
  countdownBeep('countdown_beep'),
  go('go'),
  correct('correct'),
  skip('skip'),
  tick('tick'),
  timeUp('time_up');

  const SoundEffect(this.fileName);
  final String fileName;

  /// Relative to `assets/` (the audioplayers asset prefix).
  String get assetPath => 'sounds/$fileName.wav';
}

/// Plays short sound effects. Behind an interface so tests (and devices
/// without audio) never touch the platform plugin.
abstract class SoundPlayer {
  /// Loads every effect so the first play has no delay. Safe to call often.
  Future<void> preload();

  Future<void> play(SoundEffect effect);
}

/// audioplayers implementation: one low-latency player per effect.
///
/// Audio failures must never break a round, so every platform call is guarded
/// and a failure just makes the game silent.
class AudioPlayersSoundPlayer implements SoundPlayer {
  final _players = <SoundEffect, AudioPlayer>{};
  Future<void>? _loading;
  var _failed = false;

  @override
  Future<void> preload() => _loading ??= _load();

  Future<void> _load() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            // Do not interrupt (or get interrupted by) the user's music app.
            audioFocus: AndroidAudioFocus.none,
          ),
          // "playback" keeps playing with the iPhone silent switch on, and
          // mixWithOthers leaves the user's music running.
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      for (final effect in SoundEffect.values) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(effect.assetPath));
        _players[effect] = player;
      }
    } catch (_) {
      _failed = true;
    }
  }

  @override
  Future<void> play(SoundEffect effect) async {
    await preload();
    if (_failed) return;
    final player = _players[effect];
    if (player == null) return;
    try {
      // Low-latency (SoundPool) players never report that a sound finished, so
      // audioplayers still considers it "playing" and silently ignores the next
      // play/resume of the same effect. stop() resets that state and the old
      // stream; the source stays loaded, so the replay is instant.
      await player.stop();
      await player.resume();
    } catch (_) {
      // Ignore: a missed sound is better than a crashed round.
    }
  }
}

final soundPlayerProvider = Provider<SoundPlayer>(
  (ref) => AudioPlayersSoundPlayer(),
);
