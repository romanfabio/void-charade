import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

/// Vibration patterns, as `[wait, vibrate, wait, vibrate, ...]` in ms.
abstract final class HapticPatterns {
  static const correct = [0, 150];
  static const skip = [0, 70, 70, 70];
  static const timeUp = [0, 600];
}

/// Vibrates the phone. Behind an interface so tests never touch the plugin.
abstract class Haptics {
  Future<void> vibrate(List<int> pattern);
}

class VibrationHaptics implements Haptics {
  bool? _hasVibrator;

  @override
  Future<void> vibrate(List<int> pattern) async {
    try {
      _hasVibrator ??= await Vibration.hasVibrator();
      if (_hasVibrator != true) return;
      await Vibration.vibrate(pattern: pattern);
    } catch (_) {
      // Haptics are a bonus; never let them break a round.
    }
  }
}

final hapticsProvider = Provider<Haptics>((ref) => VibrationHaptics());
