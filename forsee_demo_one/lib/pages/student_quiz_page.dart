import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'student_quiz_start.dart';
import '../quiz_data.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  String? _selectedKey;

  void _selectCategory(String key) {
    setState(() => _selectedKey = key);
  }

  void _goNext() {
    if (_selectedKey == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizStart(categoryKey: _selectedKey!),
      ),
    );
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
                    child: const Text(
                      'My Mind\n& Mood',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Description card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF6B3248),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'There are no right or wrong answers. This is just a tool to help you understand your own brain better. Read each statement and decide if it sounds like you.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── 2×2 Category circles ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                children: quizCategories.map((cat) {
                  final bool isSelected = _selectedKey == cat.key;
                  return _CategoryCircle(
                    category: cat,
                    isSelected: isSelected,
                    onTap: () => _selectCategory(cat.key),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Next button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _selectedKey != null ? _goNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _selectedKey != null
                        ? const Color(0xFFCC7090)
                        : const Color(0xFF6B3248),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _selectedKey != null ? Colors.white : Colors.white30,
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
// Category Circle
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCircle extends StatelessWidget {
  final QuizCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7DC4B8) : const Color(0xFF8B3A5A),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: Colors.white, size: 34),
            const SizedBox(height: 10),
            Text(
              category.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(${category.subtitle})',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 11,
              ),
            ),
          ],
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