import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../quiz_data.dart';

class QuizResultPage extends StatelessWidget {
  final QuizCategory category;
  final List<QuizResponse> responses;

  const QuizResultPage({
    super.key,
    required this.category,
    required this.responses,
  });

  // ── Thresholds from the PDF ──────────────────────────────────────────────
  static const Map<String, int> _thresholds = {
    'adhd':       9,   // out of 21  (7 Qs × max 3)
    'depression': 9,   // out of 21  (7 Qs × max 3)
    'dyslexia':   3,   // out of 14  (7 Qs × max 2), flag if Yes to 3+
    'anxiety':    6,   // out of 15  (5 Qs × max 3)
  };

  static const Map<String, String> _patternDescriptions = {
    'adhd':
    'This suggests a pattern consistent with ADHD (Inattentive or Hyperactive type). A specialist can give you a proper assessment.',
    'depression':
    'This suggests a Depressive pattern. If you ever feel like you want to hurt yourself, please speak to a trusted adult immediately.',
    'dyslexia':
    'This suggests a Specific Learning Disorder (Dyslexia) pattern. Many brilliant people have dyslexia — early support makes a big difference.',
    'anxiety':
    'This suggests an Anxiety pattern. Remember: feeling anxious is common, and the right support can help a lot.',
  };

  int get _totalScore => responses.fold(0, (sum, r) => sum + r.score);

  String get _severity {
    final threshold = _thresholds[category.key] ?? 9;
    if (_totalScore >= threshold + 3) return 'High';
    if (_totalScore >= threshold) return 'Moderate';
    return 'Low';
  }

  bool get _patternDetected {
    final threshold = _thresholds[category.key] ?? 9;
    return _totalScore >= threshold;
  }

  Color get _severityColor {
    switch (_severity) {
      case 'High':     return const Color(0xFFE05C7A);
      case 'Moderate': return const Color(0xFFE8A84A);
      default:         return const Color(0xFF7DC4B8);
    }
  }

  IconData get _severityIcon {
    switch (_severity) {
      case 'High':     return Icons.warning_amber_rounded;
      case 'Moderate': return Icons.info_outline_rounded;
      default:         return Icons.check_circle_outline_rounded;
    }
  }

  String get _severityLabel {
    if (!_patternDetected) return 'No Pattern Detected';
    return '$_severity Pattern Detected';
  }

  @override
  Widget build(BuildContext context) {
    // Prepare JSON payload for backend (your teammate can use this)
    final payload = responses.map((r) => r.toJson()).toList();

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
                        const Text(
                          'Your Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.title.replaceAll('\n', ' '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  // ── Result card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B3248),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(_severityIcon, color: _severityColor, size: 52),
                        const SizedBox(height: 14),
                        Text(
                          _severityLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _severityColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: $_totalScore',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 14,
                          ),
                        ),
                        if (_patternDetected) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 16),
                          Text(
                            _patternDescriptions[category.key] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Note card ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A1F2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Text(
                      '📌 This is a screening tool, not a diagnosis. Please share these results with your teacher or a trusted adult for proper support.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Back button ────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.popUntil(
                      context,
                          (route) => route.isFirst,
                    ),
                    child: Container(
                      width: double.infinity,
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
                ],
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