import 'package:flutter/material.dart';

class ReviewSubmitPage extends StatefulWidget {
  final String examTitle;
  final String date;
  final int maxMarks;
  final int passMarks;
  final String subject;
  final String className;
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

  // ── COMPUTED STATS ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filled =>
      widget.marksData.where((s) => s['marks'] != null).toList();

  double get _average {
    if (_filled.isEmpty) return 0;
    final total =
    _filled.fold<int>(0, (sum, s) => sum + (s['marks'] as int));
    return total / _filled.length;
  }

  int get _highest =>
      _filled.isEmpty ? 0 : _filled.map((s) => s['marks'] as int).reduce((a, b) => a > b ? a : b);

  int get _lowest =>
      _filled.isEmpty ? 0 : _filled.map((s) => s['marks'] as int).reduce((a, b) => a < b ? a : b);

  int get _passCount =>
      _filled.where((s) => s['passed'] == true).length;

  int get _failCount => _filled.length - _passCount;

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.greenAccent;
      case 'B':
        return Colors.lightGreenAccent;
      case 'C':
        return Colors.yellowAccent;
      case 'D':
        return Colors.orangeAccent;
      case 'F':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────────

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
            Text(
              'Submitted!',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pridi',
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Marks for "${widget.examTitle}" have been successfully submitted for ${widget.className}.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Pop dialog + all marks pages back to ClassroomPage
              Navigator.of(context).popUntil(
                    (route) =>
                route.settings.name == '/' ||
                    route.isFirst ||
                    route.settings.name == 'classroom',
              );
              Navigator.of(context)
                  .popUntil((route) => route.isFirst || route.settings.name == 'classroom');
              // Simple: pop 4 times to get back to classroom
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Classroom',
                style: TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
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
                  // Step indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9C2D7).withOpacity(0.2),
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
                    // ── EXAM SUMMARY CARD ────────────────────────────────────
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
                            widget.examTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pridi',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.subject}  •  ${widget.className}  •  ${widget.date}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          // Stats row
                          Row(
                            children: [
                              _summaryChip('Average',
                                  _average.toStringAsFixed(1), Colors.white),
                              const SizedBox(width: 10),
                              _summaryChip(
                                  'Highest', '$_highest', Colors.greenAccent),
                              const SizedBox(width: 10),
                              _summaryChip(
                                  'Lowest', '$_lowest', Colors.redAccent),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Pass/fail bar
                          Row(
                            children: [
                              Expanded(
                                flex: _passCount == 0 ? 1 : _passCount,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: _failCount == 0 ? 1 : _failCount,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Colors.greenAccent),
                              const SizedBox(width: 5),
                              Text(
                                '$_passCount Passed',
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 14),
                              const CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Colors.redAccent),
                              const SizedBox(width: 5),
                              Text(
                                '$_failCount Failed',
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── STUDENT RESULTS TABLE ────────────────────────────────
                    const Text(
                      'Student Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFA6768B),
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('Student',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 13)),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text('Marks',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 13)),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('Grade',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 13)),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('Result',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    // Student rows
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B2028),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.marksData.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (_, i) {
                          final s = widget.marksData[i];
                          final int? marks = s['marks'];
                          final String grade = s['grade'] ?? '—';
                          final bool passed = s['passed'] ?? false;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                // Name
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

                                // Marks
                                SizedBox(
                                  width: 60,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Grade
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

                                // Pass/Fail
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
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── SUBMIT BUTTON ─────────────────────────────────────────────────
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
                        size: 20,
                      ),
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

  // ── SUMMARY CHIP ─────────────────────────────────────────────────────────────

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
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}