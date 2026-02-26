import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/settings_widget.dart';
import '../shared/change_password_page.dart';
import '../shared/linked_account_page.dart';
import '../shared/faqs_page.dart';
import '../shared/report_problem_page.dart';
import '../shared/talk_counsellor_page.dart';

class StudentSettingsPage extends StatelessWidget {
  const StudentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('student settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const ProfileHeader(
              name: 'Rohan\nSharma',
              gender: 'Male',
              age: 18,
              birthday: '11/02/2007',
            ),
            const StudentIdBadge(id: '#62626946'),
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