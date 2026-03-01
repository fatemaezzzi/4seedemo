import 'package:flutter/material.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import 'profile_subpages/teacher/courses_page.dart';
import 'profile_subpages/teacher/upload_attendance_page.dart';
import 'profile_subpages/teacher/upload_result_page.dart';
import 'profile_subpages/teacher/schedule_meet_page.dart';
import 'profile_subpages/teacher/check_report_page.dart';
import 'profile_subpages/shared/calendar_page.dart';
import 'profile_subpages/shared/edit_personal_info_page.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'teacher profile',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            const CircleAvatar(
              radius: 52,
              backgroundColor: Color(0xFFB8C8D0),
            ),
            const SizedBox(height: 14),

            // Name & Designation
            const Text(
              'Rohan Sharma',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Designation',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // Courses Button
            _ActionButton(label: 'Courses', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CoursesPage()))),
            const SizedBox(height: 16),

            // My Classes Card
            _MyClassesCard(classCount: 7),
            const SizedBox(height: 16),

            // Quick Actions Card
            _QuickActionsCard(
              actions: [
                _QuickAction('Upload Attendance', () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UploadAttendancePage()))),
                _QuickAction('Upload Result', () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UploadResultPage()))),
                _QuickAction('Schedule a Meet', () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScheduleMeetPage()))),
                _QuickAction('Check Report', () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CheckReportPage()))),
                _QuickAction('Calendar', () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CalendarPage()))),
              ],
            ),
            const SizedBox(height: 16),

            // Edit Personal Info Button
            _ActionButton(label: 'Edit Personal Information', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.teacher)))),
            const SizedBox(height: 12),

            // Logout Button
            _OutlineButton(label: 'Logout', onTap: () => AuthController.to.logout()),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MyClassesCard extends StatelessWidget {
  final int classCount;
  const _MyClassesCard({required this.classCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('My classes',
              style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
            '$classCount',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
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
        color: AppColors.accent.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...actions.asMap().entries.map((entry) {
            final i = entry.key;
            final action = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(action.label,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                        const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
                      ],
                    ),
                  ),
                ),
                if (i < actions.length - 1) const Divider(height: 1, color: Colors.black12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home_outlined, color: Colors.black54),
          Icon(Icons.chat_bubble_outline, color: Colors.black54),
          Icon(Icons.school_outlined, color: Colors.black54),
          Icon(Icons.settings, color: Colors.black87),
        ],
      ),
    );
  }
}