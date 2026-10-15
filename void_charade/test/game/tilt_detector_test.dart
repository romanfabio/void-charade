import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/features/game/tilt_detector.dart';

/// A sample for a phone at [pitchDegrees] (positive = screen toward the
/// ceiling), with gravity split between the screen plane and its normal.
/// [axis] picks which in-plane axis carries gravity: 'y' is portrait-upright,
/// 'x' / '-x' are the two landscape directions.
TiltSample at(double pitchDegrees, {String axis = 'y'}) {
  final r = pitchDegrees * math.pi / 180;
  final planar = 9.8 * math.cos(r);
  final z = 9.8 * math.sin(r);
  return switch (axis) {
    'x' => TiltSample(planar, 0, z),
    '-x' => TiltSample(-planar, 0, z),
    _ => TiltSample(0, planar, z),
  };
}

/// Feeds each pitch in [pitches] for [repeat] samples and collects the events.
List<TiltDirection> feed(
  TiltDetector d,
  List<double> pitches, {
  int repeat = 12,
  String axis = 'y',
}) {
  final events = <TiltDirection>[];
  for (final p in pitches) {
    for (var i = 0; i < repeat; i++) {
      final e = d.process(at(p, axis: axis));
      if (e != null) events.add(e);
    }
  }
  return events;
}

void main() {
  test('steady upright phone gives no events and reads as upright', () {
    final d = TiltDetector();
    expect(feed(d, [0], repeat: 200), isEmpty);
    expect(d.isUpright, isTrue);
    expect(d.pitchDegrees.abs(), lessThan(1));
  });

  test('is not upright before any sample', () {
    expect(TiltDetector().isUpright, isFalse);
  });

  test('screen down is detected once, even when held', () {
    final d = TiltDetector();
    expect(feed(d, [0, -70]), [TiltDirection.screenDown]);
    expect(feed(d, [-70], repeat: 300), isEmpty);
  });

  test('screen up is detected once', () {
    final d = TiltDetector();
    expect(feed(d, [0, 70, 70, 70]), [TiltDirection.screenUp]);
  });

  test('a second tilt needs the phone to come back upright first', () {
    final d = TiltDetector();
    expect(
      feed(d, [0, -70, 0, 70, 0, -70]),
      [
        TiltDirection.screenDown,
        TiltDirection.screenUp,
        TiltDirection.screenDown,
      ],
    );
  });

  test('hovering between neutral and trigger never re-triggers', () {
    final d = TiltDetector();
    expect(feed(d, [0, -70]), [TiltDirection.screenDown]);
    // -40 is outside the neutral zone (25) but short of the trigger (50).
    expect(feed(d, [-40, -45, -40, -35, -45], repeat: 40), isEmpty);
    expect(d.isUpright, isFalse);
  });

  test('jitter around 45 degrees does not trigger', () {
    final d = TiltDetector();
    feed(d, [0]);
    final events = <TiltDirection>[];
    for (var i = 0; i < 400; i++) {
      final e = d.process(at(i.isEven ? 45 : -45));
      if (e != null) events.add(e);
    }
    expect(events, isEmpty);
  });

  test('a single noisy spike is filtered out', () {
    final d = TiltDetector();
    feed(d, [0]);
    expect(d.process(at(-90)), isNull);
    expect(feed(d, [0], repeat: 20), isEmpty);
  });

  test('starting with the phone flat does not trigger until it was upright',
      () {
    final d = TiltDetector();
    expect(feed(d, [90], repeat: 100), isEmpty);
    expect(d.isUpright, isFalse);
    expect(feed(d, [0]), isEmpty);
    expect(feed(d, [90]), [TiltDirection.screenUp]);
  });

  test('disarm requires upright again before the next trigger', () {
    final d = TiltDetector();
    feed(d, [0]);
    d.disarm();
    expect(feed(d, [-70], repeat: 100), isEmpty);
    expect(feed(d, [0, -70]), [TiltDirection.screenDown]);
  });

  test('works the same in both landscape directions', () {
    for (final axis in ['x', '-x', 'y']) {
      final d = TiltDetector();
      expect(
        feed(d, [0, -70, 0, 70], axis: axis),
        [TiltDirection.screenDown, TiltDirection.screenUp],
        reason: 'axis $axis',
      );
    }
  });

  test('a sustained tilt triggers within about 100 ms at 50 Hz', () {
    final d = TiltDetector();
    feed(d, [0]);
    var samples = 0;
    TiltDirection? event;
    while (event == null && samples < 100) {
      event = d.process(at(-70));
      samples++;
    }
    expect(event, TiltDirection.screenDown);
    expect(samples, lessThanOrEqualTo(6)); // 6 samples = 120 ms at 50 Hz
  });
}
