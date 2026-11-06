# CLAUDE.md

Guidance for Claude Code (and humans) working in this repository.

## What this is

Void Charade: an offline forehead-charades party game (Android) in Flutter.
The app lives in `void_charade/`; run every Flutter/Dart command from that folder.
Design decisions are in `docs/IMPLEMENTATION_PLAN.md`; user-facing docs in `README.md`.

## Commands (from `void_charade/`)

```bash
flutter pub get
flutter analyze                          # must stay at "No issues found"
flutter test                             # all tests, no device needed
flutter test test/game/game_engine_test.dart --plain-name "touch controls"
dart run tool/validate_words.dart --strict   # content check (also runs inside flutter test)
flutter gen-l10n                         # after editing lib/l10n/*.arb
flutter build apk --release              # signed if android/key.properties exists
```

Device checks use adb (`adb install -r`, `adb exec-out screencap -p`). Debug builds have a
pitch overlay and a bug button that fakes the sensor (tap left = skip, right = correct).

## Architecture

- `lib/features/game/game_engine.dart`: pure-Dart state machine. No clock, no sensors: it
  receives a monotonic `Duration now` and accelerometer samples. Keep it free of Flutter
  imports so every timing rule stays unit-testable with synthetic time.
- `tilt_detector.dart`: low-pass filter, pitch = `atan2(z, hypot(x, y))`, trigger angle +
  smaller neutral angle (hysteresis), one tilt = one event. Angles come from
  `TiltSensitivity` in `lib/features/settings/settings.dart`.
- `game_controller.dart`: Riverpod `Notifier` wrapping the engine with a stoppable
  stopwatch, a 50 ms timer, the sensor subscription and lifecycle suspend/resume. Touch
  mode (`Settings.touchControls`) skips the sensor entirely.
- `lib/services/`: `FeedbackService` maps `GameEvent`s to sound/vibration using the live
  settings; `SoundPlayer` and `Haptics` are interfaces so tests use fakes.
- Settings: `Settings` model -> `SettingsRepository` (shared_preferences, one key per field)
  -> `settingsProvider`. A new setting needs: model field + copyWith, repository key
  (load and save), UI tile, ARB strings in **both** languages, and a test.
- State: Riverpod 3 (`Notifier`, `NotifierProvider.autoDispose.family`). Routing: go_router.

## Conventions

- Dart style from `analysis_options.yaml`: single quotes, `unawaited_futures`, prefer const.
- Every UI string goes through `lib/l10n/app_en.arb` and `app_it.arb`; both files must have
  identical keys (`test/l10n/arb_keys_test.dart` enforces it). Only the English file needs
  `@key` placeholder metadata.
- No network code, no analytics, no new permissions. Keep the app fully offline.
- Files use LF line endings (`.gitattributes`). Word files with CRLF fail the validator.
- Keep comments sparse and explain the *why*; match the surrounding style.

## Testing notes

- Widget tests load assets from disk with `FileAssetBundle` / `realAssetOverrides()`
  (`test/helpers/`): `rootBundle` caches across fake-async zones and hangs the second test.
- Drive rounds with the fake clock and a sensor `StreamController` (see
  `test/widgets/game_flow_test.dart`). Do not `pumpAndSettle` while a round timer runs;
  end each test with `await tester.pumpWidget(const SizedBox())`.
- The home grid is lazy: tiles below the fold do not exist until scrolled into view.
- Platform plugins (audio, vibration, sensors) are always faked in tests.

## Content (word lists)

- `assets/categories.json` lists categories; `assets/words/<en|it>/<id>.txt` holds the words.
  Both languages are written separately for each culture, not translated.
- Rules (validator-enforced): <= 30 chars, <= 5 words, allowed characters only, no
  duplicates per file (case/accents/leading articles ignored), >= 300 entries, LF endings.
  Cross-category duplicates are only warnings (*Mix all* de-duplicates).
- Do not add real private individuals, slurs, or real living people in the 18+ categories.
- A category with no word file for the current language is hidden in the app and reported
  "pending" by the validator unless `--strict` is used.
- After adding or removing word files, run `flutter clean` once if a device build shows
  stale categories (Gradle caches the asset bundle).

## Gotchas

- audioplayers low-latency (SoundPool) players never report completion, so replaying the
  same effect is ignored unless `stop()` is called before `resume()`. `SoundPlayer.play`
  does this; keep it.
- Android release signing reads `android/key.properties` (git-ignored) pointing at a
  keystore outside the repo. Never commit keystores, passwords or `key.properties`.
  Without it, release builds fall back to the debug key; a debug-signed app must be
  uninstalled before installing a release-signed one.
- Sensors: `sensors_plus` gives the Android convention (flat, screen up = z +9.8). Pitch
  is positive when the screen faces the ceiling.
- Generated: `lib/l10n/app_localizations*.dart` (committed), launcher icons and splash
  resources (`dart run flutter_launcher_icons`, `dart run flutter_native_splash:create`),
  `assets/sounds` and `assets/branding` (scripts in `tool/`). Regenerate with the scripts,
  do not hand-edit.
- Licences: code and content are MIT; fonts stay OFL (`assets/fonts/OFL-*.txt` must remain
  bundled and registered in `lib/main.dart`). The app's own licence is bundled as
  `void_charade/assets/LICENSE.txt` (a copy of the root `LICENSE`; a test fails if they
  differ). Update `THIRD_PARTY_NOTICES.md` when adding a dependency or asset.
- Version: `pubspec.yaml` `version:` and `_appVersion` in `settings_screen.dart` must match
  (a test enforces it).
