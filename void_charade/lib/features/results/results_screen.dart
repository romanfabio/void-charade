import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/route_args.dart';
import '../../core/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../game/round_launcher.dart';
import 'round_result.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.args});

  final ResultsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final result = args.result;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = args.category?.nameFor(languageCode) ?? l10n.mixAll;
    final emoji = args.category?.emoji ?? '🌀';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    Text(
                      '$emoji  $title',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.resultsTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.partyGradient.createShader(bounds),
                      child: Text(
                        '${result.score}',
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 120,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      l10n.resultsScore(result.score),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _CountChip(
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          label: '${l10n.resultsGuessed} ${result.guessed}',
                        ),
                        _CountChip(
                          icon: Icons.skip_next_rounded,
                          color: AppColors.skip,
                          label: '${l10n.resultsSkipped} ${result.skipped}',
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: result.words.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _WordRow(word: result.words[i], l10n: l10n),
                ),
              ),
              Padding(
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
            ],
          ),
        ),
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
