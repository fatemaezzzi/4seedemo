import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class AdminStudentProfilePage extends StatefulWidget {
  const AdminStudentProfilePage({super.key});

  @override
  State<AdminStudentProfilePage> createState() => _AdminStudentProfilePageState();
}

class _AdminStudentProfilePageState extends State<AdminStudentProfilePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filterClass = 'All';
  final _classes = ['All', 'X A', 'X B', 'XI A', 'XII B'];

  final List<Map<String, dynamic>> _students = [
    {'name': 'Rohan Sharma', 'class': 'X A', 'roll': '01', 'attendance': 87, 'risk': false},
    {'name': 'Priya Nair', 'class': 'X A', 'roll': '02', 'attendance': 96, 'risk': false},
    {'name': 'Arjun Mehta', 'class': 'X B', 'roll': '03', 'attendance': 58, 'risk': true},
    {'name': 'Sneha Pillai', 'class': 'XI A', 'roll': '04', 'attendance': 74, 'risk': true},
    {'name': 'Rahul Gupta', 'class': 'XI A', 'roll': '05', 'attendance': 62, 'risk': true},
    {'name': 'Ananya Singh', 'class': 'XII B', 'roll': '06', 'attendance': 91, 'risk': false},
    {'name': 'Vikram Rao', 'class': 'XII B', 'roll': '07', 'attendance': 85, 'risk': false},
  ];

  List<Map<String, dynamic>> get _filtered {
    return _students.where((s) {
      final matchesSearch = s['name'].toLowerCase().contains(_query.toLowerCase());
      final matchesClass = _filterClass == 'All' || s['class'] == _filterClass;
      return matchesSearch && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Student Profiles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: 'Search student...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                // Class filter
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _classes.length,
                    itemBuilder: (context, i) {
                      final sel = _filterClass == _classes[i];
                      return GestureDetector(
                        onTap: () => setState(() => _filterClass = _classes[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(_classes[i],
                              style: TextStyle(
                                  color: sel ? AppColors.textDark : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = _filtered[i];
                return TealCard(
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(radius: 22, backgroundColor: Color(0xFF3D1F28)),
                          if (s['risk'])
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                    color: Colors.red, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'],
                                style: const TextStyle(
                                    color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text('${s['class']} • Roll ${s['roll']}',
                                    style:
                                    const TextStyle(color: Colors.black54, fontSize: 12)),
                                if (s['risk']) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('At Risk',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${s['attendance']}%',
                              style: TextStyle(
                                  color: s['attendance'] >= 85
                                      ? Colors.green.shade600
                                      : s['attendance'] >= 75
                                      ? Colors.orange.shade600
                                      : Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const Text('Attendance',
                              style: TextStyle(color: Colors.black45, fontSize: 10)),
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