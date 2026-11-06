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
  String get languageNameItalian => 'Italian';

  @override
  String get languageNameEnglish => 'English';

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
  String get tiltSensitivity => 'Tilt sensitivity';

  @override
  String get tiltStrict => 'Strict';

  @override
  String get tiltNormal => 'Normal';

  @override
  String get tiltRelaxed => 'Relaxed';

  @override
  String get touchControls => 'Touch controls';

  @override
  String get touchControlsHint =>
      'Tap the right half of the screen for correct, the left half to skip. Tilt is turned off';

  @override
  String get showAdult => 'Show 18+ categories';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get noWordsAvailable => 'No words available for this category';

  @override
  String get gameGetReady => 'Put the phone on your forehead!';

  @override
  String get gameGetReadyTouch => 'Get ready!';

  @override
  String get gameHoldUpright => 'Hold the phone upright';

  @override
  String get gameResuming => 'Get ready…';

  @override
  String get gameCorrect => 'CORRECT!';

  @override
  String get gameSkip => 'SKIP';

  @override
  String get gameTimeUp => 'TIME\'S UP!';

  @override
  String get quitTitle => 'Quit the round?';

  @override
  String get quitMessage => 'Your progress in this round will be lost.';

  @override
  String get quitConfirm => 'Quit';

  @override
  String get quitCancel => 'Keep playing';

  @override
  String get resultsTitle => 'Round over';

  @override
  String resultsScore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get resultsGuessed => 'Guessed';

  @override
  String get resultsSkipped => 'Skipped';

  @override
  String get resultsNotPlayed => 'Not played';

  @override
  String get aboutSourceCode =>
      'Free and open source (MIT licence). Source code:';

  @override
  String get aboutLegalese =>
      'Fonts: Lilita One and Nunito (SIL Open Font License 1.1). Sound effects were generated for this app. Works fully offline: no ads, no tracking.';

  @override
  String get playAgain => 'Play again';

  @override
  String get backToCategories => 'Categories';
}
