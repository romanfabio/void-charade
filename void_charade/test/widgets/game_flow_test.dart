import 'dart:async';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_charade/app.dart';
import 'package:void_charade/core/system_ui.dart';
import 'package:void_charade/features/game/game_controller.dart';
import 'package:void_charade/features/game/tilt_detector.dart';
import 'package:void_charade/features/settings/settings_controller.dart';
import 'package:void_charade/services/haptics_service.dart';
import 'package:void_charade/services/sound_service.dart';

import '../helpers/fakes.dart';
import '../helpers/file_asset_bundle.dart';

class _NoopSystemUi extends AppSystemUi {
  const _NoopSystemUi();
  @override
  Future<void> applyMenuMode() async {}
  @override
  Future<void> applyGameMode() async {}
}

class _FakeClock implements GameClock {
  Duration now = Duration.zero;
  bool running = false;

  @override
  void start() => running = true;
  @override
  void stop() => running = false;
  @override
  Duration get elapsed => now;
}

TiltSample _sample(double pitchDegrees) {
  final r = pitchDegrees * math.pi / 180;
  return TiltSample(0, 9.8 * math.cos(r), 9.8 * math.sin(r));
}

class _Session {
  _Session(this.tester);

  final WidgetTester tester;
  final sensor = StreamController<TiltSample>.broadcast(sync: true);
  final clock = _FakeClock();
  final sounds = FakeSoundPlayer();
  final haptics = FakeHaptics();

  /// Moves time forward in 20 ms steps (50 Hz), with the phone held at [pitch].
  Future<void> advance(int ms, {double pitch = 0}) async {
    for (var left = ms; left > 0; left -= 20) {
      clock.now += const Duration(milliseconds: 20);
      sensor.add(_sample(pitch));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  String get currentWord =>
      tester.widget<AutoSizeText>(find.byType(AutoSizeText)).data!;

  Future<void> openApp({Map<String, Object> prefs = const {}}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(sensor.close);

    SharedPreferences.setMockInitialValues({
      'roundSeconds': 30,
      'countdownSeconds': 3,
      ...prefs,
    });
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...realAssetOverrides(),
          ...feedbackOverrides(sounds, haptics),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          deviceLocaleProvider.overrideWithValue(const Locale('en')),
          accelerometerStreamProvider.overrideWithValue(sensor.stream),
          gameClockFactoryProvider.overrideWithValue(() => clock),
          appSystemUiProvider.overrideWithValue(const _NoopSystemUi()),
        ],
        child: const VoidCharadeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startAnimals() async {
    await tester.tap(find.text('Animals'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Lets the app dispose its timers so the test can end cleanly.
  Future<void> shutDown() async {
    await tester.pumpWidget(const SizedBox());
  }
}

void main() {
  testWidgets('home lists the categories that have words', (tester) async {
    final s = _Session(tester);
    await s.openApp();
    expect(find.text('Animals'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    // The grid is lazy: the last tile only exists once scrolled into view.
    await tester.scrollUntilVisible(
      find.text('Spicy'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Spicy'), findsOneWidget);
    await s.shutDown();
  });

  testWidgets('18+ categories can be hidden from the settings', (tester) async {
    final s = _Session(tester);
    await s.openApp(prefs: {'showAdult': false});
    expect(find.text('Animals'), findsOneWidget);
    // Scroll to the very end of the grid: the last tile is a regular one.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Easy Words'), findsOneWidget);
    expect(find.text('Spicy'), findsNothing);
    expect(find.text('Party & Nightlife'), findsNothing);
    await s.shutDown();
  });

  testWidgets('a full round: countdown, tilts, time up, results',
      (tester) async {
    final s = _Session(tester);
    await s.openApp();
    await s.startAnimals();

    // Countdown.
    expect(find.text('Put the phone on your forehead!'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await s.advance(1000);
    expect(find.text('2'), findsOneWidget);
    await s.advance(2200);

    // First word.
    expect(find.byType(AutoSizeText), findsOneWidget);
    final first = s.currentWord;

    // Screen down = correct.
    await s.advance(300, pitch: -70);
    expect(find.text('CORRECT!'), findsOneWidget);
    await s.advance(900);
    final second = s.currentWord;
    expect(second, isNot(first));

    // Screen up = skip.
    await s.advance(300, pitch: 70);
    expect(find.text('SKIP'), findsOneWidget);
    await s.advance(900);
    final third = s.currentWord;
    expect(third, isNot(anyOf(first, second)));

    // Let the time run out with the third word still on screen.
    await s.advance(28000);
    expect(find.text("TIME'S UP!"), findsOneWidget);
    await s.advance(2000);

    // Results: 1 guessed, 1 skipped, 1 not played, score 1.
    expect(find.text('Round over'), findsOneWidget);
    expect(find.text('1 point'), findsOneWidget);
    expect(find.text('Guessed 1'), findsOneWidget);
    expect(find.text('Skipped 1'), findsOneWidget);
    expect(find.text('Not played 1'), findsOneWidget);
    for (final w in [first, second, third]) {
      expect(find.text(w), findsOneWidget);
    }

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Random category'), findsOneWidget);
    await s.shutDown();
  });

  group('sound and vibration', () {
    Future<_Session> playCorrectThenSkip(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
    }) async {
      final s = _Session(tester);
      await s.openApp(prefs: prefs);
      await s.startAnimals();
      await s.advance(3200); // countdown 3-2-1, go, first word
      await s.advance(300, pitch: -70); // correct
      await s.advance(900);
      await s.advance(300, pitch: 70); // skip
      return s;
    }

    testWidgets('the whole round is audible and felt', (tester) async {
      final s = await playCorrectThenSkip(tester);
      expect(s.sounds.played, [
        SoundEffect.countdownBeep, // 3
        SoundEffect.countdownBeep, // 2
        SoundEffect.countdownBeep, // 1
        SoundEffect.go,
        SoundEffect.correct,
        SoundEffect.skip,
      ]);
      expect(s.haptics.patterns, [HapticPatterns.correct, HapticPatterns.skip]);

      // The ticking starts with 5 seconds left, then the buzzer.
      await s.advance(21000);
      final ticks = s.sounds.played.where((e) => e == SoundEffect.tick).length;
      expect(ticks, 0);
      await s.advance(7000); // ~0.3 s left: ticks for 5, 4, 3, 2, 1
      expect(s.sounds.played.where((e) => e == SoundEffect.tick).length, 5);
      await s.advance(2000);
      expect(s.sounds.played.last, SoundEffect.timeUp);
      expect(s.haptics.patterns.last, HapticPatterns.timeUp);
      await s.shutDown();
    });

    testWidgets('sounds off: still vibrates', (tester) async {
      final s = await playCorrectThenSkip(
        tester,
        prefs: {'soundEnabled': false},
      );
      expect(s.sounds.played, isEmpty);
      expect(s.haptics.patterns.length, 2);
      await s.shutDown();
    });

    testWidgets('vibration off: still plays sounds', (tester) async {
      final s = await playCorrectThenSkip(
        tester,
        prefs: {'vibrationEnabled': false},
      );
      expect(s.haptics.patterns, isEmpty);
      expect(s.sounds.played, contains(SoundEffect.correct));
      await s.shutDown();
    });

    testWidgets('ticking off: no ticks in the last seconds', (tester) async {
      final s = await playCorrectThenSkip(tester, prefs: {'tickEnabled': false});
      await s.advance(30000);
      expect(s.sounds.played, isNot(contains(SoundEffect.tick)));
      expect(s.sounds.played, contains(SoundEffect.timeUp));
      await s.shutDown();
    });
  });

  testWidgets('skip penalty makes the score negative', (tester) async {
    final s = _Session(tester);
    await s.openApp(prefs: {'skipPenalty': true});
    await s.startAnimals();
    await s.advance(3200);

    await s.advance(300, pitch: 70);
    await s.advance(900);
    await s.advance(300, pitch: 70);
    await s.advance(900);
    await s.advance(30000);
    await s.advance(2000);

    expect(find.text('-2 points'), findsOneWidget);
    await s.shutDown();
  });

  testWidgets('quit asks for confirmation and returns home', (tester) async {
    final s = _Session(tester);
    await s.openApp();
    await s.startAnimals();
    await s.advance(3200);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Quit the round?'), findsOneWidget);

    await tester.tap(find.text('Keep playing'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Quit the round?'), findsNothing);
    expect(find.byType(AutoSizeText), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Quit'));
    await tester.pumpAndSettle();
    expect(find.text('Random category'), findsOneWidget);
    await s.shutDown();
  });

  testWidgets('going to the background freezes the round and resumes with '
      'a short countdown', (tester) async {
    final s = _Session(tester);
    await s.openApp();
    await s.startAnimals();
    await s.advance(3200);
    final word = s.currentWord;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    s.clock.stop(); // (the controller stops it too; time does not move)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Get ready…'), findsOneWidget);
    await s.advance(3200);
    expect(find.text('Get ready…'), findsNothing);
    expect(s.currentWord, word);
    await s.shutDown();
  });
}
