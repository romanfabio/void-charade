import 'dart:math' as math;

/// One accelerometer reading in m/s², gravity included. Phone flat with the
/// screen up reads roughly (0, 0, +9.8) on both Android and iOS (sensors_plus
/// normalises iOS to the Android convention).
class TiltSample {
  const TiltSample(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

/// Which way the screen was tilted.
enum TiltDirection {
  /// Screen turned toward the floor.
  screenDown,

  /// Screen turned toward the ceiling.
  screenUp,
}

/// Turns raw accelerometer samples into discrete "tilt" events.
///
/// The phone is held upright on the forehead, so gravity lies in the screen
/// plane and the pitch angle `atan2(z, hypot(x, y))` is about 0°. Pitch goes
/// positive when the screen faces the ceiling and negative when it faces the
/// floor. This is independent of which landscape direction the phone is in.
///
/// Anti-jitter measures:
/// * every axis is low-pass filtered,
/// * a trigger needs a deep tilt ([triggerDegrees]) while re-arming needs the
///   phone back near upright ([neutralDegrees]) — hysteresis,
/// * after a trigger no new event is possible until the phone has been upright
///   again, so one tilt is always exactly one event.
class TiltDetector {
  TiltDetector({
    this.triggerDegrees = 50,
    this.neutralDegrees = 25,
    this.smoothing = 0.2,
  }) : assert(neutralDegrees < triggerDegrees);

  final double triggerDegrees;
  final double neutralDegrees;

  /// Weight of the newest sample in the low-pass filter (1 = no filtering).
  final double smoothing;

  double? _x;
  double? _y;
  double? _z;
  double _pitch = 0;
  bool _armed = false;
  bool _hasSample = false;

  /// Filtered pitch in degrees (positive = screen toward the ceiling).
  double get pitchDegrees => _pitch;

  /// True when a sample has been seen and the phone is within the neutral zone.
  bool get isUpright => _hasSample && _pitch.abs() < neutralDegrees;

  /// Feeds one sample. Returns a direction exactly when a tilt is detected.
  TiltDirection? process(TiltSample sample) {
    _x = _lowPass(_x, sample.x);
    _y = _lowPass(_y, sample.y);
    _z = _lowPass(_z, sample.z);
    _hasSample = true;

    final planar = math.sqrt(_x! * _x! + _y! * _y!);
    _pitch = math.atan2(_z!, planar) * 180 / math.pi;

    if (!_armed) {
      if (_pitch.abs() < neutralDegrees) _armed = true;
      return null;
    }
    if (_pitch >= triggerDegrees) {
      _armed = false;
      return TiltDirection.screenUp;
    }
    if (_pitch <= -triggerDegrees) {
      _armed = false;
      return TiltDirection.screenDown;
    }
    return null;
  }

  /// Forgets the filtered history and requires the phone to be seen upright
  /// again before the next trigger. Used when the game resumes after the app
  /// was in the background: the phone may have moved a lot meanwhile, so the
  /// old filtered angle must not be trusted.
  void disarm() {
    _armed = false;
    _hasSample = false;
    _x = _y = _z = null;
  }

  double _lowPass(double? previous, double value) =>
      previous == null ? value : previous + smoothing * (value - previous);
}
