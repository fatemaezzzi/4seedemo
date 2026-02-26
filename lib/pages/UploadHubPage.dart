import 'package:flutter/material.dart';
import 'package:forc/pages/ReviewSubmitPage.dart';

class UploadHubPage extends StatefulWidget {
  // Accepts data from CreateMarksEntryPage
  final String examTitle;
  final String date;
  final int maxMarks;
  final int passMarks;
  final String subject;
  final String className;

  const UploadHubPage({
    super.key,
    this.examTitle = 'Mid-Term I',
    this.date = '01/01/2025',
    this.maxMarks = 100,
    this.passMarks = 35,
    this.subject = 'Science',
    this.className = 'Class 12-B',
  });

  @override
  State<UploadHubPage> createState() => _UploadHubPageState();
}

class _UploadHubPageState extends State<UploadHubPage> {
  final List<Map<String, dynamic>> _students = [
    {'roll': '2090013', 'name': 'Dhruv Rathee'},
    {'roll': '2090014', 'name': 'Sourav Joshi'},
    {'roll': '2090015', 'name': 'Dhinchak Pooja'},
    {'roll': '2090016', 'name': 'Nishchay Malhan'},
    {'roll': '2090017', 'name': 'Ashish Chanchlani'},
    {'roll': '2090018', 'name': 'CarryMinati'},
    {'roll': '2090019', 'name': 'Triggered Insaan'},
    {'roll': '2090020', 'name': 'Tanmay Bhat'},
  ];

  final Map<int, int?> _enteredMarks = {};
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _students.length; i++) {
      _controllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────

  int get _filledCount =>
      _enteredMarks.values.where((v) => v != null).length;

  double get _classAverage {
    final filled = _enteredMarks.values.whereType<int>().toList();
    if (filled.isEmpty) return 0;
    return filled.reduce((a, b) => a + b) / filled.length;
  }

  Color _statusColor(int? marks) {
    if (marks == null) return Colors.white24;
    return marks >= widget.passMarks ? Colors.greenAccent : Colors.redAccent;
  }

  String _grade(int? marks) {
    if (marks == null) return '—';
    final pct = marks / widget.maxMarks * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 45) return 'C';
    if (pct >= (widget.passMarks / widget.maxMarks * 100)) return 'D';
    return 'F';
  }

  bool _isValidMark(String val) {
    final parsed = int.tryParse(val);
    return parsed != null && parsed >= 0 && parsed <= widget.maxMarks;
  }

  // ── NAVIGATE TO REVIEW ────────────────────────────────────────────────────────

  void _onNext() {
    if (_filledCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter marks for at least one student.',
            style: TextStyle(fontFamily: 'Pridi'),
          ),
          backgroundColor: const Color(0xFF3B2028),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> marksData = [];
    for (int i = 0; i < _students.length; i++) {
      marksData.add({
        'roll': _students[i]['roll'],
        'name': _students[i]['name'],
        'marks': _enteredMarks[i],
        'grade': _grade(_enteredMarks[i]),
        'passed': _enteredMarks[i] != null &&
            _enteredMarks[i]! >= widget.passMarks,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSubmitPage(
          examTitle: widget.examTitle,
          date: widget.date,
          maxMarks: widget.maxMarks,
          passMarks: widget.passMarks,
          subject: widget.subject,
          className: widget.className,
          marksData: marksData,
        ),
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
                      'Enter Scores',
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
                      color: const Color(0xFFE9C2D7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_filledCount / ${_students.length}',
                      style: const TextStyle(
                        color: Color(0xFFE9C2D7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── EXAM INFO BANNER ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2028),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.examTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pridi',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.subject}  •  ${widget.className}  •  ${widget.date}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Max: ${widget.maxMarks}',
                        style: const TextStyle(
                          color: Color(0xFFE9C2D7),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pass: ${widget.passMarks}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── LIVE STATS BAR (only shows once marks are entered) ───────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _filledCount > 0
                  ? Container(
                key: const ValueKey('stats'),
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3439),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(
                      'Average',
                      _classAverage.toStringAsFixed(1),
                      Icons.bar_chart,
                    ),
                    _statChip(
                      'Passed',
                      '${_enteredMarks.values.whereType<int>().where((m) => m >= widget.passMarks).length}',
                      Icons.check_circle_outline,
                      color: Colors.greenAccent,
                    ),
                    _statChip(
                      'Failed',
                      '${_enteredMarks.values.whereType<int>().where((m) => m < widget.passMarks).length}',
                      Icons.cancel_outlined,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              )
                  : const SizedBox(key: ValueKey('empty'), height: 0),
            ),

            const SizedBox(height: 10),

            // ── TABLE HEADER ─────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFA6768B),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 36),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Student',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Marks',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      'Grade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── STUDENT ROWS ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B2028),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.06),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (_, i) {
                    final marks = _enteredMarks[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                            _statusColor(marks).withOpacity(0.15),
                            child: Text(
                              _students[i]['name'].toString()[0],
                              style: TextStyle(
                                color: marks == null
                                    ? Colors.white38
                                    : _statusColor(marks),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pridi',
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name + roll number
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _students[i]['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Pridi',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _students[i]['roll'],
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Marks input field
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _controllers[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _statusColor(marks),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Pridi',
                              ),
                              decoration: InputDecoration(
                                hintText: '—',
                                hintStyle: const TextStyle(
                                    color: Colors.white24, fontSize: 16),
                                filled: true,
                                fillColor: const Color(0xFF4A3439),
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE9C2D7),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val.isEmpty) {
                                    _enteredMarks[i] = null;
                                  } else if (_isValidMark(val)) {
                                    _enteredMarks[i] = int.parse(val);
                                  }
                                });
                              },
                            ),
                          ),

                          // Grade badge
                          SizedBox(
                            width: 40,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: marks == null
                                      ? Colors.transparent
                                      : _statusColor(marks).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _grade(marks),
                                  style: TextStyle(
                                    color: marks == null
                                        ? Colors.white24
                                        : _statusColor(marks),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── NEXT BUTTON ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9C2D7),
                    foregroundColor: const Color(0xFF3B2028),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next: Review & Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pridi',
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16),
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

  // ── STAT CHIP ────────────────────────────────────────────────────────────────

  Widget _statChip(String label, String value, IconData icon,
      {Color color = const Color(0xFFE9C2D7)}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Pridi',
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}