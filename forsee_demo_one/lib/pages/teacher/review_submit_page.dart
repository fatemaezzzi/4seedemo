import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO NAVIGATE HERE from create_marks_entry_page.dart:
//
// Get.toNamed(AppRoutes.REVIEW_SUBMIT, arguments: {
//   'examTitle': 'Math Midterm',
//   'date':      '2024-01-15',
//   'maxMarks':  100,
//   'passMarks': 40,
//   'subject':   'Mathematics',
//   'className': 'Class 10A',
//   'marksData': [
//     {'name': 'Alice', 'marks': 85, 'passed': true,  'grade': 'A'},
//     {'name': 'Bob',   'marks': 30, 'passed': false, 'grade': 'F'},
//   ],
// });
// ─────────────────────────────────────────────────────────────────────────────

class ReviewSubmitPage extends StatefulWidget {
  const ReviewSubmitPage({super.key});

  @override
  State<ReviewSubmitPage> createState() => _ReviewSubmitPageState();
}

class _ReviewSubmitPageState extends State<ReviewSubmitPage> {
  bool _submitted = false;

  // ── All data comes from Get.arguments (Map) ───────────────────────────────
  Map<String, dynamic> get _args =>
      (Get.arguments as Map<String, dynamic>?) ?? {};

  String get _examTitle => _args['examTitle'] as String? ?? '';
  String get _date      => _args['date']      as String? ?? '';
  int    get _maxMarks  => _args['maxMarks']  as int?    ?? 0;
  int    get _passMarks => _args['passMarks'] as int?    ?? 0;
  String get _subject   => _args['subject']   as String? ?? '';
  String get _className => _args['className'] as String? ?? '';

  List<Map<String, dynamic>> get _marksData =>
      (_args['marksData'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
          [];

  // ── COMPUTED STATS ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filled =>
      _marksData.where((s) => s['marks'] != null).toList();

  double get _average {
    if (_filled.isEmpty) return 0;
    final total =
    _filled.fold<int>(0, (sum, s) => sum + (s['marks'] as int));
    return total / _filled.length;
  }

  int get _highest => _filled.isEmpty
      ? 0
      : _filled.map((s) => s['marks'] as int).reduce((a, b) => a > b ? a : b);

  int get _lowest => _filled.isEmpty
      ? 0
      : _filled.map((s) => s['marks'] as int).reduce((a, b) => a < b ? a : b);

  int get _passCount => _filled.where((s) => s['passed'] == true).length;
  int get _failCount => _filled.length - _passCount;

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':  return Colors.greenAccent;
      case 'B':  return Colors.lightGreenAccent;
      case 'C':  return Colors.yellowAccent;
      case 'D':  return Colors.orangeAccent;
      case 'F':  return Colors.redAccent;
      default:   return Colors.white38;
    }
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────
  void _onSubmit() {
    setState(() => _submitted = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            SizedBox(width: 10),
            Text('Submitted!',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pridi',
                    fontSize: 20)),
          ],
        ),
        content: Text(
          'Marks for "$_examTitle" have been successfully submitted for $_className.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Pop dialog first, then go back to classroom
              Get.back(); // closes dialog
              Get.until((route) =>
              route.settings.name == AppRoutes.CLASSROOM ||
                  route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Classroom',
                style: TextStyle(
                    fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Review & Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C2D7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Step 3 of 3',
                      style: TextStyle(
                        color: Color(0xFFE9C2D7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── EXAM SUMMARY CARD ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2028),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _examTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pridi',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_subject  •  $_className  •  $_date',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max: $_maxMarks  •  Pass: $_passMarks',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── STATS ROW ──────────────────────────────────────────
                    Row(
                      children: [
                        _summaryChip('Average',
                            _average.toStringAsFixed(1), Colors.lightBlueAccent),
                        const SizedBox(width: 8),
                        _summaryChip('Highest', '$_highest', Colors.greenAccent),
                        const SizedBox(width: 8),
                        _summaryChip('Lowest', '$_lowest', Colors.orangeAccent),
                        const SizedBox(width: 8),
                        _summaryChip(
                            'Pass/Fail', '$_passCount/$_failCount', Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── STUDENT MARKS LIST ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2028),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 3,
                                  child: Text('Student',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text('Marks',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text('Grade',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Text('P/F',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white12),

                          // Student rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _marksData.length,
                            separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.white12),
                            itemBuilder: (context, index) {
                              final s     = _marksData[index];
                              final marks = s['marks'] as int?;
                              final passed = s['passed'] as bool? ?? false;
                              final grade = s['grade'] as String? ?? '—';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 15,
                                            backgroundColor: marks == null
                                                ? Colors.white12
                                                : (passed
                                                ? Colors.greenAccent
                                                : Colors.redAccent)
                                                .withOpacity(0.15),
                                            child: Text(
                                              s['name'].toString()[0],
                                              style: TextStyle(
                                                color: marks == null
                                                    ? Colors.white38
                                                    : (passed
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              s['name'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontFamily: 'Pridi',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        marks != null
                                            ? '$marks/$_maxMarks'
                                            : '—',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: marks == null
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _gradeColor(grade)
                                                .withOpacity(0.15),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            grade,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _gradeColor(grade),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: Center(
                                        child: marks == null
                                            ? const Text('—',
                                            style: TextStyle(
                                                color: Colors.white24))
                                            : Icon(
                                          passed
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: passed
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── SUBMIT BUTTON ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitted ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9C2D7),
                    disabledBackgroundColor: Colors.white12,
                    foregroundColor: const Color(0xFF3B2028),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          _submitted ? Icons.check : Icons.upload_rounded,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _submitted ? 'Submitted ✓' : 'Confirm & Submit Marks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pridi',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY CHIP ──────────────────────────────────────────────────────────
  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pridi')),
            Text(label,
                style:
                TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}