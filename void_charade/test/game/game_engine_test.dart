import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/features/game/game_engine.dart';
import 'package:void_charade/features/game/tilt_detector.dart';
import 'package:void_charade/features/results/round_result.dart';

TiltSample _at(double pitchDegrees) {
  final r = pitchDegrees * math.pi / 180;
  return TiltSample(0, 9.8 * math.cos(r), 9.8 * math.sin(r));
}

const _down = -70.0;
const _up = 70.0;
const _flat = 85.0;

/// Drives an engine with synthetic time (20 ms steps = 50 Hz sensor).
class Harness {
  Harness({
    List<String>? words,
    Duration round = const Duration(seconds: 30),
    Duration countdown = const Duration(seconds: 3),
    bool skipPenalty = false,
    bool swapTilt = false,
    double startPitch = 0,
  }) : pitch = startPitch {
    engine = GameEngine(
      config: GameConfig(
        roundDuration: round,
        countdownDuration: countdown,
        skipPenalty: skipPenalty,
        swapTilt: swapTilt,
      ),
      words: words ?? [for (var i = 0; i < 100; i++) 'w$i'],
      onEvent: events.add,
    )..start(now);
  }

  late final GameEngine engine;
  final events = <GameEvent>[];
  var now = Duration.zero;
  double pitch;

  GameState get state => engine.state;

  List<GameEventKind> get kinds => [for (final e in events) e.kind];

  /// Lets [d] pass with the phone held at [at] degrees (or the current pitch).
  void advance(Duration d, {double? at}) {
    if (at != null) pitch = at;
    final end = now + d;
    while (now < end) {
      now += const Duration(milliseconds: 20);
      engine.onSample(_at(pitch));
      engine.tick(now);
    }
  }

  void advanceMs(int ms, {double? at}) => advance(Duration(milliseconds: ms), at: at);

  /// Plays the countdown and returns once the first word is on screen.
  void playUntilFirstWord() {
    advance(const Duration(seconds: 3, milliseconds: 200));
    expect(state.phase, GamePhase.playing);
  }

  /// A deliberate tilt (held long enough for the filter), then back to upright
  /// and past the feedback lockout, so the next word is on screen.
  void tiltAndReturn(double pitch) {
    advanceMs(300, at: pitch);
    advanceMs(800, at: 0);
  }
}

void main() {
  group('countdown', () {
    test('counts 3-2-1, beeps each second, says go, then shows a word', () {
      final h = Harness();
      expect(h.state.phase, GamePhase.countdown);
      expect(h.state.countdownValue, 3);

      h.advanceMs(1100);
      expect(h.state.countdownValue, 2);
      h.advanceMs(1000);
      expect(h.state.countdownValue, 1);
      h.advanceMs(1000);

      expect(h.state.phase, GamePhase.playing);
      expect(h.state.word, 'w0');
      expect(
        [for (final e in h.events) (e.kind, e.value)],
        [
          (GameEventKind.countdownBeep, 3),
          (GameEventKind.countdownBeep, 2),
          (GameEventKind.countdownBeep, 1),
          (GameEventKind.go, null),
        ],
      );
    });

    test('the round timer starts only when the first word appears', () {
      final h = Harness(round: const Duration(seconds: 30));
      h.advanceMs(2500);
      expect(h.state.remaining, const Duration(seconds: 30));
      h.advanceMs(700); // countdown ends at 3.0 s, first word ~0.2 s ago
      expect(h.state.phase, GamePhase.playing);
      h.advance(const Duration(seconds: 5));
      expect(h.state.remaining.inSeconds, inInclusiveRange(24, 25));
    });

    test('waits for an upright phone before the first word', () {
      final h = Harness(startPitch: _flat);
      h.advance(const Duration(seconds: 6));
      expect(h.state.phase, GamePhase.waitingUpright);
      expect(h.state.word, isNull);
      expect(h.state.remaining, const Duration(seconds: 30)); // not started

      h.advanceMs(400, at: 0);
      expect(h.state.phase, GamePhase.playing);
      expect(h.state.word, 'w0');
      h.advance(const Duration(seconds: 2));
      expect(h.state.remaining, lessThan(const Duration(seconds: 30)));
    });

    test('a tilt during the countdown does not count', () {
      final h = Harness();
      h.advanceMs(300, at: _down);
      h.advanceMs(300, at: 0);
      h.playUntilFirstWord();
      expect(h.engine.result.words, isEmpty);
    });
  });

  group('tilting', () {
    test('screen down = guessed with a flash and a correct event', () {
      final h = Harness()..playUntilFirstWord();
      h.advanceMs(300, at: _down);
      expect(h.state.phase, GamePhase.feedback);
      expect(h.state.lastOutcome, WordOutcome.guessed);
      expect(h.state.word, isNull);
      expect(h.kinds, contains(GameEventKind.correct));
    });

    test('screen up = skipped with a skip event', () {
      final h = Harness()..playUntilFirstWord();
      h.advanceMs(300, at: _up);
      expect(h.state.phase, GamePhase.feedback);
      expect(h.state.lastOutcome, WordOutcome.skipped);
      expect(h.kinds, contains(GameEventKind.skip));
    });

    test('swapped setting inverts the mapping', () {
      final h = Harness(swapTilt: true)..playUntilFirstWord();
      h.advanceMs(300, at: _down);
      expect(h.state.lastOutcome, WordOutcome.skipped);
      h.advanceMs(900, at: 0);
      h.advanceMs(300, at: _up);
      expect(h.state.lastOutcome, WordOutcome.guessed);
    });

    test('the next word needs the lockout AND an upright phone', () {
      final h = Harness()..playUntilFirstWord();
      h.advanceMs(300, at: _down);

      // Held down well past 600 ms: still showing the flash.
      h.advanceMs(1500, at: _down);
      expect(h.state.phase, GamePhase.feedback);

      // Back upright: the next word arrives.
      h.advanceMs(300, at: 0);
      expect(h.state.phase, GamePhase.playing);
      expect(h.state.word, 'w1');
    });

    test('returning upright instantly still waits for the 600 ms lockout', () {
      final h = Harness()..playUntilFirstWord();
      h.advanceMs(200, at: _down);
      expect(h.state.phase, GamePhase.feedback);
      final tiltedAt = h.now;

      h.advanceMs(200, at: 0); // upright again, but too early
      expect(h.state.phase, GamePhase.feedback);
      expect(h.now - tiltedAt, lessThan(const Duration(milliseconds: 600)));

      h.advanceMs(600, at: 0);
      expect(h.state.phase, GamePhase.playing);
    });

    test('words are served in order, never repeated, outcomes recorded', () {
      final h = Harness()..playUntilFirstWord();
      final seen = <String>[h.state.word!];
      for (var i = 0; i < 6; i++) {
        h.tiltAndReturn(i.isEven ? _down : _up);
        seen.add(h.state.word!);
      }
      expect(seen, ['w0', 'w1', 'w2', 'w3', 'w4', 'w5', 'w6']);
      expect(seen.toSet().length, seen.length);

      final words = h.engine.result.words;
      expect(words.length, 6);
      expect(
        [for (final w in words) w.outcome],
        [
          WordOutcome.guessed,
          WordOutcome.skipped,
          WordOutcome.guessed,
          WordOutcome.skipped,
          WordOutcome.guessed,
          WordOutcome.skipped,
        ],
      );
    });

    test('a tilt while the flash is showing is ignored', () {
      final h = Harness()..playUntilFirstWord();
      h.advanceMs(300, at: _down);
      h.advanceMs(300, at: 0);
      h.advanceMs(100, at: _up); // inside the lockout window
      expect(h.engine.result.words.length, 1);
    });
  });

  group('end of round', () {
    test('word on screen at time-up is "not played" and the round ends', () {
      final h = Harness(round: const Duration(seconds: 10));
      h.playUntilFirstWord();
      h.tiltAndReturn(_down);
      h.advanceMs(h.state.remaining.inMilliseconds + 200);

      expect(h.state.phase, GamePhase.timeUp);
      final words = h.engine.result.words;
      expect(words.map((w) => w.outcome), [
        WordOutcome.guessed,
        WordOutcome.notPlayed,
      ]);
      expect(words.last.text, 'w1');
      expect(h.kinds.where((k) => k == GameEventKind.timeUp).length, 1);
    });

    test('time-up screen lasts 1.5 s, then the round is finished', () {
      final h = Harness(round: const Duration(seconds: 5));
      h.playUntilFirstWord();
      h.advance(const Duration(seconds: 5, milliseconds: 100));
      expect(h.state.phase, GamePhase.timeUp);
      h.advanceMs(1000);
      expect(h.state.phase, GamePhase.timeUp);
      h.advanceMs(700);
      expect(h.state.phase, GamePhase.finished);
    });

    test('time running out during the flash adds no extra word', () {
      final h = Harness(round: const Duration(seconds: 5));
      h.playUntilFirstWord();
      h.advanceMs(h.state.remaining.inMilliseconds - 1500); // ~1.5 s left
      h.advanceMs(300, at: _down);
      expect(h.state.phase, GamePhase.feedback);
      h.advance(const Duration(seconds: 2), at: _down); // time runs out here

      expect(h.state.phase, anyOf(GamePhase.timeUp, GamePhase.finished));
      expect(h.engine.result.words.length, 1);
      expect(h.engine.result.words.single.outcome, WordOutcome.guessed);
    });

    test('ticks fire once per second for the last five seconds only', () {
      final h = Harness(round: const Duration(seconds: 8));
      h.playUntilFirstWord();
      h.advance(const Duration(seconds: 9));
      final ticks = [
        for (final e in h.events)
          if (e.kind == GameEventKind.tick) e.value,
      ];
      expect(ticks, [5, 4, 3, 2, 1]);
    });

    test('running out of words ends the round early', () {
      final h = Harness(words: ['a', 'b'])..playUntilFirstWord();
      h.tiltAndReturn(_down);
      h.tiltAndReturn(_up);
      expect(h.state.phase, GamePhase.timeUp);
      expect(h.engine.result.words.map((w) => w.text), ['a', 'b']);
    });

    test('an empty word list ends immediately instead of crashing', () {
      final h = Harness(words: const []);
      h.advance(const Duration(seconds: 4));
      expect(h.state.phase, GamePhase.timeUp);
      expect(h.engine.result.words, isEmpty);
    });
  });

  group('app lifecycle', () {
    test('background time is not lost: a resume countdown runs, clock frozen',
        () {
      final h = Harness(round: const Duration(seconds: 30))
        ..playUntilFirstWord();
      h.advance(const Duration(seconds: 10));
      final before = h.state.remaining;

      h.engine.suspend();
      // The caller's stopwatch is stopped while suspended: no ticks, no time.
      h.engine.resume(h.now);
      expect(h.state.phase, GamePhase.resuming);
      expect(h.state.countdownValue, 3);

      h.advance(const Duration(seconds: 2));
      expect(h.state.phase, GamePhase.resuming);
      expect(h.state.remaining, before); // frozen during the resume countdown

      h.advance(const Duration(seconds: 1, milliseconds: 100));
      expect(h.state.phase, GamePhase.playing);
      expect(h.state.word, 'w0');
      // The resume countdown cost no round time; only the ~0.1 s of play since
      // it ended has elapsed.
      final lost = before - h.state.remaining;
      expect(lost, greaterThanOrEqualTo(Duration.zero));
      expect(lost, lessThanOrEqualTo(const Duration(milliseconds: 200)));
    });

    test('ticks and tilts are ignored while suspended', () {
      final h = Harness()..playUntilFirstWord();
      h.engine.suspend();
      h.engine.onTilt(TiltDirection.screenDown);
      h.engine.tick(h.now + const Duration(minutes: 5));
      h.engine.resume(h.now);
      expect(h.engine.result.words, isEmpty);
    });

    test('a phone set down while away cannot cause a false skip', () {
      final h = Harness()..playUntilFirstWord();
      h.engine.suspend();
      h.engine.resume(h.now);

      // Phone now lies flat on the table (screen up = would be a skip).
      h.advance(const Duration(seconds: 5), at: _flat);
      expect(h.engine.result.words, isEmpty);
      expect(h.state.phase, GamePhase.playing);

      // Picked up and tilted properly: counts again.
      h.advanceMs(300, at: 0);
      h.advanceMs(300, at: _down);
      expect(h.engine.result.words.single.outcome, WordOutcome.guessed);
    });

    test('suspending after the time-up screen does nothing', () {
      final h = Harness(round: const Duration(seconds: 5))
        ..playUntilFirstWord();
      h.advance(const Duration(seconds: 5, milliseconds: 200));
      expect(h.state.phase, GamePhase.timeUp);
      h.engine.suspend();
      h.engine.resume(h.now);
      expect(h.state.phase, GamePhase.timeUp);
    });
  });

  group('RoundResult scoring', () {
    RoundResult result({required bool penalty}) => RoundResult(
          skipPenalty: penalty,
          words: const [
            PlayedWord('a', WordOutcome.guessed),
            PlayedWord('b', WordOutcome.guessed),
            PlayedWord('c', WordOutcome.skipped),
            PlayedWord('d', WordOutcome.skipped),
            PlayedWord('e', WordOutcome.skipped),
            PlayedWord('f', WordOutcome.notPlayed),
          ],
        );

    test('skips are free by default and not-played never counts', () {
      final r = result(penalty: false);
      expect((r.guessed, r.skipped, r.notPlayed), (2, 3, 1));
      expect(r.score, 2);
    });

    test('with the penalty each skip costs one point (can go negative)', () {
      expect(result(penalty: true).score, -1);
    });
  });
}
