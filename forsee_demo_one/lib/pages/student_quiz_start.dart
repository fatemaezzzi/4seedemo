import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../quiz_data.dart';
import 'quiz_result_page.dart';

class StudentQuizStart extends StatefulWidget {
  final String categoryKey;

  const StudentQuizStart({super.key, required this.categoryKey});

  @override
  State<StudentQuizStart> createState() => _StudentQuizStartState();
}

class _StudentQuizStartState extends State<StudentQuizStart> {
  late final QuizCategory _category;
  late final List<String> _options;

  int _currentIndex = 0;
  int? _selectedScore;                       // score index of tapped option
  final List<QuizResponse> _responses = [];  // collected answers

  @override
  void initState() {
    super.initState();
    _category = quizCategories.firstWhere((c) => c.key == widget.categoryKey);
    _options  = getOptionsForCategory(widget.categoryKey);
  }

  int get _total => _category.questions.length;
  double get _progress => (_currentIndex + 1) / _total;
  QuizQuestion get _current => _category.questions[_currentIndex];

  void _selectOption(int scoreIndex) {
    setState(() => _selectedScore = scoreIndex);
  }

  void _goNext() {
    if (_selectedScore == null) return;

    // Record this answer
    _responses.add(QuizResponse(
      questionId: _current.id,
      score: _selectedScore!,
    ));

    if (_currentIndex < _total - 1) {
      setState(() {
        _currentIndex++;
        _selectedScore = null;
      });
    } else {
      // All questions answered — go to results
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            category: _category,
            responses: _responses,
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
              child: AnimatedSwitcher(
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
                  final bool isSelected = _selectedScore == i;
                  return _OptionButton(
                    label: _options[i],
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
                onTap: _selectedScore != null ? _goNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedScore != null
                        ? const Color(0xFFCC7090)
                        : const Color(0xFF6B3248),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _selectedScore != null
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

// ─────────────────────────────────────────────────────────────────────────────
// Option Button
// ─────────────────────────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7DC4B8) : const Color(0xFFE8B4C0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF3D1A24),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave Clipper
// ─────────────────────────────────────────────────────────────────────────────

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