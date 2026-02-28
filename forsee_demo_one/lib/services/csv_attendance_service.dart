// lib/services/csv_attendance_service.dart
// ==========================================
// Picks a .csv file, parses it, and matches rows to the loaded student list.
// No new dependencies beyond file_picker and csv (already common in Flutter).
//
// Add to pubspec.yaml if not already present:
//   file_picker: ^6.1.1
//   csv: ^6.0.0

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:forsee_demo_one/model/student_model.dart';

// ── Result returned to the UI ────────────────────────────────────────────────

class CsvParseResult {
  /// firestoreId → true (present) / false (absent)
  final Map<String, bool> attendanceMap;

  /// studentId strings from the CSV that had no match in the classroom list
  final List<String> unmatchedIds;

  /// Human-readable error (null = success)
  final String? error;

  const CsvParseResult({
    required this.attendanceMap,
    required this.unmatchedIds,
    this.error,
  });

  bool get hasError   => error != null;
  bool get hasWarning => unmatchedIds.isNotEmpty;
  int  get presentCount => attendanceMap.values.where((v) => v).length;
  int  get absentCount  => attendanceMap.values.where((v) => !v).length;
}

// ── Service ──────────────────────────────────────────────────────────────────

class CsvAttendanceService {
  /// Acceptable column header names (case-insensitive)
  static const _idHeaders     = ['student_id', 'studentid', 'id', 'roll', 'roll_no'];
  static const _statusHeaders = ['status', 'attendance', 'present'];

  /// Values treated as PRESENT
  static const _presentValues = {'p', 'present', '1', 'yes', 'true'};

  /// Values treated as ABSENT
  static const _absentValues  = {'a', 'absent', '0', 'no', 'false'};

  // ── Public entry point ────────────────────────────────────────────────────

  /// Opens the file picker, parses the CSV, and matches against [students].
  /// Returns a [CsvParseResult] — caller decides what to do with warnings.
  Future<CsvParseResult?> pickAndParse(List<StudentModel> students) async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null; // user cancelled

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'Could not read file. Please try again.',
      );
    }

    // 2. Decode & parse CSV
    final raw = utf8.decode(bytes, allowMalformed: true);
    List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(eol: '\n').convert(raw);
    } catch (_) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'Invalid CSV format. Please check the file.',
      );
    }

    if (rows.isEmpty) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'The CSV file is empty.',
      );
    }

    // 3. Detect header row
    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final idCol     = _findColumn(header, _idHeaders);
    final statusCol = _findColumn(header, _statusHeaders);

    if (idCol == -1) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'Missing "student_id" column.\n'
            'Expected header: student_id, status',
      );
    }
    if (statusCol == -1) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'Missing "status" column.\n'
            'Expected header: student_id, status',
      );
    }

    // 4. Build lookup: studentId (display) → firestoreId
    final lookup = <String, String>{};
    for (final s in students) {
      // normalize: strip leading '#', lowercase, trim
      final key = s.studentId.replaceAll('#', '').trim().toLowerCase();
      lookup[key] = s.firestoreId;
    }

    // 5. Parse data rows
    final attendanceMap = <String, bool>{};
    final unmatchedIds  = <String>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= idCol || row.length <= statusCol) continue;

      final rawId     = row[idCol].toString().trim();
      final rawStatus = row[statusCol].toString().trim().toLowerCase();

      if (rawId.isEmpty) continue; // skip blank rows

      // Parse status
      bool? present;
      if (_presentValues.contains(rawStatus)) {
        present = true;
      } else if (_absentValues.contains(rawStatus)) {
        present = false;
      } else {
        continue; // unrecognized status — skip silently
      }

      // Match to student
      final normalizedId = rawId.replaceAll('#', '').trim().toLowerCase();
      final firestoreId  = lookup[normalizedId];

      if (firestoreId != null) {
        attendanceMap[firestoreId] = present;
      } else {
        unmatchedIds.add(rawId);
      }
    }

    if (attendanceMap.isEmpty && unmatchedIds.isEmpty) {
      return CsvParseResult(
        attendanceMap: {},
        unmatchedIds: [],
        error: 'No valid attendance rows found in the file.',
      );
    }

    return CsvParseResult(
      attendanceMap: attendanceMap,
      unmatchedIds: unmatchedIds,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _findColumn(List<String> header, List<String> candidates) {
    for (int i = 0; i < header.length; i++) {
      if (candidates.contains(header[i])) return i;
    }
    return -1;
  }
}