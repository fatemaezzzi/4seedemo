import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class TeacherRemarksPage extends StatelessWidget {
  const TeacherRemarksPage({super.key});

  final List<Map<String, dynamic>> _remarks = const [
    {
      'teacher': 'Mrs. Anita Desai',
      'subject': 'Mathematics',
      'date': '15 Feb 2025',
      'remark': 'Rohan has shown significant improvement in algebra. His problem-solving approach is commendable. Needs to focus more on geometry.',
      'type': 'positive',
    },
    {
      'teacher': 'Mr. Suresh Nair',
      'subject': 'Science',
      'date': '10 Feb 2025',
      'remark': 'Good participation in lab sessions. Written work needs improvement. Please revise Chapter 5 before the next assessment.',
      'type': 'neutral',
    },
    {
      'teacher': 'Ms. Priya Kapoor',
      'subject': 'English',
      'date': '5 Feb 2025',
      'remark': 'Excellent essay writing skills. Creative thinking is evident. Should participate more in class discussions.',
      'type': 'positive',
    },
    {
      'teacher': 'Mr. Ramesh Yadav',
      'subject': 'Social Studies',
      'date': '28 Jan 2025',
      'remark': 'Attendance in this subject has been inconsistent. Please ensure regular attendance and submission of pending assignments.',
      'type': 'negative',
    },
  ];

  Color _typeColor(String type) {
    if (type == 'positive') return Colors.green.shade400;
    if (type == 'negative') return Colors.red.shade400;
    return Colors.orange.shade400;
  }

  IconData _typeIcon(String type) {
    if (type == 'positive') return Icons.thumb_up_outlined;
    if (type == 'negative') return Icons.warning_amber_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Teacher Remarks')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _remarks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final r = _remarks[i];
          return TealCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _typeColor(r['type']).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_typeIcon(r['type']),
                          color: _typeColor(r['type']), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['teacher'],
                              style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text(r['subject'],
                              style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(r['date'],
                        style: const TextStyle(color: Colors.black45, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),
                Text(r['remark'],
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 13, height: 1.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}