import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/route_args.dart';
import '../../core/router.dart';
import '../../l10n/app_localizations.dart';
import '../categories/category_repository.dart';
import '../categories/round_setup.dart';
import '../settings/settings_controller.dart';

/// Prepares a shuffled deck for [selection] and opens the game screen.
/// With [replace] the current screen (the results) is replaced, so back goes to
/// the home screen rather than to the finished round.
Future<void> startRound(
  BuildContext context,
  WidgetRef ref,
  RoundSelection selection, {
  bool replace = false,
}) async {
  final round = await ref.read(roundSetupServiceProvider).prepare(
        selection,
        playable: ref.read(playableCategoriesProvider).value ?? const [],
        languageCode: ref.read(wordLanguageProvider),
      );
  if (!context.mounted) return;

  if (round.words.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).noWordsAvailable)),
    );
    return;
  }

  final replayable = selection is RandomCategorySelection && round.category != null
      ? CategorySelection(round.category!)
      : selection;
  final args = GameArgs(selection: replayable, round: round);

  if (replace) {
    context.pushReplacement(AppRoutes.game, extra: args);
  } else {
    unawaited(context.push(AppRoutes.game, extra: args));
  }
}
