import 'package:flutter/widgets.dart';

enum AppLanguageSetting { system, it, en }

enum WordLanguageSetting { sameAsApp, it, en }

/// Bounds for the numeric settings, shared by the UI and the repository.
abstract final class SettingsLimits {
  static const roundMin = 30;
  static const roundMax = 180;
  static const roundStep = 15;
  static const roundDefault = 60;

  static const countdownMin = 3;
  static const countdownMax = 10;
  static const countdownDefault = 5;
}

@immutable
class Settings {
  const Settings({
    this.appLanguage = AppLanguageSetting.system,
    this.wordLanguage = WordLanguageSetting.sameAsApp,
    this.roundSeconds = SettingsLimits.roundDefault,
    this.countdownSeconds = SettingsLimits.countdownDefault,
    this.skipPenalty = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.tickEnabled = true,
    this.swapTilt = false,
    this.showAdult = true,
  });

  final AppLanguageSetting appLanguage;
  final WordLanguageSetting wordLanguage;
  final int roundSeconds;
  final int countdownSeconds;
  final bool skipPenalty;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool tickEnabled;
  final bool swapTilt;
  final bool showAdult;

  Settings copyWith({
    AppLanguageSetting? appLanguage,
    WordLanguageSetting? wordLanguage,
    int? roundSeconds,
    int? countdownSeconds,
    bool? skipPenalty,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? tickEnabled,
    bool? swapTilt,
    bool? showAdult,
  }) {
    return Settings(
      appLanguage: appLanguage ?? this.appLanguage,
      wordLanguage: wordLanguage ?? this.wordLanguage,
      roundSeconds: roundSeconds ?? this.roundSeconds,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      skipPenalty: skipPenalty ?? this.skipPenalty,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      tickEnabled: tickEnabled ?? this.tickEnabled,
      swapTilt: swapTilt ?? this.swapTilt,
      showAdult: showAdult ?? this.showAdult,
    );
  }
}

/// Languages the app supports, for both the UI and the word lists.
const supportedLanguageCodes = ['en', 'it'];

/// UI language: explicit choice, else the device language if supported
/// (Italian), otherwise English.
Locale resolveAppLocale(Settings settings, Locale deviceLocale) {
  return switch (settings.appLanguage) {
    AppLanguageSetting.it => const Locale('it'),
    AppLanguageSetting.en => const Locale('en'),
    AppLanguageSetting.system => Locale(
        supportedLanguageCodes.contains(deviceLocale.languageCode)
            ? deviceLocale.languageCode
            : 'en',
      ),
  };
}

/// Word language code ('it' or 'en'): explicit choice, else the UI language.
String resolveWordLanguage(Settings settings, Locale appLocale) {
  return switch (settings.wordLanguage) {
    WordLanguageSetting.it => 'it',
    WordLanguageSetting.en => 'en',
    WordLanguageSetting.sameAsApp => appLocale.languageCode,
  };
}
