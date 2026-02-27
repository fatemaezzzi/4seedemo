import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/pages/teacher/behaviour_incident_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO NAVIGATE HERE:
//
// Simple (no incidents):
// Get.toNamed(AppRoutes.STUDENT_REPORT, arguments: {
//   'name':       student.name,
//   'studentId':  student.studentId,
//   'standard':   student.standard,
//   'phone':      student.phone,
//   'className':  student.className,
//   'subject':    student.subject,
//   'riskLevel':  student.riskLevel,
//   'reportType': 'Semester',          // optional, defaults to 'Semester'
//   'incidents':  [],                  // optional, pass serialized incidents
// });
// ─────────────────────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  // ✅ FIXED: no required constructor params
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {

  // ── Reconstruct data from Get.arguments ──────────────────────────────────
  late final Map<String, dynamic> _args =
      (Get.arguments as Map<String, dynamic>?) ?? {};

  late final StudentModel _student = StudentModel(
    name:      _args['name']      as String?    ?? 'Unknown Student',
    studentId: _args['studentId'] as String?    ?? '#00000',
    standard:  _args['standard']  as String?    ?? '',
    phone:     _args['phone']     as String?    ?? '',
    className: _args['className'] as String?    ?? '',
    subject:   _args['subject']   as String?    ?? '',
    riskLevel: _args['riskLevel'] as RiskLevel? ?? RiskLevel.none,
  );

  late final String _reportType =
      _args['reportType'] as String? ?? 'Semester';

  // Incidents passed as a pre-built List<BehaviourIncident> in arguments.
  // If not provided, defaults to empty list.
  late final List<BehaviourIncident> _incidents =
      (_args['incidents'] as List<BehaviourIncident>?) ?? [];

  late int activeIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _tabs = ['Mental Health', 'Academics', 'Attendance'];

  final Map<String, double> _mentalScores = {
    'Semester': 0.84,
    'Weekly':   0.72,
    'Monthly':  0.78,
  };
  final Map<String, Map<String, double>> _academicData = {
    'Semester': {'Mat': 0.80, 'SS': 0.50, 'IP': 0.90, 'LAN': 0.30, 'CS': 0.70},
    'Weekly':   {'Mat': 0.55, 'SS': 0.65, 'IP': 0.75, 'LAN': 0.45, 'CS': 0.80},
    'Monthly':  {'Mat': 0.70, 'SS': 0.60, 'IP': 0.85, 'LAN': 0.40, 'CS': 0.75},
  };
  final Map<String, Map<String, double>> _attendanceData = {
    'Semester': {'Jan': 0.70, 'Feb': 0.50, 'Mar': 0.85, 'Apr': 0.20, 'May': 0.65},
    'Weekly':   {'Mon': 0.90, 'Tue': 0.60, 'Wed': 1.0,  'Thu': 0.50, 'Fri': 0.80},
    'Monthly':  {'Aug': 0.65, 'Sep': 0.80, 'Oct': 0.45, 'Nov': 0.90, 'Dec': 0.70},
  };
  final Map<String, Map<String, List<String>>> _baseInsights = {
    'Mental Health': {
      'Semester': ['Overall mental wellness at 84% — above average', 'Stress indicators slightly elevated in Q2', 'Peer interaction scores improved by 12%', 'Quiz completion rate: 78%', 'Recommended: weekly check-in sessions'],
      'Weekly':   ['This week wellness score: 72%', 'Showed signs of anxiety on Tuesday', 'Participated actively in group activity', 'Quiz taken: 2 out of 3 completed', 'Recommended: breathing exercise routine'],
      'Monthly':  ['Monthly average wellness: 78%', 'Improvement noted from last month (+6%)', 'Attended 3 counselling sessions', 'Social engagement score: 70%', 'Next check-in: end of month'],
    },
    'Academics': {
      'Semester': ['Mathematics dropped 15% — needs attention', 'IP (Informatics) is strongest subject at 90%', 'Language scores critically low at 30%', 'Overall GPA: 2.8 / 4.0', 'Remedial classes recommended for Maths & LAN'],
      'Weekly':   ['Completed 4 of 5 assignments this week', 'Maths homework submitted late twice', 'CS project received positive feedback', 'Language quiz score: 45% (below pass)', 'Recommended: extra Maths practice'],
      'Monthly':  ['Monthly test average: 62%', 'Improvement in CS and IP noted', 'Language still a concern — 40%', 'Maths showing slow recovery (+5%)', 'Parent informed of LAN performance'],
    },
    'Attendance': {
      'Semester': ['Overall attendance: 58% — below 60% threshold', 'April attendance critically low at 20%', 'March was best month at 85%', 'Warning letter issued in April', 'Attendance improvement plan in progress'],
      'Weekly':   ['Present 3 out of 5 days this week', 'Absent: Wednesday and Thursday', 'Running total this month: 60%', 'Teacher follow-up scheduled', 'No improvement from last week'],
      'Monthly':  ['October attendance: 45% — flagged', 'Significant drop from September (80%)', 'Parent notified on 15th October', 'Medical certificate submitted for 3 days', 'Action plan to be discussed with family'],
    },
  };

  @override
  void initState() {
    super.initState();
    activeIndex = 0;
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (index == activeIndex) return;
    _animController.reverse().then((_) {
      setState(() => activeIndex = index);
      _animController.forward();
    });
  }

  List<String> _getInsights(String tab) {
    final base =
    List<String>.from(_baseInsights[tab]?[_reportType] ?? []);
    if (tab == 'Mental Health') {
      final neg =
          _incidents.where((i) => i.behaviourType == 'Negative').length;
      if (neg > 0)
        base.add('⚠️ $neg negative behaviour incident(s) flagged this period');
      if (_incidents.any((i) => i.tags.contains('Aggressive')))
        base.add('⚠️ Aggressive behaviour logged — counselling review needed');
      if (_incidents.any((i) => i.tags.contains('Distracted')))
        base.add('Focus/distraction issues noted in behaviour log');
      if (_incidents.any((i) => i.behaviourType == 'Positive'))
        base.add('✅ Positive behaviour noted — acknowledge with student');
    }
    if (tab == 'Academics') {
      if (_incidents.any((i) => i.tags.contains('No Homework')))
        base.add('⚠️ Homework non-submission logged — follow up with parents');
      if (_incidents.any((i) => i.tags.contains('Late')))
        base.add('Punctuality issues observed — impacts class participation');
    }
    if (tab == 'Attendance') {
      if (_incidents.any((i) => i.tags.contains('Absent')))
        base.add('⚠️ Unexplained absences logged via behaviour tracker');
    }
    return base;
  }

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_student.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pridi')),
                        Row(children: [
                          Text(_student.studentId,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8D0BC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$_reportType Report',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B2F2F))),
                          ),
                          if (_incidents.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.redAccent, width: 1),
                              ),
                              child: Text('${_incidents.length} incidents',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent)),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── TABS ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = i == activeIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFE9C2D7)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active
                                ? const Color(0xFF512D38)
                                : Colors.white54,
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFamily: 'Pridi',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // ── CONTENT ───────────────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    if (activeIndex == 0) _buildMentalHealthView(),
                    if (activeIndex == 1) _buildAcademicsView(),
                    if (activeIndex == 2) _buildAttendanceView(),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalHealthView() {
    final score = _mentalScores[_reportType] ?? 0.84;
    final pct = (score * 100).round();
    final color = score >= 0.75
        ? Colors.green
        : score >= 0.5
        ? Colors.orange
        : Colors.red;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C2D7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mental Health\n$_reportType Score',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B2F2F),
                  fontFamily: 'Pridi')),
          const SizedBox(height: 24),
          Center(
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: score,
                  strokeWidth: 22,
                  backgroundColor: Colors.red.withOpacity(0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(children: [
                Text('$pct%',
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B2F2F),
                        fontFamily: 'Pridi')),
                Text(
                  score >= 0.75
                      ? 'Good'
                      : score >= 0.5
                      ? 'Moderate'
                      : 'At Risk',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Mental Health'),
    ]);
  }

  Widget _buildAcademicsView() {
    final scores = _academicData[_reportType] ?? {};
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C2D7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_reportType Scores',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2F2F),
                      fontFamily: 'Pridi')),
              const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Color(0xFF3B2F2F)),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: scores.entries.map((e) => _buildBar(e.key, e.value)).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(Colors.greenAccent, '≥75%'),
              const SizedBox(width: 12),
              _dot(Colors.orangeAccent, '50-74%'),
              const SizedBox(width: 12),
              _dot(Colors.redAccent, '<50%'),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Academics'),
    ]);
  }

  Widget _buildAttendanceView() {
    final data = _attendanceData[_reportType] ?? {};
    final overall = data.isEmpty
        ? 0.0
        : data.values.reduce((a, b) => a + b) / data.length;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C2D7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_reportType Attendance',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2F2F),
                      fontFamily: 'Pridi')),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: overall >= 0.75
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(overall * 100).round()}% avg',
                  style: TextStyle(
                    color: overall >= 0.75
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.entries.map((e) => _buildBar(e.key, e.value)).toList(),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orangeAccent, size: 14),
              SizedBox(width: 4),
              Text('60% minimum required',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Attendance'),
    ]);
  }

  Widget _buildBar(String label, double value) {
    final color = value >= 0.75
        ? Colors.greenAccent
        : value >= 0.5
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Column(children: [
      Text('${(value * 100).round()}%',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Container(
        height: 140,
        width: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF3B2F2F).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FractionallySizedBox(
          heightFactor: value,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF3B2F2F))),
    ]);
  }

  Widget _buildInsightsCard(String tab) {
    final items = _getInsights(tab);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C2D7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Insights',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2F2F),
                    fontFamily: 'Pridi')),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF512D38).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_reportType,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF512D38),
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.startsWith('⚠️') || item.startsWith('✅')
                      ? ''
                      : '• ',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2F2F)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.startsWith('⚠️')
                          ? Colors.red.shade700
                          : item.startsWith('✅')
                          ? Colors.green.shade700
                          : const Color(0xFF3B2F2F),
                      fontWeight: item.startsWith('⚠️') ||
                          item.startsWith('✅')
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) => Row(children: [
    CircleAvatar(radius: 5, backgroundColor: color),
    const SizedBox(width: 4),
    Text(label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF3B2F2F))),
  ]);
}