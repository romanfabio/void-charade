# Void Charade

An offline "heads-up" charade party game for Android and iOS, built with Flutter.
Hold the phone on your forehead (landscape), friends act out the word, tilt the
screen down when you guess it, up to skip. No ads, no tracking, no network.

- 50 categories (incl. 18+), ~20 000 words per language, Italian and English lists
- UI in Italian or English (follows the device by default), separate word language
- Configurable round (30-180 s) and countdown (3-10 s), sounds, vibration and
  final-seconds ticking each with their own toggle, optional "skip = -1"
- Optional touch controls (setting, off by default): right half of the screen =
  correct, left half = skip, instead of tilting
- Results screen with guessed / skipped / not-played words and the score

The full design is in [../IMPLEMENTATION_PLAN.md](../IMPLEMENTATION_PLAN.md).

## Requirements

- Flutter 3.47 (Dart 3.13) and the Android SDK (Android Studio + command-line tools)
- A phone with USB debugging for device runs
- Building for iPhone needs a Mac (or a cloud macOS build) - see "iOS" below

## Everyday commands

Run from this folder (`void_charade/`):

```bash
flutter pub get
flutter analyze
flutter test                      # ~120 tests, fully offline
flutter run                       # debug build on the connected phone
```

Debug builds show a pitch overlay and a bug button (simulated sensors, tap left
= skip, tap right = correct); release builds do not.

> If you add or remove word files and the app shows stale categories, run
> `flutter clean` once: Gradle can reuse a cached asset bundle.

## Release APK for Android

1. Signing: `android/key.properties` (git-ignored) points to a keystore outside
   the repository. Format:

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=void_charade
   storeFile=C:/path/to/void_charade-release.jks
   ```

   To create a new keystore:

   ```bash
   keytool -genkeypair -v -keystore void_charade-release.jks -storetype PKCS12 \
     -alias void_charade -keyalg RSA -keysize 2048 -validity 10000
   ```

   **Back up the keystore and its password.** If you lose them you can no longer
   update an installed app (you would have to uninstall it first, losing its
   settings). Without `key.properties` the release build falls back to the debug
   key, which is fine for quick tests only.

2. Build:

   ```bash
   flutter build apk --release
   ```

   Output: `build/app/outputs/flutter-apk/app-release.apk` (universal APK, ~53 MB).
   Bump `version:` in `pubspec.yaml` (for example `1.0.1+2`) before a new release;
   the number after `+` must increase for Android to accept an update.

3. Install on a phone:

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

   or copy the APK to the phone and open it (allow "install unknown apps" for the
   file manager). Updating over an existing install works only if both APKs are
   signed with the same key: a debug build must be uninstalled before installing
   the release build.

## iOS

The iOS project is generated and has the icons and splash configured, but nothing
has been built for iPhone yet. Options for personal use:

- A Mac with Xcode and a free Apple ID: install by cable, the app expires after
  7 days and must be re-installed.
- A paid Apple Developer account (99 USD/year): TestFlight or ad-hoc, builds
  last 90 days / a year; a cloud CI such as Codemagic can build without a Mac.
- Sideloading tools such as Sideloadly: also limited to 7 days with a free account.

## Words

Word lists are plain text, one entry per line:
`assets/words/<en|it>/<category_id>.txt`. The category list (names, emoji, colour,
18+ flag) is `assets/categories.json`. Rules (enforced by the validator):
UTF-8 with LF line endings, at most 30 characters and 5 words per entry, letters,
digits, spaces and `' - . & ! ? , : /` only, no duplicates within a file (case,
accents and leading articles are ignored), at least 300 entries per file.

```bash
dart run tool/validate_words.dart            # errors + warnings
dart run tool/validate_words.dart --strict   # a missing word file is an error
dart run tool/validate_words.dart --seed 7   # random spot-check sample
```

The validator also writes `build/spot_check_en.md` and `build/spot_check_it.md`
with 20 random entries per category for quick review. Cross-category duplicates
are reported as warnings only: "Mix all" removes duplicates before a round.

## Generated assets

| Asset | How to regenerate |
| --- | --- |
| Sound effects (`assets/sounds/*.wav`) | `dart run tool/generate_sounds.dart` |
| Logo, icon, splash images (`assets/branding/`) | `flutter test tool/generate_branding_test.dart` |
| Android/iOS launcher icons | `dart run flutter_launcher_icons` |
| Native splash screens | `dart run flutter_native_splash:create` |

## Tuning the tilt

Detection constants are in `lib/features/game/tilt_detector.dart`:
`triggerDegrees` (default 50: how far the phone must tilt from upright to count)
and `neutralDegrees` (25: how close to upright it must come back before the next
word). The next word also needs a 600 ms pause. The pitch overlay in debug builds
shows the live angle.

## Project layout

```
lib/
  core/          router, theme, system UI
  features/
    categories/  category index, word loading, home screen
    game/        tilt detector, game engine (pure Dart), controller, screen
    results/     round result model, results screen, confetti
    settings/    settings model, storage, screen
  services/      sound, haptics, feedback mapping
  l10n/          app_en.arb, app_it.arb
tool/            content validator, asset generators
test/            unit, content and widget tests
```

## Credits and licences

Fonts: Lilita One and Nunito (SIL Open Font License 1.1, in `assets/fonts/`).
Sound effects were synthesised for this app. Flutter package licences are listed
in the app under Settings > About > View licenses.
