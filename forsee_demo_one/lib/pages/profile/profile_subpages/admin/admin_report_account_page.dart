import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

// ─── Admin Report Page ────────────────────────────────────────────────────────
/// Routed exclusively from AdminProfilePage via Quick Actions.
/// No exports. No cross-role imports.
class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});
  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  String _selectedPeriod = 'This Month';
  final _periods = ['This Week', 'This Month', 'This Semester', 'This Year'];

  final _summaryStats = [
    {'label': 'Total Students', 'value': '500', 'icon': Icons.people},
    {'label': 'Total Teachers', 'value': '8', 'icon': Icons.person},
    {'label': 'Avg Attendance', 'value': '84%', 'icon': Icons.bar_chart},
    {'label': 'At Risk Students', 'value': '8', 'icon': Icons.warning_amber},
  ];

  final _classPerformance = [
    {'class': 'XII B', 'avg': 88, 'attendance': 91},
    {'class': 'XI A', 'avg': 82, 'attendance': 86},
    {'class': 'X B', 'avg': 79, 'attendance': 83},
    {'class': 'X A', 'avg': 76, 'attendance': 80},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('School Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                itemBuilder: (context, i) {
                  final sel = _selectedPeriod == _periods[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = _periods[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(_periods[i],
                          style: TextStyle(
                              color: sel ? AppColors.textDark : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: _summaryStats.map((s) {
                return TealCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(s['icon'] as IconData, color: AppColors.background, size: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['value'] as String,
                              style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          Text(s['label'] as String,
                              style: const TextStyle(color: Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('CLASS PERFORMANCE',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              child: Column(
                children: _classPerformance.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(c['class'] as String,
                                  style: const TextStyle(
                                      color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Text('Avg: ',
                                        style: TextStyle(color: Colors.black54, fontSize: 11)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        width: 80,
                                        child: LinearProgressIndicator(
                                          value: (c['avg'] as int) / 100,
                                          minHeight: 6,
                                          backgroundColor: Colors.black12,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.background),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${c['avg']}%',
                                        style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Text('Att: ',
                                        style: TextStyle(color: Colors.black54, fontSize: 11)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(
                                        width: 80,
                                        child: LinearProgressIndicator(
                                          value: (c['attendance'] as int) / 100,
                                          minHeight: 6,
                                          backgroundColor: Colors.black12,
                                          valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${c['attendance']}%',
                                        style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _classPerformance.length - 1)
                        const Divider(height: 1, color: AppColors.divider),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Download Full Report',
              icon: Icons.download_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading report...')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Account Page ───────────────────────────────────────────────────────
/// Routed exclusively from AdminProfilePage via Quick Actions.
class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});
  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  bool _emailNotif = true;
  bool _pushNotif = true;
  bool _smsNotif = false;
  bool _twoFactor = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const TealCard(
              child: Column(
                children: [
                  InfoRow(label: 'Admin ID', value: 'ADM-2024-001'),
                  InfoRow(label: 'School', value: 'Springfield High'),
                  InfoRow(label: 'Email', value: 'admin@school.edu'),
                  InfoRow(label: 'Role', value: 'Principal', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('NOTIFICATIONS',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Email Notifications',
                    value: _emailNotif,
                    onChanged: (v) => setState(() => _emailNotif = v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ToggleRow(
                    label: 'Push Notifications',
                    value: _pushNotif,
                    onChanged: (v) => setState(() => _pushNotif = v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _ToggleRow(
                    label: 'SMS Alerts',
                    value: _smsNotif,
                    onChanged: (v) => setState(() => _smsNotif = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('SECURITY',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Two-Factor Authentication',
                    value: _twoFactor,
                    onChanged: (v) => setState(() => _twoFactor = v),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  // Wire to your shared ChangePasswordPage from settings module
                  ActionTile(
                    label: 'Change Password',
                    isLast: true,
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (_) => const ChangePasswordPage()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('DANGER ZONE',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              child: Column(
                children: [
                  ActionTile(
                    label: 'Reset All Student Data',
                    onTap: () => _showConfirmDialog(context, 'Reset All Student Data'),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  ActionTile(
                    label: 'Export School Data',
                    isLast: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preparing export...')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to: $action?',
            style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w500))),
          Switch(value: value, activeThumbColor: AppColors.background, onChanged: onChanged),
        ],
      ),
    );
  }
}