import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:void_charade/services/haptics_service.dart';
import 'package:void_charade/services/sound_service.dart';

class FakeSoundPlayer implements SoundPlayer {
  final played = <SoundEffect>[];
  var preloadCalls = 0;

  @override
  Future<void> preload() async => preloadCalls++;

  @override
  Future<void> play(SoundEffect effect) async => played.add(effect);
}

class FakeHaptics implements Haptics {
  final patterns = <List<int>>[];

  @override
  Future<void> vibrate(List<int> pattern) async => patterns.add(pattern);
}

/// Replaces the audio and vibration plugins, which do not exist in tests.
List<Override> feedbackOverrides(FakeSoundPlayer sounds, FakeHaptics haptics) => [
      soundPlayerProvider.overrideWithValue(sounds),
      hapticsProvider.overrideWithValue(haptics),
    ];
