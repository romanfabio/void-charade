import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../categories/round_setup.dart';
import '../results/round_result.dart';
import '../settings/settings_controller.dart';
import 'game_engine.dart';
import 'tilt_detector.dart';

/// Accelerometer samples at ~50 Hz. Overridden in tests.
final accelerometerStreamProvider = Provider<Stream<TiltSample>>(
  (ref) => accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  ).map((e) => TiltSample(e.x, e.y, e.z)),
);

/// A monotonic clock that can be stopped (while the app is in the background).
abstract class GameClock {
  void start();
  void stop();
  Duration get elapsed;
}

class StopwatchClock implements GameClock {
  final _stopwatch = Stopwatch();

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();

  @override
  Duration get elapsed => _stopwatch.elapsed;
}

/// Creates a fresh clock per round. Overridden in tests with a controllable one.
final gameClockFactoryProvider = Provider<GameClock Function()>(
  (ref) => StopwatchClock.new,
);

/// Debug builds only: pretend the phone is held upright and let the screen's
/// left/right halves act as skip/correct, so a round can be driven without
/// physically tilting the phone.
final debugSimulateSensorsProvider =
    NotifierProvider<DebugSimulateSensors, bool>(DebugSimulateSensors.new);

class DebugSimulateSensors extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Connects a [GameEngine] to the real world: a monotonic clock, the
/// accelerometer and the app lifecycle. One instance per round.
class GameController extends Notifier<GameState> {
  GameController(this.round);

  final PreparedRound round;

  static const _tickInterval = Duration(milliseconds: 50);

  late final GameEngine _engine;
  late final GameClock _clock;
  Timer? _timer;
  StreamSubscription<TiltSample>? _sensorSubscription;
  final _events = StreamController<GameEvent>.broadcast();

  /// Sounds, vibration and the like subscribe here.
  Stream<GameEvent> get events => _events.stream;

  RoundResult get result => _engine.result;

  @override
  GameState build() {
    final settings = ref.read(settingsProvider);
    _clock = ref.read(gameClockFactoryProvider)();
    _engine = GameEngine(
      config: GameConfig(
        roundDuration: Duration(seconds: settings.roundSeconds),
        countdownDuration: Duration(seconds: settings.countdownSeconds),
        skipPenalty: settings.skipPenalty,
        swapTilt: settings.swapTilt,
      ),
      words: round.words,
      onEvent: _events.add,
    );

    ref.onDispose(() {
      _timer?.cancel();
      _sensorSubscription?.cancel();
      _clock.stop();
      _events.close();
    });

    _clock.start();
    _engine.start(_clock.elapsed);
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
    _listenToSensors(simulated: ref.read(debugSimulateSensorsProvider));
    ref.listen(debugSimulateSensorsProvider, (_, simulated) {
      _listenToSensors(simulated: simulated);
    });
    return _engine.state;
  }

  /// The app went to the background: freeze the clock.
  void suspend() {
    _clock.stop();
    _engine.suspend();
  }

  /// The app is back: the engine runs its short "get ready" countdown.
  void resume() {
    _clock.start();
    _engine.resume(_clock.elapsed);
    _publish();
  }

  /// Debug controls: inject a tilt.
  void debugTilt(TiltDirection direction) {
    _engine.onTilt(direction);
    _publish();
  }

  void _onTick() {
    _engine.tick(_clock.elapsed);
    _publish();
  }

  void _listenToSensors({required bool simulated}) {
    _sensorSubscription?.cancel();
    final stream = simulated
        ? Stream<TiltSample>.periodic(
            const Duration(milliseconds: 20),
            // Gravity along the screen's long axis: perfectly upright.
            (_) => const TiltSample(0, 9.8, 0),
          )
        : ref.read(accelerometerStreamProvider);
    _sensorSubscription = stream.listen(
      (sample) {
        _engine.onSample(sample);
        _publish();
      },
      // A device without an accelerometer cannot play, but must not crash.
      onError: (Object _) {},
    );
  }

  void _publish() {
    final next = _engine.state;
    if (next != state) state = next;
  }
}

final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameState, PreparedRound>(GameController.new);
