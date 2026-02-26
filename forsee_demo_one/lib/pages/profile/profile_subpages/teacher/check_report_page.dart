import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

/// CheckReportPage — Teacher only.
/// Routed exclusively from TeacherProfilePage via Quick Actions.
class CheckReportPage extends StatefulWidget {
  const CheckReportPage({super.key});

  @override
  State<CheckReportPage> createState() => _CheckReportPageState();
}

class _CheckReportPageState extends State<CheckReportPage> {
  String _selectedTab = 'Attendance';
  final _tabs = ['Attendance', 'Results', 'Behaviour'];
  String? _selectedClass = 'X A';
  final _classes = ['X A', 'X B', 'XI A', 'XII B'];

  final _attendanceData = [
    {'name': 'Rohan Sharma', 'percent': 87, 'days': '43/50'},
    {'name': 'Priya Nair', 'percent': 96, 'days': '48/50'},
    {'name': 'Arjun Mehta', 'percent': 58, 'days': '29/50'},
    {'name': 'Sneha Pillai', 'percent': 74, 'days': '37/50'},
    {'name': 'Rahul Gupta', 'percent': 62, 'days': '31/50'},
  ];

  Color _attendanceColor(int p) {
    if (p >= 85) return Colors.green.shade400;
    if (p >= 75) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Class Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // Class selector
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedClass,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14),
                    ),
                    items: _classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClass = v),
                  ),
                ),
                const SizedBox(height: 12),
                // Report type tabs
                Row(
                  children: _tabs.map((tab) {
                    final sel = _selectedTab == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tab,
                            style: TextStyle(
                                color: sel
                                    ? AppColors.textDark
                                    : Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _attendanceData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = _attendanceData[i];
                return TealCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'] as String,
                                style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (s['percent'] as int) / 100,
                                minHeight: 5,
                                backgroundColor: Colors.black12,
                                valueColor: AlwaysStoppedAnimation(
                                    _attendanceColor(s['percent'] as int)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${s['percent']}%',
                              style: TextStyle(
                                  color: _attendanceColor(s['percent'] as int),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(s['days'] as String,
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}