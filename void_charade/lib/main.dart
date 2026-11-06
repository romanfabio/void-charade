import 'dart:async';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/system_ui.dart';
import 'features/settings/settings_controller.dart';
import 'services/sound_service.dart';

/// Makes the app's own licence and the bundled fonts' licences show up on the
/// app's licences page (the packages' licences are added by Flutter itself).
void _registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Void Charade'],
      await rootBundle.loadString('assets/LICENSE.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['Lilita One'],
      await rootBundle.loadString('assets/fonts/OFL-LilitaOne.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['Nunito'],
      await rootBundle.loadString('assets/fonts/OFL-Nunito.txt'),
    );
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerBundledLicenses();
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
