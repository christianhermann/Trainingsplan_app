import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/workout_repository.dart';

// ── Provider ────────────────────────────────────────────────────────────────

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettingsTableData?>(
        SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<AppSettingsTableData?> {
  @override
  Future<AppSettingsTableData?> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.getSettings();
  }

  Future<void> update(AppSettingsTableCompanion companion) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(companion);
    ref.invalidateSelf();
  }

  /// Deletes all program/week/day/prescription/log data. Settings are kept.
  Future<void> resetAllData(Ref ref) async {
    final db = ref.read(databaseProvider);
    await db.delete(db.exerciseLogs).go();
    await db.delete(db.exercisePrescriptions).go();
    await db.delete(db.workoutDays).go();
    await db.delete(db.workoutWeeks).go();
    await db.delete(db.programs).go();
    await db.delete(db.trainingMaxes).go();
    // Invalidate all affected providers
    ref.invalidateSelf();
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => settings == null
            ? const Center(child: Text('No settings found.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader('Units & Rounding'),
                  _SettingsTile(
                    title: 'Weight unit',
                    subtitle: settings.weightUnit.toUpperCase(),
                    onTap: () =>
                        _showWeightUnitPicker(context, ref, settings),
                  ),
                  _SettingsTile(
                    title: 'Rounding increment',
                    subtitle: '${settings.roundingIncrement} kg',
                    onTap: () =>
                        _showRoundingPicker(context, ref, settings),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('Timer'),
                  _SettingsTile(
                    title: 'Rest timer default',
                    subtitle:
                        '${settings.restTimerSeconds ~/ 60}m ${settings.restTimerSeconds % 60}s',
                    onTap: () =>
                        _showTimerPicker(context, ref, settings),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('Workout Display'),
                  SwitchListTile(
                    title: const Text('Show notes field'),
                    value: settings.showNotesField,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).update(
                              AppSettingsTableCompanion(
                                  showNotesField: Value(v)),
                            ),
                  ),
                  SwitchListTile(
                    title: const Text('Show video field'),
                    value: settings.showVideoField,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).update(
                              AppSettingsTableCompanion(
                                  showVideoField: Value(v)),
                            ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('Danger Zone'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    label: const Text('Reset all data',
                        style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent)),
                    onPressed: () => _confirmReset(context, ref),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import workbook (coming soon)'),
                    onPressed: null,
                  ),
                ],
              ),
      ),
    );
  }

  void _showWeightUnitPicker(BuildContext context, WidgetRef ref,
      AppSettingsTableData settings) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Weight unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['kg', 'lbs'].map((unit) {
            return RadioListTile<String>(
              title: Text(unit.toUpperCase()),
              value: unit,
              groupValue: settings.weightUnit,
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).update(
                        AppSettingsTableCompanion(weightUnit: Value(v)),
                      );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRoundingPicker(BuildContext context, WidgetRef ref,
      AppSettingsTableData settings) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rounding increment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1.0, 1.25, 2.5, 5.0].map((inc) {
            return RadioListTile<double>(
              title: Text('$inc kg'),
              value: inc,
              groupValue: settings.roundingIncrement,
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).update(
                        AppSettingsTableCompanion(
                            roundingIncrement: Value(v)),
                      );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimerPicker(BuildContext context, WidgetRef ref,
      AppSettingsTableData settings) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rest timer default'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [60, 90, 120, 150, 180, 240, 300].map((s) {
            return RadioListTile<int>(
              title: Text(
                  '${s ~/ 60}m${s % 60 > 0 ? ' ${s % 60}s' : ''}'),
              value: s,
              groupValue: settings.restTimerSeconds,
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).update(
                        AppSettingsTableCompanion(
                            restTimerSeconds: Value(v)),
                      );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'This will delete all programs, workouts, and logs. This cannot be undone.'),
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
                  .resetAllData(ref as Ref);
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
}

// ── Helpers ──────────────────────────────────────────────────────────────────

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
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing:
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      onTap: onTap,
    );
  }
}
