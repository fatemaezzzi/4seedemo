import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sample questions per category
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<String>> _categoryQuestions = {
  'Focus And Energy': [
    'When I have to do a boring or difficult assignment, I find it really hard to just get started.',
    'I often lose track of time when I am working on something.',
    'I struggle to sit still for long periods of time.',
    'I frequently forget where I put things like my bag or pencil.',
    'I find it hard to focus when there are distractions around me.',
  ],
  'Mood And Motivation': [
    'I often feel sad or empty for no clear reason.',
    'I have lost interest in things I used to enjoy.',
    'I feel tired most of the time even when I sleep enough.',
    'I find it hard to feel happy even on good days.',
    'I sometimes feel like nothing I do matters.',
  ],
  'Reading And Words': [
    'I mix up letters or words when I am reading.',
    'Reading out loud feels much harder for me than for others.',
    'I sometimes skip words or lines when reading.',
    'I find it hard to spell common words correctly.',
    'I often have to re-read sentences to understand them.',
  ],
  'Worry And Stress': [
    'I worry a lot about things that might go wrong.',
    'My mind races with thoughts before I fall asleep.',
    'I feel nervous or tense in everyday situations.',
    'Small problems feel much bigger to me than they should.',
    'I often feel overwhelmed when I have a lot to do.',
  ],
};

const List<String> _options = ['Never', 'Sometimes', 'Often', 'Very Often'];

// ─────────────────────────────────────────────────────────────────────────────
// StudentQuizStart Page
// ─────────────────────────────────────────────────────────────────────────────

class StudentQuizStart extends StatefulWidget {
  final String category;

  const StudentQuizStart({super.key, required this.category});

  @override
  State<StudentQuizStart> createState() => _StudentQuizStartState();
}

class _StudentQuizStartState extends State<StudentQuizStart> {
  int _currentQuestion = 0;
  String? _selectedOption;

  List<String> get _questions =>
      _categoryQuestions[widget.category] ?? _categoryQuestions['Focus And Energy']!;

  int get _totalQuestions => _questions.length;

  double get _progress => (_currentQuestion + 1) / _totalQuestions;

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _goNext() {
    if (_selectedOption == null) return;

    if (_currentQuestion < _totalQuestions - 1) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
      });
    } else {
      // Quiz finished — show completion or pop
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF6B3248),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Quiz Complete!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Thank you for completing this section. Your responses have been recorded.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to quiz page
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Color(0xFF7DC4B8), fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
          // ── Top wave header ──────────────────────────────────────────
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
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Progress bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF6B3248),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7DC4B8)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Question card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF6B3248),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _questions[_currentQuestion],
                  key: ValueKey(_currentQuestion),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Answer options ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _options.map((option) {
                  final bool isSelected = _selectedOption == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionButton(
                      label: option,
                      isSelected: isSelected,
                      onTap: () => _selectOption(option),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Next arrow button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _selectedOption != null ? _goNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedOption != null
                        ? const Color(0xFFCC7090)
                        : const Color(0xFF6B3248),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _selectedOption != null
                        ? Colors.white
                        : Colors.white38,
                    size: 24,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7DC4B8) : const Color(0xFFE8B4C0),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF3D1A24),
              fontWeight: FontWeight.w600,
              fontSize: 16,
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
      size.width * 0.5,
      size.height + 24,
      size.width,
      size.height - 48,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}