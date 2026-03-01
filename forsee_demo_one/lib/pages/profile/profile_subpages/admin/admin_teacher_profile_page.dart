import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class AdminTeacherProfilePage extends StatefulWidget {
  const AdminTeacherProfilePage({super.key});

  @override
  State<AdminTeacherProfilePage> createState() => _AdminTeacherProfilePageState();
}

class _AdminTeacherProfilePageState extends State<AdminTeacherProfilePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _teachers = [
    {
      'name': 'Mrs. Anita Desai',
      'subject': 'Mathematics',
      'classes': 4,
      'students': 152,
      'id': 'TCH-001',
      'status': 'Active',
    },
    {
      'name': 'Mr. Suresh Nair',
      'subject': 'Science',
      'classes': 3,
      'students': 114,
      'id': 'TCH-002',
      'status': 'Active',
    },
    {
      'name': 'Ms. Priya Kapoor',
      'subject': 'English',
      'classes': 5,
      'students': 190,
      'id': 'TCH-003',
      'status': 'Active',
    },
    {
      'name': 'Mr. Ramesh Yadav',
      'subject': 'Social Studies',
      'classes': 3,
      'students': 114,
      'id': 'TCH-004',
      'status': 'On Leave',
    },
    {
      'name': 'Ms. Kavita Singh',
      'subject': 'Hindi',
      'classes': 4,
      'students': 152,
      'id': 'TCH-005',
      'status': 'Active',
    },
  ];

  List<Map<String, dynamic>> get _filtered => _teachers
      .where((t) => t['name'].toLowerCase().contains(_query.toLowerCase()) ||
      t['subject'].toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Teacher Profiles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Search teacher or subject...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final t = _filtered[i];
                final onLeave = t['status'] == 'On Leave';
                return TealCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0xFF3D1F28),
                            child: Icon(Icons.person, color: Colors.white54),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['name'],
                                    style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(t['subject'],
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: onLeave
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(t['status'],
                                style: TextStyle(
                                    color: onLeave
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatPill(label: 'ID', value: t['id']),
                          _StatPill(label: 'Classes', value: '${t['classes']}'),
                          _StatPill(label: 'Students', value: '${t['students']}'),
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

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ],
    );
  }
}