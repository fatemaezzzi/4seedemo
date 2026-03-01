import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String _selectedTab = 'All';
  final _tabs = ['All', 'Active', 'Completed'];

  final List<Map<String, dynamic>> _courses = [
    {
      'name': 'Mathematics - Grade 10',
      'classes': ['X A', 'X B'],
      'students': 72,
      'status': 'Active',
      'progress': 0.65,
      'next': 'Quadratic Equations',
    },
    {
      'name': 'Mathematics - Grade 11',
      'classes': ['XI A'],
      'students': 38,
      'status': 'Active',
      'progress': 0.42,
      'next': 'Differentiation',
    },
    {
      'name': 'Advanced Mathematics',
      'classes': ['XII B'],
      'students': 30,
      'status': 'Active',
      'progress': 0.80,
      'next': 'Integration Review',
    },
    {
      'name': 'Mathematics - Grade 9',
      'classes': ['IX A', 'IX B'],
      'students': 80,
      'status': 'Completed',
      'progress': 1.0,
      'next': '—',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_selectedTab == 'All') return _courses;
    return _courses.where((c) => c['status'] == _selectedTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Courses')),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: _tabs.map((tab) {
                final selected = _selectedTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tab,
                        style: TextStyle(
                            color: selected ? AppColors.textDark : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final c = _filtered[i];
                final bool completed = c['status'] == 'Completed';
                return TealCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c['name'],
                                style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: completed
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(c['status'],
                                style: TextStyle(
                                    color: completed ? Colors.green.shade700 : Colors.blue.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('${c['students']} students',
                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(width: 14),
                          const Icon(Icons.class_outlined, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text((c['classes'] as List).join(', '),
                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: c['progress'] as double,
                          minHeight: 6,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              completed ? Colors.green.shade400 : AppColors.background),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${((c['progress'] as double) * 100).round()}% complete',
                              style: const TextStyle(color: Colors.black54, fontSize: 11)),
                          if (!completed)
                            Text('Next: ${c['next']}',
                                style:
                                const TextStyle(color: Colors.black54, fontSize: 11)),
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