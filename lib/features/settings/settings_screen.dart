import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/backup_service.dart';
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
          final s = settings ?? kDefaultSettings;
          return _SettingsList(settings: s);
        },
      ),
    );
  }
}

// ── Settings list ──────────────────────────────────────────────────────────────────

class _SettingsList extends ConsumerStatefulWidget {
  const _SettingsList({required this.settings});
  final AppSettings settings;

  @override
  ConsumerState<_SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends ConsumerState<_SettingsList> {
  int  _versionTapCount = 0;
  bool _exporting       = false;
  bool _importing       = false;

  AppSettings get s => widget.settings;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);
    final mode     = RoundingMode.fromString(s.roundingMode);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Units & Rounding ────────────────────────────────────────────
        const _SectionHeader('Units & Rounding'),

        _SettingsTile(
          title:    'Weight unit',
          subtitle: s.weightUnit.toUpperCase(),
          onTap:    () => _showWeightUnitDialog(context, s),
        ),

        _SettingsTile(
          title:    'Rounding mode',
          subtitle: _roundingModeLabel(mode),
          onTap:    () => _showRoundingModeDialog(context, mode),
        ),

        _SettingsTile(
          title:    'Rounding increment',
          subtitle: '${s.roundingIncrement} ${s.weightUnit}',
          onTap:    () => _showRoundingIncrementDialog(context, s),
        ),

        const SizedBox(height: 16),

        // ── Appearance ──────────────────────────────────────────────────
        const _SectionHeader('Appearance'),

        _SettingsTile(
          title:    'Theme',
          subtitle: _themeModeLabel(s.themeMode),
          onTap:    () => _showThemeModeDialog(context, s),
        ),

        const SizedBox(height: 16),

        // ── Timer ────────────────────────────────────────────────────────────
        const _SectionHeader('Timer'),

        _SettingsTile(
          title:    'Rest timer default',
          subtitle: _formatSeconds(s.restTimerSeconds),
          onTap:    () => _showTimerDialog(context, s),
        ),

        const SizedBox(height: 16),

        // ── Workout display ──────────────────────────────────────────────
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

        const SizedBox(height: 16),

        // ── Import / Export ──────────────────────────────────────────────
        const _SectionHeader('Import / Export'),
        const SizedBox(height: 4),

        OutlinedButton.icon(
          icon:  _exporting
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_rounded),
          label: Text(_exporting ? 'Exporting…' : 'Export Training Data'),
          onPressed: _exporting ? null : () => _doExport(context),
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          icon:  _importing
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_rounded),
          label: Text(_importing ? 'Importing…' : 'Import from Backup'),
          onPressed: _importing ? null : () => _doImport(context),
        ),

        const SizedBox(height: 24),

        // ── Danger zone ──────────────────────────────────────────────────
        const _SectionHeader('Danger Zone'),
        const SizedBox(height: 8),

        OutlinedButton.icon(
          icon:  const Icon(Icons.delete_forever, color: Colors.redAccent),
          label: const Text('Reset all data',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent)),
          onPressed: () => _confirmReset(context),
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          icon:  const Icon(Icons.upload_file),
          label: const Text('Import workbook (coming soon)'),
          onPressed: null,
        ),

        const SizedBox(height: 32),

        // ── Version label (5-tap easter egg → Debug screen) ─────────────────
        GestureDetector(
          onTap: () {
            setState(() => _versionTapCount++);
            if (_versionTapCount >= 5) {
              setState(() => _versionTapCount = 0);
              context.goNamed('debug');
            }
          },
          child: Center(
            child: Text(
              'v1.0.0+1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35)),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Import / Export handlers ───────────────────────────────────────────

  Future<void> _doExport(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      await ref.read(backupServiceProvider).exportAndShare();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _doImport(BuildContext context) async {
    setState(() => _importing = true);
    try {
      final msg = await ref.read(backupServiceProvider).importFromFile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────

  void _showWeightUnitDialog(BuildContext context, AppSettings s) {
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
      BuildContext context, RoundingMode current) {
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
      BuildContext context, AppSettings s) {
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

  void _showThemeModeDialog(BuildContext context, AppSettings s) {
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

  void _showTimerDialog(BuildContext context, AppSettings s) {
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

  void _confirmReset(BuildContext context) {
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
        content: RadioGroup<T>(
          groupValue: current,
          onChanged: (v) {
            if (v != null) {
              onSelected(v);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((opt) => RadioListTile<T>(
                      title: Text(labelOf(opt)),
                      value: opt,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── Label helpers ────────────────────────────────────────────────────

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

// ── Shared widgets ────────────────────────────────────────────────────────────────

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
