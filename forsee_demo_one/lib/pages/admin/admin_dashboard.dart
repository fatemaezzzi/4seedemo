import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/student/student_database_page.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';

// ── DATA MODELS ────────────────────────────────────────────────────────────────

class ClassroomRiskSummary {
  final String className;
  final String teacherName;
  final int highRiskCount;

  const ClassroomRiskSummary({
    required this.className,
    required this.teacherName,
    required this.highRiskCount,
  });
}

class ActivityLogEntry {
  final String message;
  final DateTime time;
  final IconData icon;
  final Color color;

  const ActivityLogEntry({
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
  });
}

// ── ADMIN DASHBOARD ────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedNavIndex = 0;

  // ── MOCK DATA ──────────────────────────────────────────────────────────────

  final int _totalTeachers = 42;
  final int _totalStudents = 1290;
  final int _criticalRisk = 45;
  final int _avgAttendance = 88;

  final List<ClassroomRiskSummary> _atRiskClassrooms = const [
    ClassroomRiskSummary(className: 'Class 10A', teacherName: 'Anita Desai',  highRiskCount: 5),
    ClassroomRiskSummary(className: 'Class 9B',  teacherName: 'Rajesh Kumar', highRiskCount: 7),
    ClassroomRiskSummary(className: 'Class 8C',  teacherName: 'Meena Shah',   highRiskCount: 3),
    ClassroomRiskSummary(className: 'Class 11A', teacherName: 'Arjun Patel',  highRiskCount: 6),
  ];

  final List<ActivityLogEntry> _activityLog = [
    ActivityLogEntry(message: 'Anita Desai logged a behaviour incident for Riya Sharma', time: DateTime.now().subtract(const Duration(minutes: 5)),  icon: Icons.warning_amber_rounded,  color: Colors.orangeAccent),
    ActivityLogEntry(message: 'Rajesh Kumar added 7 new student marks for Class 9B',     time: DateTime.now().subtract(const Duration(minutes: 18)), icon: Icons.edit_note,              color: Colors.lightBlueAccent),
    ActivityLogEntry(message: 'New teacher Priya Menon was registered',                   time: DateTime.now().subtract(const Duration(hours: 1)),    icon: Icons.person_add_alt_1,       color: Colors.greenAccent),
    ActivityLogEntry(message: 'Meena Shah submitted a weekly report for Class 8C',        time: DateTime.now().subtract(const Duration(hours: 2)),    icon: Icons.description_outlined,   color: Colors.purpleAccent),
    ActivityLogEntry(message: 'Arjun Patel flagged Aditya Verma as High Risk',            time: DateTime.now().subtract(const Duration(hours: 3)),    icon: Icons.flag_outlined,          color: Colors.redAccent),
    ActivityLogEntry(message: 'System: Attendance sync completed for all classes',         time: DateTime.now().subtract(const Duration(hours: 5)),    icon: Icons.sync,                   color: Colors.tealAccent),
  ];

  // ── HELPERS ────────────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── DIALOGS ────────────────────────────────────────────────────────────────

  void _showTeachersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'All Teachers (42)',
        icon: Icons.people_alt_outlined,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (_, i) {
            final teachers = ['Anita Desai', 'Rajesh Kumar', 'Meena Shah', 'Arjun Patel', 'Priya Menon', 'Suresh Nair'];
            final classes  = ['Class 10A',   'Class 9B',    'Class 8C',   'Class 11A',   'Class 7B',    'Class 12A'];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFA8D0BC),
                child: Text(teachers[i][0], style: const TextStyle(color: Color(0xFF3B2F2F), fontWeight: FontWeight.bold)),
              ),
              title: Text(teachers[i], style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
              subtitle: Text(classes[i], style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            );
          },
        ),
      ),
    );
  }

  void _showStudentsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'Student Overview (1290)',
        icon: Icons.school_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('Total Enrolled',  '1290', Colors.lightBlueAccent),
            _statRow('Active Students', '1245', Colors.greenAccent),
            _statRow('High Risk',       '45',   Colors.redAccent),
            _statRow('Medium Risk',     '112',  Colors.orangeAccent),
            _statRow('Low Risk',        '203',  Colors.yellowAccent),
            _statRow('No Risk',         '930',  Colors.tealAccent),
          ],
        ),
      ),
    );
  }

  void _showCriticalRiskDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'Critical Risk Students (45)',
        icon: Icons.warning_amber_rounded,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (_, i) {
            final names   = ['Riya Sharma', 'Aditya Verma', 'Pooja Singh', 'Mohit Jain', 'Sara Thomas'];
            final classes = ['Class 10A',   'Class 11A',    'Class 9B',    'Class 8C',   'Class 9B'];
            final reasons = ['Low attendance + behaviour', 'Multiple incidents', 'Failing 3 subjects', 'No homework + absent', 'Parent not reachable'];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                child: Text(names[i][0], style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
              title: Text(names[i], style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
              subtitle: Text('${classes[i]} · ${reasons[i]}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Text('HIGH', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAttendanceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'Attendance Overview',
        icon: Icons.bar_chart_outlined,
        child: Column(
          children: [
            _attendanceBar('Class 10A', 92, Colors.greenAccent),
            _attendanceBar('Class 9B',  85, Colors.lightBlueAccent),
            _attendanceBar('Class 8C',  78, Colors.orangeAccent),
            _attendanceBar('Class 11A', 91, Colors.tealAccent),
            _attendanceBar('Class 7B',  88, Colors.purpleAccent),
            _attendanceBar('Class 12A', 95, Colors.greenAccent),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 14),
                SizedBox(width: 6),
                Text('School Average: 88%', style: TextStyle(color: Colors.white70, fontFamily: 'Pridi')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontFamily: 'Pridi', fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _attendanceBar(String label, int pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Pridi')),
          Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A3439),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatCard('Total Teachers', '$_totalTeachers', null, _showTeachersDialog),
                    const SizedBox(height: 10),
                    _buildStatCard('Total Students', '$_totalStudents', null, _showStudentsDialog),
                    const SizedBox(height: 10),
                    _buildStatCard('Critical Risk', '$_criticalRisk', '!', _showCriticalRiskDialog, valueColor: Colors.redAccent),
                    const SizedBox(height: 10),
                    _buildStatCard('Avg Attendance', '$_avgAttendance%', null, _showAttendanceDialog),
                    const SizedBox(height: 24),
                    const Text('At-Risk Classrooms Overview',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Pridi')),
                    const SizedBox(height: 10),
                    _buildAtRiskCard(),
                    const SizedBox(height: 24),
                    const Text('Recent Activity Log',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Pridi')),
                    const SizedBox(height: 10),
                    _buildActivityLog(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        color: const Color(0xFFA8D0BC),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: const Text(
          'ADMIN DASHBOARD',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Color(0xFF3B2F2F),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pridi',
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ── STAT CARD ──────────────────────────────────────────────────────────────

  Widget _buildStatCard(String label, String value, String? badge, VoidCallback onTap, {Color? valueColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFA8D0BC),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$label: ', style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 16, fontFamily: 'Pridi')),
            Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF3B2F2F), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Text(badge, style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  // ── AT-RISK CLASSROOMS ─────────────────────────────────────────────────────

  Widget _buildAtRiskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA8D0BC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: _atRiskClassrooms.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Column(
            children: [
              GestureDetector(
                onTap: () => _showClassroomDetail(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.className} (${c.teacherName}):',
                            style: const TextStyle(color: Color(0xFF3B2F2F), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi'),
                          ),
                          Text(
                            '${c.highRiskCount} High Risk',
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Pridi'),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF3B2F2F), size: 20),
                    ],
                  ),
                ),
              ),
              if (i < _atRiskClassrooms.length - 1)
                const Divider(color: Color(0xFF3B2F2F), thickness: 0.3),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showClassroomDetail(ClassroomRiskSummary c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetContainer(
        title: '${c.className} · ${c.teacherName}',
        icon: Icons.class_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('High Risk Students', '${c.highRiskCount}', Colors.redAccent),
            _statRow('Teacher', c.teacherName, Colors.lightBlueAccent),
            const SizedBox(height: 12),
            const Text('Recommended Actions', style: TextStyle(color: Colors.white70, fontFamily: 'Pridi', fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _actionChip(Icons.people_alt_outlined,     'Schedule parent-teacher meeting'),
            _actionChip(Icons.psychology_outlined,      'Refer to school counselor'),
            _actionChip(Icons.assignment_late_outlined, 'Review academic support plan'),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: const Color(0xFFA8D0BC), size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Pridi')),
      ]),
    );
  }

  // ── ACTIVITY LOG ───────────────────────────────────────────────────────────

  Widget _buildActivityLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA8D0BC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: _activityLog.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: entry.color.withOpacity(0.15),
                  child: Icon(entry.icon, color: entry.color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.message, style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 12, fontFamily: 'Pridi')),
                      const SizedBox(height: 2),
                      Text(_timeAgo(entry.time), style: const TextStyle(color: Color(0xFF7B5B60), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── BOTTOM NAV ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded,                    'Home'),
      (Icons.supervised_user_circle_outlined, 'Teachers'),
      (Icons.school_outlined,                 'Students'),
      (Icons.settings_outlined,               'Settings'),
    ];

    return Container(
      decoration: const BoxDecoration(color: Color(0xFFA8D0BC)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final selected = _selectedNavIndex == e.key;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedNavIndex = e.key);

              if (e.key == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherAnalysisPage()),
                ).then((_) => setState(() => _selectedNavIndex = 0));
              }
              if (e.key == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentDatabasePage()),
                ).then((_) => setState(() => _selectedNavIndex = 0));
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  e.value.$1,
                  color: selected ? const Color(0xFF3B2F2F) : const Color(0xFF7B8C87),
                  size: selected ? 28 : 24,
                ),
                const SizedBox(height: 2),
                Text(
                  e.value.$2,
                  style: TextStyle(
                    color: selected ? const Color(0xFF3B2F2F) : const Color(0xFF7B8C87),
                    fontSize: 10,
                    fontFamily: 'Pridi',
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── WAVE CLIPPER ───────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(size.width * 0.75, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

// ── REUSABLE BOTTOM SHEET ──────────────────────────────────────────────────────

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _BottomSheetContainer({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF3B2028),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(icon, color: const Color(0xFFA8D0BC), size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
          ]),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}