// lib/pages/quiz_thank_you_page.dart
//
// Shown to the student after completing all 4 quiz sections.
// No scores, no results — just a thank you message.
// Results are saved to Firestore and only visible to teachers.

import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class QuizThankYouPage extends StatelessWidget {
  const QuizThankYouPage({super.key});

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
                      'All Done!',
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

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Checkmark icon ───────────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DC4B8).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF7DC4B8).withOpacity(0.5),
                          width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF7DC4B8),
                      size: 52,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Thank you message ────────────────────────────────
                  const Text(
                    'Thank you for taking this quiz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B3248),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Your responses have been recorded. A member of your school\'s support team may follow up with you if needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.5,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Back to home ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.popUntil(
                          context, (route) => route.isFirst),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DC4B8),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            'Back to Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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