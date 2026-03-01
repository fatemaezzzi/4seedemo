import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ViewPastSemesterPage extends StatefulWidget {
  const ViewPastSemesterPage({super.key});

  @override
  State<ViewPastSemesterPage> createState() => _ViewPastSemesterPageState();
}

class _ViewPastSemesterPageState extends State<ViewPastSemesterPage> {
  int _selectedSemesterIndex = 0;

  final List<Map<String, dynamic>> _semesters = [
    {
      'label': 'Sem 1 – 2024',
      'avg': '82%',
      'pass': '94%',
      'top': 'Priya Nair',
      'students': 38,
    },
    {
      'label': 'Sem 2 – 2023',
      'avg': '79%',
      'pass': '91%',
      'top': 'Rohan Sharma',
      'students': 40,
    },
    {
      'label': 'Sem 1 – 2023',
      'avg': '85%',
      'pass': '96%',
      'top': 'Ananya Singh',
      'students': 37,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final sem = _semesters[_selectedSemesterIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Semester Data'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Semester History',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Semester selector
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _semesters.length,
                itemBuilder: (context, i) {
                  final selected = _selectedSemesterIndex == i;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedSemesterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _semesters[i]['label']!,
                        style: TextStyle(
                          color:
                          selected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Stats cards
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Class Avg', value: sem['avg']!)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Pass Rate', value: sem['pass']!)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Students', value: sem['students']!.toString())),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Top Student', value: sem['top']!)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${sem['label']} Summary',
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text(
                      'This semester showed consistent student performance. High-risk students were flagged and counselling sessions were arranged. Attendance maintained above 85% for majority of the class.',
                      style:
                      TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}