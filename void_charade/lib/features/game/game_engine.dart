import '../results/round_result.dart';
import 'tilt_detector.dart';

enum GamePhase {
  /// Players put the phone on the forehead; numbers count down.
  countdown,

  /// Countdown is over but the phone is not upright yet (before the first word).
  waitingUpright,

  /// A word is on screen.
  playing,

  /// A tilt was just registered; the coloured flash is on screen.
  feedback,

  /// Short countdown after the app came back from the background.
  resuming,

  /// "Time's up" screen, shown briefly before the results.
  timeUp,

  /// Round over: the result is final and the UI should leave the screen.
  finished,
}

enum GameEventKind { countdownBeep, go, correct, skip, tick, timeUp }

/// Something the UI layer may want to react to with sound or vibration.
class GameEvent {
  const GameEvent(this.kind, [this.value]);
  final GameEventKind kind;

  /// Seconds left, for [GameEventKind.countdownBeep] and [GameEventKind.tick].
  final int? value;
}

class GameConfig {
  const GameConfig({
    required this.roundDuration,
    required this.countdownDuration,
    this.skipPenalty = false,
    this.swapTilt = false,
    this.touchControls = false,
    this.feedbackLockout = const Duration(milliseconds: 600),
    this.timeUpDuration = const Duration(milliseconds: 1500),
    this.resumeCountdown = const Duration(seconds: 3),
    this.tickSeconds = 5,
  });

  final Duration roundDuration;
  final Duration countdownDuration;
  final bool skipPenalty;

  /// Default mapping is screen down = guessed, screen up = skipped.
  final bool swapTilt;

  /// Taps (right half = guessed, left half = skipped) replace the tilt: the
  /// accelerometer is ignored and the phone never has to be upright.
  final bool touchControls;

  /// Minimum time the feedback flash stays on screen.
  final Duration feedbackLockout;
  final Duration timeUpDuration;
  final Duration resumeCountdown;

  /// Ticking starts when this many seconds are left.
  final int tickSeconds;
}

/// Immutable snapshot of what the UI needs to draw. Values are quantised
/// (remaining time to 100 ms, pitch to whole degrees) so that equal states
/// compare equal and the UI only rebuilds when something visible changes.
class GameState {
  const GameState({
    required this.phase,
    required this.countdownValue,
    required this.remaining,
    required this.roundDuration,
    required this.word,
    required this.lastOutcome,
    required this.playedCount,
    required this.pitch,
    required this.upright,
  });

  final GamePhase phase;
  final int countdownValue;
  final Duration remaining;
  final Duration roundDuration;

  /// Word on screen; only set while [GamePhase.playing] (or resuming from it).
  final String? word;

  /// Outcome shown by the flash during [GamePhase.feedback].
  final WordOutcome? lastOutcome;
  final int playedCount;
  final int pitch;
  final bool upright;

  double get progress => roundDuration.inMilliseconds == 0
      ? 0
      : (remaining.inMilliseconds / roundDuration.inMilliseconds).clamp(0, 1);

  int get secondsLeft => (remaining.inMilliseconds + 999) ~/ 1000;

  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.phase == phase &&
      other.countdownValue == countdownValue &&
      other.remaining == remaining &&
      other.roundDuration == roundDuration &&
      other.word == word &&
      other.lastOutcome == lastOutcome &&
      other.playedCount == playedCount &&
      other.pitch == pitch &&
      other.upright == upright;

  @override
  int get hashCode => Object.hash(
        phase,
        countdownValue,
        remaining,
        roundDuration,
        word,
        lastOutcome,
        playedCount,
        pitch,
        upright,
      );
}

/// The rules of one round, as a state machine driven from outside.
///
/// It has no clock and no sensors of its own: the caller passes a monotonic
/// `now` (a [Stopwatch] that is stopped while the app is in the background) to
/// [start], [tick], [onSample] and [onTilt], and accelerometer samples to
/// [onSample]. That makes every timing rule testable with synthetic time.
class GameEngine {
  GameEngine({
    required this.config,
    required List<String> words,
    TiltDetector? detector,
    this.onEvent,
  })  : _words = List.of(words),
        detector = detector ?? TiltDetector();

  final GameConfig config;
  final TiltDetector detector;
  final void Function(GameEvent event)? onEvent;

  final List<String> _words;
  final _played = <PlayedWord>[];
  var _next = 0;

  var _phase = GamePhase.countdown;
  var _now = Duration.zero;
  var _countdownEndsAt = Duration.zero;
  Duration? _roundEndsAt;
  var _feedbackEndsAt = Duration.zero;
  var _timeUpEndsAt = Duration.zero;
  var _resumeStartedAt = Duration.zero;
  var _resumeEndsAt = Duration.zero;
  var _resumeTo = GamePhase.playing;
  var _countdownValue = 0;
  int? _lastTick;
  String? _word;
  WordOutcome? _lastOutcome;
  var _suspended = false;

  GamePhase get phase => _phase;

  RoundResult get result => RoundResult(
        words: List.unmodifiable(_played),
        skipPenalty: config.skipPenalty,
      );

  GameState get state {
    final Duration remaining;
    if (_phase == GamePhase.timeUp || _phase == GamePhase.finished) {
      remaining = Duration.zero;
    } else if (_roundEndsAt == null) {
      remaining = config.roundDuration;
    } else {
      // While resuming, the round clock is frozen at the moment of suspension.
      final at = _phase == GamePhase.resuming ? _resumeStartedAt : _now;
      remaining = _clampZero(_roundEndsAt! - at);
    }
    return GameState(
      phase: _phase,
      countdownValue: _countdownValue,
      remaining: Duration(milliseconds: (remaining.inMilliseconds ~/ 100) * 100),
      roundDuration: config.roundDuration,
      word: _word,
      lastOutcome: _lastOutcome,
      playedCount: _played.length,
      pitch: detector.pitchDegrees.round(),
      upright: detector.isUpright,
    );
  }

  /// Begins the countdown.
  void start(Duration now) {
    _now = now;
    _phase = GamePhase.countdown;
    _countdownEndsAt = now + config.countdownDuration;
    _countdownValue = _ceilSeconds(config.countdownDuration);
    _emit(GameEventKind.countdownBeep, _countdownValue);
  }

  /// Advances the clock. Call at least every ~50 ms.
  void tick(Duration now) {
    if (_suspended) return;
    _now = now;

    switch (_phase) {
      case GamePhase.countdown:
        final left = _countdownEndsAt - now;
        if (left <= Duration.zero) {
          _finishCountdown();
        } else {
          _updateCountdownValue(_ceilSeconds(left));
        }
      case GamePhase.waitingUpright:
        if (_ready) _showNextWord();
      case GamePhase.playing:
        _checkRoundTime();
      case GamePhase.feedback:
        if (_checkRoundTime()) return;
        if (now >= _feedbackEndsAt && _ready) _showNextWord();
      case GamePhase.resuming:
        final left = _resumeEndsAt - now;
        if (left <= Duration.zero) {
          _finishResume(now);
        } else {
          _updateCountdownValue(_ceilSeconds(left));
        }
      case GamePhase.timeUp:
        if (now >= _timeUpEndsAt) _phase = GamePhase.finished;
      case GamePhase.finished:
        break;
    }
  }

  /// Feeds an accelerometer sample. Tilts only count while a word is on screen.
  void onSample(TiltSample sample) {
    if (config.touchControls) return;
    final direction = detector.process(sample);
    if (direction != null) onTilt(direction);
  }

  /// A tilt, from the detector or injected by debug controls.
  void onTilt(TiltDirection direction) {
    if (!_canAnswer) return;

    final guessedDirection = config.swapTilt
        ? TiltDirection.screenUp
        : TiltDirection.screenDown;
    _record(
      direction == guessedDirection
          ? WordOutcome.guessed
          : WordOutcome.skipped,
    );
  }

  /// A tap on the right ([correct]) or left half of the screen. Only counts in
  /// touch mode, while a word is on screen.
  void onTouch({required bool correct}) {
    if (!config.touchControls || !_canAnswer) return;
    _record(correct ? WordOutcome.guessed : WordOutcome.skipped);
  }

  bool get _canAnswer =>
      !_suspended && _phase == GamePhase.playing && _word != null;

  void _record(WordOutcome outcome) {
    _played.add(PlayedWord(_word!, outcome));
    _word = null;
    _lastOutcome = outcome;
    _phase = GamePhase.feedback;
    _feedbackEndsAt = _now + config.feedbackLockout;
    _emit(
      outcome == WordOutcome.guessed
          ? GameEventKind.correct
          : GameEventKind.skip,
    );
  }

  /// The app went to the background; the caller stops its clock.
  void suspend() {
    if (_phase == GamePhase.timeUp || _phase == GamePhase.finished) return;
    _suspended = true;
  }

  /// The app is back: a short countdown runs before the round continues, and
  /// the round clock does not lose any time to it.
  void resume(Duration now) {
    if (!_suspended) return;
    _suspended = false;
    _now = now;
    if (_phase == GamePhase.timeUp || _phase == GamePhase.finished) return;

    _resumeTo = _phase == GamePhase.resuming ? _resumeTo : _phase;
    _phase = GamePhase.resuming;
    _resumeStartedAt = now;
    _resumeEndsAt = now + config.resumeCountdown;
    _countdownValue = _ceilSeconds(config.resumeCountdown);
    // The phone was probably moved while away: require "upright" again before
    // the next tilt can count.
    detector.disarm();
    _emit(GameEventKind.countdownBeep, _countdownValue);
  }

  // ---------------------------------------------------------------------------

  /// Tilt mode waits for the phone to be upright before showing a word; touch
  /// mode never does.
  bool get _ready => config.touchControls || detector.isUpright;

  void _finishCountdown() {
    _emit(GameEventKind.go);
    if (_ready) {
      _showNextWord();
    } else {
      _phase = GamePhase.waitingUpright;
    }
  }

  void _finishResume(Duration now) {
    // Everything that was scheduled moves back by the time spent resuming.
    final shift = now - _resumeStartedAt;
    _countdownEndsAt += shift;
    _feedbackEndsAt += shift;
    _timeUpEndsAt += shift;
    if (_roundEndsAt != null) _roundEndsAt = _roundEndsAt! + shift;
    _phase = _resumeTo;
  }

  void _showNextWord() {
    _roundEndsAt ??= _now + config.roundDuration;
    if (_next >= _words.length) {
      _endRound();
      return;
    }
    _word = _words[_next++];
    _lastOutcome = null;
    _phase = GamePhase.playing;
  }

  /// Ends the round when time is up. Returns true if it did.
  bool _checkRoundTime() {
    final left = _roundEndsAt! - _now;
    if (left <= Duration.zero) {
      _endRound();
      return true;
    }
    final seconds = _ceilSeconds(left);
    if (seconds <= config.tickSeconds && seconds != _lastTick) {
      _lastTick = seconds;
      _emit(GameEventKind.tick, seconds);
    }
    return false;
  }

  void _endRound() {
    // The word on screen when the time ran out was never played.
    if (_phase == GamePhase.playing && _word != null) {
      _played.add(PlayedWord(_word!, WordOutcome.notPlayed));
    }
    _word = null;
    _lastOutcome = null;
    _phase = GamePhase.timeUp;
    _timeUpEndsAt = _now + config.timeUpDuration;
    _emit(GameEventKind.timeUp);
  }

  void _updateCountdownValue(int value) {
    if (value == _countdownValue) return;
    _countdownValue = value;
    _emit(GameEventKind.countdownBeep, value);
  }

  void _emit(GameEventKind kind, [int? value]) =>
      onEvent?.call(GameEvent(kind, value));

  static int _ceilSeconds(Duration d) => (d.inMilliseconds + 999) ~/ 1000;

  static Duration _clampZero(Duration d) => d.isNegative ? Duration.zero : d;
}
