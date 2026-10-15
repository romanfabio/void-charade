# Void Charade — Implementation Plan

A cross-platform (Android + iOS), fully offline "heads-up" charade game built with Flutter.

---

## 1. Decisions log

| # | Topic | Decision |
|---|-------|----------|
| 1 | Tilt mapping | Phone in landscape on forehead, screen facing the team. Screen toward **floor = guessed**, toward **ceiling = skip**. Settings toggle to swap. |
| 2 | Game mode | v1: single round → results. No teams, no multi-round scoring. |
| 3 | Word repetition | A word never appears twice **within a round**. No cross-round memory. |
| 4 | Word on screen at time-up | Shown in results as **"not played"**, 0 points. |
| 5 | Scoring | Points = guessed. Optional setting "Skip = −1" (default off). |
| 6 | Manual correction on results | Not included. |
| 7 | During a round | No pause. Player can only **quit, with confirmation**. |
| 8 | Category picker | Regular categories + **"Random category"** + **"Mix all"**. |
| 9 | Content size | **50 categories**, 300–400 words each (see §6), per language. |
| 10 | Content source | Written by Claude, checked by a validation script, spot-checked by you. |
| 11 | Languages | Same category set, **independent word lists** per language (IT / EN). |
| 12 | Word language | Separate setting, defaults to "same as app language". |
| 13 | Audience | Includes **18+ / party categories** (badged, hideable). No difficulty levels. |
| 14 | Custom categories | Not in v1. |
| 15 | Timer / countdown | Timer 30–180 s, step 15, default 60. Countdown 3–10 s, default 5. |
| 16 | Feedback | Sounds, vibration, final-seconds ticking — each with its own toggle. |
| 17 | Sounds | Free CC0 sound effects. |
| 18 | Default UI language | Device locale if Italian, otherwise English. |
| 19 | Look & name | Bold, colourful party style. Name: **Void Charade**. |
| 20 | Distribution | Personal install only (no store release for now). |
| 21 | Tooling | Flutter not installed yet → setup is Milestone 0. |
| 22 | Ads / analytics / network | None. Fully offline, no tracking, no internet permission needed. |

### Decisions I made (tell me if you disagree)
- **App sent to background mid-round** (phone call, home button): the round is frozen and resumes with a short 3 s countdown when you return. This isn't a user-facing pause — it only stops a call from wasting the round.
- **Score can go negative** when "Skip = −1" is on (e.g. 2 guessed, 5 skipped = −3).
- **18+ categories** are visible by default with an "18+" badge. A settings toggle hides them, and "Random" and "Mix all" respect that toggle.
- **The next word appears only after the phone returns upright.** After a tilt, a full-screen green/orange flash shows for at least 0.6 s. This prevents double triggers.
- **Debug-only tap controls** (tap left = skip, tap right = correct) and an angle overlay, to test on an emulator. They are not in release builds.
- **Android first.** iOS install path is in §11.

---

## 2. Tech stack

| Concern | Choice | Why |
|---|---|---|
| Framework | **Flutter (latest stable)**, Dart 3 | One codebase, great for full-screen animated UIs. |
| State management | `flutter_riverpod` | Testable controllers, no boilerplate explosion. |
| Navigation | `go_router` | Declarative routes, easy redirect/back handling. |
| Tilt detection | `sensors_plus` (accelerometer) | Standard, same axis convention on Android & iOS. |
| Sound | `audioplayers` (pre-loaded `AudioPool`) | Low-latency short effects, mature on both platforms. |
| Vibration | `vibration` | Strong, duration-controlled buzz (built-in haptics are too weak on a forehead). |
| Keep screen on | `wakelock_plus` | Screen must not sleep during a round. |
| Settings storage | `shared_preferences` | A handful of key/values. |
| Localization | `flutter_localizations` + `intl` + **gen-l10n** (ARB files) | Official, compile-time-checked strings. |
| Splash | `flutter_native_splash` | Native splash on both platforms incl. Android 12+ splash API. |
| App icon | `flutter_launcher_icons` | Generates all icon sizes from one PNG. |
| Word fitting | `auto_size_text` | Long words/phrases shrink to fit the landscape screen. |
| Tests | `flutter_test`, `mocktail` | Unit + widget tests. |

Exact versions are pinned to the latest stable at implementation time.

**Fonts** are bundled as assets, never downloaded at runtime: *Lilita One* for titles and the word on screen, *Nunito* for body text. Both are SIL Open Font License.

**Minimum OS**: Android 6.0 (API 23), iOS 13.

### Content storage: plain text, no compression
- About 50 categories × 2 languages × about 350 words ≈ 35k entries ≈ **400–500 KB** of text. APK and IPA files are already zip-compressed, so extra compression saves almost nothing and makes the lists harder to review.
- **One UTF-8 `.txt` file per category per language, one word per line.** This is the easiest format to generate, diff, review and spot-check. The app loads it directly with `rootBundle.loadString`, so there's no build/convert step.
- Category metadata (id, names in both languages, emoji, colour, 18+ flag) lives in one `assets/categories.json`.
- Word files are loaded **lazily** when a category is chosen. "Mix all" loads all visible categories of the word language, which takes a few ms.

```json
// assets/categories.json
{
  "version": 1,
  "categories": [
    { "id": "animals", "emoji": "🐾", "color": "#FF6B35", "adult": false,
      "name": { "en": "Animals", "it": "Animali" } },
    { "id": "spicy", "emoji": "🌶️", "color": "#E91E63", "adult": true,
      "name": { "en": "Spicy", "it": "Piccante" } }
  ]
}
```
```
# assets/words/it/animals.txt
Elefante
Giraffa
Ornitorinco
...
```

---

## 3. Project structure

```
charade/                         ← repo root (git init in M0)
├─ IMPLEMENTATION_PLAN.md
└─ void_charade/                 ← Flutter project (flutter create)
   ├─ pubspec.yaml
   ├─ l10n.yaml
   ├─ analysis_options.yaml      (flutter_lints + a few stricter rules)
   ├─ flutter_native_splash.yaml
   ├─ assets/
   │  ├─ categories.json
   │  ├─ words/en/<category_id>.txt
   │  ├─ words/it/<category_id>.txt
   │  ├─ sounds/  correct.wav, skip.wav, tick.wav, countdown_beep.wav, go.wav, time_up.wav
   │  ├─ fonts/   LilitaOne-Regular.ttf, Nunito-*.ttf
   │  └─ branding/ icon.png, icon_foreground.png, splash_logo.png
   ├─ lib/
   │  ├─ main.dart                       (bootstrap, ProviderScope, preload settings + sounds)
   │  ├─ app.dart                        (MaterialApp.router, theme, locale wiring)
   │  ├─ l10n/ app_en.arb, app_it.arb
   │  ├─ core/
   │  │  ├─ theme/ app_theme.dart, app_colors.dart, app_text_styles.dart
   │  │  ├─ router.dart
   │  │  └─ system_ui.dart              (orientation, immersive mode, wakelock helpers)
   │  ├─ services/
   │  │  ├─ sound_service.dart
   │  │  └─ haptics_service.dart
   │  └─ features/
   │     ├─ settings/  settings.dart, settings_repository.dart, settings_controller.dart, settings_screen.dart
   │     ├─ categories/ category.dart, category_repository.dart, word_repository.dart,
   │     │              categories_screen.dart, widgets/category_tile.dart
   │     ├─ game/      tilt_detector.dart, game_state.dart, game_controller.dart,
   │     │             game_screen.dart, widgets/ (countdown_view, word_view, feedback_flash, timer_bar, quit_dialog)
   │     └─ results/   results_screen.dart, widgets/result_row.dart
   ├─ tool/
   │  └─ validate_words.dart            (content validator, see §7)
   └─ test/
      ├─ game/ tilt_detector_test.dart, game_controller_test.dart
      ├─ categories/ word_repository_test.dart
      ├─ settings/ settings_repository_test.dart
      ├─ content/ content_validation_test.dart   (runs the validator as a test)
      ├─ l10n/ arb_keys_test.dart                 (IT and EN have identical keys)
      └─ widgets/ results_screen_test.dart, quit_dialog_test.dart, settings_screen_test.dart
```

Bundle / application id: `com.voidcharade.app` (placeholder; change before any store release).

---

## 4. Screens & flow

```
Splash ──► Categories (home) ──► Game ──► Results
               │   ▲                         │
               ▼   │                         ├─ "Play again" (same category / same mix) ─► Game
            Settings                         └─ "Categories" ─► Categories
```

| Screen | Orientation | Content |
|---|---|---|
| **Splash** | portrait | Native splash (logo on gradient) while settings, category index and sounds load (<1 s). |
| **Categories (home)** | portrait | App title + settings gear. Two wide tiles at top: **🎲 Random category**, **🌀 Mix all**. Then a 2-column grid of category tiles (emoji, name in UI language, colour, "18+" badge). Small subtitle showing current timer and word language, e.g. "60 s · 🇮🇹 words". |
| **Game** | **landscape** (both landscape directions allowed), immersive full screen, wakelock on | Phases described in §5. Small ✕ button in a corner → quit confirmation. System back → same confirmation. |
| **Results** | portrait | Big score, "Guessed X · Skipped Y" (and "−Y" if penalty on), list of words in play order with icon + colour: ✅ guessed (green), ⏭️ skipped (orange), ⏸ not played (grey). Buttons: **Play again**, **Categories**. |
| **Settings** | portrait | See below. |

### Settings screen

| Setting | Type | Default |
|---|---|---|
| App language | System / Italiano / English | System (IT if device is Italian, else EN) |
| Word language | Same as app / Italiano / English | Same as app |
| Round duration | Slider 30–180 s, step 15 | 60 s |
| Countdown | Slider 3–10 s, step 1 | 5 s |
| Skip costs 1 point | Switch | Off |
| Sounds | Switch | On |
| Vibration | Switch | On |
| Final-seconds ticking | Switch (disabled when Sounds is off) | On |
| Swap tilt directions | Switch | Off |
| Show 18+ categories | Switch | On |
| About | App version, credits (sound/font licences) | — |

All settings persist via `shared_preferences` and apply immediately. A language change rebuilds the app locale live.

---

## 5. Game mechanics (core of the app)

### 5.1 Game state machine

```
countdown ──► waitingUpright ──► showingWord ◄──► feedback ──► … ──► timeUp ──► (navigate) Results
    │                                 │                │
    └──────────── quit (confirm) ─────┴────────────────┘──► Categories
```

- **countdown**: big numbers N…1 with a beep per second, text "Put the phone on your forehead!". Last beep is the "go" sound.
- **waitingUpright**: shown only if the phone isn't upright when the countdown ends ("Hold the phone upright"). This prevents an instant false trigger. **The round timer starts when the first word is shown.**
- **showingWord**: the word fills the screen (auto-sized, Lilita One, white on the category colour), with a thin timer bar and seconds left in a corner.
- **feedback**: after a tilt, a full-screen flash: green "✔ CORRECT!" or orange "SKIP", plus sound and vibration. The next word appears when **≥ 600 ms have passed AND the phone is upright again**. The round timer keeps running.
- **Last 5 seconds**: tick sound each second (if enabled), and the timer turns red and pulses.
- **timeUp**: "Time's up!" sound + long vibration + 1.5 s "TIME'S UP" screen, then Results. The word on screen at time-up is recorded as **not played**. If the time runs out during *feedback*, no extra word is recorded.
- **Word list exhausted** (practically impossible: 300+ words in ≤180 s): the round ends early.

### 5.2 Word selection
At round start, `WordRepository` returns the list for (category, word language). For "Mix all", it merges all visible categories and de-duplicates. The list is **shuffled once** with `Random()` and consumed in order. This guarantees randomness and **no repeats within a round**. "Random category" picks a random visible category first, then does the same.

### 5.3 Tilt detection (`TiltDetector`)
- Source: `accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)` (~50 Hz, gravity included). With `sensors_plus`, a phone lying flat with the screen up reads z ≈ +9.8 on both platforms.
- **Low-pass filter** each axis (α ≈ 0.2) to remove jitter.
- **Pitch angle** θ = atan2(z, √(x² + y²)) in degrees. θ ≈ 0° when the phone stands upright on the forehead (any landscape direction, because the x/y split doesn't matter).
  - θ > **+50°** → screen tilted toward the ceiling → **SKIP**
  - θ < **−50°** → screen tilted toward the floor → **CORRECT**
  - |θ| < **25°** → **upright / neutral**
- **Hysteresis**: after a trigger, no new trigger until the phone has been back in the neutral zone (and the 600 ms feedback has elapsed). This makes "one tilt = one action" robust.
- "Swap tilt directions" just inverts the mapping.
- Thresholds are constants in one place, tuned on a real device in M7. The debug overlay shows the live θ.
- The detector is a pure class: it takes a stream of `(x, y, z)` and emits `TiltEvent.correct / skip / neutral`. It is fully unit-testable with synthetic data.

### 5.4 Timer
Elapsed time is measured with a `Stopwatch` (monotonic), not by counting `Timer.periodic` ticks, so there is no drift. A UI ticker refreshes the display. If the app goes to background (`AppLifecycleState.paused`), the stopwatch stops. On resume: 3 s mini-countdown, then it continues.

### 5.5 Scoring
`score = guessed − (skipPenalty ? skipped : 0)`. Not-played words never count.

### 5.6 Round result model
```dart
enum WordOutcome { guessed, skipped, notPlayed }
class PlayedWord { final String text; final WordOutcome outcome; }
class RoundResult {
  final String categoryLabel;        // category name or "Mix all"
  final List<PlayedWord> words;      // in play order
  final bool skipPenalty;
  int get guessed; int get skipped; int get score;
}
```

---

## 6. Content plan: 50 categories

Target **400** where the topic naturally supports it, **300** where 400 would mean filler. Total ≈ **17,800 words per language** (≈ 35,600 overall). If a category can't reach 300 *good* words in one language while being written, I'll merge or replace it and tell you.

| # | id | 🙂 | English | Italiano | Target |
|---|----|---|---------|----------|-------:|
| 1 | animals | 🐾 | Animals | Animali | 400 |
| 2 | food | 🍕 | Food | Cibo | 400 |
| 3 | kitchen | 🍳 | Kitchen & Cooking | Cucina | 300 |
| 4 | home_objects | 🛋️ | Things at Home | Oggetti di casa | 400 |
| 5 | places | 🏙️ | Places & Rooms | Luoghi e stanze | 400 |
| 6 | jobs | 💼 | Jobs | Mestieri | 400 |
| 7 | actions | 🏃 | Actions | Azioni | 400 |
| 8 | sports | 🏅 | Sports | Sport | 400 |
| 9 | football | ⚽ | Football | Calcio | 400 |
| 10 | movies | 🎬 | Movies | Film | 400 |
| 11 | tv_series | 📺 | TV Series | Serie TV | 400 |
| 12 | cartoons | 🧸 | Cartoons | Cartoni animati | 400 |
| 13 | disney | 🏰 | Disney & Pixar | Disney e Pixar | 300 |
| 14 | fictional_characters | 🦸 | Fictional Characters | Personaggi immaginari | 400 |
| 15 | celebrities | 🌟 | Celebrities | Personaggi famosi | 400 |
| 16 | historical_figures | 🏛️ | Historical Figures | Personaggi storici | 400 |
| 17 | musicians | 🎤 | Singers & Bands | Cantanti e band | 400 |
| 18 | songs | 🎵 | Songs | Canzoni | 400 |
| 19 | music | 🎸 | Music & Instruments | Musica e strumenti | 300 |
| 20 | video_games | 🎮 | Video Games | Videogiochi | 400 |
| 21 | books | 📚 | Books & Authors | Libri e scrittori | 400 |
| 22 | fairy_tales_myths | 🧚 | Fairy Tales & Myths | Fiabe e miti | 300 |
| 23 | fantasy_scifi | 🚀 | Fantasy & Sci-Fi | Fantasy e fantascienza | 300 |
| 24 | horror | 👻 | Horror & Monsters | Horror e mostri | 300 |
| 25 | geography | 🌍 | Geography | Geografia | 400 |
| 26 | landmarks | 🗼 | Landmarks | Monumenti e luoghi famosi | 300 |
| 27 | italy | 🇮🇹 | Italy | Italia | 400 |
| 28 | travel | ✈️ | Travel & Transport | Viaggi e trasporti | 400 |
| 29 | summer | 🏖️ | Summer & Holidays | Estate e vacanze | 300 |
| 30 | celebrations | 🎄 | Celebrations | Feste e ricorrenze | 300 |
| 31 | nature | 🌳 | Nature & Weather | Natura e meteo | 400 |
| 32 | body_health | 🫀 | Body & Health | Corpo e salute | 400 |
| 33 | clothes | 👗 | Clothes & Fashion | Abbigliamento e moda | 400 |
| 34 | science_tech | 🔬 | Science & Technology | Scienza e tecnologia | 400 |
| 35 | inventions | 💡 | Inventions | Invenzioni | 300 |
| 36 | internet | 📱 | Internet & Social Media | Internet e social | 300 |
| 37 | brands | 🏷️ | Brands | Marchi famosi | 400 |
| 38 | school_office | 🏫 | School & Office | Scuola e ufficio | 300 |
| 39 | hobbies | 🎨 | Hobbies | Hobby e passatempi | 300 |
| 40 | toys_games | 🎲 | Toys & Games | Giochi e giocattoli | 300 |
| 41 | retro | 📼 | 80s & 90s | Anni '80 e '90 | 300 |
| 42 | idioms | 💬 | Idioms & Sayings | Modi di dire | 400 |
| 43 | theater | 🎭 | Theater & Shows | Teatro e spettacolo | 300 |
| 44 | easy_words | 🧒 | Easy Words | Parole facili | 400 |
| 45 | party | 🎉 | Party & Nightlife **18+** | Festa e vita notturna **18+** | 300 |
| 46 | drinks | 🍸 | Drinks & Cocktails **18+** | Alcol e cocktail **18+** | 300 |
| 47 | dating | ❤️ | Love & Dating **18+** | Amore e appuntamenti **18+** | 300 |
| 48 | awkward | 😳 | Awkward Situations **18+** | Situazioni imbarazzanti **18+** | 300 |
| 49 | slang | 🤬 | Slang & Swear Words **18+** | Slang e parolacce **18+** | 300 |
| 50 | spicy | 🌶️ | Spicy **18+** | Piccante **18+** | 300 |

### Writing guidelines (applied by me, enforced by the validator where possible)
- 1–5 words per entry (most are 1–2), max 30 characters, so it stays readable from across a room. (Changed from 4 to 5 words in M2 so titles like "Il Signore degli Anelli" fit.)
- Recognisable by an average adult **of that language's culture**. Italian lists use Italian release titles (e.g. "Il Padrino", "Lo squalo") and include Italian celebrities, songs and TV. English lists use international/English-language references.
- No near-duplicates (singular/plural, with/without article), no entries that contain the category name, no ultra-obscure trivia.
- Proper capitalisation for proper nouns. Common nouns are capitalised as the first letter only, for consistent display.
- 18+ categories: cheeky/explicit is fine, but no slurs targeting protected groups.

---

## 7. Content validation script (`tool/validate_words.dart`)

Run with `dart run tool/validate_words.dart` (add `--strict` to make missing word files an error, `--seed N` for reproducible spot-check files). It also runs as a test (`test/content/content_validation_test.dart`), so `flutter test` fails on broken content. The logic lives in `tool/content_validator.dart` and shares its word normalisation with the app (`lib/features/categories/word_utils.dart`).

**Pending content:** by default a category without a word file yet is reported as "pending", not an error. The app only shows a category once its word file for the current word language is bundled, so unfinished content never appears as an empty tile. M7 finishes with a `--strict` run.

**Errors** (non-zero exit):
- `categories.json` is valid JSON, ids are unique and snake_case, `name.en` + `name.it` are present, and colour is valid hex.
- Every category has `words/en/<id>.txt` and `words/it/<id>.txt`, and there are no orphan files.
- Word count ≥ category minimum (300).
- No empty lines, no leading/trailing/double spaces, valid UTF-8, no BOM.
- **No duplicates inside a file** after normalisation: lower-case, strip accents, strip leading articles (*il, lo, la, i, gli, le, l', un, uno, una, un', the, a, an*), strip punctuation, collapse spaces.
- Max 30 characters and max 5 words.
- Allowed characters: letters (incl. accented), digits, space, `' - . & ! ? , : /`.

**Warnings**:
- The same normalised word appears in multiple categories of the same language (allowed, but listed).
- An entry contains the category's own name.

**Output**:
- Summary table: category × language → count, errors, warnings.
- `build/spot_check_en.md` and `build/spot_check_it.md` with **20 random words per category**, ready for your review.

---

## 8. UI / visual style ("bold, colourful party")
- Dark base (`#14101F`, deep purple-black) with **vivid gradients**: magenta → orange, cyan → violet. Each category has its own saturated colour, used as the background of the game screen for that category.
- Lilita One for titles and the word, Nunito for everything else. Big rounded tiles (radius 24), soft glows, chunky buttons.
- Motion: tiles pop in with a stagger, countdown numbers zoom/fade, a full-screen colour flash on guess/skip, the score counts up on the results screen, and confetti if the score ≥ 10 (custom painter, no package).
- Logo: "VOID CHARADE" wordmark with a stylised phone-on-forehead / question-mark glyph. I'll make it as SVG → PNG for icon and splash.
- Splash: logo centred on the dark gradient. Android 12+ shows the icon in a circle (API limitation), with the same background colour for a seamless hand-off.
- Accessibility: high contrast, the word text is huge, and colour is never the only signal (results also use icons).

## 9. Sounds & haptics
- **Sounds** (CC0): primary source is **Kenney.nl** audio packs (CC0 licence, e.g. "Interface Sounds", "Digital Audio"). I'll ask before downloading anything. Fallback: synthesise simple beeps/chimes with a small script.
- Files: `correct`, `skip`, `tick`, `countdown_beep`, `go`, `time_up`. They are short **WAV** files (lowest latency; OGG isn't supported on iOS).
- All sounds are pre-loaded into `AudioPool`s at app start, so playback is instant.
- iOS audio session uses category *playback* + *mixWithOthers*: sounds play **even when the silent switch is on** (a party game where players don't hear feedback is useless) and don't stop the user's music.
- **Vibration**: correct = 1 short strong pulse (150 ms), skip = 2 short pulses, time-up = 1 long pulse (600 ms). Android needs the `VIBRATE` permission (added to the manifest).
- `SoundService` and `HapticsService` read the settings toggles, so callers don't need to.

## 10. Localization
- gen-l10n with `app_en.arb` (template) and `app_it.arb`. Every UI string goes through `AppLocalizations`, with no hard-coded text.
- Category names come from `categories.json`, in the UI language.
- Locale resolution: settings override → else device locale if `it` → else `en`.
- Word language is resolved independently: settings → else the effective UI language.
- `arb_keys_test.dart` makes sure both ARB files have the same keys and placeholders.

---

## 11. Platforms, building & installing on your phones

**Android (primary, easy, works from Windows)**
- Debug run: `flutter run` with the phone connected via USB (Developer options → USB debugging).
- Personal install: `flutter build apk --release`. Sign it with a locally generated keystore (kept **outside** the repo, referenced via `key.properties`, git-ignored). Install the APK via USB (`flutter install`) or copy the file to the phone.

**iOS — needs a decision when we get there.** iOS apps can only be *built and signed* on macOS. Options:
1. **Borrow/use a Mac** with Xcode + a free Apple ID → `flutter run` installs on your iPhone. The app expires after **7 days** (re-install to refresh).
2. **Codemagic** (cloud Mac, free tier) builds the IPA + **paid Apple Developer account** (€99/year) → install via TestFlight/ad-hoc. No expiry issues.
3. Codemagic unsigned IPA + **Sideloadly** on Windows with a free Apple ID → works without a Mac, but re-sign every 7 days.

The code is iOS-ready from day one (orientations, audio session, Info.plist). Only the build/sign step depends on the option you choose.

---

## 12. Testing strategy

| Level | What |
|---|---|
| Unit | `TiltDetector` with synthetic accelerometer sequences: neutral → down → neutral = exactly 1 correct; held tilt = 1 trigger; jitter around ±45° = 0 triggers; swap mapping. `GameController` with a fake clock and fake detector: no repeated words, time-up marks not-played, scoring with/without penalty, quit, background freeze/resume, list exhaustion. `WordRepository`: parsing, mix-all de-dup, 18+ filtering. Settings: persistence and defaults. |
| Content | Validator as a test (all 100 files). |
| L10n | ARB key parity. |
| Widget | Results screen (counts, icons, negative score), quit confirmation dialog, settings screen interactions. |
| Manual on device | Checklist: tilt feel in both landscape directions, sitting vs standing, sound latency, vibration strength, silent switch (iOS), screen never sleeps, back button = quit dialog, incoming call during a round, language switch, all settings applied. **Tune thresholds here.** |

---

## 13. Milestones

| # | Milestone | Output | Done when |
|---|---|---|---|
| **M0** | Environment setup (Windows) | Flutter SDK, Android Studio (Android SDK + platform tools), VS Code Flutter extension, Git, USB debugging on your Android phone, `git init` | `flutter doctor` is green for Android, and a sample app runs on your phone |
| **M1** | Scaffold & foundations | `flutter create`, packages, lints, folder structure, theme, fonts, router, l10n wiring, settings model + repository + screen | App launches, settings persist, language switches live |
| **M2** | Content format & loader | `categories.json` (all 50 entries), validator script + test, `CategoryRepository` / `WordRepository`, **3 sample categories** fully written (IT + EN), categories screen with Random / Mix all / 18+ | Validator passes, the categories grid shows and loads words |
| **M3** | Game core | `TiltDetector`, `GameController` (state machine, Stopwatch timer, scoring), game screen (countdown, waitingUpright, word, feedback, time-up), landscape + immersive + wakelock, quit dialog, background freeze, debug tap controls + angle overlay. **Done in M3, beyond the original scope:** a functional results screen (score, counts, word list, play again) so a round has an ending, and a `GameEngine` split out of the controller so every timing rule is unit-tested | A full round is playable on the phone with tilts; unit tests are green |
| **M4** | Sounds & haptics | Sound files (CC0), `SoundService` with pools, `HapticsService`, ticking, all toggles wired | Feedback is instant and every toggle works |
| **M5** | Results (polish) | The functional screen already exists from M3; add the count-up score animation, confetti for 10+, entry animations | The results screen feels like a finished party app |
| **M6** | Branding & polish | Logo, app icon, native splash, animations, confetti, credits in About | Looks like a finished party app |
| **M7** | Content generation | Remaining 47 categories × 2 languages, written in batches of ~5 categories. Validator run after each batch, spot-check files for you | All 100 files pass the validator, and you've spot-checked them |
| **M8** | Device QA & release build | Manual checklist, threshold tuning, release-signed APK installed on your phones, README with build/install steps | You've played real rounds with friends 🎉 |
| **M9** | iOS (when you choose an option in §11) | Signed build installed on your iPhone | Same checklist passes on iOS |

**M7 can run in parallel with M3–M6** (a separate session): it only depends on the file format and validator from M2.

---

## 14. Risks & mitigations

| Risk | Mitigation |
|---|---|
| False/missed tilts (nodding, laughing, different head angles) | Low-pass filter, hysteresis + "must return upright", 600 ms lockout, thresholds tuned on a device with the debug overlay |
| Sound latency on Android | Pre-loaded `AudioPool`, short WAV files |
| No sound on iOS when muted | `playback` audio session category |
| Content quality / cultural fit | Writing guidelines, validator, spot-check files, per-category minimum with merge/replace rule |
| Emoji look different across platforms | Acceptable for v1; could be replaced with custom icons later |
| iOS signing without a Mac | Decide between the options in §11; Android is fully usable meanwhile |

## 15. Out of scope for v1 (possible v2)
Teams & multi-round scoreboard · custom categories / user words · difficulty levels · manual result correction · more languages · store release (privacy policy, store listings) · video recording of the player (a Heads Up classic).
