// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Void Charade';

  @override
  String categoriesSubtitle(int seconds, String wordLanguage) {
    return '$seconds s · parole in $wordLanguage';
  }

  @override
  String get randomCategory => 'Categoria casuale';

  @override
  String get mixAll => 'Tutte insieme';

  @override
  String get adultBadge => '18+';

  @override
  String get noCategories => 'Nessuna categoria disponibile';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsGameSection => 'Gioco';

  @override
  String get settingsLanguageSection => 'Lingua';

  @override
  String get settingsFeedbackSection => 'Suoni e sensazioni';

  @override
  String get settingsContentSection => 'Contenuti';

  @override
  String get settingsAboutSection => 'Info';

  @override
  String get appLanguage => 'Lingua dell\'app';

  @override
  String get wordLanguage => 'Lingua delle parole';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageSameAsApp => 'Auto';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get roundDuration => 'Durata del round';

  @override
  String get countdownDuration => 'Conto alla rovescia';

  @override
  String secondsValue(int seconds) {
    return '$seconds s';
  }

  @override
  String get skipPenalty => 'Il salto costa 1 punto';

  @override
  String get skipPenaltyHint => 'Ogni parola saltata toglie un punto';

  @override
  String get sounds => 'Suoni';

  @override
  String get vibration => 'Vibrazione';

  @override
  String get tickSound => 'Ticchettio negli ultimi secondi';

  @override
  String get swapTilt => 'Inverti inclinazione';

  @override
  String get swapTiltHint =>
      'Predefinito: schermo in basso = indovinata, schermo in alto = salta';

  @override
  String get showAdult => 'Mostra categorie 18+';

  @override
  String version(String version) {
    return 'Versione $version';
  }
}
