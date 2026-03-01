// lib/pages/student_quiz_page.dart
//
// Replaces the old category-selection screen.
// Now it just shows a welcome/intro screen and starts all 4 quizzes in order.

import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'student_quiz_start.dart';
import '../quiz_data.dart';

class StudentQuizPage extends StatelessWidget {
  const StudentQuizPage({super.key});

  void _begin(BuildContext context) {
    // Always start from the first category — flow continues automatically
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizStart(
          categoryIndex: 0,
          allResponses: const {},
        ),
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
                'There are no right or wrong answers. This is just a tool to help understand your wellbeing better.\n\nYou will go through 4 short sections. Read each statement and answer honestly.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section overview ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: quizCategories.asMap().entries.map((e) {
                  final i   = e.key;
                  final cat = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B3248),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cat.color.withOpacity(0.2),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                              color: cat.color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(cat.icon, color: cat.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(
                              '${cat.questions.length} questions',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Begin button ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => _begin(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DC4B8),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      'Begin',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
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