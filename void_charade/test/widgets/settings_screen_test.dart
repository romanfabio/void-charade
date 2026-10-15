import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_charade/features/settings/settings_controller.dart';
import 'package:void_charade/features/settings/settings_screen.dart';
import 'package:void_charade/l10n/app_localizations.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Locale deviceLocale = const Locale('en'),
}) async {
  // Tall surface so the whole settings list is laid out and tappable.
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceLocaleProvider.overrideWithValue(deviceLocale),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(appLocaleProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('shows defaults and persists a toggle', (tester) async {
    final container = await _pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('60 s'), findsOneWidget);
    expect(find.text('5 s'), findsOneWidget);

    await tester.tap(find.text('Skip costs 1 point'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).skipPenalty, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('skipPenalty'), isTrue);
  });

  testWidgets('switching app language rebuilds the UI live', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.text('Italiano').first);
    await tester.pumpAndSettle();

    expect(find.text('Impostazioni'), findsOneWidget);
    expect(container.read(wordLanguageProvider), 'it');
  });

  testWidgets('tick toggle is disabled while sounds are off', (tester) async {
    await _pump(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Sounds'));
    await tester.pumpAndSettle();

    final tick = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Final-seconds ticking'),
    );
    expect(tick.onChanged, isNull);
    expect(tick.value, isFalse);
  });
}
