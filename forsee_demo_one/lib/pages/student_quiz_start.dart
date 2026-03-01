// lib/pages/student_quiz_start.dart
//
// Key changes from original:
// - Takes categoryIndex (0-3) instead of categoryKey string
// - Takes allResponses map that accumulates across all 4 categories
// - After final question of each category, moves to next category
// - After all 4 categories done, saves data and goes to QuizThankYouPage
// - No results are shown to the student at any point

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/services/prediction_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../quiz_data.dart';
import 'quiz_thankyou_page.dart';

class StudentQuizStart extends StatefulWidget {
  /// Index into quizCategories (0=ADHD, 1=Anxiety, 2=Depression, 3=Dyslexia)
  final int categoryIndex;

  /// Accumulated responses from previous categories (empty on first category)
  final Map<String, List<QuizResponse>> allResponses;

  const StudentQuizStart({
    super.key,
    required this.categoryIndex,
    required this.allResponses,
  });

  @override
  State<StudentQuizStart> createState() => _StudentQuizStartState();
}

class _StudentQuizStartState extends State<StudentQuizStart> {
  late final QuizCategory _category;

  int  _currentIndex        = 0;
  int? _selectedOptionIndex;
  final List<QuizResponse> _responses = [];

  @override
  void initState() {
    super.initState();
    _category = quizCategories[widget.categoryIndex];
  }

  int              get _total    => _category.questions.length;
  double           get _progress => (_currentIndex + 1) / _total;
  QuizQuestion     get _current  => _category.questions[_currentIndex];
  List<QuizOption> get _options  => _category.options;

  // Overall progress across all 4 categories
  int get _overallCurrent =>
      widget.categoryIndex * 10 + _currentIndex; // approximate
  String get _sectionLabel =>
      'Section ${widget.categoryIndex + 1} of ${quizCategories.length}';

  void _selectOption(int index) => setState(() => _selectedOptionIndex = index);

  void _goNext() {
    if (_selectedOptionIndex == null) return;

    _responses.add(QuizResponse(
      questionId: _current.id,
      score: _options[_selectedOptionIndex!].value,
    ));

    if (_currentIndex < _total - 1) {
      // More questions in this category
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
      });
      return;
    }

    // ── This category is done — accumulate responses ──────────────────────
    final updatedAllResponses = Map<String, List<QuizResponse>>.from(
        widget.allResponses)
      ..[_category.key] = List.from(_responses);

    final nextIndex = widget.categoryIndex + 1;

    if (nextIndex < quizCategories.length) {
      // Move to the next category
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentQuizStart(
            categoryIndex: nextIndex,
            allResponses: updatedAllResponses,
          ),
        ),
      );
    } else {
      // All 4 categories done — save and show thank you
      _finishAllCategories(updatedAllResponses);
    }
  }

  Future<void> _finishAllCategories(
      Map<String, List<QuizResponse>> allResponses) async {
    final studentId = AuthController.to.firebaseUser.value?.uid ?? '';

    // ── Flatten all responses for score calculation ───────────────────────
    final flatResponses = <QuizResponse>[];
    for (final responses in allResponses.values) {
      flatResponses.addAll(responses);
    }

    // ── Calculate scores (hidden from student) ────────────────────────────
    final result = calculateWeightedScores(flatResponses, quizCategories);

    // ── Save to Firestore ──────────────────────────────────────────────────
    if (studentId.isNotEmpty) {
      // Mark quiz as completed so dashboard won't redirect again
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .set({'quizCompleted': true}, SetOptions(merge: true));

      // Save full quiz results to staging for teacher view
      try {
        final quizData = QuizData(
          studentId: studentId,
          overallScore: result.overallScore,
          categoryScores: result.categoryScores.map(
                (key, value) => MapEntry(key, value.rawPercent * 100),
          ),
        );
        await PredictionService().saveQuiz(quizData);

        // Also save detailed per-category breakdown for teacher view
        await FirebaseFirestore.instance
            .collection('quiz_results')
            .doc(studentId)
            .set({
          'studentId': studentId,
          'completedAt': FieldValue.serverTimestamp(),
          'overallScore': result.overallScore,
          'criticalTriggers': result.criticalTriggers,
          'categories': result.categoryScores.map((key, cs) => MapEntry(key, {
            'rawScore': cs.rawScore,
            'maxScore': cs.maxScore,
            'percentInt': cs.percentInt,
            'rawPercent': cs.rawPercent,
            'contribution': cs.contribution,
          })),
          // Per-category responses for full audit trail
          'responses': allResponses.map((catKey, responses) => MapEntry(
            catKey,
            responses.map((r) => r.toJson()).toList(),
          )),
        }, SetOptions(merge: false));
      } catch (e) {
        debugPrint('Quiz save error: $e');
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QuizThankYouPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D1A24),
      body: Column(
        children: [
          // ── Wave header ──────────────────────────────────────────────
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              color: const Color(0xFF7DC4B8),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 190,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sectionLabel,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _category.title.replaceAll('\n', ' '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Progress bar (within this category) ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF6B3248),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7DC4B8)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_currentIndex + 1} / $_total',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Question card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6B3248),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_current.isCritical)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.15),
                        border: Border.all(
                            color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF6B6B), size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Sensitive question — answer honestly',
                            style: TextStyle(
                                color: Color(0xFFFF6B6B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _current.text,
                      key: ValueKey(_currentIndex),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Answer options ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (_, i) {
                  final bool isSelected = _selectedOptionIndex == i;
                  return _OptionButton(
                    label: _options[i].label,
                    value: _options[i].value,
                    isSelected: isSelected,
                    onTap: () => _selectOption(i),
                  );
                },
              ),
            ),
          ),

          // ── Next / Finish arrow ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _selectedOptionIndex != null ? _goNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedOptionIndex != null
                        ? const Color(0xFFCC7090)
                        : const Color(0xFF6B3248),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Show checkmark on the very last question of the last category
                    (widget.categoryIndex == quizCategories.length - 1 &&
                        _currentIndex == _total - 1)
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: _selectedOptionIndex != null
                        ? Colors.white
                        : Colors.white30,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }
}

// ── Option Button — unchanged from original ───────────────────────────────────

class _OptionButton extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color:
          isSelected ? const Color(0xFF7DC4B8) : const Color(0xFFE8B4C0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : const Color(0xFF3D1A24).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF3D1A24),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF3D1A24),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wave clipper — unchanged ──────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 48);
    path.quadraticBezierTo(
        size.width * 0.5, size.height + 24, size.width, size.height - 48);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}