import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/app_localizations.dart';

class VoidCharadeApp extends ConsumerStatefulWidget {
  const VoidCharadeApp({super.key});

  @override
  ConsumerState<VoidCharadeApp> createState() => _VoidCharadeAppState();
}

class _VoidCharadeAppState extends ConsumerState<VoidCharadeApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
