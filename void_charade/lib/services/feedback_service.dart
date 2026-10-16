import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/game_engine.dart';
import '../features/settings/settings.dart';
import '../features/settings/settings_controller.dart';
import 'haptics_service.dart';
import 'sound_service.dart';

/// Turns game events into sound and vibration, honouring the settings that are
/// current at the moment of each event (so toggling mid-round works).
class FeedbackService {
  FeedbackService({
    required this.sounds,
    required this.haptics,
    required this.settings,
  });

  final SoundPlayer sounds;
  final Haptics haptics;
  final Settings Function() settings;

  void handle(GameEvent event) {
    final s = settings();
    switch (event.kind) {
      case GameEventKind.countdownBeep:
        _sound(SoundEffect.countdownBeep, s);
      case GameEventKind.go:
        _sound(SoundEffect.go, s);
      case GameEventKind.correct:
        _sound(SoundEffect.correct, s);
        _vibrate(HapticPatterns.correct, s);
      case GameEventKind.skip:
        _sound(SoundEffect.skip, s);
        _vibrate(HapticPatterns.skip, s);
      case GameEventKind.tick:
        if (s.tickEnabled) _sound(SoundEffect.tick, s);
      case GameEventKind.timeUp:
        _sound(SoundEffect.timeUp, s);
        _vibrate(HapticPatterns.timeUp, s);
    }
  }

  void _sound(SoundEffect effect, Settings s) {
    if (s.soundEnabled) unawaited(sounds.play(effect));
  }

  void _vibrate(List<int> pattern, Settings s) {
    if (s.vibrationEnabled) unawaited(haptics.vibrate(pattern));
  }
}

final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) => FeedbackService(
    sounds: ref.watch(soundPlayerProvider),
    haptics: ref.watch(hapticsProvider),
    settings: () => ref.read(settingsProvider),
  ),
);
