// lib/pages/teacher/teacher_feedback_page.dart
// ==============================================
// Teacher logs what she did with an AI suggestion and how the student responded.
//
// NAVIGATION (from StudentProfilePage):
//   Get.toNamed(AppRoutes.TEACHER_FEEDBACK, arguments: {
//     'studentId':   student.firestoreId,
//     'studentName': student.name,
//     'suggestion':  'Assign Peer Mentor',   // the tapped AI suggestion text
//   });
//
// On success the page pops with a TeacherFeedback object so the
// caller can refresh its local state immediately.
//
// Firestore write:  feedback/{auto-id}
// Firestore read:   feedback where studentId == firestoreId (live stream)

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/services/feedback_service.dart';

class TeacherFeedbackPage extends StatefulWidget {
  const TeacherFeedbackPage({super.key});

  @override
  State<TeacherFeedbackPage> createState() => _TeacherFeedbackPageState();
}

class _TeacherFeedbackPageState extends State<TeacherFeedbackPage>
    with SingleTickerProviderStateMixin {
  // ── Args ─────────────────────────────────────────────────────────────────
  late final Map<String, dynamic> _args =
      (Get.arguments as Map<String, dynamic>?) ?? {};

  late final String _studentId   = _args['studentId']   as String? ?? '';
  late final String _studentName = _args['studentName'] as String? ?? 'Student';
  late final String _suggestion  = _args['suggestion']  as String? ?? '';

  final _service = FeedbackService();

  // ── Tab controller ────────────────────────────────────────────────────────
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _actionCtrl.dispose();
    _responseCtrl.dispose();
    _followUpCtrl.dispose();
    super.dispose();
  }

  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _actionCtrl   = TextEditingController();
  final _responseCtrl = TextEditingController();
  final _followUpCtrl = TextEditingController();

  String _outcome       = 'neutral';   // 'positive' | 'neutral' | 'negative'
  bool   _followUp      = false;
  bool   _saving        = false;

  // ── Outcome options ───────────────────────────────────────────────────────
  static const _outcomes = [
    {'value': 'positive', 'label': 'Positive',  'emoji': '✅', 'color': Color(0xFF4CAF50)},
    {'value': 'neutral',  'label': 'Neutral',   'emoji': '➖', 'color': Color(0xFFA6768B)},
    {'value': 'negative', 'label': 'Needs More','emoji': '🔄', 'color': Color(0xFFFF7043)},
  ];

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _service.saveFeedback(
        studentId:       _studentId,
        studentName:     _studentName,
        suggestion:      _suggestion,
        actionTaken:     _actionCtrl.text.trim(),
        studentResponse: _responseCtrl.text.trim(),
        responseOutcome: _outcome,
        followUpNeeded:  _followUp,
        followUpNote:    _followUpCtrl.text.trim(),
      );

      if (!mounted) return;
      _showSuccessSnack();
      // Switch to history tab so teacher immediately sees her new entry
      _tabs.animateTo(1);
      // Clear form
      _actionCtrl.clear();
      _responseCtrl.clear();
      _followUpCtrl.clear();
      setState(() {
        _outcome   = 'neutral';
        _followUp  = false;
        _saving    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showErrorSnack('Failed to save: $e');
    }
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
        SizedBox(width: 8),
        Text('Feedback saved!', style: TextStyle(fontFamily: 'Pridi')),
      ]),
      backgroundColor: const Color(0xFF3B2028),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Pridi')),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _deleteFeedback(String feedbackId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete entry?',
            style: TextStyle(color: Colors.white, fontFamily: 'Pridi')),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFE9C2D7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteFeedback(feedbackId);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildSuggestionChip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildLogForm(),
                _buildHistory(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B2028),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Feedback Log',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            Text(_studentName,
                style: const TextStyle(color: Color(0xFFE9C2D7),
                    fontSize: 13, fontFamily: 'Pridi')),
          ]),
        ),
        // Feedback loop icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFA6768B),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.loop_rounded, color: Colors.white, size: 22),
        ),
      ]),
    );
  }

  // ── SUGGESTION CHIP ───────────────────────────────────────────────────────

  Widget _buildSuggestionChip() {
    if (_suggestion.isEmpty) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B2028),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA6768B), width: 1),
        ),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline,
              color: Color(0xFFF4BFDB), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_suggestion,
                style: const TextStyle(color: Color(0xFFE9C2D7),
                    fontSize: 13, fontFamily: 'Pridi')),
          ),
        ]),
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF3B2028),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: const Color(0xFFA6768B),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontFamily: 'Pridi',
              fontWeight: FontWeight.bold,
              fontSize: 13),
          tabs: const [
            Tab(text: 'Log Action'),
            Tab(text: 'History'),
          ],
        ),
      ),
    );
  }

  // ── LOG FORM ──────────────────────────────────────────────────────────────

  Widget _buildLogForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── What did you do? ───────────────────────────────────────────
          _sectionLabel('What did you do?', Icons.edit_note_rounded),
          const SizedBox(height: 8),
          _textArea(
            controller: _actionCtrl,
            hint: 'Describe the action you took with this student…\n'
                'e.g. "Spoke to Ayaan privately after class, paired him with Rohan as peer mentor"',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please describe what you did'
                : null,
          ),

          const SizedBox(height: 22),

          // ── Student's response ─────────────────────────────────────────
          _sectionLabel('Student\'s response', Icons.person_outline),
          const SizedBox(height: 8),
          _textArea(
            controller: _responseCtrl,
            hint: 'How did the student react or respond?\n'
                'e.g. "Initially resistant but engaged more in the next session"',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please describe the student\'s response'
                : null,
          ),

          const SizedBox(height: 22),

          // ── Outcome ────────────────────────────────────────────────────
          _sectionLabel('Outcome', Icons.bar_chart_rounded),
          const SizedBox(height: 8),
          Row(
            children: _outcomes.map((o) {
              final selected = _outcome == o['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _outcome = o['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? (o['color'] as Color).withOpacity(0.25)
                          : const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? (o['color'] as Color)
                            : Colors.white12,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Text(o['emoji'] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(o['label'] as String,
                          style: TextStyle(
                              color: selected
                                  ? (o['color'] as Color)
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pridi')),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // ── Follow-up toggle ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B2028),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.alarm_outlined,
                  color: Color(0xFFE9C2D7), size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Follow-up needed?',
                    style: TextStyle(color: Colors.white,
                        fontFamily: 'Pridi', fontSize: 14)),
              ),
              Switch(
                value: _followUp,
                onChanged: (v) => setState(() => _followUp = v),
                activeColor: const Color(0xFFE9C2D7),
                activeTrackColor: const Color(0xFFA6768B),
                inactiveThumbColor: Colors.white30,
                inactiveTrackColor: Colors.white10,
              ),
            ]),
          ),

          if (_followUp) ...[
            const SizedBox(height: 10),
            _textArea(
              controller: _followUpCtrl,
              hint: 'What needs to happen next?\n'
                  'e.g. "Check in again next week, monitor attendance"',
              minLines: 2,
            ),
          ],

          const SizedBox(height: 30),

          // ── Submit button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9C2D7),
                foregroundColor: const Color(0xFF512D38),
                disabledBackgroundColor: const Color(0xFFE9C2D7).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF512D38)))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.save_rounded, size: 20),
                SizedBox(width: 8),
                Text('Save Feedback',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── HISTORY TAB ───────────────────────────────────────────────────────────

  Widget _buildHistory() {
    if (_studentId.isEmpty) {
      return const Center(
        child: Text('No student ID provided',
            style: TextStyle(color: Colors.white38, fontFamily: 'Pridi')),
      );
    }

    return StreamBuilder<List<TeacherFeedback>>(
      stream: _service.streamFeedbackForStudent(_studentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE9C2D7)));
        }

        final entries = snap.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B2028),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_outlined,
                    color: Color(0xFFA6768B), size: 36),
              ),
              const SizedBox(height: 16),
              const Text('No feedback logged yet',
                  style: TextStyle(color: Colors.white60,
                      fontFamily: 'Pridi', fontSize: 15)),
              const SizedBox(height: 6),
              const Text('Switch to "Log Action" to add the first entry',
                  style: TextStyle(color: Colors.white30, fontSize: 12)),
            ]),
          );
        }

        // Summary bar
        final pos = entries.where((e) => e.isPositive).length;
        final neg = entries.where((e) => e.isNegative).length;
        final neu = entries.length - pos - neg;

        return Column(children: [
          // ── Summary strip ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2028),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryChip('${entries.length}', 'Total',    Colors.white70),
                  _vDivider(),
                  _summaryChip('$pos', 'Positive', const Color(0xFF4CAF50)),
                  _vDivider(),
                  _summaryChip('$neu', 'Neutral',  const Color(0xFFA6768B)),
                  _vDivider(),
                  _summaryChip('$neg', 'More Work',const Color(0xFFFF7043)),
                ],
              ),
            ),
          ),

          // ── Entry list ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
              itemCount: entries.length,
              itemBuilder: (_, i) => _buildHistoryCard(entries[i]),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildHistoryCard(TeacherFeedback fb) {
    final outcomeColor = fb.isPositive
        ? const Color(0xFF4CAF50)
        : fb.isNegative
        ? const Color(0xFFFF7043)
        : const Color(0xFFA6768B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2028),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: outcomeColor.withOpacity(0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: outcomeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outcomeColor.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(fb.outcomeEmoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(fb.responseOutcome == 'negative'
                    ? 'Needs More Work'
                    : fb.responseOutcome.capitalizeFirst ?? '',
                    style: TextStyle(color: outcomeColor,
                        fontSize: 11, fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi')),
              ]),
            ),
            const Spacer(),
            Text(fb.timeAgo,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteFeedback(fb.feedbackId),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white24, size: 18),
            ),
          ]),
        ),

        // ── Suggestion reference ──────────────────────────────────────
        if (fb.suggestion.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline,
                  size: 13, color: Color(0xFFF4BFDB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(fb.suggestion,
                    style: const TextStyle(color: Color(0xFFE9C2D7),
                        fontSize: 12, fontFamily: 'Pridi'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

        const SizedBox(height: 10),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 10),

        // ── Action taken ──────────────────────────────────────────────
        _cardRow(Icons.edit_note_rounded, 'Action', fb.actionTaken),

        const SizedBox(height: 8),

        // ── Student response ──────────────────────────────────────────
        _cardRow(Icons.person_outline, 'Response', fb.studentResponse),

        // ── Follow-up ─────────────────────────────────────────────────
        if (fb.followUpNeeded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF7043).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.alarm_on_rounded,
                    color: Color(0xFFFF7043), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fb.followUpNote.isNotEmpty
                        ? fb.followUpNote
                        : 'Follow-up required',
                    style: const TextStyle(color: Color(0xFFFF7043),
                        fontSize: 12, fontFamily: 'Pridi'),
                  ),
                ),
              ]),
            ),
          ),
        ],

        const SizedBox(height: 14),
      ]),
    );
  }

  // ── REUSABLE WIDGETS ──────────────────────────────────────────────────────

  Widget _sectionLabel(String label, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFFE9C2D7), size: 16),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(color: Color(0xFFE9C2D7),
              fontFamily: 'Pridi',
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    ]);
  }

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
    int minLines = 3,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: 6,
      style: const TextStyle(color: Colors.white, fontFamily: 'Pridi', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24,
            fontSize: 13, fontFamily: 'Pridi'),
        filled: true,
        fillColor: const Color(0xFF3B2028),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFA6768B), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _cardRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38,
                fontSize: 12, fontFamily: 'Pridi')),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white70,
                  fontSize: 12, fontFamily: 'Pridi')),
        ),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(color: color, fontSize: 20,
              fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
      Text(label,
          style: const TextStyle(color: Colors.white38,
              fontSize: 11, fontFamily: 'Pridi')),
    ]);
  }

  Widget _vDivider() => Container(
    width: 1, height: 28,
    color: Colors.white10,
  );
}