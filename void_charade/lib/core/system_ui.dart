import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Platform behaviour that differs between the menus (portrait) and a round
/// (landscape, full screen, screen kept on). Behind a provider so widget tests
/// can replace it with a no-op.
class AppSystemUi {
  const AppSystemUi();

  /// Menus: portrait, normal system bars.
  Future<void> applyMenuMode() async {
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  /// A round: either landscape direction, immersive, screen never sleeps.
  Future<void> applyGameMode() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();
  }
}

final appSystemUiProvider = Provider<AppSystemUi>((ref) => const AppSystemUi());
