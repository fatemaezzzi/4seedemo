import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

class MentalHealthQuizPage extends StatefulWidget {
  const MentalHealthQuizPage({super.key});

  @override
  State<MentalHealthQuizPage> createState() => _MentalHealthQuizPageState();
}

class _MentalHealthQuizPageState extends State<MentalHealthQuizPage> {
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};
  bool _submitted = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How often have you felt down, depressed, or hopeless in the last 2 weeks?',
      'options': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    },
    {
      'question': 'How often have you had little interest or pleasure in doing things?',
      'options': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    },
    {
      'question': 'How often have you felt nervous, anxious, or on edge?',
      'options': ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'],
    },
    {
      'question': 'How would you rate your sleep quality lately?',
      'options': ['Very good', 'Fairly good', 'Fairly bad', 'Very bad'],
    },
    {
      'question': 'How often have you felt overwhelmed by schoolwork or exams?',
      'options': ['Rarely', 'Sometimes', 'Often', 'Almost always'],
    },
  ];

  int get _score => _answers.values.fold(0, (a, b) => a + b);

  String get _result {
    if (_score <= 3) return 'You seem to be doing well! Keep taking care of yourself.';
    if (_score <= 7) return 'Mild stress detected. Consider speaking to a friend or counsellor.';
    if (_score <= 11) return 'Moderate stress levels. We recommend talking to a counsellor.';
    return 'High stress detected. Please reach out to a counsellor immediately.';
  }

  Color get _resultColor {
    if (_score <= 3) return Colors.green.shade400;
    if (_score <= 7) return Colors.yellow.shade700;
    if (_score <= 11) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mental Health Quiz')),
      body: _submitted ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentQuestion];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Progress
          Row(
            children: [
              Text('${_currentQuestion + 1} / ${_questions.length}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / _questions.length,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TealCard(
            child: Text(
              q['question'],
              style: const TextStyle(
                  color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(q['options'].length, (i) {
            final selected = _answers[_currentQuestion] == i;
            return GestureDetector(
              onTap: () => setState(() => _answers[_currentQuestion] = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? AppColors.accent : Colors.white12, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selected ? AppColors.textDark : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      q['options'][i],
                      style: TextStyle(
                        color: selected ? AppColors.textDark : Colors.white,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          Row(
            children: [
              if (_currentQuestion > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentQuestion--),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentQuestion > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _answers.containsKey(_currentQuestion)
                      ? () {
                    if (_currentQuestion < _questions.length - 1) {
                      setState(() => _currentQuestion++);
                    } else {
                      setState(() => _submitted = true);
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(_currentQuestion < _questions.length - 1 ? 'Next' : 'Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _resultColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _score <= 3 ? Icons.sentiment_very_satisfied : Icons.sentiment_neutral,
              color: _resultColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quiz Complete',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TealCard(
            child: Column(
              children: [
                const SectionTitle('Your Result'),
                Text(_result,
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 14, height: 1.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _resultColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Score: $_score / ${(_questions.length - 1) * 3}',
                      style: TextStyle(
                          color: _resultColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Talk to a Counsellor',
            onTap: () {},
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _currentQuestion = 0;
              _answers.clear();
              _submitted = false;
            }),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Retake Quiz'),
          ),
        ],
      ),
    );
  }
}