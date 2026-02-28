// lib/pages/admin/admin_dashboard.dart
//
// Class name: AdminDashboard  ← matches app_pages.dart route exactly
// Import path used in app_pages.dart:
//   import 'package:forsee_demo_one/pages/admin/admin_dashboard.dart';

import 'package:flutter/material.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/services/admin_firebase_service.dart';
import 'package:forsee_demo_one/pages/student/student_database_page.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';
import 'package:forsee_demo_one/pages/profile/admin_profile_page.dart';
import 'package:forsee_demo_one/pages/settings/admin_settings_page.dart';

// ── COLORS ────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF512D38);
const _petalPink = Color(0xFFB27092);
const _pastel    = Color(0xFFF4BFDB);
const _blush     = Color(0xFFFFE9F3);
const _teal      = Color(0xFF87BAAB);
const _dark      = Color(0xFF3B2028);

// ── PAGE ──────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _navIndex = 0;

  AdminStats?   _stats;
  AdminProfile? _adminProfile;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final results = await Future.wait([
        AdminFirebaseService.fetchAdminStats(),
        AdminFirebaseService.fetchCurrentAdmin(),
      ]);
      if (mounted) {
        setState(() {
          _stats        = results[0] as AdminStats;
          _adminProfile = results[1] as AdminProfile?;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _petalPink,
              backgroundColor: _dark,
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 8),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildActivityFeed(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final name = _adminProfile?.name.isNotEmpty == true
        ? _adminProfile!.name
        : AuthController.to.userName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                      color: _pastel.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Pridi'),
                ),
                Text(
                  name.isNotEmpty ? name : 'Admin',
                  style: const TextStyle(
                      color: _blush,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pridi'),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfilePage()),
            ).then((_) => _loadStats()),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: _petalPink.withOpacity(0.35),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                    color: _blush,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pridi'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS GRID ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    if (_statsLoading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: _petalPink, strokeWidth: 2),
        ),
      );
    }

    final s = _stats;
    final items = [
      _StatItem(
        icon:  Icons.people_alt_outlined,
        label: 'Total Students',
        value: '${s?.totalStudents ?? 0}',
        color: _teal,
      ),
      _StatItem(
        icon:  Icons.supervised_user_circle_outlined,
        label: 'Teachers',
        value: '${s?.totalTeachers ?? 0}',
        color: _pastel,
      ),
      _StatItem(
        icon:  Icons.warning_amber_rounded,
        label: 'High Risk',
        value: '${s?.highRiskCount ?? 0}',
        color: Colors.redAccent,
      ),
      _StatItem(
        icon:  Icons.info_outline,
        label: 'Medium Risk',
        value: '${s?.mediumRiskCount ?? 0}',
        color: Colors.orangeAccent,
      ),
      _StatItem(
        icon:  Icons.check_circle_outline,
        label: 'Low Risk',
        value: '${s?.lowRiskCount ?? 0}',
        color: Colors.yellowAccent,
      ),
      _StatItem(
        icon:  Icons.verified_outlined,
        label: 'No Prediction',
        value: '${s?.noRiskCount ?? 0}',
        color: Colors.tealAccent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, i) => _StatCard(item: items[i]),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
              color: _pastel.withOpacity(0.8),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pridi'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _QuickActionButton(
              icon:  Icons.school_outlined,
              label: 'Students',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentDatabasePage()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              icon:  Icons.supervised_user_circle_outlined,
              label: 'Teachers',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherAnalysisPage()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              icon:  Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsPage()),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ── ACTIVITY FEED ─────────────────────────────────────────────────────────

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent AI Predictions',
          style: TextStyle(
              color: _pastel.withOpacity(0.8),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pridi'),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AdminFirebaseService.streamRecentPredictions(limit: 8),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _petalPink),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load predictions.',
                  style: TextStyle(
                      color: _pastel.withOpacity(0.5), fontFamily: 'Pridi'),
                ),
              );
            }

            final preds = snapshot.data ?? [];
            if (preds.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _dark, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Text(
                    'No predictions yet.',
                    style: TextStyle(
                        color: _pastel.withOpacity(0.45), fontFamily: 'Pridi'),
                  ),
                ),
              );
            }
            return Column(
              children: preds.map((p) => _PredictionTile(data: p)).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      (Icons.home_rounded,                    'Home'),
      (Icons.supervised_user_circle_outlined, 'Teachers'),
      (Icons.school_outlined,                 'Students'),
      (Icons.settings_outlined,               'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
          color: _dark,
          border: Border(top: BorderSide(color: _petalPink.withOpacity(0.2)))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final active = _navIndex == e.key;
          return GestureDetector(
            onTap: () {
              switch (e.key) {
                case 0:
                  setState(() => _navIndex = 0);
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherAnalysisPage()),
                  );
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudentDatabasePage()),
                  );
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminSettingsPage()),
                  );
              }
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                e.value.$1,
                color: active ? _teal : _pastel.withOpacity(0.4),
                size:  active ? 26 : 22,
              ),
              const SizedBox(height: 2),
              Text(
                e.value.$2,
                style: TextStyle(
                  color:      active ? _teal : _pastel.withOpacity(0.4),
                  fontSize:   10,
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
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _petalPink.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
                color:      item.color,
                fontSize:   22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi'),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color:      _pastel.withOpacity(0.6),
                fontSize:   10,
                fontFamily: 'Pridi'),
          ),
        ],
      ),
    );
  }
}

// ── QUICK ACTION BUTTON ───────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _petalPink.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: _teal, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color:      _blush,
                fontSize:   12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pridi'),
          ),
        ]),
      ),
    );
  }
}

// ── PREDICTION TILE ───────────────────────────────────────────────────────────

class _PredictionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PredictionTile({required this.data});

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      case 'LOW':    return Colors.yellowAccent;
      default:       return Colors.tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentId = data['studentId'] as String? ?? 'Unknown';
    final riskLevel = data['risk_level'] as String? ?? 'UNKNOWN';
    final dropout   = (data['dropout_probability'] as num?)?.toDouble() ?? 0.0;
    final color     = _riskColor(riskLevel);

    final displayId = studentId.length > 14
        ? '${studentId.substring(0, 14)}…'
        : studentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _petalPink.withOpacity(0.15)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.person_outline, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: $displayId',
                style: const TextStyle(
                    color:      _blush,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pridi'),
              ),
              Text(
                'Dropout prob: ${(dropout * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    color:      _pastel.withOpacity(0.55),
                    fontSize:   11,
                    fontFamily: 'Pridi'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color:        color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: color.withOpacity(0.6))),
          child: Text(
            riskLevel.toUpperCase(),
            style: TextStyle(
                color:      color,
                fontSize:   10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi'),
          ),
        ),
      ]),
    );
  }
}