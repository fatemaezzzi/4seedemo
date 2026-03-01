import 'package:flutter/material.dart';
import '../../widgets/settings_widget.dart';
import '../shared/change_password_page.dart';
import '../shared/linked_account_page.dart';
import '../shared/faqs_page.dart';
import '../shared/report_problem_page.dart';
import '../shared/talk_counsellor_page.dart';
import '../teacher_only/download_class_reports_page.dart';
import '../teacher_only/view_past_semester_page.dart';
import '../teacher_only/alerts_high_risk_page.dart';
import '../teacher_only/messages_page.dart';

class TeacherSettingsPage extends StatelessWidget {
  const TeacherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('teacher settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const ProfileHeader(
              name: 'Niti\nPatel',
              subtitle: 'Designation',
            ),
            const SizedBox(height: 8),
            const SettingsSectionTitle('Account Settings'),
            SettingsCard(items: [
              SettingsItem(
                label: 'Change Password',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage())),
              ),
              SettingsItem(
                label: 'Linked Account',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const LinkedAccountPage())),
              ),
            ]),
            const SettingsSectionTitle('Data Management'),
            SettingsCard(items: [
              SettingsItem(
                label: 'Download Class Reports',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const DownloadClassReportsPage())),
              ),
              SettingsItem(
                label: 'View Past Semester Data',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ViewPastSemesterPage())),
              ),
            ]),
            const SettingsSectionTitle('Notifications'),
            SettingsCard(items: [
              SettingsItem(
                label: 'Alerts for High Risk Students',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AlertsHighRiskPage())),
              ),
              SettingsItem(
                label: 'Messages from Admin/Student',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const MessagesPage())),
              ),
            ]),
            const SettingsSectionTitle('Help and Support'),
            SettingsCard(items: [
              SettingsItem(
                label: 'FAQs',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FAQsPage())),
              ),
              SettingsItem(
                label: 'Report a Problem',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ReportProblemPage())),
              ),
              SettingsItem(
                label: 'Talk to a Counsellor',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TalkToCounsellorPage())),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}