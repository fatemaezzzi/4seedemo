import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class ScheduleMeetPage extends StatefulWidget {
  const ScheduleMeetPage({super.key});

  @override
  State<ScheduleMeetPage> createState() => _ScheduleMeetPageState();
}

class _ScheduleMeetPageState extends State<ScheduleMeetPage> {
  final _titleCtrl = TextEditingController();
  final _agendaCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _meetType = 'Online';
  final List<String> _invitees = [];
  final List<String> _allContacts = [
    'Mrs. Anita Desai (Maths)',
    'Mr. Suresh Nair (Science)',
    'Rohan Sharma (Student)',
    'Priya Nair (Student)',
    'Admin Office',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _agendaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Schedule a Meet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            EditableField(
              label: 'MEETING TITLE',
              initialValue: '',
              controller: _titleCtrl,
            ),
            // Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATE',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIME',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (picked != null) setState(() => _time = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _time.format(context),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Meet type
            const Text('MEETING TYPE',
                style:
                TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: ['Online', 'In Person'].map((type) {
                final selected = _meetType == type;
                return GestureDetector(
                  onTap: () => setState(() => _meetType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(type,
                        style: TextStyle(
                            color: selected ? AppColors.textDark : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Agenda
            const Text('AGENDA',
                style:
                TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _agendaCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Describe the meeting agenda...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Invitees
            const Text('INVITE PARTICIPANTS',
                style:
                TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            TealCard(
              child: Column(
                children: _allContacts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final invited = _invitees.contains(c);
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          if (invited) {
                            _invitees.remove(c);
                          } else {
                            _invitees.add(c);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(c,
                                      style: const TextStyle(
                                          color: AppColors.textDark, fontSize: 13))),
                              Icon(
                                invited ? Icons.check_circle : Icons.add_circle_outline,
                                color: invited ? AppColors.background : Colors.black38,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < _allContacts.length - 1)
                        const Divider(height: 1, color: AppColors.divider),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Schedule Meet',
              icon: Icons.video_call_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meeting scheduled successfully!')),
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