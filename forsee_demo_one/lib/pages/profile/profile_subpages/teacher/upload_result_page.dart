import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class UploadResultPage extends StatefulWidget {
  const UploadResultPage({super.key});

  @override
  State<UploadResultPage> createState() => _UploadResultPageState();
}

class _UploadResultPageState extends State<UploadResultPage> {
  String? _selectedClass;
  String? _selectedExam;
  final List<String> _classes = ['X A', 'X B', 'XI A', 'XII B'];
  final List<String> _exams = ['Unit Test 1', 'Mid-term', 'Unit Test 2', 'Final'];

  final List<Map<String, dynamic>> _students = [
    {'name': 'Rohan Sharma', 'roll': '01'},
    {'name': 'Priya Nair', 'roll': '02'},
    {'name': 'Arjun Mehta', 'roll': '03'},
    {'name': 'Sneha Pillai', 'roll': '04'},
    {'name': 'Rahul Gupta', 'roll': '05'},
  ];

  final Map<String, TextEditingController> _markControllers = {};

  @override
  void initState() {
    super.initState();
    for (final s in _students) {
      _markControllers[s['roll']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _markControllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Class selector
            const Text('CLASS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
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
                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v),
              ),
            ),
            const SizedBox(height: 16),
            // Exam type
            const Text('EXAM TYPE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedExam,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14),
                  hintText: 'Select Exam',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                items: _exams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedExam = v),
              ),
            ),
            const SizedBox(height: 20),
            const Text('ENTER MARKS (out of 100)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              child: Column(
                children: _students.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(s['roll'],
                                style: const TextStyle(color: Colors.black45, fontSize: 12)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(s['name'],
                                  style: const TextStyle(
                                      color: AppColors.textDark, fontWeight: FontWeight.w500)),
                            ),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                controller: _markControllers[s['roll']],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white30,
                                  hintText: '—',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _students.length - 1)
                        const Divider(height: 1, color: AppColors.divider),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Submit Results',
              icon: Icons.upload_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Results submitted successfully!')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}