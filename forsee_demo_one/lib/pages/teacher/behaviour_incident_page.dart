// lib/pages/teacher/behaviour_incident_page.dart
// ================================================
// BACKEND WIRED:
//  • Reads student from Get.arguments — includes firestoreId
//  • _submit() saves to Firebase staging via PredictionService.saveBehaviour()
//    using student.firestoreId (NOT the display studentId)
//  • Returns BehaviourIncident object back to StudentProfilePage via Get.back()
//  • Submit button is disabled after save (prevents double-saving)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/services/prediction_service.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL — returned to StudentProfilePage
// ─────────────────────────────────────────────────────────────────────────────

class BehaviourIncident {
  final StudentModel student;
  final DateTime     date;
  final String       behaviourType; // 'Positive' | 'Negative'
  final List<String> tags;
  final String       description;

  BehaviourIncident({
    required this.student,
    required this.date,
    required this.behaviourType,
    required this.tags,
    required this.description,
  });

  String get summary =>
      '${DateFormat('dd MMM').format(date)}  •  $behaviourType  •  ${tags.join(', ')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class BehaviourIncidentPage extends StatefulWidget {
  const BehaviourIncidentPage({super.key});

  @override
  State<BehaviourIncidentPage> createState() => _BehaviourIncidentPageState();
}

class _BehaviourIncidentPageState extends State<BehaviourIncidentPage> {
  late final StudentModel _student = _fromArgs();

  StudentModel _fromArgs() {
    final a = (Get.arguments as Map<String, dynamic>?) ?? {};
    return StudentModel(
      name:        a['name']        as String?    ?? 'Unknown Student',
      studentId:   a['studentId']   as String?    ?? '#00000',
      firestoreId: a['firestoreId'] as String?    ?? 'unknown',
      standard:    a['standard']    as String?    ?? '',
      phone:       a['phone']       as String?    ?? '',
      className:   a['className']   as String?    ?? '',
      subject:     a['subject']     as String?    ?? '',
      riskLevel:   a['riskLevel']   as RiskLevel? ?? RiskLevel.none,
    );
  }

  DateTime      _date          = DateTime.now();
  String        _type          = 'Negative';
  final Set<String> _tags      = {'Disruptive'};
  final _descCtrl              = TextEditingController();
  bool          _submitted     = false;
  bool          _isSaving      = false;

  final _svc = PredictionService();

  final _negativeTags = ['Disruptive','Late','No Homework','Aggressive','Distracted','Absent','Disrespectful'];
  final _positiveTags = ['Helpful','Punctual','Participated','Improved','Leadership','Kind','Creative'];
  List<String> get _currentTags => _type == 'Negative' ? _negativeTags : _positiveTags;

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6B3FA0), onPrimary: Colors.white,
            onSurface: Color(0xFF3B2F2F), surface: Color(0xFFF4BFDB),
          ),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _submit() async {
    if (_tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Select at least one tag.',
            style: TextStyle(fontFamily: 'Pridi')),
        backgroundColor: const Color(0xFF6B3FA0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSaving = true);
    try {
      // Save to Firebase using firestoreId — not the display studentId
      await _svc.saveBehaviour(BehaviourData(
        studentId:    _student.firestoreId,
        negativeTags: _type == 'Negative' ? _tags.toList() : [],
        positiveTags: _type == 'Positive' ? _tags.toList() : [],
      ));
      setState(() { _submitted = true; _isSaving = false; });

      final incident = BehaviourIncident(
        student:       _student,
        date:          _date,
        behaviourType: _type,
        tags:          _tags.toList(),
        description:   _descCtrl.text.trim(),
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF4A2D6B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(
              _type == 'Positive' ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: _type == 'Positive' ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            const Text('Incident Logged',
                style: TextStyle(color: Colors.white, fontFamily: 'Pridi', fontSize: 18)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_type incident for ${_student.name} on '
                '${DateFormat('dd MMM yyyy').format(_date)}.',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Tags: ${_tags.join(', ')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (_descCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_descCtrl.text.trim(),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFE9C2D7), size: 14),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Prediction auto-runs when attendance, marks & quiz are also complete.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                )),
              ]),
            ),
          ]),
          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();                  // close dialog
                Get.back(result: incident);  // return incident to StudentProfilePage
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9C2D7),
                foregroundColor: const Color(0xFF512D38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = _type == 'Positive' ? Colors.greenAccent : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF6B3FA0),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Get.back(),
              ),
              const Expanded(
                child: Text('Behaviour Incident',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              ),
              if (_submitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Saved ✓',
                      style: TextStyle(color: Color(0xFF1B4D2A), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ]),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Student (read-only)
                _lbl('Student:'),
                const SizedBox(height: 8),
                _box(Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFE9C2D7),
                    child: Text(_student.initial,
                        style: const TextStyle(color: Color(0xFF512D38),
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_student.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15,
                            fontFamily: 'Pridi', fontWeight: FontWeight.w600)),
                    Text('${_student.studentId}  •  ${_student.className}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ])),
                ])),

                const SizedBox(height: 16),

                // Date
                _lbl('Date:'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: _box(Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_date),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Pridi')),
                      const Icon(Icons.calendar_month, color: Colors.white54, size: 18),
                    ],
                  )),
                ),

                const SizedBox(height: 16),

                // Positive / Negative toggle
                _lbl('Behavior Type:'),
                const SizedBox(height: 10),
                Row(children: [
                  _typeBtn('Positive', Colors.greenAccent, const Color(0xFF1B4D2A)),
                  const SizedBox(width: 10),
                  _typeBtn('Negative', Colors.redAccent, Colors.white),
                ]),

                const SizedBox(height: 16),

                // Tags
                _lbl('Category (Tags):'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _currentTags.map((tag) {
                    final sel = _tags.contains(tag);
                    return GestureDetector(
                      onTap: () => setState(() => sel ? _tags.remove(tag) : _tags.add(tag)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Colors.transparent : const Color(0xFF3D2060),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? accent : Colors.transparent, width: 2),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                              color: sel ? accent : Colors.white,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'Pridi', fontSize: 14,
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Description
                _lbl('Description / Notes:'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF3D2060), borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter specific details about the incident...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: (_submitted || _isSaving) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _type == 'Positive' ? Colors.greenAccent : Colors.redAccent,
                      foregroundColor: _type == 'Positive' ? const Color(0xFF1B4D2A) : Colors.white,
                      disabledBackgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_type == 'Positive' ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(_submitted ? 'Logged ✓' : 'Log $_type Incident',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Text(t, style: const TextStyle(
      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Pridi'));

  Widget _box(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: const Color(0xFF3D2060), borderRadius: BorderRadius.circular(12)),
    child: child,
  );

  Widget _typeBtn(String type, Color activeColor, Color textColor) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _tags.clear();
          if (type == 'Negative') _tags.add('Disruptive');
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFF3D2060),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(child: Text(
            type == 'Positive' ? 'Positive (+)' : 'Negative (-)',
            style: TextStyle(
              color: active ? textColor : Colors.white70,
              fontWeight: FontWeight.bold, fontFamily: 'Pridi', fontSize: 15,
            ),
          )),
        ),
      ),
    );
  }
}