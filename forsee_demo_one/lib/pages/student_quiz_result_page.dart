// lib/pages/teacher_only/student_quiz_results_page.dart
//
// Teacher-only page. Shows the full quiz breakdown for a specific student.
// Students never see this page.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../quiz_data.dart';

class StudentQuizResultsPage extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentQuizResultsPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentQuizResultsPage> createState() => _StudentQuizResultsPageState();
}

class _StudentQuizResultsPageState extends State<StudentQuizResultsPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quiz_results')
          .doc(widget.studentId)
          .get();

      if (!doc.exists || doc.data() == null) {
        setState(() { _data = null; _loading = false; });
        return;
      }
      setState(() { _data = doc.data(); _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _loading = false; });
    }
  }

  // ── Severity helpers ──────────────────────────────────────────────────────

  Color _severityColor(double percent) {
    if (percent < 0.20) return const Color(0xFF7DC4B8);
    if (percent < 0.40) return const Color(0xFFE8A84A);
    if (percent < 0.60) return const Color(0xFFF5A87E);
    if (percent < 0.80) return const Color(0xFFFF6B6B);
    return const Color(0xFFFF4444);
  }

  String _severityLabel(double percent) {
    if (percent < 0.20) return 'Minimal';
    if (percent < 0.40) return 'Mild';
    if (percent < 0.60) return 'Moderate';
    if (percent < 0.80) return 'High';
    return 'Severe';
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D1A24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1A24),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studentName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const Text('Quiz Results',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DC4B8)))
          : _error != null
          ? _buildError()
          : _data == null
          ? _buildNotTaken()
          : _buildResults(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DC4B8)),
            child: const Text('Retry'),
          ),
        ]),
      ),
    );
  }

  Widget _buildNotTaken() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.quiz_outlined, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(
            '${widget.studentName} has not completed the quiz yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ]),
      ),
    );
  }

  Widget _buildResults() {
    final data        = _data!;
    final overallScore = (data['overallScore'] as num?)?.toDouble() ?? 0.0;
    final categories  = data['categories']  as Map<String, dynamic>? ?? {};
    final criticals   = List<String>.from(data['criticalTriggers'] as List? ?? []);
    final completedAt = data['completedAt'] as Timestamp?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Completed timestamp ──────────────────────────────────────
        if (completedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Completed: ${_formatDate(completedAt.toDate())}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),

        // ── Critical alert ───────────────────────────────────────────
        if (criticals.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Critical Flag Detected',
                          style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      ...criticals.map((t) => Text(
                        '• $t',
                        style: const TextStyle(
                            color: Color(0xFFE8B0B0), fontSize: 12),
                      )),
                      const SizedBox(height: 8),
                      const Text(
                        'Consider reaching out to this student or referring them to a counsellor.',
                        style: TextStyle(
                            color: Color(0xFFE8B0B0),
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Overall score card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6B3248),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Wellbeing Score',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    overallScore.toStringAsFixed(1),
                    style: TextStyle(
                        color: _severityColor(overallScore / 100),
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '/ 100  ·  ${_severityLabel(overallScore / 100)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            _SeverityRing(percent: overallScore / 100),
          ]),
        ),

        // ── Per-category breakdown ───────────────────────────────────
        const Text('Category Breakdown',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),

        ...quizCategories.map((cat) {
          final catData = categories[cat.key] as Map<String, dynamic>?;
          if (catData == null) return const SizedBox.shrink();

          final rawScore  = (catData['rawScore']   as num?)?.toInt()    ?? 0;
          final maxScore  = (catData['maxScore']   as num?)?.toInt()    ?? 1;
          final percent   = (catData['rawPercent'] as num?)?.toDouble() ?? 0.0;
          final severityC = _severityColor(percent);
          final severityL = _severityLabel(percent);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A1F2E),
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: cat.color, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(cat.icon, color: cat.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cat.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityC.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: severityC.withOpacity(0.4)),
                    ),
                    child: Text(severityL,
                        style: TextStyle(
                            color: severityC,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF6B3248),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(cat.color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Score: $rawScore / $maxScore  ·  ${(percent * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // ── Disclaimer ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A1F2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '📌 These scores are from a screening tool, not a clinical diagnosis. Use them as a guide for conversation and support, not as a definitive assessment.',
            style: TextStyle(
                color: Colors.white38, fontSize: 12, height: 1.5),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Severity ring widget ──────────────────────────────────────────────────────

class _SeverityRing extends StatelessWidget {
  final double percent; // 0.0 - 1.0
  const _SeverityRing({required this.percent});

  Color get _color {
    if (percent < 0.20) return const Color(0xFF7DC4B8);
    if (percent < 0.40) return const Color(0xFFE8A84A);
    if (percent < 0.60) return const Color(0xFFF5A87E);
    if (percent < 0.80) return const Color(0xFFFF6B6B);
    return const Color(0xFFFF4444);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
            backgroundColor: const Color(0xFF4A1F2E),
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Center(
            child: Text(
              '${(percent * 100).round()}',
              style: TextStyle(
                  color: _color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}