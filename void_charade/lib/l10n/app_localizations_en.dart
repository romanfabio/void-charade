// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Void Charade';

  @override
  String categoriesSubtitle(int seconds, String wordLanguage) {
    return '$seconds s · $wordLanguage words';
  }

  @override
  String get randomCategory => 'Random category';

  @override
  String get mixAll => 'Mix all';

  @override
  String get adultBadge => '18+';

  @override
  String get noCategories => 'No categories available';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGameSection => 'Game';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsFeedbackSection => 'Sound & feel';

  @override
  String get settingsContentSection => 'Content';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get appLanguage => 'App language';

  @override
  String get wordLanguage => 'Word language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSameAsApp => 'Auto';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get roundDuration => 'Round duration';

  @override
  String get countdownDuration => 'Countdown';

  @override
  String secondsValue(int seconds) {
    return '$seconds s';
  }

  @override
  String get skipPenalty => 'Skip costs 1 point';

  @override
  String get skipPenaltyHint => 'Each skipped word subtracts one point';

  @override
  String get sounds => 'Sounds';

  @override
  String get vibration => 'Vibration';

  @override
  String get tickSound => 'Final-seconds ticking';

  @override
  String get swapTilt => 'Swap tilt directions';

  @override
  String get swapTiltHint => 'Default: screen down = correct, screen up = skip';

  @override
  String get showAdult => 'Show 18+ categories';

  @override
  String version(String version) {
    return 'Version $version';
  }
}
