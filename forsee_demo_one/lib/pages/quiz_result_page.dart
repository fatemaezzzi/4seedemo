// quiz_result_page.dart — UPDATED
// =================================
// Changes from original:
// 1. initState() now saves quiz overallScore to staging via PredictionService
// 2. Everything else (all UI) is completely unchanged

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:forsee_demo_one/services/prediction_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../quiz_data.dart';

class QuizResultPage extends StatefulWidget {
  final QuizCategory category;
  final List<QuizResponse> responses;
  final String studentId; // ← ADD THIS: pass from StudentQuizStart

  const QuizResultPage({
    super.key,
    required this.category,
    required this.responses,
    required this.studentId, // ← ADD THIS
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage>
    with SingleTickerProviderStateMixin {
  late final QuizScoreResult _result;
  late final SeverityResult _severity;
  late final OverallLevel _overallLevel;

  late final AnimationController _animController;
  late final Animation<double> _ringAnim;
  late final Animation<double> _barAnim;

  final _predictionService = PredictionService();

  @override
  void initState() {
    super.initState();

    _result = calculateWeightedScores(widget.responses, quizCategories);
    final cs = _result.categoryScores[widget.category.key]!;
    _severity = getSeverity(cs.rawScore, cs.maxScore);
    _overallLevel = getOverallLevel(_result.overallScore);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _ringAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _barAnim  = CurvedAnimation(parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });

    // ── SAVE QUIZ SCORE TO STAGING ────────────────────────────────────────
    // This triggers prediction auto-run if all 4 inputs are complete
    _saveQuizScore();
  }

  Future<void> _saveQuizScore() async {
    try {
      final quizData = QuizData(
        studentId: widget.studentId,
        overallScore: _result.overallScore,
        categoryScores: _result.categoryScores.map(
              (key, value) => MapEntry(key, value.rawPercent * 100),
        ),
      );
      await _predictionService.saveQuiz(quizData);
    } catch (e) {
      debugPrint('Quiz save error: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── ALL UI BELOW IS 100% UNCHANGED FROM ORIGINAL ──────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = _result.categoryScores[widget.category.key]!;

    return Scaffold(
      backgroundColor: const Color(0xFF3D1A24),
      body: Column(
        children: [
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
                        const Text('Your Results',
                            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(widget.category.title.replaceAll('\n', ' '),
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 18)),
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
                  if (_result.criticalTriggers.isNotEmpty)
                    _CriticalAlertCard(triggers: _result.criticalTriggers),

                  _OverallScoreCard(
                    overallScore: _result.overallScore,
                    overallLevel: _overallLevel,
                    ringAnim: _ringAnim,
                  ),

                  const SizedBox(height: 16),
                  _WeightedBarsCard(categoryScores: _result.categoryScores, barAnim: _barAnim),
                  const SizedBox(height: 16),
                  _CategoryResultCard(
                    category: widget.category,
                    categoryScore: cs,
                    severity: _severity,
                    barAnim: _barAnim,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A1F2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Text(
                      '📌 This is a screening tool, not a diagnosis. Please share these results with your teacher or a trusted adult for proper support.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7DC4B8),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: Text('Back to Home',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }
}

// ── All sub-widgets below are 100% unchanged ──────────────────────────────────

class _CriticalAlertCard extends StatelessWidget {
  final List<String> triggers;
  const _CriticalAlertCard({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.07),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚨', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Immediate Support Recommended',
                    style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text(
                  'Your response to a sensitive question indicates you may be experiencing significant distress. Please consider reaching out to a counselor, trusted adult, or a crisis support line today.',
                  style: TextStyle(color: Color(0xFFE8B0B0), fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 10),
                Text('Trigger: ${triggers.join(', ')}',
                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text(
                  '📞 iCall (India): 9152987821\n📞 Vandrevala Foundation: 1860-2662-345 (24/7)',
                  style: TextStyle(color: Color(0xFFE8B0B0), fontSize: 12, height: 1.6, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final double overallScore;
  final OverallLevel overallLevel;
  final Animation<double> ringAnim;
  const _OverallScoreCard({required this.overallScore, required this.overallLevel, required this.ringAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF6B3248), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('Overall Wellbeing Score',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
          const SizedBox(height: 20),
          SizedBox(
            width: 160, height: 160,
            child: AnimatedBuilder(
              animation: ringAnim,
              builder: (context, _) {
                final progress = ringAnim.value * (overallScore / 100);
                final displayScore = (ringAnim.value * overallScore).round();
                return CustomPaint(
                  painter: _RingPainter(progress: progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$displayScore',
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1)),
                        const Text('/ 100', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(overallLevel.label,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(overallLevel.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
        Paint()..color = const Color(0xFF4A1F2E)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);

    if (progress > 0) {
      final clampedProgress = progress.clamp(0.001, 1.0);
      final gradientShader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * clampedProgress,
        colors: const [Color(0xFF5BC8AF), Color(0xFFA78BFA)],
      ).createShader(rect);

      canvas.drawArc(rect, -pi / 2, 2 * pi * clampedProgress, false,
          Paint()..shader = gradientShader..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _WeightedBarsCard extends StatelessWidget {
  final Map<String, CategoryScore> categoryScores;
  final Animation<double> barAnim;
  const _WeightedBarsCard({required this.categoryScores, required this.barAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF6B3248), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEIGHTED CONTRIBUTION TO OVERALL SCORE',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          ...quizCategories.map((cat) {
            final cs = categoryScores[cat.key]!;
            return _WeightedBarRow(label: cat.subtitle, color: cat.color, rawPercent: cs.rawPercent, barAnim: barAnim);
          }),
        ],
      ),
    );
  }
}

class _WeightedBarRow extends StatelessWidget {
  final String label;
  final Color color;
  final double rawPercent;
  final Animation<double> barAnim;
  const _WeightedBarRow({required this.label, required this.color, required this.rawPercent, required this.barAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 78,
              child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(
            child: AnimatedBuilder(
              animation: barAnim,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: barAnim.value * rawPercent,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF4A1F2E),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 34,
              child: Text('${(rawPercent * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _CategoryResultCard extends StatelessWidget {
  final QuizCategory category;
  final CategoryScore categoryScore;
  final SeverityResult severity;
  final Animation<double> barAnim;
  const _CategoryResultCard({required this.category, required this.categoryScore, required this.severity, required this.barAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6B3248),
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: category.color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title.replaceAll('\n', ' '),
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Weight in overall: ${(category.weight * 100).round()}%',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: severity.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: severity.color.withOpacity(0.4)),
                ),
                child: Text(severity.label,
                    style: TextStyle(color: severity.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: barAnim,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: barAnim.value * categoryScore.rawPercent,
                minHeight: 8,
                backgroundColor: const Color(0xFF4A1F2E),
                valueColor: AlwaysStoppedAnimation<Color>(category.color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Score: ${categoryScore.rawScore} / ${categoryScore.maxScore}  ·  ${categoryScore.percentInt}% of maximum',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF4A1F2E), borderRadius: BorderRadius.circular(10)),
            child: Text(severity.description,
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.55)),
          ),
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
    path.quadraticBezierTo(size.width * 0.5, size.height + 24, size.width, size.height - 48);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}