import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class ContactTeacherPage extends StatefulWidget {
  const ContactTeacherPage({super.key});

  @override
  State<ContactTeacherPage> createState() => _ContactTeacherPageState();
}

class _ContactTeacherPageState extends State<ContactTeacherPage> {
  final List<Map<String, dynamic>> _teachers = const [
    {'name': 'Mrs. Anita Desai', 'subject': 'Mathematics', 'available': true},
    {'name': 'Mr. Suresh Nair', 'subject': 'Science', 'available': false},
    {'name': 'Ms. Priya Kapoor', 'subject': 'English', 'available': true},
    {'name': 'Mr. Ramesh Yadav', 'subject': 'Social Studies', 'available': true},
    {'name': 'Ms. Kavita Singh', 'subject': 'Hindi', 'available': false},
  ];

  String? _selected;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contact Teacher')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Select Teacher',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TealCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                children: _teachers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  final isSelected = _selected == t['name'];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selected = t['name']),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white24 : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  const CircleAvatar(
                                      radius: 20, backgroundColor: Color(0xFF3D1F28)),
                                  if (t['available'])
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Colors.green, shape: BoxShape.circle),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['name'],
                                        style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w600,
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
                                  color: t['available']
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t['available'] ? 'Online' : 'Away',
                                  style: TextStyle(
                                      color: t['available'] ? Colors.green.shade700 : Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < _teachers.length - 1)
                        const Divider(height: 1, color: AppColors.divider, indent: 14),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Message',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _msgCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Write your message here...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Send Message',
              icon: Icons.send_outlined,
              onTap: () {
                if (_selected == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a teacher')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message sent to $_selected!')),
                );
                _msgCtrl.clear();
                setState(() => _selected = null);
              },
            ),
          ],
        ),
      ),
    );
  }
}