import 'package:flutter/material.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/pages/profile/profile_subpages/student/mental_health_quiz.dart';
import '../../theme/app_theme.dart';
import 'profile_subpages/student/teacher_remarks_page.dart';
import 'profile_subpages/student/contact_teacher_page.dart';
import 'profile_subpages/shared/edit_personal_info_page.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'student profile',
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

            // Name & Class
            const Text(
              'Rohan Sharma',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'X A',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // Mental Health Quiz Button
            _ActionButton(
              label: 'Mental Health Quiz',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MentalHealthQuizPage())),
            ),
            const SizedBox(height: 16),

            // Attendance Card
            _AttendanceCard(percentage: 76),
            const SizedBox(height: 16),

            // Personal Details Card
            _PersonalDetailsCard(
              details: const {
                'Name': 'Rohan Sharma',
                'DOB': '11/02/2007',
                'Phone': '+91 98765 43210',
                'Roll No': '24',
                "Mother's Name": 'Sunita Sharma',
              },
            ),
            const SizedBox(height: 16),

            // Teacher Remarks Button
            _ActionButton(
              label: 'Teacher Remarks',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TeacherRemarksPage())),
            ),
            const SizedBox(height: 12),

            // Contact Teacher Button
            _ActionButton(
              label: 'Contact Teacher',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContactTeacherPage())),
            ),
            const SizedBox(height: 16),

            // Edit Personal Info Button
            _ActionButton(
              label: 'Edit Personal Information',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.student))),
            ),
            const SizedBox(height: 12),

            // Logout Button
            _OutlineButton(
              label: 'Logout',
              onTap: () => AuthController.to.logout(),
            ),
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

class _AttendanceCard extends StatelessWidget {
  final int percentage;
  const _AttendanceCard({required this.percentage});

  Color get _barColor {
    if (percentage >= 85) return Colors.green.shade400;
    if (percentage >= 75) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Attendance',
                  style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            percentage >= 85
                ? 'Great attendance! Keep it up.'
                : percentage >= 75
                ? 'Attendance is borderline. Try to improve.'
                : 'Low attendance. Please attend classes.',
            style: const TextStyle(color: AppColors.textDark, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  final Map<String, String> details;
  const _PersonalDetailsCard({required this.details});

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
          const Text('Personal Details',
              style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...details.entries.map((e) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                    Text(e.value,
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (e.key != details.keys.last)
                const Divider(height: 1, color: Colors.black12),
            ],
          )),
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