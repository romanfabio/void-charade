import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_charade/features/settings/settings.dart';
import 'package:void_charade/features/settings/settings_repository.dart';

Future<SettingsRepository> _repo([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsRepository(await SharedPreferences.getInstance());
}

void main() {
  group('SettingsRepository', () {
    test('returns the documented defaults when nothing is stored', () async {
      final s = (await _repo()).load();
      expect(s.appLanguage, AppLanguageSetting.system);
      expect(s.wordLanguage, WordLanguageSetting.sameAsApp);
      expect(s.roundSeconds, 60);
      expect(s.countdownSeconds, 5);
      expect(s.skipPenalty, isFalse);
      expect(s.soundEnabled, isTrue);
      expect(s.vibrationEnabled, isTrue);
      expect(s.tickEnabled, isTrue);
      expect(s.swapTilt, isFalse);
      expect(s.showAdult, isTrue);
    });

    test('round-trips every field', () async {
      final repo = await _repo();
      const written = Settings(
        appLanguage: AppLanguageSetting.it,
        wordLanguage: WordLanguageSetting.en,
        roundSeconds: 120,
        countdownSeconds: 8,
        skipPenalty: true,
        soundEnabled: false,
        vibrationEnabled: false,
        tickEnabled: false,
        swapTilt: true,
        showAdult: false,
      );
      await repo.save(written);
      final read = repo.load();
      expect(read.appLanguage, written.appLanguage);
      expect(read.wordLanguage, written.wordLanguage);
      expect(read.roundSeconds, 120);
      expect(read.countdownSeconds, 8);
      expect(read.skipPenalty, isTrue);
      expect(read.soundEnabled, isFalse);
      expect(read.vibrationEnabled, isFalse);
      expect(read.tickEnabled, isFalse);
      expect(read.swapTilt, isTrue);
      expect(read.showAdult, isFalse);
    });

    test('clamps and snaps out-of-range numeric values', () async {
      final s = (await _repo({
        'roundSeconds': 500,
        'countdownSeconds': 1,
      }))
          .load();
      expect(s.roundSeconds, 180);
      expect(s.countdownSeconds, 3);

      final snapped = (await _repo({'roundSeconds': 67})).load();
      expect(snapped.roundSeconds, 60);
    });

    test('falls back to defaults for unknown enum names', () async {
      final s = (await _repo({
        'appLanguage': 'klingon',
        'wordLanguage': 'elvish',
      }))
          .load();
      expect(s.appLanguage, AppLanguageSetting.system);
      expect(s.wordLanguage, WordLanguageSetting.sameAsApp);
    });
  });

  group('locale resolution', () {
    test('system follows an Italian device', () {
      expect(
        resolveAppLocale(const Settings(), const Locale('it', 'IT')),
        const Locale('it'),
      );
    });

    test('system falls back to English for unsupported device languages', () {
      expect(
        resolveAppLocale(const Settings(), const Locale('fr')),
        const Locale('en'),
      );
    });

    test('explicit choice overrides the device', () {
      expect(
        resolveAppLocale(
          const Settings(appLanguage: AppLanguageSetting.en),
          const Locale('it'),
        ),
        const Locale('en'),
      );
    });

    test('word language follows the app language unless overridden', () {
      expect(
        resolveWordLanguage(const Settings(), const Locale('it')),
        'it',
      );
      expect(
        resolveWordLanguage(
          const Settings(wordLanguage: WordLanguageSetting.en),
          const Locale('it'),
        ),
        'en',
      );
    });
  });
}
