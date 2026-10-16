import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Void Charade'**
  String get appTitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s · {wordLanguage} words'**
  String categoriesSubtitle(int seconds, String wordLanguage);

  /// No description provided for @randomCategory.
  ///
  /// In en, this message translates to:
  /// **'Random category'**
  String get randomCategory;

  /// No description provided for @mixAll.
  ///
  /// In en, this message translates to:
  /// **'Mix all'**
  String get mixAll;

  /// No description provided for @adultBadge.
  ///
  /// In en, this message translates to:
  /// **'18+'**
  String get adultBadge;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategories;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGameSection.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get settingsGameSection;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsFeedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Sound & feel'**
  String get settingsFeedbackSection;

  /// No description provided for @settingsContentSection.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get settingsContentSection;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @wordLanguage.
  ///
  /// In en, this message translates to:
  /// **'Word language'**
  String get wordLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSameAsApp.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get languageSameAsApp;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNameItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageNameItalian;

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @roundDuration.
  ///
  /// In en, this message translates to:
  /// **'Round duration'**
  String get roundDuration;

  /// No description provided for @countdownDuration.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdownDuration;

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String secondsValue(int seconds);

  /// No description provided for @skipPenalty.
  ///
  /// In en, this message translates to:
  /// **'Skip costs 1 point'**
  String get skipPenalty;

  /// No description provided for @skipPenaltyHint.
  ///
  /// In en, this message translates to:
  /// **'Each skipped word subtracts one point'**
  String get skipPenaltyHint;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get sounds;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @tickSound.
  ///
  /// In en, this message translates to:
  /// **'Final-seconds ticking'**
  String get tickSound;

  /// No description provided for @swapTilt.
  ///
  /// In en, this message translates to:
  /// **'Swap tilt directions'**
  String get swapTilt;

  /// No description provided for @swapTiltHint.
  ///
  /// In en, this message translates to:
  /// **'Default: screen down = correct, screen up = skip'**
  String get swapTiltHint;

  /// No description provided for @tiltSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Tilt sensitivity'**
  String get tiltSensitivity;

  /// No description provided for @tiltStrict.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get tiltStrict;

  /// No description provided for @tiltNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get tiltNormal;

  /// No description provided for @tiltRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get tiltRelaxed;

  /// No description provided for @touchControls.
  ///
  /// In en, this message translates to:
  /// **'Touch controls'**
  String get touchControls;

  /// No description provided for @touchControlsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the right half of the screen for correct, the left half to skip. Tilt is turned off'**
  String get touchControlsHint;

  /// No description provided for @showAdult.
  ///
  /// In en, this message translates to:
  /// **'Show 18+ categories'**
  String get showAdult;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @noWordsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No words available for this category'**
  String get noWordsAvailable;

  /// No description provided for @gameGetReady.
  ///
  /// In en, this message translates to:
  /// **'Put the phone on your forehead!'**
  String get gameGetReady;

  /// No description provided for @gameGetReadyTouch.
  ///
  /// In en, this message translates to:
  /// **'Get ready!'**
  String get gameGetReadyTouch;

  /// No description provided for @gameHoldUpright.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone upright'**
  String get gameHoldUpright;

  /// No description provided for @gameResuming.
  ///
  /// In en, this message translates to:
  /// **'Get ready…'**
  String get gameResuming;

  /// No description provided for @gameCorrect.
  ///
  /// In en, this message translates to:
  /// **'CORRECT!'**
  String get gameCorrect;

  /// No description provided for @gameSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get gameSkip;

  /// No description provided for @gameTimeUp.
  ///
  /// In en, this message translates to:
  /// **'TIME\'S UP!'**
  String get gameTimeUp;

  /// No description provided for @quitTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit the round?'**
  String get quitTitle;

  /// No description provided for @quitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress in this round will be lost.'**
  String get quitMessage;

  /// No description provided for @quitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quitConfirm;

  /// No description provided for @quitCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get quitCancel;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Round over'**
  String get resultsTitle;

  /// No description provided for @resultsScore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{count} points}}'**
  String resultsScore(int count);

  /// No description provided for @resultsGuessed.
  ///
  /// In en, this message translates to:
  /// **'Guessed'**
  String get resultsGuessed;

  /// No description provided for @resultsSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get resultsSkipped;

  /// No description provided for @resultsNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Not played'**
  String get resultsNotPlayed;

  /// No description provided for @aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Fonts: Lilita One and Nunito (SIL Open Font License 1.1). Sound effects were generated for this app. Works fully offline: no ads, no tracking.'**
  String get aboutLegalese;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @backToCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get backToCategories;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
