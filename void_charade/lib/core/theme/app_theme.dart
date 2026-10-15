import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled as assets (see pubspec.yaml), both SIL OFL 1.1.
abstract final class AppFonts {
  static const display = 'LilitaOne';
  static const body = 'Nunito';
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.magenta,
    onPrimary: Colors.white,
    secondary: AppColors.cyan,
    onSecondary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.body,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge
          ?.copyWith(fontFamily: AppFonts.display, color: AppColors.onSurface),
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontFamily: AppFonts.display, color: AppColors.onSurface),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontFamily: AppFonts.display, color: AppColors.onSurface),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.magenta,
      thumbColor: AppColors.orange,
      inactiveTrackColor: AppColors.surfaceHigh,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.onSurfaceMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.magenta
            : AppColors.surfaceHigh,
      ),
    ),
  );
}
