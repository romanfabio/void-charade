import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';
import 'settings_repository.dart';

/// Overridden in `main()` once SharedPreferences has been loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() => ref.watch(settingsRepositoryProvider).load();

  void update(Settings Function(Settings current) change) {
    final next = change(state);
    state = next;
    ref.read(settingsRepositoryProvider).save(next);
  }
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

/// The device locale, kept in a provider so tests can override it.
final deviceLocaleProvider = Provider<Locale>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale,
);

final appLocaleProvider = Provider<Locale>(
  (ref) => resolveAppLocale(
    ref.watch(settingsProvider),
    ref.watch(deviceLocaleProvider),
  ),
);

final wordLanguageProvider = Provider<String>(
  (ref) => resolveWordLanguage(
    ref.watch(settingsProvider),
    ref.watch(appLocaleProvider),
  ),
);
