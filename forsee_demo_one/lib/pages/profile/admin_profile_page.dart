import 'package:flutter/material.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/services/admin_firebase_service.dart';
import '../../theme/app_theme.dart';
import 'profile_subpages/admin/admin_student_profile_page.dart';
import 'profile_subpages/admin/admin_teacher_profile_page.dart';
import 'profile_subpages/admin/admin_report_account_page.dart';
import 'profile_subpages/teacher/check_report_page.dart';
import 'profile_subpages/shared/calendar_page.dart';
import 'profile_subpages/shared/edit_personal_info_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  AdminProfile? _profile;
  AdminStats?   _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminFirebaseService.fetchCurrentAdmin(),
        AdminFirebaseService.fetchAdminStats(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as AdminProfile?;
          _stats   = results[1] as AdminStats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name     = _profile?.name     ?? 'Admin';
    final schoolId = _profile?.schoolId ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Admin Profile',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.accent.withOpacity(0.6),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'School: $schoolId',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // Profile Button
            _ActionButton(
              label: 'Edit Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const EditPersonalInfoPage(role: UserRole.admin)),
              ).then((_) => _load()),
            ),
            const SizedBox(height: 16),

            // Stats Grid — live from Firestore
            if (_stats != null)
              _StatsGrid(
                stats: [
                  _StatItem(
                      value: '${_stats!.totalTeachers}',
                      label: 'Total\nTeachers'),
                  _StatItem(
                      value: '${_stats!.totalStudents}',
                      label: 'Total\nStudents'),
                  _StatItem(
                      value: '${_stats!.highRiskCount}',
                      label: 'High\nRisk'),
                  _StatItem(
                      value: '${_stats!.mediumRiskCount}',
                      label: 'Medium\nRisk'),
                ],
              ),
            const SizedBox(height: 16),

            // Quick Actions Card
            _QuickActionsCard(
              actions: [
                _QuickAction(
                    'Student Profiles',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const AdminStudentProfilePage()))),
                _QuickAction(
                    'Teacher Profiles',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const AdminTeacherProfilePage()))),
                _QuickAction(
                    'Report',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminReportPage()))),
                _QuickAction(
                    'Account',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminAccountPage()))),
                _QuickAction(
                    'Calendar',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalendarPage()))),
                _QuickAction(
                    'Check Reports',
                        () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckReportPage()))),
              ],
            ),
            const SizedBox(height: 16),

            _ActionButton(
              label: 'Edit Personal Information',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const EditPersonalInfoPage(role: UserRole.admin)),
              ).then((_) => _load()),
            ),
            const SizedBox(height: 12),

            _OutlineButton(
                label: 'Logout',
                onTap: () => AuthController.to.logout()),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

// ─── Stat Model ─────────────────────────────────────────────

class _StatItem {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});
}

// ─── Shared Widgets ─────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child:
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child:
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map((s) => _StatCard(item: s)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.value,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1),
          ),
          Text(
            item.label,
            style: const TextStyle(
                color: AppColors.textDark, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Model ──────────────────────────────────────

class _QuickAction {
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.onTap);
}

class _QuickActionsCard extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionsCard({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...actions.asMap().entries.map((entry) {
            final i      = entry.key;
            final action = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(action.label,
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const Icon(Icons.chevron_right,
                            color: Colors.black38, size: 18),
                      ],
                    ),
                  ),
                ),
                if (i < actions.length - 1)
                  const Divider(height: 1, color: Colors.black12),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home_outlined, color: Colors.black54),
          Icon(Icons.chat_bubble_outline, color: Colors.black54),
          Icon(Icons.school_outlined, color: Colors.black54),
          Icon(Icons.settings, color: Colors.black87),
        ],
      ),
    );
  }
}