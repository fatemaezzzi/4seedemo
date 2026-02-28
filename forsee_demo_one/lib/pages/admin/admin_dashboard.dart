import 'package:flutter/material.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/pages/settings/admin_settings_page.dart';
import 'package:forsee_demo_one/pages/student/student_database_page.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';
import 'package:forsee_demo_one/services/admin_firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── ADMIN DASHBOARD ────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedNavIndex = 0;

  // Live data
  AdminStats? _stats;
  List<ClassroomRiskData> _classroomRisks = [];
  List<Map<String, dynamic>> _recentPredictions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadClassrooms();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminFirebaseService.fetchAdminStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadClassrooms() async {
    try {
      final rooms = await AdminFirebaseService.fetchClassroomRiskData();
      if (mounted) setState(() => _classroomRisks = rooms);
    } catch (_) {}
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      case 'LOW':    return Colors.yellowAccent;
      default:       return Colors.tealAccent;
    }
  }

  // ── DIALOGS ────────────────────────────────────────────────────────────────

  void _showStudentsDialog() {
    if (_stats == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'Student Overview (${_stats!.totalStudents})',
        icon: Icons.school_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('Total Enrolled',  '${_stats!.totalStudents}', Colors.lightBlueAccent),
            _statRow('High Risk',       '${_stats!.highRiskCount}',   Colors.redAccent),
            _statRow('Medium Risk',     '${_stats!.mediumRiskCount}', Colors.orangeAccent),
            _statRow('Low Risk',        '${_stats!.lowRiskCount}',    Colors.yellowAccent),
            _statRow('No Risk / Unknown', '${_stats!.noRiskCount}',   Colors.tealAccent),
          ],
        ),
      ),
    );
  }

  void _showTeachersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BottomSheetContainer(
        title: 'Teachers (${_stats?.totalTeachers ?? '…'})',
        icon: Icons.people_alt_outlined,
        child: StreamBuilder<List<FirestoreTeacher>>(
          stream: AdminFirebaseService.streamTeachers(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFA8D0BC)),
                ),
              );
            }
            final teachers = snap.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teachers.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, i) {
                final t = teachers[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFA8D0BC),
                    child: Text(
                      t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF3B2F2F), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(t.name, style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
                  subtitle: Text(t.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                );
              },
            );
          },
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
        title: 'Critical Risk Students (${_stats?.highRiskCount ?? '…'})',
        icon: Icons.warning_amber_rounded,
        child: FutureBuilder<List<FirestoreStudent>>(
          future: AdminFirebaseService.fetchAllStudents(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              );
            }
            final highRisk = snap.data!.where((s) => s.isHighRisk).toList();
            if (highRisk.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No high-risk students found.', style: TextStyle(color: Colors.white54, fontFamily: 'Pridi')),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: highRisk.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (_, i) {
                final s = highRisk[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(s.name, style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    s.riskFactors.isNotEmpty ? s.riskFactors.join(', ') : 'Dropout risk: ${(s.dropoutProbability * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('HIGH', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontFamily: 'Pridi', fontSize: 14)),
        Text(value, style: TextStyle(color: color, fontFamily: 'Pridi', fontWeight: FontWeight.bold, fontSize: 16)),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA8D0BC)))
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Total Teachers',
                      '${_stats?.totalTeachers ?? '…'}',
                      null,
                      _showTeachersDialog,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'Total Students',
                      '${_stats?.totalStudents ?? '…'}',
                      null,
                      _showStudentsDialog,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'Critical Risk',
                      '${_stats?.highRiskCount ?? '…'}',
                      _stats != null && _stats!.highRiskCount > 0 ? '!' : null,
                      _showCriticalRiskDialog,
                      valueColor: Colors.redAccent,
                    ),
                    const SizedBox(height: 24),
                    const Text('At-Risk Classrooms Overview',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Pridi')),
                    const SizedBox(height: 10),
                    _buildAtRiskCard(),
                    const SizedBox(height: 24),
                    const Text('Recent Predictions',
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ADMIN DASHBOARD',
              style: TextStyle(
                color: Color(0xFF3B2F2F),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi',
                letterSpacing: 1.2,
              ),
            ),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF3B2F2F)),
                onPressed: () {
                  setState(() => _loading = true);
                  _loadStats();
                  _loadClassrooms();
                },
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF3B2F2F)),
                onPressed: () => AuthController.to.logout(),
                tooltip: 'Logout',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── STAT CARD ──────────────────────────────────────────────────────────────

  Widget _buildStatCard(String label, String value, String? badge, VoidCallback onTap,
      {Color? valueColor}) {
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
            Text(value,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF3B2F2F),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pridi',
                )),
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
    if (_classroomRisks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
        child: const Center(
          child: Text('No classroom data yet.', style: TextStyle(color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
        ),
      );
    }

    // Only show classrooms that have at least 1 high-risk student
    final atRisk = _classroomRisks.where((c) => c.highRiskCount > 0).toList()
      ..sort((a, b) => b.highRiskCount.compareTo(a.highRiskCount));

    if (atRisk.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
        child: const Center(
          child: Text('No high-risk classrooms! 🎉', style: TextStyle(color: Color(0xFF3B2F2F), fontFamily: 'Pridi')),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: atRisk.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        'Classroom ${c.classroomId}',
                        style: const TextStyle(color: Color(0xFF3B2F2F), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi'),
                      ),
                      Text(
                        '${c.highRiskCount} High Risk  ·  ${c.mediumRiskCount} Medium Risk',
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Pridi'),
                      ),
                      Text(
                        '${c.totalStudents} total students',
                        style: const TextStyle(color: Color(0xFF7B5B60), fontSize: 11, fontFamily: 'Pridi'),
                      ),
                    ]),
                    const Icon(Icons.chevron_right, color: Color(0xFF3B2F2F), size: 20),
                  ],
                ),
              ),
              if (i < atRisk.length - 1)
                const Divider(color: Color(0xFF3B2F2F), thickness: 0.3),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── ACTIVITY LOG (recent predictions) ────────────────────────────────────

  Widget _buildActivityLog() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminFirebaseService.streamRecentPredictions(limit: 8),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFA8D0BC)));
        }

        final items = snap.data!;
        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('No recent predictions.', style: TextStyle(color: Color(0xFF3B2F2F), fontFamily: 'Pridi'))),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: items.map((item) {
              final riskLevel  = item['risk_level'] as String? ?? 'UNKNOWN';
              final studentName = item['studentName'] as String? ?? 'Unknown';
              final ts         = item['timestamp'] as Timestamp?;
              final color      = _riskColor(riskLevel);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(Icons.analytics_outlined, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$studentName flagged as $riskLevel risk',
                            style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 12, fontFamily: 'Pridi'),
                          ),
                          if (item['recommendation'] != null)
                            Text(
                              item['recommendation'],
                              style: const TextStyle(color: Color(0xFF7B5B60), fontSize: 11, fontFamily: 'Pridi'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 2),
                          Text(_timeAgo(ts), style: const TextStyle(color: Color(0xFF7B5B60), fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(riskLevel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAnalysisPage()))
                    .then((_) => setState(() => _selectedNavIndex = 0));
              }
              if (e.key == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDatabasePage()))
                    .then((_) => setState(() => _selectedNavIndex = 0));
              }
              if (e.key == 3) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsPage()))
                    .then((_) => setState(() => _selectedNavIndex = 0));
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.value.$1,
                    color: selected ? const Color(0xFF3B2F2F) : const Color(0xFF7B8C87),
                    size: selected ? 28 : 24),
                const SizedBox(height: 2),
                Text(e.value.$2,
                    style: TextStyle(
                      color: selected ? const Color(0xFF3B2F2F) : const Color(0xFF7B8C87),
                      fontSize: 10,
                      fontFamily: 'Pridi',
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    )),
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
            Flexible(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pridi'))),
          ]),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}