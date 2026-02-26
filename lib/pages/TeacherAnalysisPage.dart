import 'package:flutter/material.dart';
import 'package:forc/pages/StudentDatabasePage.dart';

// ── COLORS (matching app palette) ─────────────────────────────────────────────
const _bg        = Color(0xFF512D38);
const _petalPink = Color(0xFFB27092);
const _pastel    = Color(0xFFF4BFDB);
const _blush     = Color(0xFFFFE9F3);
const _teal      = Color(0xFF87BAAB);
const _dark      = Color(0xFF3B2028);
const _card      = Color(0xFF4A2D38);

// ── DATA MODELS ────────────────────────────────────────────────────────────────

enum ActivityLevel { low, medium, high }

class ClassRiskInfo {
  final String className;
  final int highRiskCount;
  const ClassRiskInfo({required this.className, required this.highRiskCount});
}

class TeacherRecord {
  final String name;
  final String subject;
  final int classesManaged;
  final ActivityLevel activityLevel;
  final List<ClassRiskInfo> classRisks;
  final String phone;
  final String email;
  final int totalStudents;
  final double avgClassScore;
  final int yearsExperience;

  const TeacherRecord({
    required this.name,
    required this.subject,
    required this.classesManaged,
    required this.activityLevel,
    required this.classRisks,
    required this.phone,
    required this.email,
    required this.totalStudents,
    required this.avgClassScore,
    required this.yearsExperience,
  });

  int get totalHighRisk => classRisks.fold(0, (sum, c) => sum + c.highRiskCount);

  Color get activityColor {
    switch (activityLevel) {
      case ActivityLevel.high:   return Colors.greenAccent;
      case ActivityLevel.medium: return Colors.orangeAccent;
      case ActivityLevel.low:    return Colors.redAccent;
    }
  }

  String get activityLabel {
    switch (activityLevel) {
      case ActivityLevel.high:   return 'High';
      case ActivityLevel.medium: return 'Medium';
      case ActivityLevel.low:    return 'Low';
    }
  }
}

// ── MOCK DATA ──────────────────────────────────────────────────────────────────

final List<TeacherRecord> _allTeachers = [
  TeacherRecord(
    name: 'Anita Desai', subject: 'Mathematics', classesManaged: 4,
    activityLevel: ActivityLevel.high,
    classRisks: [ClassRiskInfo(className: 'Class 10A', highRiskCount: 5), ClassRiskInfo(className: 'Class 9B', highRiskCount: 2)],
    phone: '9876501001', email: 'anita@school.edu', totalStudents: 128, avgClassScore: 74.5, yearsExperience: 8,
  ),
  TeacherRecord(
    name: 'Rajesh Kumar', subject: 'Science', classesManaged: 3,
    activityLevel: ActivityLevel.high,
    classRisks: [ClassRiskInfo(className: 'Class 9B', highRiskCount: 7), ClassRiskInfo(className: 'Class 8C', highRiskCount: 1)],
    phone: '9876501002', email: 'rajesh@school.edu', totalStudents: 96, avgClassScore: 68.2, yearsExperience: 12,
  ),
  TeacherRecord(
    name: 'Meena Shah', subject: 'English', classesManaged: 3,
    activityLevel: ActivityLevel.medium,
    classRisks: [ClassRiskInfo(className: 'Class 8C', highRiskCount: 3)],
    phone: '9876501003', email: 'meena@school.edu', totalStudents: 90, avgClassScore: 81.0, yearsExperience: 6,
  ),
  TeacherRecord(
    name: 'Arjun Patel', subject: 'History', classesManaged: 4,
    activityLevel: ActivityLevel.high,
    classRisks: [ClassRiskInfo(className: 'Class 11A', highRiskCount: 6), ClassRiskInfo(className: 'Class 12A', highRiskCount: 2)],
    phone: '9876501004', email: 'arjun@school.edu', totalStudents: 140, avgClassScore: 71.8, yearsExperience: 15,
  ),
  TeacherRecord(
    name: 'Priya Menon', subject: 'Geography', classesManaged: 2,
    activityLevel: ActivityLevel.low,
    classRisks: [ClassRiskInfo(className: 'Class 7B', highRiskCount: 1)],
    phone: '9876501005', email: 'priya@school.edu', totalStudents: 60, avgClassScore: 77.3, yearsExperience: 3,
  ),
  TeacherRecord(
    name: 'Suresh Nair', subject: 'Physics', classesManaged: 3,
    activityLevel: ActivityLevel.medium,
    classRisks: [ClassRiskInfo(className: 'Class 12A', highRiskCount: 4), ClassRiskInfo(className: 'Class 11A', highRiskCount: 2)],
    phone: '9876501006', email: 'suresh@school.edu', totalStudents: 102, avgClassScore: 65.9, yearsExperience: 10,
  ),
];

// ── PAGE ───────────────────────────────────────────────────────────────────────

class TeacherAnalysisPage extends StatefulWidget {
  const TeacherAnalysisPage({super.key});

  @override
  State<TeacherAnalysisPage> createState() => _TeacherAnalysisPageState();
}

class _TeacherAnalysisPageState extends State<TeacherAnalysisPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filterHighActivity = false;
  bool _filterCritical     = false;
  int _navIndex = 1; // Teachers tab

  // ── FILTERING ──────────────────────────────────────────────────────────────

  List<TeacherRecord> get _filtered {
    return _allTeachers.where((t) {
      final q = _query.toLowerCase();
      final matchesSearch   = q.isEmpty || t.name.toLowerCase().contains(q) || t.subject.toLowerCase().contains(q);
      final matchesActivity = !_filterHighActivity || t.activityLevel == ActivityLevel.high;
      final matchesCritical = !_filterCritical     || t.totalHighRisk >= 3;
      return matchesSearch && matchesActivity && matchesCritical;
    }).toList();
  }

  int get _criticalClassrooms => _allTeachers.where((t) => t.totalHighRisk >= 3).length;

  // ── DETAIL SHEET ───────────────────────────────────────────────────────────

  void _openDetail(TeacherRecord t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
              // Handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _petalPink.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                _avatarWidget(t, radius: 36),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.name, style: const TextStyle(color: _blush, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Text(t.subject, style: TextStyle(color: _pastel.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    CircleAvatar(radius: 5, backgroundColor: t.activityColor),
                    const SizedBox(width: 6),
                    Text('Activity: ${t.activityLabel}', style: TextStyle(color: t.activityColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ])),
              ]),

              const SizedBox(height: 20),
              Divider(color: _petalPink.withOpacity(0.3)),
              const SizedBox(height: 12),

              // Stats grid
              _detailSection('Overview', [
                _detailRow('Classes Managed', '${t.classesManaged}'),
                _detailRow('Total Students',  '${t.totalStudents}'),
                _detailRow('Avg Class Score', '${t.avgClassScore.toStringAsFixed(1)}%'),
                _detailRow('Experience',      '${t.yearsExperience} years'),
              ]),
              const SizedBox(height: 14),

              _detailSection('Contact', [
                _detailRow('Phone', t.phone),
                _detailRow('Email', t.email),
              ]),
              const SizedBox(height: 14),

              // Classroom risk breakdown
              const Text('Classroom Risk Analysis:', style: TextStyle(color: _teal, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _petalPink.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: t.classRisks.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(c.className, style: TextStyle(color: _pastel.withOpacity(0.7), fontFamily: 'Pridi', fontSize: 13)),
                      Row(children: [
                        Text('${c.highRiskCount} High Risk', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
                        const SizedBox(width: 8),
                        // Mini bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 60, height: 6,
                            child: LinearProgressIndicator(
                              value: (c.highRiskCount / 10).clamp(0.0, 1.0),
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  )).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // Recommendations
              if (t.totalHighRisk >= 3) ...[
                const Text('Recommendations:', style: TextStyle(color: _teal, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _petalPink.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    _recommendRow(Icons.people_alt_outlined,     'Schedule parent-teacher meeting'),
                    _recommendRow(Icons.psychology_outlined,      'Refer high-risk students to counselor'),
                    _recommendRow(Icons.assignment_late_outlined, 'Review academic intervention plan'),
                  ]),
                ),
                const SizedBox(height: 14),
              ],

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

  Widget _recommendRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: _teal, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: _pastel.withOpacity(0.8), fontSize: 13, fontFamily: 'Pridi'))),
      ]),
    );
  }

  // ── TEACHER CARD ───────────────────────────────────────────────────────────

  Widget _avatarWidget(TeacherRecord t, {double radius = 28}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _petalPink.withOpacity(0.25),
      child: Icon(Icons.person, color: _pastel.withOpacity(0.6), size: radius * 1.2),
    );
  }

  Widget _teacherCard(TeacherRecord t) {
    return GestureDetector(
      onTap: () => _openDetail(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _petalPink.withOpacity(0.3), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section: avatar + info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatarWidget(t),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: const TextStyle(color: _blush, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                      Text(t.subject, style: TextStyle(color: _pastel.withOpacity(0.55), fontSize: 12, fontFamily: 'Pridi')),
                      const SizedBox(height: 6),
                      Text('Classes Managed: ${t.classesManaged}', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 12, fontFamily: 'Pridi')),
                      Row(children: [
                        Text('Avg Activity: ${t.activityLabel}', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 12, fontFamily: 'Pridi')),
                        const SizedBox(width: 6),
                        CircleAvatar(radius: 5, backgroundColor: t.activityColor),
                      ]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: _petalPink, size: 20),
                ],
              ),
            ),

            Divider(color: _petalPink.withOpacity(0.2), height: 1),

            // Risk analysis section
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text('Classroom Risk Analysis:', style: TextStyle(color: _pastel.withOpacity(0.6), fontSize: 12, fontFamily: 'Pridi')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: t.classRisks.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(children: [
                    Text('${c.className}: ', style: TextStyle(color: _pastel.withOpacity(0.75), fontSize: 13, fontFamily: 'Pridi')),
                    Text('${c.highRiskCount} High Risk', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
                  ]),
                )).toList(),
              ),
            ),

            // View Classes button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _openDetail(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: _dark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Classes', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi', fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _petalPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _petalPink : _pastel.withOpacity(0.4), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _blush : _pastel.withOpacity(0.8),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Pridi',
            fontSize: 13,
          ),
        ),
      ),
    );
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

            // ── HEADER ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teacher Analysis', style: TextStyle(color: _pastel, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  const SizedBox(height: 12),

                  // Summary pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(30), border: Border.all(color: _petalPink.withOpacity(0.3))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Total Teachers: ', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 14, fontFamily: 'Pridi')),
                      Text('${_allTeachers.length}', style: const TextStyle(color: _blush, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                      Text('  |  Critical Classrooms: ', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 14, fontFamily: 'Pridi')),
                      Text('${_criticalClassrooms.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    ]),
                  ),

                  const SizedBox(height: 14),

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
                            hintText: 'Search Teacher / Subject...',
                            hintStyle: TextStyle(color: _pastel.withOpacity(0.35), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: _petalPink.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.tune, color: _pastel.withOpacity(0.7), size: 18),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  Row(children: [
                    _filterChip('High Activity', _filterHighActivity, () => setState(() => _filterHighActivity = !_filterHighActivity)),
                    const SizedBox(width: 8),
                    _filterChip('Critical',      _filterCritical,     () => setState(() => _filterCritical     = !_filterCritical)),
                  ]),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '${results.length} teacher${results.length == 1 ? '' : 's'} found',
                style: TextStyle(color: _pastel.withOpacity(0.45), fontSize: 12, fontFamily: 'Pridi'),
              ),
            ),

            // List
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text('No teachers match your search.', style: TextStyle(color: _pastel.withOpacity(0.45), fontFamily: 'Pridi')))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (_, i) => _teacherCard(results[i]),
              ),
            ),
          ],
        ),
      ),

      // ── BOTTOM NAV ──────────────────────────────────────────────────────
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
      decoration: BoxDecoration(
        color: _dark,
        border: Border(top: BorderSide(color: _petalPink.withOpacity(0.2))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final active = _navIndex == e.key;
          return GestureDetector(
            onTap: () {
              if (e.key == 0) {
                Navigator.pop(context);
                return;
              }
              if (e.key == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentDatabasePage()),
                );
                return;
              }
              setState(() => _navIndex = e.key);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.value.$1, color: active ? _teal : _pastel.withOpacity(0.4), size: active ? 26 : 22),
              const SizedBox(height: 2),
              Text(e.value.$2, style: TextStyle(
                color: active ? _teal : _pastel.withOpacity(0.4),
                fontSize: 10, fontFamily: 'Pridi',
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              )),
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