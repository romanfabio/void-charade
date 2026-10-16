import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/route_args.dart';
import '../../core/router.dart';
import '../../core/system_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../results/round_result.dart';
import '../settings/settings_controller.dart';
import 'game_controller.dart';
import 'game_engine.dart';
import 'tilt_detector.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.args});

  final GameArgs args;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late final AppSystemUi _systemUi;

  late final _provider = gameControllerProvider(widget.args.round);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _systemUi = ref.read(appSystemUiProvider);
    unawaited(_systemUi.applyGameMode());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_systemUi.applyMenuMode());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(_provider.notifier);
    if (state == AppLifecycleState.paused) {
      controller.suspend();
    } else if (state == AppLifecycleState.resumed) {
      controller.resume();
    }
  }

  void _showResults() {
    final controller = ref.read(_provider.notifier);
    context.pushReplacement(
      AppRoutes.results,
      extra: ResultsArgs(
        result: controller.result,
        selection: widget.args.selection,
        category: widget.args.round.category,
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final l10n = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quitTitle),
        content: Text(l10n.quitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.quitCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.quitConfirm),
          ),
        ],
      ),
    );
    if (quit == true && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final simulated = kDebugMode && ref.watch(debugSimulateSensorsProvider);
    final touch = ref.watch(settingsProvider.select((s) => s.touchControls));

    ref.listen(_provider, (previous, next) {
      if (next.phase == GamePhase.finished &&
          previous?.phase != GamePhase.finished) {
        _showResults();
      }
    });

    final category = widget.args.round.category;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmQuit());
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: category?.color,
            gradient: category == null ? AppColors.coolGradient : null,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            // Touch mode: right half = correct, left half = skip. Debug builds
            // can also fake tilts with the same taps.
            onTapUp: touch || simulated
                ? (details) {
                    final left = details.globalPosition.dx <
                        MediaQuery.sizeOf(context).width / 2;
                    final controller = ref.read(_provider.notifier);
                    if (touch) {
                      controller.touch(correct: !left);
                    } else {
                      controller.debugTilt(
                        left ? TiltDirection.screenUp : TiltDirection.screenDown,
                      );
                    }
                  }
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _PhaseView(
                    key: ValueKey((state.phase, state.word)),
                    state: state,
                    touch: touch,
                  ),
                ),
                if (touch && state.phase == GamePhase.playing)
                  const _TouchHints(),
                _TopBar(state: state, onClose: _confirmQuit),
                if (kDebugMode) _DebugOverlay(state: state, simulated: simulated),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faint labels at the bottom corners reminding which half does what.
class _TouchHints extends StatelessWidget {
  const _TouchHints();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = _bigStyle(22).copyWith(color: Colors.white54, shadows: null);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.skip_next_rounded, color: Colors.white54),
                const SizedBox(width: 6),
                Text(l10n.gameSkip, style: style),
              ]),
              Row(children: [
                Text(l10n.gameCorrect, style: style),
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, color: Colors.white54),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _bigStyle(double size) => TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      color: Colors.white,
      height: 1.05,
      shadows: const [Shadow(color: Colors.black26, blurRadius: 12)],
    );

class _PhaseView extends StatelessWidget {
  const _PhaseView({super.key, required this.state, required this.touch});

  final GameState state;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (state.phase) {
      case GamePhase.countdown:
      case GamePhase.resuming:
        return _Centered(
          children: [
            Text(
              state.phase == GamePhase.countdown
                  ? (touch ? l10n.gameGetReadyTouch : l10n.gameGetReady)
                  : l10n.gameResuming,
              textAlign: TextAlign.center,
              style: _bigStyle(36),
            ),
            _CountdownNumber(value: state.countdownValue),
          ],
        );
      case GamePhase.waitingUpright:
        return _Centered(
          children: [
            const Icon(Icons.screen_rotation_alt_rounded,
                size: 96, color: Colors.white),
            Text(l10n.gameHoldUpright, style: _bigStyle(44)),
          ],
        );
      case GamePhase.playing:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
            child: AutoSizeText(
              state.word ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 28,
              stepGranularity: 2,
              wrapWords: false,
              style: _bigStyle(150),
            ),
          ),
        );
      case GamePhase.feedback:
        final guessed = state.lastOutcome == WordOutcome.guessed;
        return ColoredBox(
          color: guessed ? AppColors.success : AppColors.skip,
          child: _Centered(
            children: [
              Icon(
                guessed ? Icons.check_circle_rounded : Icons.skip_next_rounded,
                size: 110,
                color: Colors.white,
              ),
              Text(
                guessed ? l10n.gameCorrect : l10n.gameSkip,
                style: _bigStyle(72),
              ),
            ],
          ),
        );
      case GamePhase.timeUp:
      case GamePhase.finished:
        return _Centered(
          children: [
            const Icon(Icons.timer_off_rounded, size: 96, color: Colors.white),
            Text(l10n.gameTimeUp, style: _bigStyle(72)),
          ],
        );
    }
  }
}

/// A countdown digit that zooms in and fades in each time the value changes.
class _CountdownNumber extends StatelessWidget {
  const _CountdownNumber({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Opacity(
        opacity: (t * 2).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1.6 - 0.6 * t,
          child: Text('$value', style: _bigStyle(180)),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.onClose});

  final GameState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final roundRunning = state.phase == GamePhase.playing ||
        state.phase == GamePhase.feedback;
    final urgent = roundRunning && state.secondsLeft <= 5;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (roundRunning)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 10,
                  backgroundColor: Colors.black26,
                  color: urgent ? AppColors.danger : Colors.white,
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                iconSize: 30,
              ),
              const Spacer(),
              if (roundRunning)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    '${state.secondsLeft}',
                    style: _bigStyle(urgent ? 44 : 34).copyWith(
                      color: urgent ? AppColors.danger : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Debug builds only: live pitch angle (for tuning the tilt thresholds) and a
/// switch that replaces the sensor with tap controls.
class _DebugOverlay extends ConsumerWidget {
  const _DebugOverlay({required this.state, required this.simulated});

  final GameState state;
  final bool simulated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 6,
      child: Row(
        children: [
          Text(
            'pitch ${state.pitch}°  ${state.upright ? 'upright' : ''}'
            '${simulated ? '  [tap: left=skip right=correct]' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Simulate sensors',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(debugSimulateSensorsProvider.notifier).set(!simulated),
            icon: Icon(
              Icons.bug_report_rounded,
              color: simulated ? Colors.yellowAccent : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
