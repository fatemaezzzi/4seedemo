// lib/pages/teacher/create_marks_entry_page.dart
// ================================================
// BACKEND WIRED:
//  • Receives classTitle, subject, semester, students list (with firestoreIds)
//    from ClassroomPage so marks can be linked to correct Firestore documents
//  • Form validates required fields before proceeding
//  • Passes all metadata + students list forward to UploadHubPage

import 'package:flutter/material.dart';
import 'package:forsee_demo_one/pages/teacher/upload_hub_page.dart';

class CreateMarksEntryPage extends StatefulWidget {
  // Class context passed from ClassroomPage
  final String classTitle;
  final String subject;
  final String semester;
  // Each map: { 'roll': String, 'name': String, 'firestoreId': String }
  final List<Map<String, dynamic>> students;

  const CreateMarksEntryPage({
    super.key,
    this.classTitle = '',
    this.subject    = '',
    this.semester   = '',
    this.students   = const [],
  });

  @override
  State<CreateMarksEntryPage> createState() => _CreateMarksEntryPageState();
}

class _CreateMarksEntryPageState extends State<CreateMarksEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl    = TextEditingController();
  final _maxCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _subjectCtrl  = TextEditingController();
  final _classCtrl    = TextEditingController();

  DateTime _examDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-fill from classroom context
    _subjectCtrl.text = widget.subject;
    _classCtrl.text   = widget.classTitle;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _maxCtrl.dispose();
    _passCtrl.dispose();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   Color(0xFF512D38),
            onPrimary: Colors.white,
            surface:   Color(0xFFF4BFDB),
            onSurface: Color(0xFF3B2F2F),
          ),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _examDate = p);
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    final maxMarks  = int.tryParse(_maxCtrl.text.trim())  ?? 0;
    final passMarks = int.tryParse(_passCtrl.text.trim()) ?? 0;

    if (passMarks > maxMarks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pass marks cannot exceed max marks.',
            style: TextStyle(fontFamily: 'Pridi')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadHubPage(
          examTitle:  _titleCtrl.text.trim(),
          date:       '${_examDate.day}/${_examDate.month}/${_examDate.year}',
          maxMarks:   maxMarks,
          passMarks:  passMarks,
          subject:    _subjectCtrl.text.trim(),
          className:  _classCtrl.text.trim(),
          semester:   widget.semester,
          students:   widget.students,     // ← firestoreIds flow through
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(children: [

          // ── HEADER ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('Create Marks Entry',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              ),
            ]),
          ),

          // ── FORM ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  _label('Exam Title *'),
                  const SizedBox(height: 8),
                  _field(
                    controller: _titleCtrl,
                    hint: 'e.g. Unit Test 1, Mid Term...',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter exam title' : null,
                  ),

                  const SizedBox(height: 16),

                  _label('Exam Date *'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF6B3248),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_examDate.day}/${_examDate.month}/${_examDate.year}',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 15, fontFamily: 'Pridi'),
                          ),
                          const Icon(Icons.calendar_month,
                              color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Max Marks *'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _maxCtrl,
                          hint: '100',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) return 'Numbers only';
                            return null;
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Pass Marks *'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _passCtrl,
                          hint: '35',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (int.tryParse(v.trim()) == null) return 'Numbers only';
                            return null;
                          },
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  _label('Subject'),
                  const SizedBox(height: 8),
                  _field(controller: _subjectCtrl, hint: 'Science'),

                  const SizedBox(height: 16),

                  _label('Class'),
                  const SizedBox(height: 8),
                  _field(controller: _classCtrl, hint: 'Class 12-B'),

                  const SizedBox(height: 16),

                  // Students count info
                  if (widget.students.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF6B3248),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.people_outline,
                            color: Color(0xFFE9C2D7), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${widget.students.length} students from ${widget.classTitle}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13,
                              fontFamily: 'Pridi'),
                        ),
                      ]),
                    ),

                  const SizedBox(height: 32),

                  // Next button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE9C2D7),
                        foregroundColor: const Color(0xFF512D38),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Next: Enter Marks',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Pridi')),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.white70, fontSize: 13,
          fontWeight: FontWeight.w600, fontFamily: 'Pridi'));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontFamily: 'Pridi'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF6B3248),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
      ),
    );
  }
}