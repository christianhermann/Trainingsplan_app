import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';
import 'settings_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (settings) {
          final s = settings ?? _kDefault;
          return _SettingsList(settings: s);
        },
      ),
    );
  }
}

// ── Default re-exported for convenience ───────────────────────────────────────────────

const _kDefault = AppSettings(
  id:               'default',
  weightUnit:       'kg',
  roundingMode:     'nearest',
  roundingIncrement: 2.5,
  themeMode:        'dark',
  restTimerSeconds: 180,
  showVideoField:   true,
  showNotesField:   true,
);

// ── Settings list ────────────────────────────────────────────────────────────────────

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final s        = settings;
    final mode     = RoundingMode.fromString(s.roundingMode);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Units & Rounding ──────────────────────────────────────────────────
        const _SectionHeader('Units & Rounding'),

        _SettingsTile(
          title:    'Weight unit',
          subtitle: s.weightUnit.toUpperCase(),
          onTap:    () => _showWeightUnitDialog(context, ref, s),
        ),

        _SettingsTile(
          title:    'Rounding mode',
          subtitle: _roundingModeLabel(mode),
          onTap:    () => _showRoundingModeDialog(context, ref, mode),
        ),

        _SettingsTile(
          title:    'Rounding increment',
          subtitle: '${s.roundingIncrement} ${s.weightUnit}',
          onTap:    () => _showRoundingIncrementDialog(context, ref, s),
        ),

        const SizedBox(height: 16),

        // ── Appearance ────────────────────────────────────────────────────────
        const _SectionHeader('Appearance'),

        _SettingsTile(
          title:    'Theme',
          subtitle: _themeModeLabel(s.themeMode),
          onTap:    () => _showThemeModeDialog(context, ref, s),
        ),

        const SizedBox(height: 16),

        // ── Timer ────────────────────────────────────────────────────────────────────
        const _SectionHeader('Timer'),

        _SettingsTile(
          title:    'Rest timer default',
          subtitle: _formatSeconds(s.restTimerSeconds),
          onTap:    () => _showTimerDialog(context, ref, s),
        ),

        const SizedBox(height: 16),

        // ── Workout display ────────────────────────────────────────────────────
        const _SectionHeader('Workout Display'),

        SwitchListTile(
          title:     const Text('Show notes field'),
          value:     s.showNotesField,
          onChanged: (_) => notifier.toggleNotesField(),
        ),

        SwitchListTile(
          title:     const Text('Show video field'),
          value:     s.showVideoField,
          onChanged: (_) => notifier.toggleVideoField(),
        ),

        const SizedBox(height: 24),

        // ── Danger zone ─────────────────────────────────────────────────────────
        const _SectionHeader('Danger Zone'),
        const SizedBox(height: 8),

        OutlinedButton.icon(
          icon:  const Icon(Icons.delete_forever, color: Colors.redAccent),
          label: const Text('Reset all data',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent)),
          onPressed: () => _confirmReset(context, ref),
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          icon:  const Icon(Icons.upload_file),
          label: const Text('Import workbook (coming soon)'),
          onPressed: null,
        ),
      ],
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showWeightUnitDialog(
      BuildContext context, WidgetRef ref, AppSettings s) {
    _showRadioDialog<String>(
      context:    context,
      title:      'Weight unit',
      options:    const ['kg', 'lbs'],
      labelOf:    (v) => v.toUpperCase(),
      current:    s.weightUnit,
      onSelected: (v) =>
          ref.read(settingsProvider.notifier).setWeightUnit(v),
    );
  }

  void _showRoundingModeDialog(
      BuildContext context, WidgetRef ref, RoundingMode current) {
    _showRadioDialog<RoundingMode>(
      context:    context,
      title:      'Rounding mode',
      options:    RoundingMode.values,
      labelOf:    _roundingModeLabel,
      current:    current,
      onSelected: (v) =>
          ref.read(settingsProvider.notifier).setRoundingMode(v),
    );
  }

  void _showRoundingIncrementDialog(
      BuildContext context, WidgetRef ref, AppSettings s) {
    _showRadioDialog<double>(
      context:    context,
      title:      'Rounding increment',
      options:    const [1.0, 1.25, 2.5, 5.0],
      labelOf:    (v) => '$v ${s.weightUnit}',
      current:    s.roundingIncrement,
      onSelected: (v) =>
          ref.read(settingsProvider.notifier).setRoundingIncrement(v),
    );
  }

  void _showThemeModeDialog(
      BuildContext context, WidgetRef ref, AppSettings s) {
    _showRadioDialog<String>(
      context:    context,
      title:      'Theme',
      options:    const ['dark', 'light', 'system'],
      labelOf:    _themeModeLabel,
      current:    s.themeMode,
      onSelected: (v) =>
          ref.read(settingsProvider.notifier).setThemeMode(v),
    );
  }

  void _showTimerDialog(BuildContext context, WidgetRef ref, AppSettings s) {
    _showRadioDialog<int>(
      context:    context,
      title:      'Rest timer default',
      options:    const [60, 90, 120, 150, 180, 240, 300],
      labelOf:    _formatSeconds,
      current:    s.restTimerSeconds,
      onSelected: (v) =>
          ref.read(settingsProvider.notifier).setRestTimerSeconds(v),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Reset all data?'),
        content: const Text(
            'This will delete all programs, workouts, and logs.\n'
            'Settings are kept. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(settingsProvider.notifier)
                  .resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All data has been reset.')),
                );
              }
            },
            child: const Text('Reset',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Generic radio dialog ───────────────────────────────────────────────────

  /// Generic single-select dialog. Closes and calls [onSelected] immediately
  /// on tap — no confirm button needed (matches one-tap patterns from guidelines).
  void _showRadioDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T current,
    required void Function(T) onSelected,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((opt) => RadioListTile<T>(
                    title:     Text(labelOf(opt)),
                    value:     opt,
                    groupValue: current,
                    onChanged: (v) {
                      if (v != null) {
                        onSelected(v);
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  static String _roundingModeLabel(RoundingMode m) => switch (m) {
    RoundingMode.nearest => 'Nearest',
    RoundingMode.floor   => 'Always round down',
    RoundingMode.ceiling => 'Always round up',
  };

  static String _themeModeLabel(String t) => switch (t) {
    'dark'   => 'Dark',
    'light'  => 'Light',
    'system' => 'System default',
    _        => t,
  };

  static String _formatSeconds(int s) {
    final m = s ~/ 60;
    final r = s  % 60;
    return r > 0 ? '${m}m ${r}s' : '${m}m';
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:    Text(title),
      trailing: Text(subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary)),
      onTap: onTap,
    );
  }
}
