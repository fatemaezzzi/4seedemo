import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/pages/teacher/behaviour_incident_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO NAVIGATE HERE:
//
// Get.toNamed(AppRoutes.STUDENT_REPORT, arguments: {
//   'name':       student.name,
//   'studentId':  student.studentId,   // Firestore doc ID in students collection
//   'standard':   student.standard,
//   'phone':      student.phone,
//   'className':  student.className,
//   'subject':    student.subject,
//   'riskLevel':  student.riskLevel,
//   'reportType': 'Semester',           // optional
//   'incidents':  <BehaviourIncident>[],// optional
// });
// ─────────────────────────────────────────────────────────────────────────────

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  // ── Args ──────────────────────────────────────────────────────────────────
  late final Map<String, dynamic> _args =
      (Get.arguments as Map<String, dynamic>?) ?? {};

  late final StudentModel _student = StudentModel(
    name:        _args['name']        as String?    ?? 'Unknown Student',
    studentId:   _args['studentId']   as String?    ?? '',
    firestoreId: _args['firestoreId'] as String?    ?? '',
    standard:    _args['standard']    as String?    ?? '',
    phone:       _args['phone']       as String?    ?? '',
    className:   _args['className']   as String?    ?? '',
    subject:     _args['subject']     as String?    ?? '',
    riskLevel:   _args['riskLevel']   as RiskLevel? ?? RiskLevel.none,
  );

  late final String _reportType =
      _args['reportType'] as String? ?? 'Semester';

  late final List<BehaviourIncident> _incidents =
      (_args['incidents'] as List<BehaviourIncident>?) ?? [];

  // ── Tabs ──────────────────────────────────────────────────────────────────
  int _activeIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final List<String> _tabs = ['Mental Health', 'Academics', 'Attendance'];

  // ── Firebase data state ───────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  // From students/{studentId}
  Map<String, dynamic> _studentDoc = {};

  // From predictions collection (query where studentId == _student.studentId)
  Map<String, dynamic> _prediction = {};

  // From staging/{studentId}
  Map<String, dynamic> _staging = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Load all Firestore data ───────────────────────────────────────────────
  Future<void> _loadData() async {
    if (_student.firestoreId.isEmpty) {
      setState(() {
        _error = 'No student ID provided.';
        _loading = false;
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      // 1) Student base doc
      final studentSnap =
      await db.collection('students').doc(_student.firestoreId).get();
      final studentData =
      studentSnap.exists ? studentSnap.data() ?? {} : <String, dynamic>{};

      // 2) Latest prediction for this student
      final predSnap = await db
          .collection('predictions')
          .where('studentId', isEqualTo: _student.firestoreId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      final predData = predSnap.docs.isNotEmpty
          ? predSnap.docs.first.data()
          : <String, dynamic>{};

      // 3) Staging doc (attendance / marks / quiz / behaviour inputs)
      final stagingSnap =
      await db.collection('staging').doc(_student.firestoreId).get();
      final stagingData =
      stagingSnap.exists ? stagingSnap.data() ?? {} : <String, dynamic>{};

      setState(() {
        _studentDoc = studentData;
        _prediction = predData;
        _staging = stagingData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  void _switchTab(int index) {
    if (index == _activeIndex) return;
    _animController.reverse().then((_) {
      setState(() => _activeIndex = index);
      _animController.forward();
    });
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// Mental health score: from staging.quiz.mentalHealthScore (0-100).
  /// Falls back to prediction input_features if quiz not staged yet.
  double get _mentalScore {
    final quiz = _staging['quiz'] as Map<String, dynamic>?;
    if (quiz != null) {
      final s = (quiz['mentalHealthScore'] as num?)?.toDouble();
      if (s != null) return (s / 100).clamp(0.0, 1.0);
    }
    // fallback: prediction stored mental health
    final inputFeatures =
    _prediction['input_features'] as Map<String, dynamic>?;
    if (inputFeatures != null) {
      final s = (inputFeatures['mentalHealthScore'] as num?)?.toDouble();
      if (s != null) return (s / 100).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Category scores from quiz (e.g. anxiety, stress, etc.)
  Map<String, double> get _categoryScores {
    final quiz = _staging['quiz'] as Map<String, dynamic>?;
    if (quiz == null) return {};
    final cats = quiz['categoryScores'] as Map<String, dynamic>?;
    if (cats == null) return {};
    return cats.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// G1, G2 from staging.marks (normalized 0-20) or fallback to student doc.
  int get _g1 {
    final marks = _staging['marks'] as Map<String, dynamic>?;
    if (marks != null) return (marks['G1'] as num?)?.toInt() ?? _g1Fallback;
    return _g1Fallback;
  }

  int get _g2 {
    final marks = _staging['marks'] as Map<String, dynamic>?;
    if (marks != null) return (marks['G2'] as num?)?.toInt() ?? _g2Fallback;
    return _g2Fallback;
  }

  int get _g1Fallback => (_studentDoc['G1'] as num?)?.toInt() ?? 0;
  int get _g2Fallback => (_studentDoc['G2'] as num?)?.toInt() ?? 0;

  /// G3 = average of G1 and G2 (as fractions for bar display)
  double get _g3 => ((_g1 + _g2) / 2.0) / 20.0;

  int get _failures =>
      (_studentDoc['failures'] as num?)?.toInt() ?? 0;

  int get _studytime =>
      (_studentDoc['studytime'] as num?)?.toInt() ?? 0;

  /// Attendance from staging.attendance or student doc absences field
  int get _totalDays {
    final att = _staging['attendance'] as Map<String, dynamic>?;
    return (att?['totalDays'] as num?)?.toInt() ?? 0;
  }

  int get _presentDays {
    final att = _staging['attendance'] as Map<String, dynamic>?;
    return (att?['presentDays'] as num?)?.toInt() ?? 0;
  }

  int get _absences {
    final att = _staging['attendance'] as Map<String, dynamic>?;
    if (att != null) return (att['absences'] as num?)?.toInt() ?? 0;
    return (_studentDoc['absences'] as num?)?.toInt() ?? 0;
  }

  double get _attendancePct =>
      _totalDays > 0 ? (_presentDays / _totalDays).clamp(0.0, 1.0) : 0.0;

  /// Risk info from prediction
  String get _riskLevel =>
      (_prediction['risk_level'] as String?) ?? 'UNKNOWN';

  List<String> get _riskFactors {
    final rf = _prediction['risk_factors'];
    if (rf is List) return rf.map((e) => e.toString()).toList();
    return [];
  }

  String get _recommendation =>
      (_prediction['recommendation'] as String?) ?? '';

  double get _dropoutProbability =>
      ((_prediction['dropout_probability'] as num?)?.toDouble() ?? 0.0);

  // ── Build insights list ───────────────────────────────────────────────────
  List<_Insight> _getInsights(String tab) {
    final List<_Insight> items = [];

    if (tab == 'Mental Health') {
      final score = _mentalScore * 100;
      items.add(_Insight(
        text: 'Mental wellness score: ${score.round()}%',
        type: score >= 75
            ? _InsightType.good
            : score >= 50
            ? _InsightType.normal
            : _InsightType.warning,
      ));

      // Category scores from quiz
      _categoryScores.forEach((cat, val) {
        final pct = (val * 100).round();
        items.add(_Insight(
          text: '${_capitalize(cat)}: $pct%',
          type: val >= 0.6 ? _InsightType.normal : _InsightType.warning,
        ));
      });

      // Behaviour incidents
      final neg =
          _incidents.where((i) => i.behaviourType == 'Negative').length;
      if (neg > 0) {
        items.add(_Insight(
          text: '$neg negative behaviour incident(s) flagged this period',
          type: _InsightType.warning,
        ));
      }
      if (_incidents.any((i) => i.tags.contains('Aggressive'))) {
        items.add(_Insight(
          text: 'Aggressive behaviour logged — counselling review needed',
          type: _InsightType.warning,
        ));
      }
      if (_incidents.any((i) => i.behaviourType == 'Positive')) {
        items.add(_Insight(
          text: 'Positive behaviour noted — acknowledge with student',
          type: _InsightType.good,
        ));
      }

      // Risk factors from prediction
      for (final rf in _riskFactors) {
        items.add(_Insight(text: rf, type: _InsightType.warning));
      }

      if (_recommendation.isNotEmpty) {
        items.add(_Insight(
            text: 'Recommendation: $_recommendation',
            type: _InsightType.normal));
      }
    }

    if (tab == 'Academics') {
      final g1Pct = (_g1 / 20.0 * 100).round();
      final g2Pct = (_g2 / 20.0 * 100).round();
      final g3Pct = (_g3 * 100).round();

      items.add(_Insight(
        text: 'Term 1 score: $g1Pct% (${_g1}/20)',
        type: _g1 >= 14
            ? _InsightType.good
            : _g1 >= 10
            ? _InsightType.normal
            : _InsightType.warning,
      ));
      items.add(_Insight(
        text: 'Term 2 score: $g2Pct% (${_g2}/20)',
        type: _g2 >= 14
            ? _InsightType.good
            : _g2 >= 10
            ? _InsightType.normal
            : _InsightType.warning,
      ));
      items.add(_Insight(
        text: 'Average score: $g3Pct%',
        type: _g3 >= 0.7
            ? _InsightType.good
            : _g3 >= 0.5
            ? _InsightType.normal
            : _InsightType.warning,
      ));

      if (_failures > 0) {
        items.add(_Insight(
          text: '$_failures past failure(s) on record',
          type: _InsightType.warning,
        ));
      }

      final studytimeLabel = [
        '', '< 2 hrs/week', '2–5 hrs/week', '5–10 hrs/week', '> 10 hrs/week'
      ];
      if (_studytime > 0 && _studytime <= 4) {
        items.add(_Insight(
          text: 'Study time: ${studytimeLabel[_studytime]}',
          type: _studytime >= 3 ? _InsightType.good : _InsightType.normal,
        ));
      }

      // Dropout probability
      final dropPct = (_dropoutProbability * 100).toStringAsFixed(1);
      items.add(_Insight(
        text: 'Dropout risk probability: $dropPct%',
        type: _dropoutProbability > 0.5
            ? _InsightType.warning
            : _InsightType.normal,
      ));

      if (_incidents.any((i) => i.tags.contains('No Homework'))) {
        items.add(_Insight(
          text: 'Homework non-submission logged — follow up with parents',
          type: _InsightType.warning,
        ));
      }

      if (_recommendation.isNotEmpty) {
        items.add(_Insight(
            text: 'Recommendation: $_recommendation',
            type: _InsightType.normal));
      }
    }

    if (tab == 'Attendance') {
      final pct = (_attendancePct * 100).round();
      items.add(_Insight(
        text: 'Attendance: $pct% ($_presentDays / $_totalDays days present)',
        type: _attendancePct >= 0.75
            ? _InsightType.good
            : _InsightType.warning,
      ));
      items.add(_Insight(
        text: 'Total absences: $_absences',
        type: _absences > 10 ? _InsightType.warning : _InsightType.normal,
      ));

      if (_attendancePct < 0.6) {
        items.add(_Insight(
          text: 'Attendance below 60% minimum — action required',
          type: _InsightType.warning,
        ));
      }

      if (_incidents.any((i) => i.tags.contains('Absent'))) {
        items.add(_Insight(
          text: 'Unexplained absences logged via behaviour tracker',
          type: _InsightType.warning,
        ));
      }

      if (_recommendation.isNotEmpty) {
        items.add(_Insight(
            text: 'Recommendation: $_recommendation',
            type: _InsightType.normal));
      }
    }

    return items;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE9C2D7)))
                  : _error != null
                  ? _buildError()
                  : FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    if (_activeIndex == 0) _buildMentalHealthView(),
                    if (_activeIndex == 1) _buildAcademicsView(),
                    if (_activeIndex == 2) _buildAttendanceView(),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontFamily: 'Pridi')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9C2D7)),
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF512D38), fontFamily: 'Pridi')),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_student.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pridi')),
            Row(children: [
              Text(_student.studentId,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              _pill('$_reportType Report', const Color(0xFFA8D0BC),
                  const Color(0xFF3B2F2F)),
              if (_riskLevel != 'UNKNOWN') ...[
                const SizedBox(width: 6),
                _pill(_riskLevel, _riskColor(_riskLevel).withOpacity(0.2),
                    _riskColor(_riskLevel)),
              ],
              if (_incidents.isNotEmpty) ...[
                const SizedBox(width: 6),
                _pill('${_incidents.length} incidents',
                    Colors.redAccent.withOpacity(0.2), Colors.redAccent,
                    bordered: true),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String text, Color bg, Color textColor,
      {bool bordered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: bordered ? Border.all(color: textColor) : null,
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor)),
    );
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH': return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      case 'LOW': return Colors.greenAccent;
      default: return Colors.white54;
    }
  }

  Widget _buildTabs() {
    return Padding(
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
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF512D38)
                        : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Pridi',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── MENTAL HEALTH TAB ─────────────────────────────────────────────────────
  Widget _buildMentalHealthView() {
    final score = _mentalScore;
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
          // Category breakdown if available
          if (_categoryScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Category Breakdown',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2F2F),
                    fontFamily: 'Pridi')),
            const SizedBox(height: 10),
            ..._categoryScores.entries.map((e) => _miniBar(
                _capitalize(e.key), e.value)),
          ],
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Mental Health'),
    ]);
  }

  // ── ACADEMICS TAB ─────────────────────────────────────────────────────────
  Widget _buildAcademicsView() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C2D7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$_reportType Scores',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2F2F),
                    fontFamily: 'Pridi')),
            const Icon(Icons.school_outlined,
                size: 22, color: Color(0xFF3B2F2F)),
          ]),
          const SizedBox(height: 8),
          Text('Grades out of 20',
              style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3B2F2F).withOpacity(0.55),
                  fontFamily: 'Pridi')),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar('Term 1', _g1 / 20.0),
              _buildBar('Term 2', _g2 / 20.0),
              _buildBar('Average', _g3),
            ],
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _dot(Colors.greenAccent, '≥70%'),
            const SizedBox(width: 12),
            _dot(Colors.orangeAccent, '50-69%'),
            const SizedBox(width: 12),
            _dot(Colors.redAccent, '<50%'),
          ]),
          // Extra info row
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip('Failures', '$_failures',
                  _failures > 0 ? Colors.redAccent : Colors.greenAccent),
              _infoChip('Study Time', _studytimeText(_studytime),
                  Colors.lightBlueAccent),
              _infoChip('Dropout Risk',
                  '${(_dropoutProbability * 100).toStringAsFixed(0)}%',
                  _dropoutProbability > 0.5
                      ? Colors.redAccent
                      : Colors.greenAccent),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Academics'),
    ]);
  }

  String _studytimeText(int st) {
    switch (st) {
      case 1: return '<2 hrs';
      case 2: return '2–5 hrs';
      case 3: return '5–10 hrs';
      case 4: return '>10 hrs';
      default: return 'Unknown';
    }
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF3B2F2F).withOpacity(0.55),
              fontFamily: 'Pridi')),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Pridi')),
    ]);
  }

  // ── ATTENDANCE TAB ────────────────────────────────────────────────────────
  Widget _buildAttendanceView() {
    final pct = _attendancePct;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C2D7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                color: pct >= 0.75
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  color: pct >= 0.75
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          // Big attendance ring
          Center(
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                height: 160,
                width: 160,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 18,
                  backgroundColor: Colors.red.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 0.75 ? Colors.green : Colors.redAccent),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(children: [
                Text('${(pct * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B2F2F),
                        fontFamily: 'Pridi')),
                Text('$_presentDays / $_totalDays days',
                    style: TextStyle(
                        fontSize: 11,
                        color:
                        const Color(0xFF3B2F2F).withOpacity(0.6),
                        fontFamily: 'Pridi')),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          // Absences row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip('Present', '$_presentDays days', Colors.greenAccent),
              _infoChip('Absent', '$_absences days',
                  _absences > 10 ? Colors.redAccent : Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orangeAccent, size: 14),
            const SizedBox(width: 4),
            const Text('60% minimum required',
                style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      _buildInsightsCard('Attendance'),
    ]);
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildBar(String label, double value) {
    final color = value >= 0.70
        ? Colors.greenAccent
        : value >= 0.50
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Column(children: [
      Text('${(value * 100).round()}%',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Container(
        height: 140,
        width: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF3B2F2F).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: FractionallySizedBox(
          heightFactor: value.clamp(0.0, 1.0),
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
              fontSize: 11,
              color: Color(0xFF3B2F2F))),
    ]);
  }

  Widget _miniBar(String label, double value) {
    final color = value >= 0.6 ? Colors.green : Colors.orangeAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3B2F2F).withOpacity(0.7),
                  fontFamily: 'Pridi')),
          Text('${(value * 100).round()}%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 7,
          ),
        ),
      ]),
    );
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Insights',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B2F2F),
                  fontFamily: 'Pridi')),
          const SizedBox(width: 8),
          _pill(_reportType,
              const Color(0xFF512D38).withOpacity(0.15), const Color(0xFF512D38)),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text('No data available yet.',
              style: TextStyle(
                  color: const Color(0xFF3B2F2F).withOpacity(0.5),
                  fontFamily: 'Pridi'))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.type == _InsightType.warning
                      ? Icons.warning_amber_rounded
                      : item.type == _InsightType.good
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: item.type == _InsightType.warning
                      ? Colors.red.shade700
                      : item.type == _InsightType.good
                      ? Colors.green.shade700
                      : const Color(0xFF3B2F2F),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.type == _InsightType.warning
                          ? Colors.red.shade700
                          : item.type == _InsightType.good
                          ? Colors.green.shade700
                          : const Color(0xFF3B2F2F),
                      fontWeight: item.type != _InsightType.normal
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          )),
      ]),
    );
  }

  Widget _dot(Color color, String label) => Row(children: [
    CircleAvatar(radius: 5, backgroundColor: color),
    const SizedBox(width: 4),
    Text(label,
        style: const TextStyle(
            fontSize: 11, color: Color(0xFF3B2F2F))),
  ]);
}

// ── Insight model ─────────────────────────────────────────────────────────────

enum _InsightType { normal, warning, good }

class _Insight {
  final String text;
  final _InsightType type;
  const _Insight({required this.text, required this.type});
}