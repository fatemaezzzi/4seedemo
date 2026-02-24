import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'student_quiz_start.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category data
// ─────────────────────────────────────────────────────────────────────────────

class _Category {
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeKey; // matches key in _categoryQuestions

  const _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeKey,
  });
}

const List<_Category> _categories = [
  _Category(
    icon: Icons.bolt_rounded,
    title: 'Focus & Energy',
    subtitle: 'ADHD Patterns',
    routeKey: 'Focus And Energy',
  ),
  _Category(
    icon: Icons.sentiment_satisfied_alt_rounded,
    title: 'Mood & Motivation',
    subtitle: 'Depression Patterns',
    routeKey: 'Mood And Motivation',
  ),
  _Category(
    icon: Icons.menu_book_rounded,
    title: 'Reading & Words',
    subtitle: 'Dyslexia Patterns',
    routeKey: 'Reading And Words',
  ),
  _Category(
    icon: Icons.self_improvement_rounded,
    title: 'Worry & Stress',
    subtitle: 'ADHD Patterns',
    routeKey: 'Worry And Stress',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// StudentQuizPage
// ─────────────────────────────────────────────────────────────────────────────

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key});

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  String? _selectedRouteKey;

  void _selectCategory(String routeKey) {
    setState(() {
      _selectedRouteKey = routeKey;
    });
  }

  void _goNext() {
    if (_selectedRouteKey == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizStart(category: _selectedRouteKey!),
      ),
    );
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
                    child: const Text(
                      'My Mind\n& Mood',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
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
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Category circles 2×2 grid ────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                physics: const NeverScrollableScrollPhysics(),
                children: _categories.map((cat) {
                  final bool isSelected = _selectedRouteKey == cat.routeKey;
                  return _CategoryCircle(
                    icon: cat.icon,
                    title: cat.title,
                    subtitle: cat.subtitle,
                    isSelected: isSelected,
                    onTap: () => _selectCategory(cat.routeKey),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Next arrow button ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _selectedRouteKey != null ? _goNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedRouteKey != null
                        ? const Color(0xFFCC7090)
                        : const Color(0xFF6B3248),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _selectedRouteKey != null
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
// Category Circle — circle shape with selection highlight
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCircle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '($subtitle)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
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
// Wave Clipper  (identical to student_quiz_start.dart)
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