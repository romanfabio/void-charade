import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/route_args.dart';
import '../../core/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/round_launcher.dart';
import 'confetti.dart';
import 'round_result.dart';

/// Score needed for the confetti.
const confettiScore = 10;

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.args});

  final ResultsArgs args;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "remove animations" setting: show the final state.
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Progress (0..1) of the part of the intro between [start] and [end].
  double _phase(double start, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(Interval(start, end).transform(_intro.value));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final args = widget.args;
    final result = args.result;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = args.category?.nameFor(languageCode) ?? l10n.mixAll;
    final emoji = args.category?.emoji ?? '🌀';
    final celebrate = result.score >= confettiScore &&
        !MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: AnimatedBuilder(
                animation: _intro,
                builder: (context, _) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: _phase(0, 0.2),
                            child: Text(
                              '$emoji  $title',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: _phase(0, 0.2),
                            child: Text(
                              l10n.resultsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildScore(l10n, result.score),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: _phase(0.45, 0.7),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _CountChip(
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  label:
                                      '${l10n.resultsGuessed} ${result.guessed}',
                                ),
                                _CountChip(
                                  icon: Icons.skip_next_rounded,
                                  color: AppColors.skip,
                                  label:
                                      '${l10n.resultsSkipped} ${result.skipped}',
                                ),
                                if (result.notPlayed > 0)
                                  _CountChip(
                                    icon: Icons.pause_circle_rounded,
                                    color: AppColors.onSurfaceMuted,
                                    label:
                                        '${l10n.resultsNotPlayed} ${result.notPlayed}',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: result.words.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => _buildRow(i, l10n),
                      ),
                    ),
                    Opacity(
                      opacity: _phase(0.6, 0.85),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                                onPressed: () => context.go(AppRoutes.home),
                                child: Text(l10n.backToCategories),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  backgroundColor: AppColors.magenta,
                                ),
                                onPressed: () => startRound(
                                  context,
                                  ref,
                                  args.selection,
                                  replace: true,
                                ),
                                child: Text(l10n.playAgain),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (celebrate) const Positioned.fill(child: ConfettiBurst()),
          ],
        ),
      ),
    );
  }

  /// The big number counts up from 0 and pops in; the label below is final
  /// straight away so screen readers and tests see the real score.
  Widget _buildScore(AppLocalizations l10n, int score) {
    final counted = (score * _phase(0.05, 0.6)).round();
    final pop = Curves.elasticOut
        .transform(const Interval(0, 0.5).transform(_intro.value));

    return Column(
      children: [
        Semantics(
          label: l10n.resultsScore(score),
          excludeSemantics: true,
          child: Transform.scale(
            scale: 0.5 + 0.5 * pop,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.partyGradient.createShader(bounds),
              child: Text(
                '$counted',
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 120,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Text(
          l10n.resultsScore(score),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildRow(int index, AppLocalizations l10n) {
    // Rows slide in one after another; past the first screenful they all share
    // the same timing so a long list is not slow to appear.
    final start = 0.3 + math.min(index, 12) * 0.035;
    final t = _phase(start, math.min(1, start + 0.25));
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - t)),
        child: _WordRow(word: widget.args.result.words[index], l10n: l10n),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word, required this.l10n});

  final PlayedWord word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (word.outcome) {
      WordOutcome.guessed => (
          Icons.check_circle_rounded,
          AppColors.success,
          l10n.resultsGuessed,
        ),
      WordOutcome.skipped => (
          Icons.skip_next_rounded,
          AppColors.skip,
          l10n.resultsSkipped,
        ),
      WordOutcome.notPlayed => (
          Icons.pause_circle_rounded,
          AppColors.onSurfaceMuted,
          l10n.resultsNotPlayed,
        ),
    };

    return Semantics(
      label: '${word.text}, $label',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          word.text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: word.outcome == WordOutcome.notPlayed
                ? AppColors.onSurfaceMuted
                : AppColors.onSurface,
          ),
        ),
        trailing: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
