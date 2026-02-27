import 'package:flutter/material.dart';
import 'package:get/get.dart';                                      // ← ADDED
import 'package:forsee_demo_one/app/routes/app_routes.dart';        // ← ADDED
import 'package:intl/intl.dart';

class CreateMarksEntryPage extends StatefulWidget {
  const CreateMarksEntryPage({super.key});

  @override
  State<CreateMarksEntryPage> createState() => _CreateMarksEntryPageState();
}

class _CreateMarksEntryPageState extends State<CreateMarksEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _examTitleController = TextEditingController();
  final TextEditingController _maxMarksController = TextEditingController();
  final TextEditingController _passMarksController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedSubject;
  String? _selectedClass;

  final List<String> _subjects = [
    'Science',
    'Mathematics',
    'English',
    'History',
    'Geography',
    'Computer Science',
  ];

  final List<String> _classes = [
    'Class 9-C',
    'Class 10-A',
    'Class 12-B',
  ];

  // ── DATE PICKER ───────────────────────────────────────────────────────────
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF512D38),
              onPrimary: Colors.white,
              onSurface: Color(0xFF3B2F2F),
              surface: Color(0xFFF4BFDB),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF512D38),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── VALIDATION & SUBMIT ───────────────────────────────────────────────────
  void _onNext() {
    bool formValid = _formKey.currentState?.validate() ?? false;
    bool dateValid = _selectedDate != null;
    bool subjectValid = _selectedSubject != null;
    bool classValid = _selectedClass != null;

    if (!formValid || !dateValid || !subjectValid || !classValid) {
      String missing = '';
      if (!dateValid) missing += '• Date of Exam\n';
      if (!subjectValid) missing += '• Subject\n';
      if (!classValid) missing += '• Class\n';

      if (missing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in:\n$missing',
              style: const TextStyle(fontFamily: 'Pridi'),
            ),
            backgroundColor: const Color(0xFF3B2028),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // ✅ FIXED: Get.toNamed with Map arguments instead of Navigator.push
    Get.toNamed(AppRoutes.UPLOAD_HUB, arguments: {
      'examTitle': _examTitleController.text.trim(),
      'date':      DateFormat('dd/MM/yyyy').format(_selectedDate!),
      'maxMarks':  int.tryParse(_maxMarksController.text.trim()) ?? 100,
      'passMarks': int.tryParse(_passMarksController.text.trim()) ?? 35,
      'subject':   _selectedSubject!,
      'className': _selectedClass!,
    });
  }

  @override
  void dispose() {
    _examTitleController.dispose();
    _maxMarksController.dispose();
    _passMarksController.dispose();
    super.dispose();
  }

  // ── BUILD — all UI below is UNCHANGED ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Marks Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── FORM CARD ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2028),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepIndicator(),
                        const SizedBox(height: 28),

                        // ── Exam Title ─────────────────────────────────────
                        _buildLabel('Exam Title'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _examTitleController,
                          hint: 'e.g. Mid-Term I',
                          icon: Icons.edit_note,
                          validator: (val) =>
                          (val == null || val.trim().isEmpty)
                              ? 'Please enter exam title'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        // ── Subject ────────────────────────────────────────
                        _buildLabel('Subject'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: _selectedSubject,
                          hint: 'Select Subject',
                          icon: Icons.book_outlined,
                          items: _subjects,
                          onChanged: (val) =>
                              setState(() => _selectedSubject = val),
                        ),

                        const SizedBox(height: 20),

                        // ── Class ──────────────────────────────────────────
                        _buildLabel('Class'),
                        const SizedBox(height: 8),
                        _buildDropdown(
                          value: _selectedClass,
                          hint: 'Select Class',
                          icon: Icons.class_outlined,
                          items: _classes,
                          onChanged: (val) =>
                              setState(() => _selectedClass = val),
                        ),

                        const SizedBox(height: 20),

                        // ── Date picker ────────────────────────────────────
                        _buildLabel('Date of Exam'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A3439),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedDate != null
                                    ? const Color(0xFFE9C2D7).withOpacity(0.6)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: Color(0xFFE9C2D7), size: 18),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Select Date'
                                      : DateFormat('dd MMMM yyyy')
                                      .format(_selectedDate!),
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.white38
                                        : Colors.white,
                                    fontFamily: 'Pridi',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Max & Pass Marks ───────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Max Marks'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _maxMarksController,
                                    hint: '100',
                                    icon: Icons.score,
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty)
                                        return 'Required';
                                      if (int.tryParse(val.trim()) == null)
                                        return 'Numbers only';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Pass Marks'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passMarksController,
                                    hint: '35',
                                    icon: Icons.check_circle_outline,
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty)
                                        return 'Required';
                                      if (int.tryParse(val.trim()) == null)
                                        return 'Numbers only';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Summary preview ────────────────────────────────
                        _buildSummaryPreview(),

                        const SizedBox(height: 28),

                        // ── Next button ────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE9C2D7),
                              foregroundColor: const Color(0xFF3B2028),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next: Enter Scores',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Pridi',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUMMARY PREVIEW ───────────────────────────────────────────────────────
  Widget _buildSummaryPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3439),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE9C2D7).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entry Summary',
            style: TextStyle(
              color: Color(0xFFE9C2D7),
              fontWeight: FontWeight.bold,
              fontFamily: 'Pridi',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _summaryRow(Icons.edit_note, _examTitleController.text.trim()),
          if (_selectedSubject != null)
            _summaryRow(Icons.book_outlined, _selectedSubject!),
          if (_selectedClass != null)
            _summaryRow(Icons.class_outlined, _selectedClass!),
          if (_selectedDate != null)
            _summaryRow(Icons.calendar_month,
                DateFormat('dd MMMM yyyy').format(_selectedDate!)),
          if (_maxMarksController.text.isNotEmpty)
            _summaryRow(
              Icons.score,
              'Max: ${_maxMarksController.text}  |  Pass: ${_passMarksController.text.isEmpty ? '?' : _passMarksController.text}',
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP INDICATOR ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _step('1', 'Setup', true),
        _stepLine(true),
        _step('2', 'Scores', false),
        _stepLine(false),
        _step('3', 'Review', false),
      ],
    );
  }

  Widget _step(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? const Color(0xFFE9C2D7) : Colors.white12,
          child: Text(
            number,
            style: TextStyle(
              color: active ? const Color(0xFF512D38) : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFE9C2D7) : Colors.white30,
            fontSize: 11,
            fontFamily: 'Pridi',
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: active
            ? const Color(0xFFE9C2D7).withOpacity(0.5)
            : Colors.white12,
      ),
    );
  }

  // ── FIELD HELPERS ─────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontFamily: 'Pridi'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF4A3439),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFE9C2D7), size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Color(0xFFE9C2D7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle:
        const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3439),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null
              ? const Color(0xFFE9C2D7).withOpacity(0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF4A3439),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFFE9C2D7)),
          hint: Row(
            children: [
              Icon(icon, color: const Color(0xFFE9C2D7), size: 18),
              const SizedBox(width: 12),
              Text(hint,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                      fontFamily: 'Pridi')),
            ],
          ),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(icon,
                    color: const Color(0xFFE9C2D7), size: 16),
                const SizedBox(width: 12),
                Text(item,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Pridi',
                        fontSize: 14)),
              ],
            ),
          ))
              .toList(),
          onChanged: (val) {
            onChanged(val);
            setState(() {});
          },
          selectedItemBuilder: (context) => items
              .map((item) => Row(
            children: [
              Icon(icon,
                  color: const Color(0xFFE9C2D7), size: 18),
              const SizedBox(width: 12),
              Text(item,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pridi',
                      fontSize: 14)),
            ],
          ))
              .toList(),
        ),
      ),
    );
  }
}