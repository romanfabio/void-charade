import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../services/haptics_service.dart';
import '../../services/sound_service.dart';
import 'settings.dart';
import 'settings_controller.dart';

const _appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Section(
              title: l10n.settingsLanguageSection,
              children: [
                _SegmentedTile<AppLanguageSetting>(
                  label: l10n.appLanguage,
                  value: settings.appLanguage,
                  options: {
                    AppLanguageSetting.system: l10n.languageSystem,
                    AppLanguageSetting.it: l10n.languageItalian,
                    AppLanguageSetting.en: l10n.languageEnglish,
                  },
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(appLanguage: v)),
                ),
                _SegmentedTile<WordLanguageSetting>(
                  label: l10n.wordLanguage,
                  value: settings.wordLanguage,
                  options: {
                    WordLanguageSetting.sameAsApp: l10n.languageSameAsApp,
                    WordLanguageSetting.it: l10n.languageItalian,
                    WordLanguageSetting.en: l10n.languageEnglish,
                  },
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(wordLanguage: v)),
                ),
              ],
            ),
            _Section(
              title: l10n.settingsGameSection,
              children: [
                _SliderTile(
                  label: l10n.roundDuration,
                  valueLabel: l10n.secondsValue(settings.roundSeconds),
                  value: settings.roundSeconds,
                  min: SettingsLimits.roundMin,
                  max: SettingsLimits.roundMax,
                  step: SettingsLimits.roundStep,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(roundSeconds: v)),
                ),
                _SliderTile(
                  label: l10n.countdownDuration,
                  valueLabel: l10n.secondsValue(settings.countdownSeconds),
                  value: settings.countdownSeconds,
                  min: SettingsLimits.countdownMin,
                  max: SettingsLimits.countdownMax,
                  step: 1,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(countdownSeconds: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.skipPenalty),
                  subtitle: Text(l10n.skipPenaltyHint),
                  value: settings.skipPenalty,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(skipPenalty: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.swapTilt),
                  subtitle: Text(l10n.swapTiltHint),
                  value: settings.swapTilt,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(swapTilt: v)),
                ),
              ],
            ),
            _Section(
              title: l10n.settingsFeedbackSection,
              children: [
                SwitchListTile(
                  title: Text(l10n.sounds),
                  value: settings.soundEnabled,
                  onChanged: (v) {
                    controller.update((s) => s.copyWith(soundEnabled: v));
                    // Let the player hear what they just switched on.
                    if (v) {
                      unawaited(
                        ref.read(soundPlayerProvider).play(SoundEffect.correct),
                      );
                    }
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.tickSound),
                  value: settings.tickEnabled && settings.soundEnabled,
                  onChanged: settings.soundEnabled
                      ? (v) =>
                          controller.update((s) => s.copyWith(tickEnabled: v))
                      : null,
                ),
                SwitchListTile(
                  title: Text(l10n.vibration),
                  value: settings.vibrationEnabled,
                  onChanged: (v) {
                    controller.update((s) => s.copyWith(vibrationEnabled: v));
                    if (v) {
                      unawaited(
                        ref.read(hapticsProvider).vibrate(HapticPatterns.correct),
                      );
                    }
                  },
                ),
              ],
            ),
            _Section(
              title: l10n.settingsContentSection,
              children: [
                SwitchListTile(
                  title: Text(l10n.showAdult),
                  value: settings.showAdult,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(showAdult: v)),
                ),
              ],
            ),
            _Section(
              title: l10n.settingsAboutSection,
              children: [
                ListTile(
                  title: Text(l10n.appTitle),
                  subtitle: Text(l10n.version(_appVersion)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.cyan,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTile<T> extends StatelessWidget {
  const _SegmentedTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final entry in options.entries)
                  ButtonSegment(
                    value: entry.key,
                    label: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              selected: {value},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ step,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
