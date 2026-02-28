import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import 'package:forsee_demo_one/pages/student/report_page.dart';
import 'package:forsee_demo_one/pages/profile/student_profile_page.dart';
import 'package:forsee_demo_one/pages/settings/student_settings_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentNavIndex = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    ReportPage(),
    StudentProfilePage(),
    StudentSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstTime());
  }

  Future<void> _checkFirstTime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final quizDone = doc.data()?['quizCompleted'] as bool? ?? false;
      if (!quizDone && mounted) {
        Get.toNamed(AppRoutes.STUDENT_QUIZ_START);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: _pages[_currentNavIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HOME — loads real data from Firebase
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool   _loading       = true;
  String _studentName   = '';
  String _className     = '';
  String _rollNo        = '';
  int    _attendance    = 0;
  int    _totalDays     = 0;
  int    _presentDays   = 0;
  String _lastG2        = '—';
  String _teacherRemark = 'No remarks yet.';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // 1) users/{uid} → name, className, studentId (display), studentDocId
      final userDoc  = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      _studentName = userData['name']      as String? ?? 'Student';
      _className   = userData['className'] as String? ?? '';
      _rollNo      = userData['studentId'] as String? ?? '';

      final studentDocId = userData['studentDocId'] as String?;

      if (studentDocId != null) {
        // 2) students/{studentDocId} → G2, teacherRemark
        final studentDoc = await _db.collection('students').doc(studentDocId).get();
        final sData      = studentDoc.data() ?? {};

        final g2 = (sData['G2'] as num?)?.toInt();
        _lastG2  = g2 != null ? '$g2 / 20' : '—';

        _teacherRemark = userData['teacherRemark'] as String?
            ?? sData['teacherRemark']  as String?
            ?? 'No remarks yet.';

        // 3) staging/{studentDocId} → attendance
        final stagingDoc = await _db.collection('staging').doc(studentDocId).get();
        final att        = stagingDoc.data()?['attendance'] as Map<String, dynamic>?;
        _totalDays   = (att?['totalDays']   as num?)?.toInt() ?? 0;
        _presentDays = (att?['presentDays'] as num?)?.toInt() ?? 0;
        _attendance  = _totalDays > 0
            ? ((_presentDays / _totalDays) * 100).round()
            : 0;
      }

      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFA8D0BC)),
      );
    }

    final subtitle = _className.isNotEmpty && _rollNo.isNotEmpty
        ? '$_className | Roll No. $_rollNo'
        : _studentName;

    final attendanceLabel = _totalDays > 0
        ? 'My Attendance: $_attendance%  ($_presentDays / $_totalDays days)'
        : 'My Attendance: $_attendance%';

    return Column(children: [
      _WaveHeader(name: _studentName, subtitle: subtitle),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 24),
            _InfoTile(
              label: attendanceLabel,
              icon:  Icons.calendar_today_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _InfoTile(
              label: 'Last Test Score: $_lastG2',
              icon:  Icons.description_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _TeacherRemarksCard(remark: _teacherRemark),
            const SizedBox(height: 20),
            _PerformanceButton(
              onTap: () => Get.toNamed(AppRoutes.STUDENT_REPORT),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAVE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _WaveHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  const _WaveHeader({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFA8D0BC),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 48),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: Color(0xFF2B1F22),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pridi')),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xFF2B1F22),
                  fontSize: 14,
                  fontFamily: 'Pridi')),
        ]),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width * 0.35, size.height + 10,
        size.width * 0.6,  size.height - 25);
    path.quadraticBezierTo(
        size.width * 0.8, size.height - 50,
        size.width,       size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO TILE
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _InfoTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: const Color(0xFF6B4050),
            borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Pridi')),
          ),
          Icon(icon, color: Colors.white70, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEACHER REMARKS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TeacherRemarksCard extends StatelessWidget {
  final String remark;
  const _TeacherRemarksCard({required this.remark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFA8D0BC),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Teacher Remarks',
            style: TextStyle(
                color: Color(0xFF2B1F22),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi')),
        const SizedBox(height: 12),
        Text(remark,
            style: const TextStyle(
                color: Color(0xFF3B2F2F),
                fontSize: 13,
                fontFamily: 'Pridi',
                height: 1.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY PERFORMANCE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PerformanceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: const Color(0xFF6B4050),
            borderRadius: BorderRadius.circular(30)),
        child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Performance',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Pridi')),
              Icon(Icons.arrow_forward, color: Color(0xFFA8D0BC), size: 20),
            ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded,      'Home'),
      (Icons.bar_chart_rounded, 'Report'),
      (Icons.person_outline,    'Profile'),
      (Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      color: const Color(0xFFA8D0BC),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final selected = currentIndex == e.key;
          return GestureDetector(
            onTap: () => onTap(e.key),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(e.value.$1,
                  color: selected
                      ? const Color(0xFF2B1F22)
                      : Colors.black38,
                  size: selected ? 28 : 24),
              const SizedBox(height: 2),
              Text(e.value.$2,
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF2B1F22)
                          : Colors.black38,
                      fontSize: 10,
                      fontFamily: 'Pridi',
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}