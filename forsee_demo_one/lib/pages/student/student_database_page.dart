import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';

// ── COLORS ─────────────────────────────────────────────────────────────────────
// 512D38  Mauve Shadow    (darkest background)
// B27092  Petal Pink      (mid accent)
// F4BFDB  Pastel Petal    (cards / highlights)
// FFE9F3  Lavender Blush  (light surface)
// 87BAAB  Muted Teal      (secondary accent)

const _bg         = Color(0xFF512D38);
const _petalPink  = Color(0xFFB27092);
const _pastel     = Color(0xFFF4BFDB);
const _blush      = Color(0xFFFFE9F3);
const _teal       = Color(0xFF87BAAB);
const _dark       = Color(0xFF3B2028);
const _textDark   = Color(0xFF3B2F2F);

// ── DATA MODEL ─────────────────────────────────────────────────────────────────

enum StudentRiskLevel { none, low, medium, high }

class StudentRecord {
  final String name;
  final String rollNo;
  final bool isVerified;
  final int attendance;
  final double avgScore;
  final int behaviourScore;
  final StudentRiskLevel riskLevel;
  final bool hasScholarship;
  final String className;
  final String standard;
  final String phone;

  const StudentRecord({
    required this.name,
    required this.rollNo,
    required this.isVerified,
    required this.attendance,
    required this.avgScore,
    required this.behaviourScore,
    required this.riskLevel,
    required this.hasScholarship,
    required this.className,
    required this.standard,
    required this.phone,
  });

  String get attendanceLabel {
    if (attendance < 60) return 'Low';
    if (attendance < 75) return 'Medium';
    return 'Good';
  }

  Color get attendanceColor {
    if (attendance < 60) return Colors.redAccent;
    if (attendance < 75) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
}

// ── MOCK DATA ──────────────────────────────────────────────────────────────────

final List<StudentRecord> _allStudents = [
  StudentRecord(name: 'Dhruv Rathee',   rollNo: '2090013', isVerified: true,  attendance: 55, avgScore: 62,  behaviourScore: 85, riskLevel: StudentRiskLevel.high,   hasScholarship: false, className: 'Class 10A', standard: 'Std 10th', phone: '9876543210'),
  StudentRecord(name: 'Ananya Sharma',  rollNo: '2090014', isVerified: true,  attendance: 82, avgScore: 78,  behaviourScore: 90, riskLevel: StudentRiskLevel.none,   hasScholarship: true,  className: 'Class 10A', standard: 'Std 10th', phone: '9876543211'),
  StudentRecord(name: 'Rohan Mehta',    rollNo: '2090015', isVerified: false, attendance: 48, avgScore: 44,  behaviourScore: 60, riskLevel: StudentRiskLevel.high,   hasScholarship: false, className: 'Class 9B',  standard: 'Std 9th',  phone: '9876543212'),
  StudentRecord(name: 'Priya Iyer',     rollNo: '2090016', isVerified: true,  attendance: 91, avgScore: 88,  behaviourScore: 95, riskLevel: StudentRiskLevel.none,   hasScholarship: true,  className: 'Class 11A', standard: 'Std 11th', phone: '9876543213'),
  StudentRecord(name: 'Karan Singh',    rollNo: '2090017', isVerified: true,  attendance: 67, avgScore: 55,  behaviourScore: 70, riskLevel: StudentRiskLevel.medium, hasScholarship: false, className: 'Class 9B',  standard: 'Std 9th',  phone: '9876543214'),
  StudentRecord(name: 'Meera Nair',     rollNo: '2090018', isVerified: false, attendance: 73, avgScore: 69,  behaviourScore: 80, riskLevel: StudentRiskLevel.low,    hasScholarship: true,  className: 'Class 8C',  standard: 'Std 8th',  phone: '9876543215'),
  StudentRecord(name: 'Aditya Verma',   rollNo: '2090019', isVerified: true,  attendance: 40, avgScore: 38,  behaviourScore: 45, riskLevel: StudentRiskLevel.high,   hasScholarship: false, className: 'Class 11A', standard: 'Std 11th', phone: '9876543216'),
  StudentRecord(name: 'Sneha Joshi',    rollNo: '2090020', isVerified: true,  attendance: 88, avgScore: 92,  behaviourScore: 98, riskLevel: StudentRiskLevel.none,   hasScholarship: true,  className: 'Class 12A', standard: 'Std 12th', phone: '9876543217'),
  StudentRecord(name: 'Vikram Desai',   rollNo: '2090021', isVerified: false, attendance: 60, avgScore: 51,  behaviourScore: 65, riskLevel: StudentRiskLevel.medium, hasScholarship: false, className: 'Class 8C',  standard: 'Std 8th',  phone: '9876543218'),
  StudentRecord(name: 'Pooja Pillai',   rollNo: '2090022', isVerified: true,  attendance: 79, avgScore: 74,  behaviourScore: 88, riskLevel: StudentRiskLevel.low,    hasScholarship: true,  className: 'Class 12A', standard: 'Std 12th', phone: '9876543219'),
];

// ── PAGE ───────────────────────────────────────────────────────────────────────

class StudentDatabasePage extends StatefulWidget {
  const StudentDatabasePage({super.key});

  @override
  State<StudentDatabasePage> createState() => _StudentDatabasePageState();
}

class _StudentDatabasePageState extends State<StudentDatabasePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _filterHighRisk    = false;
  bool _filterScholarship = false;
  bool _filterVerified    = false;
  int _navIndex = 2;

  // ── FILTERING ──────────────────────────────────────────────────────────────

  List<StudentRecord> get _filtered {
    return _allStudents.where((s) {
      final q = _query.toLowerCase();
      final matchesSearch      = q.isEmpty || s.name.toLowerCase().contains(q) || s.rollNo.contains(q);
      final matchesRisk        = !_filterHighRisk    || s.riskLevel == StudentRiskLevel.high;
      final matchesScholarship = !_filterScholarship || s.hasScholarship;
      final matchesVerified    = !_filterVerified    || s.isVerified;
      return matchesSearch && matchesRisk && matchesScholarship && matchesVerified;
    }).toList();
  }

  // ── DETAIL SHEET ───────────────────────────────────────────────────────────

  void _openDetail(StudentRecord s) {
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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _petalPink.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                _avatar(s, radius: 36),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: const TextStyle(color: _blush, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Text('Roll No: ${s.rollNo}', style: TextStyle(color: _pastel.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 6),
                  if (s.isVerified) _verifiedBadge(),
                ])),
                _riskBadge(s.riskLevel),
              ]),
              const SizedBox(height: 20),
              Divider(color: _petalPink.withOpacity(0.3)),
              const SizedBox(height: 12),
              _detailSection('Academic Info', [
                _detailRow('Class',     s.className),
                _detailRow('Standard',  s.standard),
                _detailRow('Avg Score', '${s.avgScore.toStringAsFixed(0)}%'),
                _detailRow('Behaviour', '${s.behaviourScore}/100'),
              ]),
              const SizedBox(height: 14),
              _detailSection('Attendance', [
                _detailRow('Percentage', '${s.attendance}%', valueColor: s.attendanceColor),
                _detailRow('Status',     s.attendanceLabel,  valueColor: s.attendanceColor),
              ]),
              const SizedBox(height: 14),
              _detailSection('Other', [
                _detailRow('Phone',       s.phone),
                _detailRow('Scholarship', s.hasScholarship ? 'Yes' : 'No', valueColor: s.hasScholarship ? _teal : _pastel),
                _detailRow('Verified',    s.isVerified     ? 'Yes' : 'No', valueColor: s.isVerified     ? _teal : _pastel),
              ]),
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

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _avatar(StudentRecord s, {double radius = 28}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _petalPink.withOpacity(0.25),
      child: Icon(Icons.person, color: _pastel.withOpacity(0.6), size: radius * 1.2),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, size: 13, color: _dark),
        SizedBox(width: 4),
        Text('Verified Record', style: TextStyle(color: _dark, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
      ]),
    );
  }

  Widget _riskBadge(StudentRiskLevel level) {
    const labels = {StudentRiskLevel.high: 'HIGH', StudentRiskLevel.medium: 'MED', StudentRiskLevel.low: 'LOW', StudentRiskLevel.none: ''};
    final colors = {StudentRiskLevel.high: Colors.redAccent, StudentRiskLevel.medium: Colors.orangeAccent, StudentRiskLevel.low: Colors.yellowAccent, StudentRiskLevel.none: Colors.transparent};
    if (level == StudentRiskLevel.none) return const SizedBox.shrink();
    final c = colors[level]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.6))),
      child: Text(labels[level]!, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _studentCard(StudentRecord s) {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(s),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: const TextStyle(color: _blush, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    Text('Roll No: ${s.rollNo}', style: TextStyle(color: _pastel.withOpacity(0.55), fontSize: 12)),
                    const SizedBox(height: 6),
                    if (s.isVerified) _verifiedBadge(),
                  ]),
                ),
                Column(children: [
                  const Icon(Icons.chevron_right, color: _petalPink, size: 20),
                  const SizedBox(height: 4),
                  _riskBadge(s.riskLevel),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: _petalPink.withOpacity(0.2), height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statPill('Attendance', '${s.attendance}%  (${s.attendanceLabel})', s.attendanceColor, showDot: s.attendance < 75),
                _statPill('Avg Score',  '${s.avgScore.toStringAsFixed(0)}%',        _pastel),
                _statPill('Behavior',   '${s.behaviourScore}/100',                  _pastel),
              ],
            ),
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

            // ── HEADER ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Database', style: TextStyle(color: _pastel, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                  Text('(Authentic Records)', style: TextStyle(color: _pastel.withOpacity(0.7), fontSize: 16, fontFamily: 'Pridi')),
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
                            hintText: 'Search Student / Roll No...',
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
                    _filterChip('High Risk',   _filterHighRisk,    () => setState(() => _filterHighRisk    = !_filterHighRisk)),
                    const SizedBox(width: 8),
                    _filterChip('Scholarship', _filterScholarship, () => setState(() => _filterScholarship = !_filterScholarship)),
                    const SizedBox(width: 8),
                    _filterChip('Verified',    _filterVerified,    () => setState(() => _filterVerified    = !_filterVerified)),
                  ]),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '${results.length} student${results.length == 1 ? '' : 's'} found',
                style: TextStyle(color: _pastel.withOpacity(0.45), fontSize: 12, fontFamily: 'Pridi'),
              ),
            ),

            // List
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text('No students match your search.', style: TextStyle(color: _pastel.withOpacity(0.45), fontFamily: 'Pridi')))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (_, i) => _studentCard(results[i]),
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
              if (e.key == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherAnalysisPage()),
                );
                return;
              }
              setState(() => _navIndex = e.key);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                e.value.$1,
                color: active ? _teal : _pastel.withOpacity(0.4),
                size: active ? 26 : 22,
              ),
              const SizedBox(height: 2),
              Text(
                e.value.$2,
                style: TextStyle(
                  color: active ? _teal : _pastel.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'Pridi',
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
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