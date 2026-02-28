// lib/pages/teacher/review_submit_page.dart
// ===========================================
// BACKEND WIRED:
//  • Receives all exam data + marksData (with firestoreId per student)
//  • _onSubmit() saves marks to Firebase staging via PredictionService.saveMarks()
//    using student.firestoreId — triggers auto-prediction when all 4 inputs ready
//  • Loading spinner on button during save
//  • Success dialog with prediction info, then navigate back to classroom

import 'package:flutter/material.dart';
import 'package:forsee_demo_one/services/prediction_service.dart';

class ReviewSubmitPage extends StatefulWidget {
  final String examTitle;
  final String date;
  final int    maxMarks;
  final int    passMarks;
  final String subject;
  final String className;
  // Each: { 'name', 'roll', 'firestoreId', 'marks', 'grade', 'passed' }
  final List<Map<String, dynamic>> marksData;

  const ReviewSubmitPage({
    super.key,
    required this.examTitle,
    required this.date,
    required this.maxMarks,
    required this.passMarks,
    required this.subject,
    required this.className,
    required this.marksData,
  });

  @override
  State<ReviewSubmitPage> createState() => _ReviewSubmitPageState();
}

class _ReviewSubmitPageState extends State<ReviewSubmitPage> {
  bool _submitted = false;
  bool _isSaving  = false;

  final _svc = PredictionService();

  // ── STATS ─────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filled =>
      widget.marksData.where((s) => s['marks'] != null).toList();

  double get _average => _filled.isEmpty
      ? 0
      : _filled.fold<int>(0, (sum, s) => sum + (s['marks'] as int)) /
      _filled.length;

  int get _highest => _filled.isEmpty
      ? 0
      : _filled.map((s) => s['marks'] as int).reduce((a, b) => a > b ? a : b);

  int get _lowest => _filled.isEmpty
      ? 0
      : _filled.map((s) => s['marks'] as int).reduce((a, b) => a < b ? a : b);

  int get _passCount =>
      _filled.where((s) => s['passed'] == true).length;

  int get _failCount => _filled.length - _passCount;

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+': return Colors.greenAccent;
      case 'A':  return Colors.lightGreenAccent;
      case 'B':  return Colors.yellowAccent;
      case 'C':  return Colors.orangeAccent;
      case 'D':  return Colors.orange;
      case 'F':  return Colors.redAccent;
      default:   return Colors.white38;
    }
  }

  // ── SUBMIT → Firebase ─────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    setState(() { _submitted = true; _isSaving = true; });

    int saved = 0;
    for (final student in widget.marksData) {
      final firestoreId = student['firestoreId'] as String?;
      final marks       = student['marks']       as int?;
      if (firestoreId == null || marks == null) continue;

      try {
        // Save to Firebase staging — prediction auto-triggers when
        // attendance + behaviour + quiz are also saved for this student
        await _svc.saveMarks(MarksData(
          studentId: firestoreId,          // ← real Firestore doc ID
          g1:        marks,
          g2:        marks,
          maxMarks:  widget.maxMarks,
          passed:    student['passed'] as bool? ?? false,
        ));
        saved++;
      } catch (e) {
        debugPrint('Marks save error for $firestoreId: $e');
      }
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
          SizedBox(width: 10),
          Text('Submitted!',
              style: TextStyle(color: Colors.white,
                  fontFamily: 'Pridi', fontSize: 20)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Marks for "${widget.examTitle}" submitted for ${widget.className}.\n'
                '$saved / ${widget.marksData.length} students saved.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF4A3439),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFFE9C2D7), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Dropout prediction auto-runs once attendance, behaviour & quiz are also complete.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              )),
            ]),
          ),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              // Pop back to classroom (skip create_marks + upload_hub)
              int count = 0;
              Navigator.popUntil(context, (_) => count++ >= 3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Classroom',
                style: TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(children: [

          // ── HEADER ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: _submitted ? null : () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('Review & Submit',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              ),
            ]),
          ),

          // ── SCROLLABLE CONTENT ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // Exam summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF6B3248),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.examTitle,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.bold,
                            fontFamily: 'Pridi')),
                    const SizedBox(height: 6),
                    Text('${widget.subject}  •  ${widget.className}  •  ${widget.date}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _chip('Max', '${widget.maxMarks}', Colors.white70),
                      const SizedBox(width: 10),
                      _chip('Pass', '${widget.passMarks}', Colors.lightGreenAccent),
                    ]),
                  ]),
                ),

                const SizedBox(height: 14),

                // Stats row
                if (_filled.isNotEmpty)
                  Row(children: [
                    _statCard('Average',  _average.toStringAsFixed(1), Colors.white),
                    const SizedBox(width: 8),
                    _statCard('Highest',  '$_highest', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _statCard('Lowest',   '$_lowest',  Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _statCard('Pass/Fail','$_passCount/$_failCount', Colors.lightBlueAccent),
                  ]),

                const SizedBox(height: 14),

                // Marks table
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    // Table header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(children: const [
                        Expanded(flex: 3, child: Text('Student',
                            style: TextStyle(color: Colors.white54,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                        SizedBox(width: 60, child: Text('Marks',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                        SizedBox(width: 44, child: Text('Grade',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                        SizedBox(width: 44, child: Text('P/F',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                    const Divider(height: 1, color: Colors.white12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.marksData.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.white12),
                      itemBuilder: (_, i) {
                        final s      = widget.marksData[i];
                        final marks  = s['marks']  as int?;
                        final passed = s['passed'] as bool? ?? false;
                        final grade  = s['grade']  as String? ?? '—';
                        final gc     = _gradeColor(grade);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Expanded(flex: 3, child: Row(children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: marks == null
                                    ? Colors.white12
                                    : (passed
                                    ? Colors.greenAccent
                                    : Colors.redAccent)
                                    .withOpacity(0.15),
                                child: Text(
                                  (s['name'] as String)[0],
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold,
                                    color: marks == null
                                        ? Colors.white38
                                        : passed
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s['name'] as String,
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 13, fontFamily: 'Pridi'),
                                  overflow: TextOverflow.ellipsis)),
                            ])),
                            SizedBox(width: 60,
                              child: Text(
                                marks != null
                                    ? '$marks/${widget.maxMarks}'
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: marks == null
                                        ? Colors.white38
                                        : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 44,
                              child: Center(child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: gc.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(grade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: gc, fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              )),
                            ),
                            SizedBox(width: 44,
                              child: Center(
                                child: marks == null
                                    ? const Text('—',
                                    style: TextStyle(color: Colors.white24))
                                    : Icon(
                                    passed
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: passed
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 18),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ]),
                ),

                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── SUBMIT BUTTON ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: (_submitted || _isSaving) ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9C2D7),
                  disabledBackgroundColor: Colors.white12,
                  foregroundColor: const Color(0xFF3B2028),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF512D38)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_submitted ? Icons.check : Icons.upload_rounded,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _submitted ? 'Submitted ✓' : 'Confirm & Submit Marks',
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text('$label: $value',
        style: TextStyle(color: color, fontSize: 12, fontFamily: 'Pridi')),
  );

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 15,
                fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
        Text(label,
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
      ]),
    ),
  );
}