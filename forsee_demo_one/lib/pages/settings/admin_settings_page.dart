import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/profile/admin_profile_page.dart';
import 'package:forsee_demo_one/services/admin_firebase_service.dart';
import 'package:forsee_demo_one/pages/settings/settings_widget.dart';
import '../shared/change_password_page.dart';
import '../shared/linked_account_page.dart';
import '../shared/faqs_page.dart';
import '../shared/report_problem_page.dart';
import '../shared/talk_counsellor_page.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  AdminProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await AdminFirebaseService.fetchCurrentAdmin();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name     = _profile?.name     ?? '—';
    final email    = _profile?.email    ?? '—';
    final schoolId = _profile?.schoolId ?? '—';

    // We show role as a readable badge-style detail
    // Admin settings don't have a student ID — we repurpose the badge for school ID
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Real profile header from Firestore
            ProfileHeader(
              name: name,
              subtitle: email,
            ),

            // Show school ID as a badge
            if (schoolId.isNotEmpty && schoolId != '—')
              SchoolIdBadge(id: 'School: $schoolId'),

            const SettingsSectionTitle('Account Settings'),
            SettingsCard(items: [
              SettingsItem(
                label: 'Change Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage()),
                ),
              ),
              SettingsItem(
                label: 'Linked Account',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LinkedAccountPage()),
                ),
              ),
              SettingsItem(
                label: 'Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminProfilePage()),
                ).then((_) => _loadProfile()),
              ),
            ]),

            const SettingsSectionTitle('Help and Support'),
            SettingsCard(items: [
              SettingsItem(
                label: 'FAQs',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FAQsPage()),
                ),
              ),
              SettingsItem(
                label: 'Report a Problem',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReportProblemPage()),
                ),
              ),
              SettingsItem(
                label: 'Talk to a Counsellor',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TalkToCounsellorPage()),
                ),
              ),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}