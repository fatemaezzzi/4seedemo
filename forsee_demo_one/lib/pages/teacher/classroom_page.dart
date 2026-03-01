// lib/pages/teacher/classroom_page.dart
// =======================================
// BACKEND WIRED:
//  • Student list → live Firestore stream via FirestoreRepository
//  • Manual attendance Submit → PredictionService.saveAttendance() per student
//  • Camera / CSV attendance  → Camera marks all present; CSV picks file, previews, saves to Firebase
//  • Upload Marks             → passes students list + firestoreIds to CreateMarksEntryPage
//  • Search                   → live filter by name or studentId
//  • Attendance badge         → shows present count after submit

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/pages/teacher/create_marks_entry_page.dart';
import 'package:forsee_demo_one/pages/student/student_profile.dart';
import 'package:forsee_demo_one/services/prediction_service.dart';
import 'package:forsee_demo_one/services/firestore_repository.dart';
import 'dart:io';
import 'package:forsee_demo_one/services/csv_attendance_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ClassroomPage extends StatefulWidget {
  final String classTitle;
  final String classroomId; // ← ADDED: raw Firestore doc ID e.g. '001'
  final String subject;
  final String semester;
  final String std;
  final int participants;

  const ClassroomPage({
    super.key,
    this.classTitle   = 'Class 12-B',
    this.classroomId  = '',           // ← ADDED
    this.subject      = 'Science',
    this.semester     = 'Semester II',
    this.std          = 'STD 12th',
    this.participants = 24,
  });

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  final _searchCtrl        = TextEditingController();
  final _predictionService = PredictionService();
  final _repo              = Get.find<FirestoreRepository>();
  final _csvService        = CsvAttendanceService();

  String _searchQuery       = '';
  bool   _attendanceSaved   = false;
  bool   _isSaving          = false;
  int    _savedPresentCount = 0;

  final Map<String, bool?> _attendanceMap = {};

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:   return Colors.red;
      case RiskLevel.medium: return Colors.orange;
      case RiskLevel.low:    return Colors.yellow;
      case RiskLevel.none:   return Colors.green;
    }
  }

  List<StudentModel> _filtered(List<StudentModel> students) {
    if (_searchQuery.isEmpty) return students;
    final q = _searchQuery.toLowerCase();
    return students.where((s) =>
    s.name.toLowerCase().contains(q) ||
        s.studentId.toLowerCase().contains(q)).toList();
  }

  int _presentCount() =>
      _attendanceMap.values.where((v) => v == true).length;

  // ── ATTENDANCE OPTIONS SHEET ─────────────────────────────────────────────

  void _showAttendanceOptions(List<StudentModel> students) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF3B2028),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Attendance',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            const SizedBox(height: 6),
            Text('${widget.classTitle}  •  ${widget.subject}',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            _attendanceOption(
              icon: Icons.camera_alt,
              label: 'Scan via Camera',
              subtitle: 'Auto-detect attendance via camera',
              onTap: () { Navigator.pop(context); _autoAttendance('Camera', students); },
            ),
            const SizedBox(height: 12),
            _attendanceOption(
              icon: Icons.download,
              label: 'Download Roster',
              subtitle: 'Get pre-filled CSV with student IDs',
              onTap: () { Navigator.pop(context); _downloadRoster(students); },
            ),
            const SizedBox(height: 12),
            _attendanceOption(
              icon: Icons.upload_file,
              label: 'Upload CSV File',
              subtitle: 'Import attendance from a .csv file',
              onTap: () { Navigator.pop(context); _pickCsvAttendance(students); },
            ),
            const SizedBox(height: 12),
            _attendanceOption(
              icon: Icons.edit_note,
              label: 'Mark Manually',
              subtitle: 'Tap each student to mark P / A',
              onTap: () { Navigator.pop(context); _showManualSheet(students); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _attendanceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFF4A3439),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: const Color(0xFFE9C2D7),
              radius: 20,
              child: Icon(icon, color: const Color(0xFF512D38), size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Colors.white30),
        ]),
      ),
    );
  }

  Future<void> _autoAttendance(String method, List<StudentModel> students) async {
    for (final s in students) {
      _attendanceMap[s.firestoreId] = true;
    }
    await _saveAttendance(students);
    if (!mounted) return;
    _showSnack('$method attendance uploaded for ${widget.classTitle}!');
  }

  // ── CSV ATTENDANCE ────────────────────────────────────────────────────────

  // ── DOWNLOAD ROSTER ──────────────────────────────────────────────────────

  Future<void> _downloadRoster(List<StudentModel> students) async {
    if (students.isEmpty) {
      _showSnack('No students in this classroom yet.', isError: true);
      return;
    }

    // Check if any students are missing IDs (signed up before the fix)
    final missingId = students.where((s) => s.studentId.isEmpty || s.studentId == s.firestoreId).toList();
    if (missingId.isNotEmpty) {
      _showSnack(
        '${missingId.length} student(s) have no ID yet — ask them to re-verify their profile.',
        isError: true,
      );
    }

    // Build CSV — student_id, name, status (blank for teacher to fill)
    final buffer = StringBuffer();
    buffer.writeln('student_id,name,status');
    for (final s in students) {
      final id = s.studentId.isNotEmpty ? s.studentId : s.firestoreId;
      // Escape commas in names
      final safeName = s.name.contains(',') ? '"${s.name}"' : s.name;
      buffer.writeln('$id,$safeName,');
    }

    try {
      final dir      = await getTemporaryDirectory();
      final fileName = 'roster_${widget.classroomId.isNotEmpty ? widget.classroomId : widget.classTitle}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file     = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Attendance Roster — ${widget.classTitle}',
        text: 'Fill in the status column with P (Present) or A (Absent), then upload via "Upload CSV File".',
      );
    } catch (e) {
      if (mounted) _showSnack('Could not export roster: \$e', isError: true);
    }
  }

  Future<void> _pickCsvAttendance(List<StudentModel> students) async {
    // Guard: students with no IDs can't be matched from CSV
    final validStudents = students.where((s) => s.studentId.isNotEmpty).toList();
    if (validStudents.isEmpty) {
      _showSnack(
        'No student IDs found. Download the roster first — students may need to update their profiles.',
        isError: true,
      );
      return;
    }

    _showSnack('Opening file picker…');
    final result = await _csvService.pickAndParse(validStudents);
    if (result == null) return; // user cancelled
    if (!mounted) return;
    if (result.hasError) {
      _showSnack(result.error!, isError: true);
      return;
    }
    _showCsvPreviewSheet(students, result);
  }

  void _showCsvPreviewSheet(List<StudentModel> students, CsvParseResult result) {
    final idToStudent = {for (final s in students) s.firestoreId: s};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF3B2028),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // ── Handle ───────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CSV Preview',
                      style: TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Row(children: [
                    _countBadge('P ${result.presentCount}', Colors.green),
                    const SizedBox(width: 6),
                    _countBadge('A ${result.absentCount}', Colors.redAccent),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${result.attendanceMap.length} students matched from CSV',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),

            // ── Unmatched warning ─────────────────────────────────────────
            if (result.hasWarning) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${result.unmatchedIds.length} ID(s) not found in this class: '
                              '${result.unmatchedIds.take(5).join(', ')}'
                              '${result.unmatchedIds.length > 5 ? '…' : ''}',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),

            // ── Student rows ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: result.attendanceMap.entries.map((entry) {
                  final student   = idToStudent[entry.key];
                  final isPresent = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF4A3439),
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE9C2D7),
                        child: Text(student?.initial ?? '?',
                            style: const TextStyle(
                                color: Color(0xFF512D38),
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(student?.name ?? entry.key,
                          style: const TextStyle(color: Colors.white,
                              fontFamily: 'Pridi', fontSize: 14)),
                      subtitle: Text(student?.studentId ?? '',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? Colors.green.withOpacity(0.2)
                              : Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPresent
                                ? Colors.green.withOpacity(0.5)
                                : Colors.redAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Confirm button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  result.attendanceMap.forEach((firestoreId, present) {
                    _attendanceMap[firestoreId] = present;
                  });
                  await _saveAttendance(students);
                  if (mounted) {
                    _showSnack(
                        'CSV attendance saved!  '
                            'Present: ${result.presentCount} / ${result.attendanceMap.length}');
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE9C2D7),
                      borderRadius: BorderRadius.circular(28)),
                  child: const Center(
                    child: Text('Confirm & Save',
                        style: TextStyle(fontFamily: 'Pridi',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF512D38))),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── MANUAL ATTENDANCE SHEET ───────────────────────────────────────────────

  void _showManualSheet(List<StudentModel> students) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize:     0.95,
          minChildSize:     0.5,
          builder: (_, scroll) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3B2028),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mark Attendance',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    Row(children: [
                      _countBadge(
                          'P ${_attendanceMap.values.where((v) => v == true).length}',
                          Colors.green),
                      const SizedBox(width: 6),
                      _countBadge(
                          'A ${_attendanceMap.values.where((v) => v == false).length}',
                          Colors.redAccent),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final st = students[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF4A3439),
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE9C2D7),
                          child: Text(st.initial,
                              style: const TextStyle(
                                  color: Color(0xFF512D38),
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(st.name,
                            style: const TextStyle(color: Colors.white,
                                fontFamily: 'Pridi', fontSize: 14)),
                        subtitle: Text(st.studentId,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _pill('P', Colors.green,
                                _attendanceMap[st.firestoreId] == true, () {
                                  setState(() => _attendanceMap[st.firestoreId] = true);
                                  setSheet(() {});
                                }),
                            const SizedBox(width: 6),
                            _pill('A', Colors.redAccent,
                                _attendanceMap[st.firestoreId] == false, () {
                                  setState(() => _attendanceMap[st.firestoreId] = false);
                                  setSheet(() {});
                                }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _saveAttendance(students);
                    if (mounted) {
                      _showSnack(
                          'Attendance saved!  Present: $_savedPresentCount / ${students.length}');
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE9C2D7),
                        borderRadius: BorderRadius.circular(28)),
                    child: const Center(
                      child: Text('Submit Attendance',
                          style: TextStyle(fontFamily: 'Pridi',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF512D38))),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── SAVE ATTENDANCE ───────────────────────────────────────────────────────

  Future<void> _saveAttendance(List<StudentModel> students) async {
    setState(() => _isSaving = true);
    try {
      for (final st in students) {
        final present = _attendanceMap[st.firestoreId];
        if (present == null) continue;

        await _predictionService.saveAttendance(AttendanceData(
          studentId:   st.firestoreId,
          totalDays:   1,
          presentDays: present ? 1 : 0,
        ));
      }
      setState(() {
        _attendanceSaved   = true;
        _isSaving          = false;
        _savedPresentCount = _presentCount();
      });
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Error saving attendance: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Pridi')),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF512D38),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // Always use classroomId (the classCode e.g. "AB12CD") to query students.
    // classTitle is display-only and must NEVER be used as a Firestore query key —
    // students store classroomId = classCode, not the human-readable title.
    final streamId = widget.classroomId;

    return Scaffold(
      backgroundColor: const Color(0xFF3B2F2F),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<StudentModel>>(
          stream: _repo.streamStudentsByClass(streamId), // ← CHANGED
          builder: (context, snapshot) {
            final students = snapshot.data ?? [];
            final filtered = _filtered(students);

            return Column(children: [

              // ── HEADER ────────────────────────────────────────────────
              Stack(children: [
                Image.asset('assets/imagesfor4see/Ellipse 17.png',
                    width: w, fit: BoxFit.fill),
                Positioned(
                  top: 40, left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 48, left: 50, right: 20,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(widget.subject,
                            style: const TextStyle(fontSize: 48,
                                color: Colors.white, fontFamily: 'Pridi')),
                        const Spacer(),
                        Text(widget.std,
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.semester,
                        style: const TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 10),
                    RichText(text: TextSpan(
                      style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 17),
                      children: [
                        const TextSpan(text: 'No. of Participants '),
                        TextSpan(
                            text: students.isNotEmpty
                                ? '${students.length}'
                                : '${widget.participants}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 21)),
                      ],
                    )),
                  ]),
                ),

                if (_attendanceSaved)
                  Positioned(
                    top: 44, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (_isSaving)
                          const SizedBox(width: 12, height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF1B5E20)))
                        else
                          const Icon(Icons.check_circle,
                              size: 14, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 4),
                        Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Done  $_savedPresentCount/${students.length}',
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ),
              ]),

              // ── ATTENDANCE + SEARCH ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 12),
                  _actionButton('Upload Attendance', students),
                  const SizedBox(height: 10),
                  _searchBar(),
                  const SizedBox(height: 12),
                ]),
              ),

              // ── STUDENT LIST ──────────────────────────────────────────
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE9C2D7)))
                    : filtered.isEmpty
                    ? const Center(
                    child: Text('No students found',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 15)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final st = filtered[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  StudentProfilePage(student: st))),
                      child: StudentListItem(
                        name:        st.name,
                        statusColor: _riskColor(st.riskLevel),
                      ),
                    );
                  },
                ),
              ),

              // ── UPLOAD MARKS ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                child: _actionButton('Upload Marks', students),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _searchBar() => Container(
    height: 46,
    decoration: BoxDecoration(
        color: const Color(0xFFF4D2DE),
        borderRadius: BorderRadius.circular(28)),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search Student',
        hintStyle: const TextStyle(color: Colors.black45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        border: InputBorder.none,
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
            child: const Icon(Icons.close, color: Colors.black45, size: 18))
            : Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/imagesfor4see/Trailing-Elements.png')),
      ),
    ),
  );

  Widget _actionButton(String title, List<StudentModel> students) {
    return GestureDetector(
      onTap: () {
        if (title == 'Upload Marks') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateMarksEntryPage(
                classTitle: widget.classTitle,
                subject:    widget.subject,
                semester:   widget.semester,
                students: students.map((st) => {
                  'roll':        st.studentId,
                  'name':        st.name,
                  'firestoreId': st.firestoreId,
                }).toList(),
              ),
            ),
          );
        } else {
          _showAttendanceOptions(students);
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
            color: const Color(0xFFF4BFDB),
            borderRadius: BorderRadius.circular(30)),
        child: Row(children: [
          if (title == 'Upload Marks') ...[
            const Icon(Icons.add, color: Color(0xFF3B2F2F), size: 22),
            const SizedBox(width: 8),
          ],
          Text(title, style: const TextStyle(fontSize: 18, fontFamily: 'Pridi')),
          const Spacer(),
          _iconBtn('assets/imagesfor4see/mingcute_camera-fill.png', true),
          const SizedBox(width: 10),
          _iconBtn('assets/imagesfor4see/bi_filetype-csv.png', false),
        ]),
      ),
    );
  }

  Widget _iconBtn(String asset, bool white) => Container(
    padding: const EdgeInsets.all(7),
    decoration: const BoxDecoration(
        color: Color(0xFF512D38), shape: BoxShape.circle),
    child: Image.asset(asset, height: 20, color: white ? Colors.white : null),
  );

  Widget _countBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4))),
    child: Text(label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _pill(String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34, height: 30,
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT LIST ITEM
// ─────────────────────────────────────────────────────────────────────────────

class StudentListItem extends StatelessWidget {
  final String name;
  final Color  statusColor;

  const StudentListItem({
    super.key,
    required this.name,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4BFDB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
      ),
      child: Column(children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Image.asset('assets/imagesfor4see/account_circle.png', height: 22),
          title: Text(name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          trailing: Image.asset('assets/imagesfor4see/Arrow right.png', height: 16),
        ),
        Container(
          height: 6,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8)),
        ),
      ]),
    );
  }
}