import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO NAVIGATE HERE:
//
// Get.toNamed(AppRoutes.BEHAVIOUR_INCIDENT, arguments: {
//   'name':      student.name,
//   'studentId': student.studentId,
//   'standard':  student.standard,
//   'phone':     student.phone,
//   'className': student.className,
//   'subject':   student.subject,
//   'riskLevel': student.riskLevel,   // pass the RiskLevel enum value
// });
// ─────────────────────────────────────────────────────────────────────────────

class BehaviourIncident {
  final StudentModel student;
  final DateTime date;
  final String behaviourType;
  final List<String> tags;
  final String description;

  BehaviourIncident({
    required this.student,
    required this.date,
    required this.behaviourType,
    required this.tags,
    required this.description,
  });

  String get summary {
    final tagStr = tags.isNotEmpty ? tags.join(', ') : 'No tags';
    return '${behaviourType == 'Negative' ? '⚠️' : '✅'} $tagStr — ${DateFormat('dd MMM yyyy').format(date)}';
  }
}

class BehaviourIncidentPage extends StatefulWidget {
  // ✅ FIXED: no required constructor params — data comes from Get.arguments
  const BehaviourIncidentPage({super.key});

  @override
  State<BehaviourIncidentPage> createState() => _BehaviourIncidentPageState();
}

class _BehaviourIncidentPageState extends State<BehaviourIncidentPage> {

  // ── Reconstruct StudentModel from Get.arguments ───────────────────────────
  late final StudentModel _student = _buildStudentFromArgs();

  StudentModel _buildStudentFromArgs() {
    final args = (Get.arguments as Map<String, dynamic>?) ?? {};
    return StudentModel(
      name:      args['name']      as String?    ?? 'Unknown Student',
      studentId: args['studentId'] as String?    ?? '#00000',
      standard:  args['standard']  as String?    ?? '',
      phone:     args['phone']     as String?    ?? '',
      className: args['className'] as String?    ?? '',
      subject:   args['subject']   as String?    ?? '',
      riskLevel: args['riskLevel'] as RiskLevel? ?? RiskLevel.none,
    );
  }

  DateTime _selectedDate = DateTime.now();
  String _behaviourType = 'Negative';
  final Set<String> _selectedTags = {'Disruptive'};
  final TextEditingController _descController = TextEditingController();
  bool _submitted = false;

  final List<String> _negativeTags = ['Disruptive', 'Late', 'No Homework', 'Aggressive', 'Distracted', 'Absent', 'Disrespectful'];
  final List<String> _positiveTags = ['Helpful', 'Punctual', 'Participated', 'Improved', 'Leadership', 'Kind', 'Creative'];

  List<String> get _currentTags =>
      _behaviourType == 'Negative' ? _negativeTags : _positiveTags;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6B3FA0),
            onPrimary: Colors.white,
            onSurface: Color(0xFF3B2F2F),
            surface: Color(0xFFF4BFDB),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select at least one category tag.',
            style: TextStyle(fontFamily: 'Pridi')),
        backgroundColor: const Color(0xFF6B3FA0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // BehaviourIncident still uses the full StudentModel internally
    final incident = BehaviourIncident(
      student:       _student,
      date:          _selectedDate,
      behaviourType: _behaviourType,
      tags:          _selectedTags.toList(),
      description:   _descController.text.trim(),
    );

    // If a callback was registered (future use), it can be stored in args too
    setState(() => _submitted = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A2D6B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(
            _behaviourType == 'Positive'
                ? Icons.check_circle
                : Icons.warning_rounded,
            color: _behaviourType == 'Positive'
                ? Colors.greenAccent
                : Colors.orangeAccent,
          ),
          const SizedBox(width: 10),
          const Text('Incident Logged',
              style: TextStyle(
                  color: Colors.white, fontFamily: 'Pridi', fontSize: 18)),
        ]),
        content: Text(
          '$_behaviourType incident for ${_student.name} logged on '
              '${DateFormat('dd MMM yyyy').format(_selectedDate)}.\n\n'
              'Tags: ${_selectedTags.join(', ')}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // go back to previous page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done',
                style: TextStyle(
                    fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B3FA0),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Log Behavior Incident',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pridi'),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── FORM CARD ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4FBB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15), width: 1),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student card (read-only, pre-filled from args)
                      _label('Student:'),
                      const SizedBox(height: 8),
                      _darkField(
                        child: Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFE9C2D7),
                            child: Text(_student.initial,
                                style: const TextStyle(
                                    color: Color(0xFF512D38),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_student.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontFamily: 'Pridi',
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${_student.studentId}  •  ${_student.className}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Date
                      _label('Date:'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: _darkField(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Pridi'),
                              ),
                              const Icon(Icons.calendar_month,
                                  color: Colors.white54, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Behavior Type toggle
                      _label('Behavior Type:'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _behaviourType = 'Positive';
                                _selectedTags.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 48,
                              decoration: BoxDecoration(
                                color: _behaviourType == 'Positive'
                                    ? Colors.greenAccent
                                    : const Color(0xFF3D2060),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Positive (+)',
                                  style: TextStyle(
                                    color: _behaviourType == 'Positive'
                                        ? const Color(0xFF1B4D2A)
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _behaviourType = 'Negative';
                                _selectedTags.clear();
                                _selectedTags.add('Disruptive');
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 48,
                              decoration: BoxDecoration(
                                color: _behaviourType == 'Negative'
                                    ? Colors.redAccent
                                    : const Color(0xFF3D2060),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Negative (-)',
                                  style: TextStyle(
                                    color: _behaviourType == 'Negative'
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // Category Tags
                      _label('Category (Tags):'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currentTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          final accentColor = _behaviourType == 'Positive'
                              ? Colors.greenAccent
                              : Colors.orangeAccent;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                isSelected
                                    ? _selectedTags.remove(tag)
                                    : _selectedTags.add(tag);
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(0xFF3D2060),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color:
                                  isSelected ? accentColor : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontFamily: 'Pridi',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _label('Description / Notes:'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D2060),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _descController,
                          maxLines: 4,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Pridi',
                              fontSize: 14),
                          decoration: const InputDecoration(
                            hintText:
                            'Enter specific details about the incident...',
                            hintStyle:
                            TextStyle(color: Colors.white38, fontSize: 14),
                            contentPadding: EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitted ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _behaviourType == 'Positive'
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            foregroundColor: _behaviourType == 'Positive'
                                ? const Color(0xFF1B4D2A)
                                : Colors.white,
                            disabledBackgroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _behaviourType == 'Positive'
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Log $_behaviourType Incident',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pridi'),
  );

  Widget _darkField({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF3D2060),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }
}