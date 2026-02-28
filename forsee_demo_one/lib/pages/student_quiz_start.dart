import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../quiz_data.dart';
import 'quiz_result_page.dart';

class StudentQuizStart extends StatefulWidget {
  final String categoryKey;

  const StudentQuizStart({super.key, required this.categoryKey});

  @override
  State<StudentQuizStart> createState() => _StudentQuizStartState();
}

class _StudentQuizStartState extends State<StudentQuizStart> {
  late final QuizCategory _category;

  int _currentIndex = 0;
  int? _selectedOptionIndex;
  final List<QuizResponse> _responses = [];

  @override
  void initState() {
    super.initState();
    _category = quizCategories.firstWhere((c) => c.key == widget.categoryKey);
  }

  int get _total => _category.questions.length;
  double get _progress => (_currentIndex + 1) / _total;
  QuizQuestion get _current => _category.questions[_currentIndex];
  List<QuizOption> get _options => _category.options;

  void _selectOption(int index) {
    setState(() => _selectedOptionIndex = index);
  }

  void _goNext() {
    if (_selectedOptionIndex == null) return;

    final actualScore = _options[_selectedOptionIndex!].value;

    _responses.add(QuizResponse(
      questionId: _current.id,
      score: actualScore,
    ));

    if (_currentIndex < _total - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
      });
    } else {
      // ── Get the logged-in student's Firestore UID from AuthController ────
      final studentId = AuthController.to.firebaseUser.value?.uid ?? '';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            category:  _category,
            responses: _responses,
            studentId: studentId, // ✅ passed here
          ),
        ),
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
                    child: Text(
                      _category.title.replaceAll('\n', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Progress bar ─────────────────────────────────────────────
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
                    color: Colors.white.withValues(alpha: 0.55),
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
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                        border: Border.all(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
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

          // ── Next arrow ────────────────────────────────────────────────
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
                    Icons.arrow_forward_rounded,
                    color: _selectedOptionIndex != null
                        ? Colors.white
                        : Colors.white30,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom nav ────────────────────────────────────────────────
          const BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }
}

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
          color: isSelected ? const Color(0xFF7DC4B8) : const Color(0xFFE8B4C0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFF3D1A24).withValues(alpha: 0.15),
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

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 48);
    path.quadraticBezierTo(
      size.width * 0.5, size.height + 24,
      size.width, size.height - 48,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}