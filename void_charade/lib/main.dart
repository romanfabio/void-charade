import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/system_ui.dart';
import 'features/settings/settings_controller.dart';
import 'services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await const AppSystemUi().applyMenuMode();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Load the sound effects in the background so the first beep is instant.
  unawaited(container.read(soundPlayerProvider).preload());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VoidCharadeApp(),
    ),
  );
}
