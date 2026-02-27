import 'package:flutter/material.dart';

void main() {
  runApp(const QuizStartPage());
}

class QuizStartPage extends StatelessWidget {
  const QuizStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyMindMoodScreen(),
    );
  }
}

class MyMindMoodScreen extends StatelessWidget {
  const MyMindMoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A1E2E),
      body: Stack(
        children: [
          // ───────── FULL TEAL DOME ─────────
          ClipPath(
            clipper: _TealDomeClipper(),
            child: Container(
              height: 320,
              width: double.infinity,
              color: const Color(0xFF6BBFAA),
            ),
          ),

          // ───────── PAGE CONTENT ─────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Title
                const Text(
                  "My Mind & Mood",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 140),

                // Info Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF7A3F55),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "There are no right or wrong answers. This is just a tool to help you understand your own brain better. Read each statement and decide if it sounds like you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Category Circles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      CategoryCircle(
                        icon: Icons.menu_book_rounded,
                        label: "Reading &\nWords",
                        subLabel: "(Dyslexia Patterns)",
                        color: Color(0xFF8E5C7A),
                      ),
                      CategoryCircle(
                        icon: Icons.bolt,
                        label: "Focus &\nEnergy",
                        subLabel: "(ADHD Patterns)",
                        color: Color(0xFFB07090),
                      ),
                      CategoryCircle(
                        icon: Icons.sentiment_satisfied_alt,
                        label: "Mood &\nMotivation",
                        subLabel: "(Depression Patterns)",
                        color: Color(0xFFCE8FAA),
                      ),
                      CategoryCircle(
                        icon: Icons.favorite_border,
                        label: "Worry &\nStress",
                        subLabel: "(ADHD Patterns)",
                        color: Color(0xFFEFBDD0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────── CATEGORY CIRCLE ─────────

class CategoryCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;

  const CategoryCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.black87),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ───────── TEAL DOME CLIPPER ─────────

class _TealDomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.75);

    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.3,
      size.width,
      size.height * 0.75,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
