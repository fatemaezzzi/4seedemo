import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forsee_demo_one/services/classroom_service.dart';

class AddClassroomPage extends StatefulWidget {
  const AddClassroomPage({super.key});

  @override
  State<AddClassroomPage> createState() => _AddClassroomPageState();
}

class _AddClassroomPageState extends State<AddClassroomPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  String _selectedSemester = 'Semester I';
  String _selectedStd = 'STD 9th';
  bool _isLoading = false;

  String? _generatedCode;
  Map<String, dynamic>? _createdClassroom;

  final List<String> _semesters = ['Semester I', 'Semester II', 'Semester III', 'Semester IV'];
  final List<String> _standards = [
    'STD 4th', 'STD 5th','STD 6th', 'STD 7th', 'STD 8th',
    'STD 9th', 'STD 10th', 'STD 11th', 'STD 12th',
  ];

  // Cycles through these for new classroom cards — same colours as dashboard
  static const List<Map<String, dynamic>> _palette = [
    {'color': Color(0xFF382128), 'textColor': Colors.white},
    {'color': Color(0xFFA6768B), 'textColor': Colors.white},
    {'color': Color(0xFFF4BFDB), 'textColor': Colors.black},
    {'color': Color(0xFF4A2030), 'textColor': Colors.white},
    {'color': Color(0xFF6B3F50), 'textColor': Colors.white},
  ];

  static const _bg          = Color(0xFF512D38);
  static const _card        = Color(0xFF3B2028);
  static const _accent      = Color(0xFFA6768B);
  static const _accentLight = Color(0xFFE9C2D7);
  static const _fieldFill   = Color(0xFF4A2030);

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  // ── CREATE ───────────────────────────────────────────────────────────────────
  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await ClassroomService.createClassroom(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        semester: _selectedSemester,
        std: _selectedStd,
      );

      // Pick a stable card colour from the palette using the doc id hash
      final paletteIndex = result['id'].hashCode.abs() % _palette.length;
      final cardStyle = _palette[paletteIndex];

      setState(() {
        _generatedCode = result['classCode'];
        // Exact same map shape that _buildClassCard in TeacherDashboard expects
        _createdClassroom = {
          'title':        result['title'],
          'subject':      result['subject'],
          'semester':     result['semester'],
          'std':          result['std'],
          'participants': result['participants'],
          'color':        cardStyle['color'],
          'textColor':    cardStyle['textColor'],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // Hands the complete classroom map back to the dashboard
  void _done() => Navigator.pop(context, _createdClassroom);

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Code copied!'),
      backgroundColor: Color(0xFF4A2030),
      duration: Duration(seconds: 2),
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Classroom',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pridi',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: _generatedCode != null ? _buildSuccessCard() : _buildForm(),
        ),
      ),
    );
  }

  // ── FORM ─────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          _field(
            controller: _titleController,
            label: 'Class Title',
            hint: 'e.g. Class 12-B',
            icon: Icons.class_outlined,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          _field(
            controller: _subjectController,
            label: 'Subject',
            hint: 'e.g. Mathematics',
            icon: Icons.menu_book_outlined,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),

          _dropdown(
            label: 'Standard',
            icon: Icons.school_outlined,
            value: _selectedStd,
            items: _standards,
            onChanged: (v) => setState(() => _selectedStd = v!),
          ),
          const SizedBox(height: 14),

          _dropdown(
            label: 'Semester',
            icon: Icons.calendar_month_outlined,
            value: _selectedSemester,
            items: _semesters,
            onChanged: (v) => setState(() => _selectedSemester = v!),
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _accentLight, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'A unique 6-character class code will be generated automatically.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _create,
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
                  : const Text(
                'Create Classroom',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pridi',
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── SUCCESS CARD ─────────────────────────────────────────────────────────────
  Widget _buildSuccessCard() {
    return Column(
      children: [
        const SizedBox(height: 30),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child:
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
        ),
        const SizedBox(height: 20),

        const Text(
          'Classroom Created!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pridi',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _createdClassroom?['title'] ?? '',
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        ),
        const SizedBox(height: 36),

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            children: [
              const Text(
                'CLASS CODE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _generatedCode ?? '',
                style: const TextStyle(
                  color: _accentLight,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'Pridi',
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 16, color: _accentLight),
                label: const Text('Copy Code',
                    style: TextStyle(color: _accentLight)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _accent.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.person_add_alt_1_outlined,
                  color: Colors.white54, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Share this code with students to let them join.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _done,
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi',
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: _card,
      style: const TextStyle(color: Colors.white),
      icon: const Icon(Icons.keyboard_arrow_down, color: _accent),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
      ),
      items: items
          .map((s) => DropdownMenuItem(
        value: s,
        child:
        Text(s, style: const TextStyle(color: Colors.white)),
      ))
          .toList(),
    );
  }
}