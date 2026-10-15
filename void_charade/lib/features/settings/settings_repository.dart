import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kAppLanguage = 'appLanguage';
  static const _kWordLanguage = 'wordLanguage';
  static const _kRoundSeconds = 'roundSeconds';
  static const _kCountdownSeconds = 'countdownSeconds';
  static const _kSkipPenalty = 'skipPenalty';
  static const _kSound = 'soundEnabled';
  static const _kVibration = 'vibrationEnabled';
  static const _kTick = 'tickEnabled';
  static const _kSwapTilt = 'swapTilt';
  static const _kShowAdult = 'showAdult';

  Settings load() {
    const defaults = Settings();
    return Settings(
      appLanguage: _enum(
        AppLanguageSetting.values,
        _prefs.getString(_kAppLanguage),
        defaults.appLanguage,
      ),
      wordLanguage: _enum(
        WordLanguageSetting.values,
        _prefs.getString(_kWordLanguage),
        defaults.wordLanguage,
      ),
      roundSeconds: _snappedRound(
        _prefs.getInt(_kRoundSeconds) ?? defaults.roundSeconds,
      ),
      countdownSeconds: (_prefs.getInt(_kCountdownSeconds) ??
              defaults.countdownSeconds)
          .clamp(SettingsLimits.countdownMin, SettingsLimits.countdownMax),
      skipPenalty: _prefs.getBool(_kSkipPenalty) ?? defaults.skipPenalty,
      soundEnabled: _prefs.getBool(_kSound) ?? defaults.soundEnabled,
      vibrationEnabled: _prefs.getBool(_kVibration) ?? defaults.vibrationEnabled,
      tickEnabled: _prefs.getBool(_kTick) ?? defaults.tickEnabled,
      swapTilt: _prefs.getBool(_kSwapTilt) ?? defaults.swapTilt,
      showAdult: _prefs.getBool(_kShowAdult) ?? defaults.showAdult,
    );
  }

  Future<void> save(Settings s) async {
    await Future.wait([
      _prefs.setString(_kAppLanguage, s.appLanguage.name),
      _prefs.setString(_kWordLanguage, s.wordLanguage.name),
      _prefs.setInt(_kRoundSeconds, s.roundSeconds),
      _prefs.setInt(_kCountdownSeconds, s.countdownSeconds),
      _prefs.setBool(_kSkipPenalty, s.skipPenalty),
      _prefs.setBool(_kSound, s.soundEnabled),
      _prefs.setBool(_kVibration, s.vibrationEnabled),
      _prefs.setBool(_kTick, s.tickEnabled),
      _prefs.setBool(_kSwapTilt, s.swapTilt),
      _prefs.setBool(_kShowAdult, s.showAdult),
    ]);
  }

  static T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  /// Clamps to the allowed range and snaps to the slider step so a stale or
  /// hand-edited value can never put the slider in an invalid position.
  static int _snappedRound(int value) {
    final clamped = value.clamp(SettingsLimits.roundMin, SettingsLimits.roundMax);
    final steps = ((clamped - SettingsLimits.roundMin) / SettingsLimits.roundStep)
        .round();
    return SettingsLimits.roundMin + steps * SettingsLimits.roundStep;
  }
}
