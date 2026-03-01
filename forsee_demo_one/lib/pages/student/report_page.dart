// lib/pages/student/report_page.dart
// ====================================
// LONGITUDINAL CHANGES:
//   • getInsights() now called with studentId so it fetches + saves history
//   • InsightsResult contains full history (past sessions)
//   • Each tab shows: Current Insights card + History Timeline card
//   • History timeline shows every past session with date, trend arrows, insights

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/pages/teacher/behaviour_incident_page.dart';
import 'package:forsee_demo_one/services/api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {

  late final Map<String, dynamic> _args =
      (Get.arguments as Map<String, dynamic>?) ?? {};

  // When opened from the student dashboard there are no Get.arguments.
  // In that case fall back to the currently logged-in user's own UID so
  // _loadData() can fetch /students/{uid} directly.
  late final String _selfUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isSelfView => _args.isEmpty;

  late final StudentModel _student = StudentModel(
    name:        _args['name']        as String?    ?? 'Me',
    studentId:   _args['studentId']   as String?    ?? '',
    firestoreId: _args['firestoreId'] as String?    ?? _selfUid,
    standard:    _args['standard']    as String?    ?? '',
    phone:       _args['phone']       as String?    ?? '',
    className:   _args['className']   as String?    ?? '',
    subject:     _args['subject']     as String?    ?? '',
    riskLevel:   _args['riskLevel']   as RiskLevel? ?? RiskLevel.none,
  );

  late final String _reportType = _args['reportType'] as String? ?? 'My';
  late final List<BehaviourIncident> _incidents =
      (_args['incidents'] as List<BehaviourIncident>?) ?? [];

  // ── Tabs ──────────────────────────────────────────────────────────────────
  int _activeIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  static const List<String> _tabs = ['Mental Health', 'Academics', 'Attendance'];

  // ── Firestore ─────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _studentDoc = {};
  Map<String, dynamic> _prediction = {};
  Map<String, dynamic> _staging    = {};

  // ── LLM insights cache per tab ────────────────────────────────────────────
  final Map<String, List<String>?>          _llmInsights  = {'Mental Health': null, 'Academics': null, 'Attendance': null};
  final Map<String, bool>                   _insightsLoading = {'Mental Health': false, 'Academics': false, 'Attendance': false};
  // Full session history per tab (oldest → newest)
  final Map<String, List<InsightSession>?>  _history      = {'Mental Health': null, 'Academics': null, 'Attendance': null};
  // Whether history section is expanded per tab
  final Map<String, bool>                   _historyExpanded = {'Mental Health': false, 'Academics': false, 'Attendance': false};

  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Firestore load ────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (_student.firestoreId.isEmpty) {
      setState(() { _error = 'Sign in required to view report.'; _loading = false; });
      return;
    }
    try {
      final db = FirebaseFirestore.instance;
      final studentSnap = await db.collection('students').doc(_student.firestoreId).get();
      final predSnap    = await db.collection('predictions')
          .where('studentId', isEqualTo: _student.firestoreId)
          .orderBy('timestamp', descending: true).limit(1).get();
      final stagingSnap = await db.collection('staging').doc(_student.firestoreId).get();

      setState(() {
        _studentDoc = studentSnap.data() ?? {};
        _prediction = predSnap.docs.isNotEmpty ? predSnap.docs.first.data() : {};
        _staging    = stagingSnap.data() ?? {};
        _loading    = false;
      });
      _loadInsights(_tabs[_activeIndex]);
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _loading = false; });
    }
  }

  // ── Load LLM insights (longitudinal) ──────────────────────────────────────

  Future<void> _loadInsights(String tab) async {
    if (_llmInsights[tab] != null || _insightsLoading[tab] == true) return;
    if (_student.firestoreId.isEmpty) return;

    setState(() => _insightsLoading[tab] = true);

    try {
      final result = await _api.getInsights(
        studentId:          _student.firestoreId,
        studentName:        _student.name,
        tab:                tab,
        riskLevel:          _riskLevel,
        riskFactors:        _riskFactors,
        mentalHealthScore:  _mentalScore * 100,
        categoryScores:     _categoryScores,
        behaviourScore:     _behaviourScore,
        behaviourIncidents: _incidents.length,
        negativeIncidents:  _incidents.where((i) => i.behaviourType == 'Negative').length,
        g1:                 _g1.toDouble(),
        g2:                 _g2.toDouble(),
        failures:           _failures,
        studytime:          _studytime,
        dropoutProbability: _dropoutProbability,
        attendancePct:      _attendancePct * 100,
        presentDays:        _presentDays,
        totalDays:          _totalDays,
        absences:           _absences,
      );
      if (mounted) {
        setState(() {
          _llmInsights[tab]    = result.insights;
          _history[tab]        = result.history;
          _insightsLoading[tab] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _llmInsights[tab]    = ['Unable to load AI insights.'];
          _insightsLoading[tab] = false;
        });
      }
    }
  }

  void _switchTab(int i) {
    if (i == _activeIndex) return;
    _animController.reverse().then((_) {
      setState(() => _activeIndex = i);
      _animController.forward();
    });
    _loadInsights(_tabs[i]);
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  double get _mentalScore {
    final quiz = _staging['quiz'] as Map<String, dynamic>?;
    if (quiz != null) {
      final s = (quiz['mentalHealthScore'] as num?)?.toDouble();
      if (s != null) return (s / 100).clamp(0.0, 1.0);
    }
    return 0.0;
  }
  double get _behaviourScore {
    final bh = (_prediction['behaviour_score'] as num?)?.toDouble();
    return bh ?? 50.0;
  }
  Map<String, double> get _categoryScores {
    final quiz = _staging['quiz'] as Map<String, dynamic>?;
    final cats = quiz?['categoryScores'] as Map<String, dynamic>?;
    return cats?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {};
  }
  int get _g1 {
    final m = _staging['marks'] as Map<String, dynamic>?;
    return (m?['G1'] as num?)?.toInt() ?? (_studentDoc['G1'] as num?)?.toInt() ?? 0;
  }
  int get _g2 {
    final m = _staging['marks'] as Map<String, dynamic>?;
    return (m?['G2'] as num?)?.toInt() ?? (_studentDoc['G2'] as num?)?.toInt() ?? 0;
  }
  double get _g3     => ((_g1 + _g2) / 2.0) / 20.0;
  int get _failures  => (_studentDoc['failures']  as num?)?.toInt() ?? 0;
  int get _studytime => (_studentDoc['studytime'] as num?)?.toInt() ?? 2;
  int get _totalDays {
    final a = _staging['attendance'] as Map<String, dynamic>?;
    return (a?['totalDays'] as num?)?.toInt() ?? 0;
  }
  int get _presentDays {
    final a = _staging['attendance'] as Map<String, dynamic>?;
    return (a?['presentDays'] as num?)?.toInt() ?? 0;
  }
  int get _absences {
    final a = _staging['attendance'] as Map<String, dynamic>?;
    return (a?['absences'] as num?)?.toInt() ?? (_studentDoc['absences'] as num?)?.toInt() ?? 0;
  }
  double get _attendancePct =>
      _totalDays > 0 ? (_presentDays / _totalDays).clamp(0.0, 1.0) : 0.0;
  String get _riskLevel   => (_prediction['risk_level'] as String?) ?? 'UNKNOWN';
  List<String> get _riskFactors {
    final rf = _prediction['risk_factors'];
    if (rf is List) return rf.map((e) => e.toString()).toList();
    if (rf is Map<String, dynamic>) return rf.entries.map((e) => '${e.key}: ${e.value}').toList();
    return [];
  }
  double get _dropoutProbability => ((_prediction['dropout_probability'] as num?)?.toDouble() ?? 0.0);

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE9C2D7)))
                : _error != null
                ? _buildError()
                : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  if (_activeIndex == 0) _buildMentalHealthView(),
                  if (_activeIndex == 1) _buildAcademicsView(),
                  if (_activeIndex == 2) _buildAttendanceView(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontFamily: 'Pridi')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () { setState(() { _loading = true; _error = null; }); _loadData(); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9C2D7)),
          child: const Text('Retry', style: TextStyle(color: Color(0xFF512D38))),
        ),
      ]),
    ),
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
    child: Row(children: [
      if (!_isSelfView)
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isSelfView ? (_studentDoc['name'] as String? ?? 'My Report') : _student.name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
        Row(children: [
          Text(_student.studentId, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          _pill('$_reportType Report', const Color(0xFFA8D0BC), const Color(0xFF3B2F2F)),
          if (_riskLevel != 'UNKNOWN') ...[
            const SizedBox(width: 6),
            _pill(_riskLevel, _riskColor(_riskLevel).withOpacity(0.2), _riskColor(_riskLevel)),
          ],
        ]),
      ])),
    ]),
  );

  Widget _buildTabs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: List.generate(_tabs.length, (i) {
        final active = i == _activeIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => _switchTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFE9C2D7) : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? const Color(0xFF512D38) : Colors.white54,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Pridi',
                  )),
            ),
          ),
        );
      }),
    ),
  );

  // ── MENTAL HEALTH ─────────────────────────────────────────────────────────

  Widget _buildMentalHealthView() {
    final score = _mentalScore;
    final pct   = (score * 100).round();
    final color = score >= 0.75 ? Colors.green : score >= 0.5 ? Colors.orange : Colors.red;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mental Health\n$_reportType Score',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
          const SizedBox(height: 20),
          Center(child: Stack(alignment: Alignment.center, children: [
            SizedBox(height: 160, width: 160,
                child: CircularProgressIndicator(value: score, strokeWidth: 20,
                    backgroundColor: Colors.red.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(color), strokeCap: StrokeCap.round)),
            Column(children: [
              Text('$pct%', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
              Text(score >= 0.75 ? 'Good' : score >= 0.5 ? 'Moderate' : 'At Risk',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
          ])),
          if (_categoryScores.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._categoryScores.entries.map((e) => _miniBar(_capitalize(e.key), e.value)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      _buildInsightsCard('Mental Health'),
      const SizedBox(height: 16),
      _buildHistoryTimeline('Mental Health'),
    ]);
  }

  // ── ACADEMICS ─────────────────────────────────────────────────────────────

  Widget _buildAcademicsView() => Column(children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$_reportType Scores',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
          const Icon(Icons.school_outlined, size: 22, color: Color(0xFF3B2F2F)),
        ]),
        const SizedBox(height: 6),
        Text('Grades out of 20',
            style: TextStyle(fontSize: 11, color: const Color(0xFF3B2F2F).withOpacity(0.5))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('Term 1', _g1 / 20.0),
              _buildBar('Term 2', _g2 / 20.0),
              _buildBar('Average', _g3),
            ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _infoChip('Failures', '$_failures', _failures > 0 ? Colors.redAccent : Colors.greenAccent),
          _infoChip('Study Time', _studytimeText(_studytime), Colors.lightBlueAccent),
          _infoChip('Dropout Risk', '${_dropoutProbability.toStringAsFixed(0)}%',
              _dropoutProbability > 50 ? Colors.redAccent : Colors.greenAccent),
        ]),
      ]),
    ),
    const SizedBox(height: 16),
    _buildInsightsCard('Academics'),
    const SizedBox(height: 16),
    _buildHistoryTimeline('Academics'),
  ]);

  // ── ATTENDANCE ────────────────────────────────────────────────────────────

  Widget _buildAttendanceView() {
    final pct = _attendancePct;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$_reportType Attendance',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
            _pill('${(pct * 100).round()}%',
                pct >= 0.75 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                pct >= 0.75 ? Colors.green.shade700 : Colors.red.shade700),
          ]),
          const SizedBox(height: 20),
          Center(child: Stack(alignment: Alignment.center, children: [
            SizedBox(height: 150, width: 150,
                child: CircularProgressIndicator(value: pct, strokeWidth: 16,
                    backgroundColor: Colors.red.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(pct >= 0.75 ? Colors.green : Colors.redAccent),
                    strokeCap: StrokeCap.round)),
            Column(children: [
              Text('${(pct * 100).round()}%',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
              Text('$_presentDays / $_totalDays days',
                  style: TextStyle(fontSize: 10, color: const Color(0xFF3B2F2F).withOpacity(0.55))),
            ]),
          ])),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _infoChip('Present', '$_presentDays days', Colors.greenAccent),
            _infoChip('Absent', '$_absences days', _absences > 10 ? Colors.redAccent : Colors.orangeAccent),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 13),
            const SizedBox(width: 4),
            const Text('75% minimum required',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontStyle: FontStyle.italic)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _buildInsightsCard('Attendance'),
      const SizedBox(height: 16),
      _buildHistoryTimeline('Attendance'),
    ]);
  }

  // ── CURRENT INSIGHTS CARD ─────────────────────────────────────────────────

  Widget _buildInsightsCard(String tab) {
    final loading  = _insightsLoading[tab] ?? false;
    final insights = _llmInsights[tab];
    final history  = _history[tab];
    final isFirstSession = history == null || history.length <= 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('AI Insights',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
          const SizedBox(width: 8),
          _pill(_reportType, const Color(0xFF512D38).withOpacity(0.15), const Color(0xFF512D38)),
          const SizedBox(width: 6),
          // Longitudinal badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isFirstSession ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isFirstSession ? Icons.auto_awesome : Icons.trending_up,
                  size: 11, color: isFirstSession ? Colors.blue.shade700 : Colors.purple.shade700),
              const SizedBox(width: 3),
              Text(isFirstSession ? 'Baseline' : 'Longitudinal',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: isFirstSession ? Colors.blue.shade700 : Colors.purple.shade700)),
            ]),
          ),
        ]),
        if (!isFirstSession && history != null) ...[
          const SizedBox(height: 4),
          Text('Based on ${history.length} session${history.length == 1 ? '' : 's'} of data',
              style: TextStyle(fontSize: 11, color: const Color(0xFF3B2F2F).withOpacity(0.5), fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 12),

        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Color(0xFF512D38), strokeWidth: 2),
              SizedBox(height: 10),
              Text('EduCare is analysing trends…',
                  style: TextStyle(color: Color(0xFF3B2F2F), fontSize: 12, fontStyle: FontStyle.italic)),
            ])),
          )
        else if (insights == null || insights.isEmpty)
          Text('No insights yet.', style: TextStyle(color: const Color(0xFF3B2F2F).withOpacity(0.5)))
        else
          ...insights.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_insightIcon(text), color: _insightColor(text), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: TextStyle(
                  fontSize: 14, color: _insightColor(text),
                  fontWeight: _isWarning(text) ? FontWeight.bold : FontWeight.normal))),
            ]),
          )),

        if (!loading && insights != null && insights.length == 1 && insights.first.contains('Unable'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () { setState(() { _llmInsights[tab] = null; _insightsLoading[tab] = false; }); _loadInsights(tab); },
              icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF512D38)),
              label: const Text('Retry', style: TextStyle(color: Color(0xFF512D38), fontSize: 12)),
            ),
          ),
      ]),
    );
  }

  // ── HISTORY TIMELINE ─────────────────────────────────────────────────────
  // Shows all past sessions for this tab with date, risk pill, insights, trend arrows

  Widget _buildHistoryTimeline(String tab) {
    final sessions = _history[tab];
    // Need at least 2 entries (1 past + current just saved) to show history
    if (sessions == null || sessions.length < 2) return const SizedBox.shrink();

    // Past sessions = all except the last one (which is the just-loaded session)
    final past = sessions.sublist(0, sessions.length - 1);
    if (past.isEmpty) return const SizedBox.shrink();

    final expanded = _historyExpanded[tab] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2028),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFA6768B), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        GestureDetector(
          onTap: () => setState(() => _historyExpanded[tab] = !expanded),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.history_rounded, color: Color(0xFFE9C2D7), size: 18),
              const SizedBox(width: 8),
              Text('Progress History (${past.length} session${past.length == 1 ? '' : 's'})',
                  style: const TextStyle(color: Color(0xFFE9C2D7), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            ]),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFFE9C2D7), size: 22),
          ]),
        ),

        if (expanded) ...[
          const SizedBox(height: 16),
          // Timeline: oldest at top, newest at bottom
          ...past.asMap().entries.map((entry) {
            final i = entry.key;
            final session = entry.value;
            final isLast  = i == past.length - 1;
            return _buildTimelineEntry(session, isLast, tab, past, i);
          }),
        ],
      ]),
    );
  }

  Widget _buildTimelineEntry(InsightSession session, bool isLast, String tab,
      List<InsightSession> allPast, int index) {
    final riskColor = _riskColor(session.riskLevel);

    // Compute metric trend vs previous session
    String trendText = '';
    Color  trendColor = Colors.white54;
    IconData trendIcon = Icons.remove;

    if (index > 0) {
      final prev = allPast[index - 1];
      double? prevVal, currVal;
      String metricName = '';

      switch (tab) {
        case 'Mental Health':
          prevVal = prev.mentalHealthScore; currVal = session.mentalHealthScore;
          metricName = 'MH';
          break;
        case 'Academics':
          prevVal = prev.g2; currVal = session.g2;
          metricName = 'T2';
          break;
        case 'Attendance':
          prevVal = prev.attendancePct; currVal = session.attendancePct;
          metricName = 'Att';
          break;
      }
      if (prevVal != null && currVal != null) {
        final delta = currVal - prevVal;
        if (delta.abs() < 0.5) {
          trendText  = '$metricName stable';
          trendColor = Colors.white54;
          trendIcon  = Icons.trending_flat;
        } else if (delta > 0) {
          trendText  = '$metricName +${delta.abs().toStringAsFixed(0)}';
          trendColor = Colors.greenAccent;
          trendIcon  = Icons.trending_up;
        } else {
          trendText  = '$metricName -${delta.abs().toStringAsFixed(0)}';
          trendColor = Colors.redAccent;
          trendIcon  = Icons.trending_down;
        }
      }
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timeline line + dot
        SizedBox(width: 28, child: Column(children: [
          Container(width: 12, height: 12,
              decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5))),
          if (!isLast)
            Expanded(child: Container(width: 2, color: Colors.white12)),
        ])),
        const SizedBox(width: 10),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Date row
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(session.date,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Row(children: [
                  _pill(session.riskLevel, riskColor.withOpacity(0.2), riskColor),
                  if (trendText.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Row(children: [
                      Icon(trendIcon, size: 12, color: trendColor),
                      const SizedBox(width: 2),
                      Text(trendText,
                          style: TextStyle(fontSize: 10, color: trendColor, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ]),
              ]),
              const SizedBox(height: 6),
              // Insights from that session
              ...session.insights.map((ins) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('•  ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Expanded(child: Text(ins,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4))),
                ]),
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildBar(String label, double value) {
    final color = value >= 0.70 ? Colors.greenAccent : value >= 0.50 ? Colors.orangeAccent : Colors.redAccent;
    return Column(children: [
      Text('${(value * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Container(height: 130, width: 38,
          decoration: BoxDecoration(color: const Color(0xFF3B2F2F).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(heightFactor: value.clamp(0.0, 1.0), alignment: Alignment.bottomCenter,
              child: AnimatedContainer(duration: const Duration(milliseconds: 600), curve: Curves.easeOut,
                  decoration: BoxDecoration(color: color.withOpacity(0.85), borderRadius: BorderRadius.circular(10))))),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF3B2F2F))),
    ]);
  }

  Widget _miniBar(String label, double value) {
    final color = value >= 0.6 ? Colors.green : Colors.orangeAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFF3B2F2F).withOpacity(0.65))),
          Text('${(value * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: value.clamp(0.0, 1.0),
                backgroundColor: Colors.white30, valueColor: AlwaysStoppedAnimation(color), minHeight: 7)),
      ]),
    );
  }

  Widget _infoChip(String label, String value, Color color) => Column(children: [
    Text(label, style: TextStyle(fontSize: 10, color: const Color(0xFF3B2F2F).withOpacity(0.5))),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color, fontFamily: 'Pridi')),
  ]);

  Widget _pill(String text, Color bg, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
  );

  bool _isWarning(String t) {
    final l = t.toLowerCase();
    return l.contains('risk') || l.contains('below') || l.contains('critical') ||
        l.contains('decline') || l.contains('absent') || l.contains('fail') ||
        l.contains('contact') || l.contains('concern') || l.contains('worsen');
  }
  bool _isGood(String t) {
    final l = t.toLowerCase();
    return l.contains('good') || l.contains('excellent') || l.contains('positive') ||
        l.contains('improv') || l.contains('well') || l.contains('acknowledg');
  }
  IconData _insightIcon(String t) =>
      _isWarning(t) ? Icons.warning_amber_rounded : _isGood(t) ? Icons.check_circle_outline : Icons.info_outline;
  Color _insightColor(String t) =>
      _isWarning(t) ? Colors.red.shade700 : _isGood(t) ? Colors.green.shade700 : const Color(0xFF3B2F2F);

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      case 'LOW':    return Colors.greenAccent;
      default:       return Colors.white54;
    }
  }

  String _studytimeText(int st) {
    switch (st) { case 1: return '<2 hrs'; case 2: return '2-5 hrs';
      case 3: return '5-10 hrs'; case 4: return '>10 hrs'; default: return '?'; }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}