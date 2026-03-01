import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class UploadAttendancePage extends StatefulWidget {
  const UploadAttendancePage({super.key});

  @override
  State<UploadAttendancePage> createState() => _UploadAttendancePageState();
}

class _UploadAttendancePageState extends State<UploadAttendancePage> {
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  final List<String> _classes = ['X A', 'X B', 'XI A', 'XII B'];

  final List<Map<String, dynamic>> _students = [
    {'name': 'Rohan Sharma', 'roll': '01', 'present': true},
    {'name': 'Priya Nair', 'roll': '02', 'present': true},
    {'name': 'Arjun Mehta', 'roll': '03', 'present': false},
    {'name': 'Sneha Pillai', 'roll': '04', 'present': true},
    {'name': 'Rahul Gupta', 'roll': '05', 'present': false},
    {'name': 'Ananya Singh', 'roll': '06', 'present': true},
    {'name': 'Vikram Rao', 'roll': '07', 'present': true},
    {'name': 'Meera Joshi', 'roll': '08', 'present': true},
  ];

  int get _presentCount => _students.where((s) => s['present'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Class + Date row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14),
                            hintText: 'Select Class',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          items: _classes
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedClass = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.accent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Summary bar
                TealCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryChip(
                          label: 'Present', value: '$_presentCount', color: Colors.green.shade400),
                      _SummaryChip(
                          label: 'Absent',
                          value: '${_students.length - _presentCount}',
                          color: Colors.red.shade400),
                      _SummaryChip(
                          label: 'Total', value: '${_students.length}', color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Mark all buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(
                                () => _students.forEach((s) => s['present'] = true)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade600,
                          side: BorderSide(color: Colors.green.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Mark All Present'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(
                                () => _students.forEach((s) => s['present'] = false)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Mark All Absent'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TealCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _students.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider, indent: 14),
                itemBuilder: (context, i) {
                  final s = _students[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(s['roll'],
                            style: const TextStyle(color: Colors.black45, fontSize: 12, )), //width: 20
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s['name'],
                              style: const TextStyle(
                                  color: AppColors.textDark, fontWeight: FontWeight.w500)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => s['present'] = !s['present']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: s['present']
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              s['present'] ? 'P' : 'A',
                              style: TextStyle(
                                color: s['present'] ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: PrimaryButton(
              label: 'Submit Attendance',
              icon: Icons.upload_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance submitted successfully!')),
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }
}