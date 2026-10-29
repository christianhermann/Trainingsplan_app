import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:share_plus/share_plus.dart';

import '../persistence/database.dart';

// ── JSON keys ─────────────────────────────────────────────────────────

const _kVersion = 'version';
const _kExportedAt = 'exportedAt';
const _kTrainingMaxes = 'trainingMaxes';
const _kExerciseLogs = 'exerciseLogs';

// ── Service ────────────────────────────────────────────────────────────

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  // ── Export ────────────────────────────────────────────────────

  /// Serialises the complete training database to JSON,
  /// writes a temp file, and triggers the OS share sheet.
  Future<void> exportAndShare() async {
    final programs = await _db.select(_db.programs).get();
    final weeks = await _db.select(_db.workoutWeeks).get();
    final days = await _db.select(_db.workoutDays).get();
    final prescriptions = await _db.select(_db.exercisePrescriptions).get();
    final logs = await _db.select(_db.exerciseLogs).get();
    final maxes = await _db.select(_db.trainingMaxes).get();

    final payload = jsonEncode({
      _kVersion: 2,
      _kExportedAt: DateTime.now().toIso8601String(),
      'programs': programs
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'frequency': p.frequency,
                'currentWeek': p.currentWeek,
                'totalWeeks': p.totalWeeks,
                'isActive': p.isActive,
                'createdAt': p.createdAt.toIso8601String(),
                'updatedAt': p.updatedAt.toIso8601String(),
              })
          .toList(),
      'weeks': weeks
          .map((w) => {
                'id': w.id,
                'programId': w.programId,
                'weekNumber': w.weekNumber,
                'displayLabel': w.displayLabel,
                'startDate': w.startDate?.toIso8601String(),
                'endDate': w.endDate?.toIso8601String(),
              })
          .toList(),
      'days': days
          .map((d) => {
                'id': d.id,
                'workoutWeekId': d.workoutWeekId,
                'dayIndex': d.dayIndex,
                'title': d.title,
                'status': d.status,
                'completedAt': d.completedAt?.toIso8601String(),
              })
          .toList(),
      'prescriptions': prescriptions
          .map((p) => {
                'id': p.id,
                'workoutDayId': p.workoutDayId,
                'liftId': p.liftId,
                'trainingMaxSnapshot': p.trainingMaxSnapshot,
                'intensity': p.intensity,
                'workingWeight': p.workingWeight,
                'repsPerNormalSet': p.repsPerNormalSet,
                'repOutTarget': p.repOutTarget,
                'setGoal': p.setGoal,
                'displayOrder': p.displayOrder,
                'isPrimaryBlock': p.isPrimaryBlock,
              })
          .toList(),
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

  /// Exports full workout history formatted as standard CSV for coaches,
  /// Excel, and Google Sheets, then triggers the OS share sheet.
  Future<void> exportToCsv() async {
    final programs = await _db.select(_db.programs).get();
    final weeks = await _db.select(_db.workoutWeeks).get();
    final days = await _db.select(_db.workoutDays).get();
    final prescriptions = await _db.select(_db.exercisePrescriptions).get();
    final logs = await _db.select(_db.exerciseLogs).get();
    final lifts = await _db.select(_db.lifts).get();

    final programMap = {for (final p in programs) p.id: p};
    final weekMap = {for (final w in weeks) w.id: w};
    final dayMap = {for (final d in days) d.id: d};
    final prescMap = {for (final p in prescriptions) p.id: p};
    final liftMap = {for (final l in lifts) l.id: l};

    final sortedLogs = List<ExerciseLog>.from(logs)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    final buffer = StringBuffer();
    // CSV Header row
    buffer.writeln(
      'Date,Program,Week,Day,Lift,Category,Working_Weight_kg,'
      'Prescribed_Sets,Completed_Sets,Prescribed_Reps,Rep_Out_Target,'
      'Reps_On_Last_Set,Rep_Diff,Estimated_1RM_kg,Volume_kg,Notes,Video_URL',
    );

    for (final log in sortedLogs) {
      final presc = prescMap[log.prescriptionId];
      final day = presc != null ? dayMap[presc.workoutDayId] : null;
      final week = day != null ? weekMap[day.workoutWeekId] : null;
      final program = week != null ? programMap[week.programId] : null;
      final lift = presc != null ? liftMap[presc.liftId] : null;

      final dateStr = log.completedAt
          .toIso8601String()
          .substring(0, 16)
          .replaceAll('T', ' ');
      final programName = program?.name ?? '';
      final weekNum = week?.weekNumber.toString() ?? '';
      final dayTitle = day != null ? 'Day ${day.dayIndex + 1}' : '';
      final liftName = lift?.displayName ?? '';
      final category = (presc?.isPrimaryBlock ?? true) ? 'Main' : 'Auxiliary';
      final weight = presc?.workingWeight.toStringAsFixed(1) ?? '';
      final setGoal = presc?.setGoal.toString() ?? '';
      final setsDone = log.completedSets.toString();
      final repsPerSet = presc?.repsPerNormalSet.toString() ?? '';
      final target = presc?.repOutTarget.toString() ?? '';
      final actualReps = log.repsOnLastSet?.toString() ?? '';
      final diff = (log.repsOnLastSet != null && presc != null)
          ? (log.repsOnLastSet! - presc.repOutTarget).toString()
          : '';

      final e1rm = (log.repsOnLastSet != null && presc != null)
          ? (presc.workingWeight * (1 + log.repsOnLastSet! / 30.0))
              .toStringAsFixed(1)
          : '';

      double vol = 0;
      if (presc != null && log.completedSets > 0) {
        final normalSets = (log.completedSets - 1).clamp(0, 999);
        final totalReps = (normalSets * presc.repsPerNormalSet) +
            (log.repsOnLastSet ?? presc.repsPerNormalSet);
        vol = totalReps * presc.workingWeight;
      }
      final volumeStr = vol > 0 ? vol.toStringAsFixed(0) : '';

      final notes = _escapeCsv(log.notes);
      final video = _escapeCsv(log.videoUrl);

      buffer.writeln(
        '$dateStr,'
        '${_escapeCsv(programName)},'
        '$weekNum,'
        '${_escapeCsv(dayTitle)},'
        '${_escapeCsv(liftName)},'
        '$category,'
        '$weight,'
        '$setGoal,'
        '$setsDone,'
        '$repsPerSet,'
        '$target,'
        '$actualReps,'
        '$diff,'
        '$e1rm,'
        '$volumeStr,'
        '$notes,'
        '$video',
      );
    }

    final dir = await getTemporaryDirectory();
    final dateFileStr = DateTime.now().toIso8601String().substring(0, 10);
    final fileName = 'trainingsplan_history_$dateFileStr.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Trainingsplan Workout History (CSV / Excel)',
    );
  }

  static String _escapeCsv(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Import ────────────────────────────────────────────────────

  /// Opens the OS file picker, reads the chosen JSON backup, and restores
  /// all relational data in a single database transaction.
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

    int programsRestored = 0;
    int maxesRestored = 0;
    int logsRestored = 0;

    await _db.transaction(() async {
      // Restore programs if present (version 2)
      if (json.containsKey('programs')) {
        final rawPrograms = json['programs'] as List<dynamic>? ?? [];
        for (final raw in rawPrograms) {
          final p = raw as Map<String, dynamic>;
          await _db.into(_db.programs).insertOnConflictUpdate(
                ProgramsCompanion(
                  id: Value(p['id'] as int),
                  name: Value(p['name'] as String),
                  frequency: Value(p['frequency'] as String),
                  currentWeek: Value(p['currentWeek'] as int),
                  totalWeeks: Value(p['totalWeeks'] as int),
                  isActive: Value(p['isActive'] as bool),
                  createdAt: Value(DateTime.parse(p['createdAt'] as String)),
                  updatedAt: Value(DateTime.parse(p['updatedAt'] as String)),
                ),
              );
          programsRestored++;
        }
      }

      if (json.containsKey('weeks')) {
        final rawWeeks = json['weeks'] as List<dynamic>? ?? [];
        for (final raw in rawWeeks) {
          final w = raw as Map<String, dynamic>;
          await _db.into(_db.workoutWeeks).insertOnConflictUpdate(
                WorkoutWeeksCompanion(
                  id: Value(w['id'] as int),
                  programId: Value(w['programId'] as int),
                  weekNumber: Value(w['weekNumber'] as int),
                  displayLabel: Value(w['displayLabel'] as String? ?? ''),
                  startDate: Value(w['startDate'] != null
                      ? DateTime.parse(w['startDate'] as String)
                      : null),
                  endDate: Value(w['endDate'] != null
                      ? DateTime.parse(w['endDate'] as String)
                      : null),
                ),
              );
        }
      }

      if (json.containsKey('days')) {
        final rawDays = json['days'] as List<dynamic>? ?? [];
        for (final raw in rawDays) {
          final d = raw as Map<String, dynamic>;
          await _db.into(_db.workoutDays).insertOnConflictUpdate(
                WorkoutDaysCompanion(
                  id: Value(d['id'] as int),
                  workoutWeekId: Value(d['workoutWeekId'] as int),
                  dayIndex: Value(d['dayIndex'] as int),
                  title: Value(d['title'] as String? ?? ''),
                  status: Value(d['status'] as String? ?? 'planned'),
                  completedAt: Value(d['completedAt'] != null
                      ? DateTime.parse(d['completedAt'] as String)
                      : null),
                ),
              );
        }
      }

      if (json.containsKey('prescriptions')) {
        final rawPrescs = json['prescriptions'] as List<dynamic>? ?? [];
        for (final raw in rawPrescs) {
          final p = raw as Map<String, dynamic>;
          await _db.into(_db.exercisePrescriptions).insertOnConflictUpdate(
                ExercisePrescriptionsCompanion(
                  id: Value(p['id'] as int),
                  workoutDayId: Value(p['workoutDayId'] as int),
                  liftId: Value(p['liftId'] as int),
                  trainingMaxSnapshot:
                      Value((p['trainingMaxSnapshot'] as num).toDouble()),
                  intensity: Value((p['intensity'] as num).toDouble()),
                  workingWeight: Value((p['workingWeight'] as num).toDouble()),
                  repsPerNormalSet: Value(p['repsPerNormalSet'] as int),
                  repOutTarget: Value(p['repOutTarget'] as int),
                  setGoal: Value(p['setGoal'] as int),
                  displayOrder: Value(p['displayOrder'] as int? ?? 0),
                  isPrimaryBlock: Value(p['isPrimaryBlock'] as bool? ?? true),
                ),
              );
        }
      }

      // Restore TrainingMaxes
      final rawMaxes = json[_kTrainingMaxes] as List<dynamic>? ?? [];
      for (final raw in rawMaxes) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.trainingMaxes).insertOnConflictUpdate(
              TrainingMaxesCompanion(
                id: Value(m['id'] as int),
                liftId: Value(m['liftId'] as int),
                value: Value((m['value'] as num).toDouble()),
                singleEightPercentage: Value(
                    (m['singleEightPercentage'] as num?)?.toDouble() ?? 0.9),
                sourceType: Value(m['sourceType'] as String? ?? 'import'),
                effectiveDate:
                    Value(DateTime.parse(m['effectiveDate'] as String)),
                notes: Value(m['notes'] as String?),
              ),
            );
        maxesRestored++;
      }

      // Restore ExerciseLogs
      final rawLogs = json[_kExerciseLogs] as List<dynamic>? ?? [];
      for (final raw in rawLogs) {
        final l = raw as Map<String, dynamic>;
        await _db.into(_db.exerciseLogs).insertOnConflictUpdate(
              ExerciseLogsCompanion(
                id: Value(l['id'] as int),
                prescriptionId: Value(l['prescriptionId'] as int),
                completedSets: Value(l['completedSets'] as int? ?? 0),
                repsOnLastSet: Value(l['repsOnLastSet'] as int?),
                notes: Value(l['notes'] as String?),
                videoUrl: Value(l['videoUrl'] as String?),
                completedAt:
                    Value(DateTime.parse(l['completedAt'] as String)),
              ),
            );
        logsRestored++;
      }
    });

    return programsRestored > 0
        ? 'Restored $programsRestored program(s), $maxesRestored maxes, and $logsRestored logs.'
        : 'Restored $maxesRestored training max(es) and $logsRestored log(s).';
  }

  // ── Helpers ───────────────────────────────────────────────────────

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
    if (v as int > 2) {
      throw FormatException(
          'Backup version $v is newer than this app supports.');
    }
  }
}

// ── Provider ────────────────────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
