import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/features/game/game_engine.dart';
import 'package:void_charade/features/settings/settings.dart';
import 'package:void_charade/services/feedback_service.dart';
import 'package:void_charade/services/haptics_service.dart';
import 'package:void_charade/services/sound_service.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeSoundPlayer sounds;
  late FakeHaptics haptics;
  var settings = const Settings();

  late FeedbackService service;

  setUp(() {
    sounds = FakeSoundPlayer();
    haptics = FakeHaptics();
    settings = const Settings();
    service = FeedbackService(
      sounds: sounds,
      haptics: haptics,
      settings: () => settings,
    );
  });

  void fire(GameEventKind kind, [int? value]) =>
      service.handle(GameEvent(kind, value));

  group('with everything on', () {
    test('correct: success chime and one strong pulse', () {
      fire(GameEventKind.correct);
      expect(sounds.played, [SoundEffect.correct]);
      expect(haptics.patterns, [HapticPatterns.correct]);
    });

    test('skip: bad sound and a double pulse', () {
      fire(GameEventKind.skip);
      expect(sounds.played, [SoundEffect.skip]);
      expect(haptics.patterns, [HapticPatterns.skip]);
      expect(HapticPatterns.skip.where((ms) => ms > 0).length, 3);
    });

    test('time up: buzzer and a long pulse', () {
      fire(GameEventKind.timeUp);
      expect(sounds.played, [SoundEffect.timeUp]);
      expect(haptics.patterns, [HapticPatterns.timeUp]);
      expect(HapticPatterns.timeUp.last, greaterThanOrEqualTo(500));
    });

    test('countdown beep, go and tick are sound only', () {
      fire(GameEventKind.countdownBeep, 3);
      fire(GameEventKind.go);
      fire(GameEventKind.tick, 2);
      expect(sounds.played, [
        SoundEffect.countdownBeep,
        SoundEffect.go,
        SoundEffect.tick,
      ]);
      expect(haptics.patterns, isEmpty);
    });
  });

  group('toggles', () {
    test('sounds off silences everything but keeps vibration', () {
      settings = const Settings(soundEnabled: false);
      for (final kind in GameEventKind.values) {
        fire(kind);
      }
      expect(sounds.played, isEmpty);
      expect(haptics.patterns, [
        HapticPatterns.correct,
        HapticPatterns.skip,
        HapticPatterns.timeUp,
      ]);
    });

    test('vibration off keeps the sounds', () {
      settings = const Settings(vibrationEnabled: false);
      for (final kind in GameEventKind.values) {
        fire(kind);
      }
      expect(haptics.patterns, isEmpty);
      expect(sounds.played.length, GameEventKind.values.length);
    });

    test('ticking off drops only the tick', () {
      settings = const Settings(tickEnabled: false);
      fire(GameEventKind.tick, 3);
      fire(GameEventKind.correct);
      expect(sounds.played, [SoundEffect.correct]);
    });

    test('ticking stays silent when sounds are off, even if it is on', () {
      settings = const Settings(soundEnabled: false, tickEnabled: true);
      fire(GameEventKind.tick, 3);
      expect(sounds.played, isEmpty);
    });

    test('changing a setting takes effect for the next event', () {
      fire(GameEventKind.correct);
      settings = const Settings(soundEnabled: false);
      fire(GameEventKind.correct);
      expect(sounds.played.length, 1);
      expect(haptics.patterns.length, 2);
    });
  });
}
