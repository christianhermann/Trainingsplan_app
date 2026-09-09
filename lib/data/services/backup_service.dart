import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:share_plus/share_plus.dart';

import '../persistence/database.dart';
import '../repositories/training_max_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/program_repository.dart';

// ── JSON keys ─────────────────────────────────────────────────────────

const _kVersion = 'version';
const _kExportedAt = 'exportedAt';
const _kTrainingMaxes = 'trainingMaxes';
const _kExerciseLogs = 'exerciseLogs';

// ── Service ────────────────────────────────────────────────────────────

class BackupService {
  BackupService(this._tmRepo, this._workoutRepo, this._programRepo);

  final TrainingMaxRepository _tmRepo;
  final WorkoutRepository _workoutRepo;
  final ProgramRepository _programRepo;

  // ── Export ────────────────────────────────────────────────────

  /// Serialises all [TrainingMaxe] and [ExerciseLog] rows to JSON,
  /// writes a temp file, and triggers the OS share sheet.
  Future<void> exportAndShare() async {
    final maxes = await _tmRepo.getAllMaxes();
    final logs = await _collectAllLogs();

    final payload = jsonEncode({
      _kVersion: 1,
      _kExportedAt: DateTime.now().toIso8601String(),
      _kTrainingMaxes: maxes.map(_maxToJson).toList(),
      _kExerciseLogs: logs.map(_logToJson).toList(),
    });

    final dir = await getTemporaryDirectory();
    final fileName = 'trainingsplan_backup_'
        '${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(payload);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Trainingsplan Backup',
    );
  }

  // ── Import ────────────────────────────────────────────────────

  /// Opens the OS file picker, reads the chosen JSON backup, and restores
  /// [TrainingMaxe] and [ExerciseLog] rows using insertOnConflictUpdate
  /// so existing rows are overwritten by the backup values.
  ///
  /// Returns a human-readable summary string, or throws on parse failure.
  Future<String> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return 'Import cancelled.';
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) throw const FormatException('Could not read file.');

    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    _validateVersion(json);

    int maxesRestored = 0;
    int logsRestored = 0;

    // ── Restore TrainingMaxes ──────────────────────────────────────
    final rawMaxes = json[_kTrainingMaxes] as List<dynamic>? ?? [];
    for (final raw in rawMaxes) {
      final m = raw as Map<String, dynamic>;
      await _tmRepo.saveMax(
        TrainingMaxesCompanion.insert(
          id: Value(m['id'] as int),
          liftId: m['liftId'] as int,
          value: (m['value'] as num).toDouble(),
          singleEightPercentage:
              Value((m['singleEightPercentage'] as num?)?.toDouble() ?? 0.9),
          sourceType: Value(m['sourceType'] as String? ?? 'import'),
          effectiveDate: DateTime.parse(m['effectiveDate'] as String),
          notes: Value(m['notes'] as String?),
        ),
      );
      maxesRestored++;
    }

    // ── Restore ExerciseLogs ───────────────────────────────────────
    final rawLogs = json[_kExerciseLogs] as List<dynamic>? ?? [];
    for (final raw in rawLogs) {
      final l = raw as Map<String, dynamic>;
      await _workoutRepo.saveLog(
        ExerciseLogsCompanion.insert(
          id: Value(l['id'] as int),
          prescriptionId: l['prescriptionId'] as int,
          completedSets: Value(l['completedSets'] as int? ?? 0),
          repsOnLastSet: Value(l['repsOnLastSet'] as int?),
          notes: Value(l['notes'] as String?),
          videoUrl: Value(l['videoUrl'] as String?),
          completedAt: DateTime.parse(l['completedAt'] as String),
        ),
      );
      logsRestored++;
    }

    return 'Restored $maxesRestored training max(es) and $logsRestored log(s).';
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Future<List<ExerciseLog>> _collectAllLogs() async {
    final programs = await _programRepo.getAllPrograms();
    final all = <ExerciseLog>[];
    for (final prog in programs) {
      final weeks = await _programRepo.getWeeksForProgram(prog.id);
      for (final week in weeks) {
        final days = await _programRepo.getDaysForWeek(week.id);
        for (final day in days) {
          all.addAll(await _workoutRepo.getLogsForDay(day.id));
        }
      }
    }
    return all;
  }

  static Map<String, dynamic> _maxToJson(TrainingMaxe m) => {
        'id': m.id,
        'liftId': m.liftId,
        'value': m.value,
        'singleEightPercentage': m.singleEightPercentage,
        'sourceType': m.sourceType,
        'effectiveDate': m.effectiveDate.toIso8601String(),
        'notes': m.notes,
      };

  static Map<String, dynamic> _logToJson(ExerciseLog l) => {
        'id': l.id,
        'prescriptionId': l.prescriptionId,
        'completedSets': l.completedSets,
        'repsOnLastSet': l.repsOnLastSet,
        'notes': l.notes,
        'videoUrl': l.videoUrl,
        'completedAt': l.completedAt.toIso8601String(),
      };

  static void _validateVersion(Map<String, dynamic> json) {
    final v = json[_kVersion];
    if (v == null) throw const FormatException('Missing version field.');
    if (v as int > 1) {
      throw FormatException(
          'Backup version $v is newer than this app supports.');
    }
  }
}

// ── Provider ────────────────────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(trainingMaxRepositoryProvider),
    ref.watch(workoutRepositoryProvider),
    ref.watch(programRepositoryProvider),
  );
});
