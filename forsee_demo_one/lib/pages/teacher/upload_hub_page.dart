// lib/pages/teacher/upload_hub_page.dart
// ========================================
// BACKEND WIRED:
//  • Receives students list with firestoreIds from CreateMarksEntryPage
//  • Live grade calculation and stats bar as teacher types marks
//  • Passes complete marksData (including firestoreId per student) to ReviewSubmitPage
//  • Validation: marks must be between 0 and maxMarks

import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/teacher/review_submit_page.dart';

class UploadHubPage extends StatefulWidget {
  final String examTitle;
  final String date;
  final int    maxMarks;
  final int    passMarks;
  final String subject;
  final String className;
  final String semester;
  // Each: { 'roll': String, 'name': String, 'firestoreId': String }
  final List<Map<String, dynamic>> students;

  const UploadHubPage({
    super.key,
    required this.examTitle,
    required this.date,
    required this.maxMarks,
    required this.passMarks,
    required this.subject,
    required this.className,
    required this.semester,
    required this.students,
  });

  @override
  State<UploadHubPage> createState() => _UploadHubPageState();
}

class _UploadHubPageState extends State<UploadHubPage> {
  // One controller and marks value per student
  late final List<TextEditingController> _controllers;
  late final List<int?> _marks;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
        widget.students.length, (_) => TextEditingController());
    _marks = List.filled(widget.students.length, null);
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  // ── GRADE CALCULATION ─────────────────────────────────────────────────────

  String _grade(int marks) {
    final pct = marks / widget.maxMarks * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 45) return 'C';
    if (marks >= widget.passMarks) return 'D';
    return 'F';
  }

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

  // ── STATS ─────────────────────────────────────────────────────────────────

  List<int?> get _filledMarks => _marks.where((m) => m != null).toList();

  double get _average => _filledMarks.isEmpty
      ? 0
      : _filledMarks.fold<int>(0, (s, m) => s + m!) / _filledMarks.length;

  int get _passCount =>
      _filledMarks.where((m) => m! >= widget.passMarks).length;

  int get _failCount => _filledMarks.length - _passCount;

  // ── NAVIGATE TO REVIEW ────────────────────────────────────────────────────

  void _next() {
    // Check if any marks are entered
    if (_filledMarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter marks for at least one student.',
            style: TextStyle(fontFamily: 'Pridi')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Build marksData list — includes firestoreId for each student
    final marksData = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.students.length; i++) {
      final st = widget.students[i];
      final m  = _marks[i];
      marksData.add({
        'name':        st['name'],
        'roll':        st['roll'],
        'firestoreId': st['firestoreId'], // ← propagated for Firebase save
        'marks':       m,
        'grade':       m != null ? _grade(m) : '—',
        'passed':      m != null && m >= widget.passMarks,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewSubmitPage(
          examTitle: widget.examTitle,
          date:      widget.date,
          maxMarks:  widget.maxMarks,
          passMarks: widget.passMarks,
          subject:   widget.subject,
          className: widget.className,
          marksData: marksData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filled = _filledMarks.length;

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
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Enter Marks',
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Text('${widget.examTitle}  •  ${widget.className}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF6B3248),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$filled / ${widget.students.length}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ]),
          ),

          // ── EXAM INFO ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF6B3248),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoChip('Max', '${widget.maxMarks}', Colors.white),
                  _infoChip('Pass', '${widget.passMarks}', Colors.lightGreenAccent),
                  _infoChip('Date', widget.date, Colors.white70),
                  _infoChip('Subject', widget.subject, const Color(0xFFE9C2D7)),
                ],
              ),
            ),
          ),

          // ── LIVE STATS (visible once marks are entered) ───────────────────
          if (filled > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF3B2028),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill('Avg', _average.toStringAsFixed(1), Colors.white),
                    _statPill('Pass', '$_passCount', Colors.greenAccent),
                    _statPill('Fail', '$_failCount', Colors.redAccent),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          // ── TABLE HEADER ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: const [
              SizedBox(width: 40, child: Text('Roll', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 12),
              Expanded(child: Text('Student', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 80, child: Text('Marks', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600))),
              SizedBox(width: 44, child: Text('Grade', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
          ),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),

          // ── STUDENT ROWS ──────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.students.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
              itemBuilder: (_, i) {
                final st    = widget.students[i];
                final m     = _marks[i];
                final grade = m != null ? _grade(m) : '—';
                final gc    = _gradeColor(grade);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    // Roll
                    SizedBox(
                      width: 40,
                      child: Text(st['roll'] as String,
                          style: const TextStyle(color: Colors.white38,
                              fontSize: 11, fontFamily: 'Pridi'),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    // Name + avatar
                    Expanded(
                      child: Row(children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: m == null
                              ? Colors.white12
                              : (m >= widget.passMarks
                              ? Colors.greenAccent
                              : Colors.redAccent)
                              .withOpacity(0.15),
                          child: Text(
                            (st['name'] as String)[0],
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold,
                              color: m == null
                                  ? Colors.white38
                                  : m >= widget.passMarks
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(st['name'] as String,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 13, fontFamily: 'Pridi'),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                    // Marks input
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _controllers[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '—',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF6B3248),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val.trim());
                          setState(() {
                            if (parsed == null) {
                              _marks[i] = null;
                            } else {
                              _marks[i] = parsed.clamp(0, widget.maxMarks);
                              // Clamp input visually
                              if (parsed > widget.maxMarks) {
                                _controllers[i].text =
                                '${widget.maxMarks}';
                                _controllers[i].selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: _controllers[i].text.length));
                              }
                            }
                          });
                        },
                      ),
                    ),
                    // Grade badge
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: m == null
                              ? const Text('—',
                              style: TextStyle(color: Colors.white24))
                              : Container(
                            key: ValueKey(grade),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                                color: gc.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(grade,
                                style: TextStyle(
                                    color: gc,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),

          // ── NEXT BUTTON ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9C2D7),
                  foregroundColor: const Color(0xFF512D38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    'Next: Review & Submit  ($filled/${widget.students.length})',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
  ]);

  Widget _statPill(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pridi')),
    Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
  ]);
}