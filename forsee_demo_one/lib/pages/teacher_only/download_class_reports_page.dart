import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DownloadClassReportsPage extends StatefulWidget {
  const DownloadClassReportsPage({super.key});

  @override
  State<DownloadClassReportsPage> createState() =>
      _DownloadClassReportsPageState();
}

class _DownloadClassReportsPageState extends State<DownloadClassReportsPage> {
  String _selectedFormat = 'PDF';
  String? _selectedClass;

  final _classes = ['Class 10-A', 'Class 10-B', 'Class 11-A', 'Class 12-B'];
  final _reports = [
    {'title': 'Mid-term Results', 'date': 'Nov 2024', 'size': '1.2 MB'},
    {'title': 'Attendance Summary', 'date': 'Oct 2024', 'size': '0.4 MB'},
    {'title': 'Behaviour Log', 'date': 'Sep 2024', 'size': '0.8 MB'},
    {'title': 'Final Semester Report', 'date': 'Mar 2024', 'size': '3.1 MB'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Class Reports'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Class Reports',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Download reports for your classes.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            // Filters
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedClass,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 12)),
                      hint: const Text('Select Class',
                          style:
                          TextStyle(color: AppColors.textMuted)),
                      items: _classes
                          .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedClass = v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ...['PDF', 'Excel'].map((f) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _selectedFormat == f,
                    selectedColor: AppColors.accent,
                    onSelected: (_) =>
                        setState(() => _selectedFormat = f),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _reports.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, i) {
                  final r = _reports[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.description,
                              color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['title']!,
                                  style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600)),
                              Text('${r['date']} · ${r['size']}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: AppColors.background),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Downloading ${r['title']} as $_selectedFormat...')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}