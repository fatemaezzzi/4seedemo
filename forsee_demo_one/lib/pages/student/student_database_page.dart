import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';
import 'package:forsee_demo_one/services/admin_firebase_service.dart';

// ── COLORS ─────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF512D38);
const _petalPink = Color(0xFFB27092);
const _pastel    = Color(0xFFF4BFDB);
const _blush     = Color(0xFFFFE9F3);
const _teal      = Color(0xFF87BAAB);
const _dark      = Color(0xFF3B2028);

// ── PAGE ───────────────────────────────────────────────────────────────────────

class StudentDatabasePage extends StatefulWidget {
  const StudentDatabasePage({super.key});

  @override
  State<StudentDatabasePage> createState() => _StudentDatabasePageState();
}

class _StudentDatabasePageState extends State<StudentDatabasePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filterHighRisk = false;
  bool _filterMediumRisk = false;
  bool _filterLowRisk = false;
  int _navIndex = 2;

  List<FirestoreStudent> _allStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final students = await AdminFirebaseService.fetchAllStudents();
      if (mounted) setState(() { _allStudents = students; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── FILTERING ──────────────────────────────────────────────────────────────

  List<FirestoreStudent> get _filtered {
    return _allStudents.where((s) {
      final q = _query.toLowerCase();
      final matchesSearch = q.isEmpty || s.name.toLowerCase().contains(q);
      final anyRiskFilter = _filterHighRisk || _filterMediumRisk || _filterLowRisk;
      final matchesRisk = !anyRiskFilter ||
          (_filterHighRisk   && s.isHighRisk)   ||
          (_filterMediumRisk && s.isMediumRisk) ||
          (_filterLowRisk    && s.isLowRisk);
      return matchesSearch && matchesRisk;
    }).toList();
  }

  // ── DETAIL SHEET ───────────────────────────────────────────────────────────

  void _openDetail(FirestoreStudent s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: _petalPink.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                _avatar(s, radius: 36),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: const TextStyle(color: _blush, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Text('Age: ${s.age}', style: TextStyle(color: _pastel.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 6),
                  _riskBadge(s.riskLevel),
                ])),
              ]),

              const SizedBox(height: 20),
              Divider(color: _petalPink.withOpacity(0.3)),
              const SizedBox(height: 12),

              _detailSection('Academic', [
                _detailRow('G1 Score',  '${s.g1}/20'),
                _detailRow('G2 Score',  '${s.g2}/20'),
                _detailRow('Avg Score', '${s.avgScore.toStringAsFixed(0)}%'),
                _detailRow('Studytime', '${s.studytime} hrs/week'),
                _detailRow('Failures',  '${s.failures}'),
              ]),
              const SizedBox(height: 14),

              _detailSection('Attendance & Behaviour', [
                _detailRow('Absences', '${s.absences} days', valueColor: s.absences > 15 ? Colors.redAccent : _blush),
                _detailRow('Status',   s.attendanceLabel,    valueColor: s.absences > 15 ? Colors.redAccent : Colors.greenAccent),
                _detailRow('Health',   '${s.health}/5'),
                _detailRow('Dalc (workday alcohol)', '${s.dalc}/5'),
                _detailRow('Walc (weekend alcohol)', '${s.walc}/5'),
              ]),
              const SizedBox(height: 14),

              _detailSection('AI Risk Prediction', [
                _detailRow('Risk Level',    s.riskLevel,  valueColor: _riskColor(s.riskLevel)),
                _detailRow('Risk Score',    s.riskScore.toStringAsFixed(2)),
                _detailRow('Dropout Prob.', '${(s.dropoutProbability * 100).toStringAsFixed(1)}%'),
                _detailRow('Confidence',    s.confidence),
              ]),

              if (s.riskFactors.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Risk Factors:', style: TextStyle(color: _teal, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _petalPink.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: s.riskFactors.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: TextStyle(color: _pastel.withOpacity(0.8), fontSize: 13, fontFamily: 'Pridi'))),
                      ]),
                    )).toList(),
                  ),
                ),
              ],

              if (s.recommendation.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Recommendation:', style: TextStyle(color: _teal, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _petalPink.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Text(s.recommendation, style: TextStyle(color: _pastel.withOpacity(0.8), fontSize: 13, fontFamily: 'Pridi')),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petalPink,
                    foregroundColor: _blush,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _avatar(FirestoreStudent s, {double radius = 28}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _petalPink.withOpacity(0.25),
      child: Text(
        s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
        style: TextStyle(color: _pastel, fontSize: radius * 0.8, fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
      ),
    );
  }

  Widget _riskBadge(String level) {
    final color = _riskColor(level);
    if (level.toUpperCase() == 'UNKNOWN') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.6))),
      child: Text(level.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      case 'LOW':    return Colors.yellowAccent;
      default:       return Colors.tealAccent;
    }
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _teal, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _petalPink.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Column(children: rows),
      ),
    ]);
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: _pastel.withOpacity(0.6), fontSize: 13, fontFamily: 'Pridi')),
        Text(value, style: TextStyle(color: valueColor ?? _blush, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Pridi')),
      ]),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _petalPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _petalPink : _pastel.withOpacity(0.4), width: 1.2),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? _blush : _pastel.withOpacity(0.8),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Pridi',
              fontSize: 12,
            )),
      ),
    );
  }

  Widget _studentCard(FirestoreStudent s) {
    final riskColor = _riskColor(s.riskLevel);
    return GestureDetector(
      onTap: () => _openDetail(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _petalPink.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _avatar(s),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(color: _blush, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                Text('Age ${s.age}  ·  ${s.failures} failure${s.failures == 1 ? '' : 's'}',
                    style: TextStyle(color: _pastel.withOpacity(0.55), fontSize: 12)),
                const SizedBox(height: 4),
                _riskBadge(s.riskLevel),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.chevron_right, color: _petalPink, size: 20),
                const SizedBox(height: 4),
                Text('${(s.dropoutProbability * 100).toStringAsFixed(0)}% dropout',
                    style: TextStyle(color: riskColor, fontSize: 10, fontFamily: 'Pridi')),
              ]),
            ]),
            const SizedBox(height: 12),
            Divider(color: _petalPink.withOpacity(0.2), height: 1),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _statPill('Absences', '${s.absences} days', s.absences > 15 ? Colors.redAccent : Colors.greenAccent,
                  showDot: s.absences > 15),
              _statPill('Avg Score', '${s.avgScore.toStringAsFixed(0)}%', _pastel),
              _statPill('G1 / G2', '${s.g1} / ${s.g2}', _pastel),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, String value, Color valueColor, {bool showDot = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label:', style: TextStyle(color: _pastel.withOpacity(0.45), fontSize: 10, fontFamily: 'Pridi')),
      const SizedBox(height: 2),
      Row(children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Pridi')),
        if (showDot) ...[const SizedBox(width: 4), const CircleAvatar(radius: 4, backgroundColor: Colors.redAccent)],
      ]),
    ]);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Student Database',
                        style: TextStyle(color: _pastel, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: _pastel),
                      onPressed: _fetchStudents,
                    ),
                  ]),
                  Text('AI-powered risk data', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 14, fontFamily: 'Pridi')),
                  const SizedBox(height: 16),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: _dark,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _petalPink.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Icon(Icons.search, color: _pastel.withOpacity(0.5), size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: _blush, fontFamily: 'Pridi', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by name…',
                            hintStyle: TextStyle(color: _pastel.withOpacity(0.35), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  Wrap(spacing: 8, children: [
                    _filterChip('High Risk',   _filterHighRisk,   () => setState(() => _filterHighRisk   = !_filterHighRisk)),
                    _filterChip('Medium Risk', _filterMediumRisk, () => setState(() => _filterMediumRisk = !_filterMediumRisk)),
                    _filterChip('Low Risk',    _filterLowRisk,    () => setState(() => _filterLowRisk    = !_filterLowRisk)),
                  ]),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _loading ? 'Loading…' : '${results.length} student${results.length == 1 ? '' : 's'} found',
                style: TextStyle(color: _pastel.withOpacity(0.45), fontSize: 12, fontFamily: 'Pridi'),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _petalPink))
                  : results.isEmpty
                  ? Center(child: Text('No students match.', style: TextStyle(color: _pastel.withOpacity(0.45), fontFamily: 'Pridi')))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (_, i) => _studentCard(results[i]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (Icons.home_rounded,                    'Home'),
      (Icons.supervised_user_circle_outlined, 'Teachers'),
      (Icons.school_outlined,                 'Students'),
      (Icons.settings_outlined,               'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(color: _dark, border: Border(top: BorderSide(color: _petalPink.withOpacity(0.2)))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final active = _navIndex == e.key;
          return GestureDetector(
            onTap: () {
              if (e.key == 0) { Navigator.pop(context); return; }
              if (e.key == 1) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherAnalysisPage())); return; }
              setState(() => _navIndex = e.key);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.value.$1, color: active ? _teal : _pastel.withOpacity(0.4), size: active ? 26 : 22),
              const SizedBox(height: 2),
              Text(e.value.$2, style: TextStyle(
                  color: active ? _teal : _pastel.withOpacity(0.4),
                  fontSize: 10, fontFamily: 'Pridi',
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}