import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/core/route_args.dart';
import 'package:void_charade/features/categories/round_setup.dart';
import 'package:void_charade/features/results/confetti.dart';
import 'package:void_charade/features/results/results_screen.dart';
import 'package:void_charade/features/results/round_result.dart';
import 'package:void_charade/l10n/app_localizations.dart';

List<PlayedWord> _words({int guessed = 0, int skipped = 0, int notPlayed = 0}) => [
      for (var i = 0; i < guessed; i++) PlayedWord('Good $i', WordOutcome.guessed),
      for (var i = 0; i < skipped; i++) PlayedWord('Skip $i', WordOutcome.skipped),
      for (var i = 0; i < notPlayed; i++) PlayedWord('Left $i', WordOutcome.notPlayed),
    ];

Future<void> _pump(
  WidgetTester tester,
  RoundResult result, {
  bool disableAnimations = false,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 1600),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ResultsScreen(
            args: ResultsArgs(
              result: result,
              selection: const MixAllSelection(),
              category: null,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the score counts up from zero to the final value',
      (tester) async {
    await _pump(
      tester,
      RoundResult(words: _words(guessed: 7, skipped: 2), skipPenalty: false),
    );

    // First frame: the big number has not started counting; the label is final.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('7 points'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    final midway = int.parse(
      tester.widget<Text>(find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
      )).data!,
    );
    expect(midway, inInclusiveRange(1, 7));

    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows counts, rows and hides "not played" when there is none',
      (tester) async {
    await _pump(
      tester,
      RoundResult(words: _words(guessed: 2, skipped: 1), skipPenalty: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guessed 2'), findsOneWidget);
    expect(find.text('Skipped 1'), findsOneWidget);
    expect(find.textContaining('Not played'), findsNothing);
    expect(find.text('Good 0'), findsOneWidget);
    expect(find.text('Skip 0'), findsOneWidget);
  });

  testWidgets('a negative score is shown with the penalty', (tester) async {
    await _pump(
      tester,
      RoundResult(words: _words(guessed: 1, skipped: 4), skipPenalty: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('-3'), findsOneWidget);
    expect(find.text('-3 points'), findsOneWidget);
  });

  testWidgets('Italian labels', (tester) async {
    await _pump(
      tester,
      RoundResult(words: _words(guessed: 1, notPlayed: 1), skipPenalty: false),
      locale: const Locale('it'),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 punto'), findsOneWidget);
    expect(find.text('Indovinate 1'), findsOneWidget);
    expect(find.text('Non giocata 1'), findsWidgets);
    expect(find.text('Gioca ancora'), findsOneWidget);
  });

  group('confetti', () {
    testWidgets('appears from $confettiScore points and then finishes',
        (tester) async {
      await _pump(
        tester,
        RoundResult(words: _words(guessed: confettiScore), skipPenalty: false),
      );
      expect(find.byType(ConfettiBurst), findsOneWidget);
      await tester.pumpAndSettle(); // finishes by itself (no endless timers)
    });

    testWidgets('not below $confettiScore points', (tester) async {
      await _pump(
        tester,
        RoundResult(
          words: _words(guessed: confettiScore - 1),
          skipPenalty: false,
        ),
      );
      expect(find.byType(ConfettiBurst), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('not when the system asks to remove animations',
        (tester) async {
      await _pump(
        tester,
        RoundResult(words: _words(guessed: 15), skipPenalty: false),
        disableAnimations: true,
      );
      expect(find.byType(ConfettiBurst), findsNothing);
      // ...and the final score is there immediately, with no count-up.
      expect(find.text('15'), findsOneWidget);
    });
  });
}
