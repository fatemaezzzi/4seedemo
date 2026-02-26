import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AlertsHighRiskPage extends StatefulWidget {
  const AlertsHighRiskPage({super.key});

  @override
  State<AlertsHighRiskPage> createState() => _AlertsHighRiskPageState();
}

class _AlertsHighRiskPageState extends State<AlertsHighRiskPage> {
  bool _emailAlerts = true;
  bool _pushAlerts = true;
  bool _smsAlerts = false;
  String _threshold = 'Medium';

  final _students = [
    {'name': 'Arjun Mehta', 'risk': 'High', 'reason': 'Attendance < 60%'},
    {'name': 'Sneha Pillai', 'risk': 'High', 'reason': 'Grades dropped 30%'},
    {'name': 'Rahul Gupta', 'risk': 'Medium', 'reason': 'Irregular attendance'},
  ];

  Color _riskColor(String risk) {
    if (risk == 'High') return Colors.red.shade400;
    if (risk == 'Medium') return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High Risk Alerts'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('High Risk\nAlerts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
            const SizedBox(height: 8),
            const Text(
                'Configure how you get notified about at-risk students.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 28),
            // Current flagged students
            const Text('FLAGGED STUDENTS',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, i) {
                  final s = _students[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _riskColor(s['risk']!).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.warning_rounded,
                              color: _riskColor(s['risk']!), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name']!,
                                  style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600)),
                              Text(s['reason']!,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _riskColor(s['risk']!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s['risk']!,
                              style: TextStyle(
                                  color: _riskColor(s['risk']!),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // Alert settings
            const Text('ALERT SETTINGS',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _ToggleTile(
                    label: 'Email Alerts',
                    value: _emailAlerts,
                    onChanged: (v) => setState(() => _emailAlerts = v),
                  ),
                  const Divider(
                      height: 1, color: AppColors.divider, indent: 16),
                  _ToggleTile(
                    label: 'Push Notifications',
                    value: _pushAlerts,
                    onChanged: (v) => setState(() => _pushAlerts = v),
                  ),
                  const Divider(
                      height: 1, color: AppColors.divider, indent: 16),
                  _ToggleTile(
                    label: 'SMS Alerts',
                    value: _smsAlerts,
                    onChanged: (v) => setState(() => _smsAlerts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('RISK THRESHOLD',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              children: ['Low', 'Medium', 'High'].map((t) {
                final selected = _threshold == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _threshold = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(t,
                          style: TextStyle(
                              color: selected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500))),
          Switch(
              value: value,
              activeThumbColor: AppColors.accent,
              onChanged: onChanged),
        ],
      ),
    );
  }
}