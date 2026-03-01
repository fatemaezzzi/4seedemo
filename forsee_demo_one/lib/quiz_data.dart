import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class QuizQuestion {
  final String id;
  final String text;
  final bool isCritical;

  const QuizQuestion({
    required this.id,
    required this.text,
    this.isCritical = false,
  });
}

class QuizOption {
  final String label;
  final int value;

  const QuizOption({required this.label, required this.value});
}

class QuizCategory {
  final String key;
  final String title;       // used in UI header
  final String fullName;    // used in results
  final String subtitle;    // shown in category circle
  final IconData icon;
  final Color color;
  final double weight;      // contribution to overall score (0.0–1.0)
  final int maxScore;       // questions × max option value
  final int threshold;      // score above which pattern is flagged
  final List<QuizQuestion> questions;
  final List<QuizOption> options;

  const QuizCategory({
    required this.key,
    required this.title,
    required this.fullName,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.weight,
    required this.maxScore,
    required this.threshold,
    required this.questions,
    required this.options,
  });
}

class QuizResponse {
  final String questionId;
  final int score;

  const QuizResponse({required this.questionId, required this.score});

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'score': score,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Severity
// ─────────────────────────────────────────────────────────────────────────────

enum SeverityLevel { minimal, mild, moderate, high, severe }

class SeverityResult {
  final SeverityLevel level;
  final String label;
  final String description;
  final Color color;

  const SeverityResult({
    required this.level,
    required this.label,
    required this.description,
    required this.color,
  });
}

SeverityResult getSeverity(int score, int maxScore) {
  final pct = score / maxScore;
  if (pct < 0.20) {
    return const SeverityResult(
      level: SeverityLevel.minimal,
      label: 'Minimal',
      description: 'Your responses in this area fall within a typical range. No significant concerns detected.',
      color: Color(0xFF7DC4B8),
    );
  } else if (pct < 0.40) {
    return const SeverityResult(
      level: SeverityLevel.mild,
      label: 'Mild',
      description: 'Some patterns present. Worth monitoring over time, but not immediately concerning.',
      color: Color(0xFFE8A84A),
    );
  } else if (pct < 0.60) {
    return const SeverityResult(
      level: SeverityLevel.moderate,
      label: 'Moderate',
      description: 'A notable pattern is emerging. Consider speaking with a professional about these experiences.',
      color: Color(0xFFF5A87E),
    );
  } else if (pct < 0.80) {
    return const SeverityResult(
      level: SeverityLevel.high,
      label: 'High',
      description: 'Significant patterns detected. A consultation with a qualified professional is strongly recommended.',
      color: Color(0xFFFF6B6B),
    );
  } else {
    return const SeverityResult(
      level: SeverityLevel.severe,
      label: 'Severe',
      description: 'Very elevated responses. Please prioritize speaking with a mental health professional or counselor soon.',
      color: Color(0xFFFF4444),
    );
  }
}

class OverallLevel {
  final String label;
  final String description;

  const OverallLevel({required this.label, required this.description});
}

OverallLevel getOverallLevel(double score) {
  if (score < 20) {
    return const OverallLevel(
      label: 'Low Concern',
      description: 'Your combined responses suggest you are managing well overall. Continue to check in with yourself regularly.',
    );
  } else if (score < 40) {
    return const OverallLevel(
      label: 'Mild Concern',
      description: 'A few patterns are worth noting. Self-care, rest, and talking to someone you trust can help.',
    );
  } else if (score < 60) {
    return const OverallLevel(
      label: 'Moderate Concern',
      description: 'Multiple areas show moderate patterns. Speaking with a counselor or mental health professional is a good next step.',
    );
  } else if (score < 80) {
    return const OverallLevel(
      label: 'High Concern',
      description: 'Several areas have significant patterns. A professional evaluation is strongly recommended.',
    );
  } else {
    return const OverallLevel(
      label: 'Severe Concern',
      description: 'Your responses indicate significant distress across multiple areas. Please reach out to a mental health professional as soon as possible.',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Calculation
// ─────────────────────────────────────────────────────────────────────────────

class CategoryScore {
  final String categoryKey;
  final int rawScore;
  final int maxScore;
  final double rawPercent;   // 0.0–1.0
  final double contribution; // rawPercent * weight * 100 → points toward overall

  CategoryScore({
    required this.categoryKey,
    required this.rawScore,
    required this.maxScore,
  })  : rawPercent = rawScore / maxScore,
        contribution = (rawScore / maxScore) * _weightFor(categoryKey) * 100;

  static double _weightFor(String key) {
    switch (key) {
      case 'adhd':       return 0.25;
      case 'anxiety':    return 0.30;
      case 'depression': return 0.30;
      case 'dyslexia':   return 0.15;
      default:           return 0.25;
    }
  }

  int get percentInt => (rawPercent * 100).round();
}

class QuizScoreResult {
  final Map<String, CategoryScore> categoryScores;
  final double overallScore; // 0–100
  final List<String> criticalTriggers;

  QuizScoreResult({
    required this.categoryScores,
    required this.overallScore,
    required this.criticalTriggers,
  });
}

QuizScoreResult calculateWeightedScores(
    List<QuizResponse> responses,
    List<QuizCategory> categories,
    ) {
  // Sum raw scores per category
  final rawScores = <String, int>{};
  for (final cat in categories) {
    rawScores[cat.key] = 0;
  }

  // Map questionId → categoryKey for fast lookup
  final questionCatMap = <String, String>{};
  for (final cat in categories) {
    for (final q in cat.questions) {
      questionCatMap[q.id] = cat.key;
    }
  }

  for (final r in responses) {
    final catKey = questionCatMap[r.questionId];
    if (catKey != null) {
      rawScores[catKey] = (rawScores[catKey] ?? 0) + r.score;
    }
  }

  // Build CategoryScore objects
  final categoryScores = <String, CategoryScore>{};
  double overall = 0.0;
  for (final cat in categories) {
    final cs = CategoryScore(
      categoryKey: cat.key,
      rawScore: rawScores[cat.key] ?? 0,
      maxScore: cat.maxScore,
    );
    categoryScores[cat.key] = cs;
    overall += cs.contribution;
  }

  // Check critical triggers (depression hopelessness question)
  final criticalTriggers = <String>[];
  final dep6 = responses.firstWhere(
        (r) => r.questionId == 'dep6',
    orElse: () => const QuizResponse(questionId: '', score: -1),
  );
  if (dep6.score == 3) {
    criticalTriggers.add('Severe Hopelessness / Outlook (Depression Q6)');
  }

  return QuizScoreResult(
    categoryScores: categoryScores,
    overallScore: overall.clamp(0, 100),
    criticalTriggers: criticalTriggers,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz Categories Data
// ─────────────────────────────────────────────────────────────────────────────

final List<QuizCategory> quizCategories = [
  QuizCategory(
    key: 'adhd',
    title: 'Focus &\nEnergy',
    fullName: 'Focus & Energy (ADHD)',
    subtitle: 'ADHD',
    icon: Icons.bolt_rounded,
    color: const Color(0xFFF5C842),
    weight: 0.25,
    maxScore: 24, // 6 questions × max 4
    threshold: 14,
    options: const [
      QuizOption(label: 'Never', value: 0),
      QuizOption(label: 'Rarely', value: 1),
      QuizOption(label: 'Sometimes', value: 2),
      QuizOption(label: 'Often', value: 3),
      QuizOption(label: 'Very Often', value: 4),
    ],
    questions: const [
      QuizQuestion(
        id: 'a1',
        text: 'How often do you have trouble wrapping up the final details of a project once the challenging parts have been done?',
      ),
      QuizQuestion(
        id: 'a2',
        text: 'How often do you have difficulty getting things in order when you have to do a task that requires organization?',
      ),
      QuizQuestion(
        id: 'a3',
        text: 'How often do you have problems remembering appointments or obligations?',
      ),
      QuizQuestion(
        id: 'a4',
        text: 'When you have a task that requires a lot of thought, how often do you avoid or delay getting started?',
      ),
      QuizQuestion(
        id: 'a5',
        text: 'How often do you fidget or squirm with your hands or feet when you have to sit down for a long time?',
      ),
      QuizQuestion(
        id: 'a6',
        text: 'How often do you feel overly active and compelled to do things, as if you were driven by a motor?',
      ),
    ],
  ),

  QuizCategory(
    key: 'anxiety',
    title: 'Worry &\nTension',
    fullName: 'Worry & Tension (GAD-7)',
    subtitle: 'Anxiety',
    icon: Icons.cyclone_rounded,
    color: const Color(0xFF5BC8AF),
    weight: 0.30,
    maxScore: 21, // 7 questions × max 3
    threshold: 10,
    options: const [
      QuizOption(label: 'Not at all', value: 0),
      QuizOption(label: 'Several days', value: 1),
      QuizOption(label: 'More than half', value: 2),
      QuizOption(label: 'Nearly every day', value: 3),
    ],
    questions: const [
      QuizQuestion(id: 'gad1', text: 'Feeling nervous, anxious, or on edge?'),
      QuizQuestion(id: 'gad2', text: 'Not being able to stop or control worrying?'),
      QuizQuestion(id: 'gad3', text: 'Worrying too much about different things?'),
      QuizQuestion(id: 'gad4', text: 'Trouble relaxing?'),
      QuizQuestion(id: 'gad5', text: 'Being so restless that it is hard to sit still?'),
      QuizQuestion(id: 'gad6', text: 'Becoming easily annoyed or irritable?'),
      QuizQuestion(id: 'gad7', text: 'Feeling afraid, as if something awful might happen?'),
    ],
  ),

  QuizCategory(
    key: 'depression',
    title: 'Mood &\nFunctioning',
    fullName: 'Mood & Functioning',
    subtitle: 'Depression',
    icon: Icons.nightlight_round,
    color: const Color(0xFFA78BFA),
    weight: 0.30,
    maxScore: 21, // 7 questions × max 3
    threshold: 10,
    options: const [
      QuizOption(label: 'Not at all', value: 0),
      QuizOption(label: 'Several days', value: 1),
      QuizOption(label: 'More than half', value: 2),
      QuizOption(label: 'Nearly every day', value: 3),
    ],
    questions: const [
      QuizQuestion(
        id: 'dep1',
        text: 'How often have you felt physically heavy, as if your limbs are weighted down, making simple movements feel like a chore?',
      ),
      QuizQuestion(
        id: 'dep2',
        text: 'How often have you struggled to make even tiny decisions (like what to eat or what to wear) because they felt overwhelming?',
      ),
      QuizQuestion(
        id: 'dep3',
        text: 'How often have you avoided answering texts, calls, or invitations — not because you were busy, but because you didn\'t have the \'energy\' to interact?',
      ),
      QuizQuestion(
        id: 'dep4',
        text: 'How often have you felt \'numb\' or disconnected from your surroundings, as if you are watching your life happen from behind a pane of glass?',
      ),
      QuizQuestion(
        id: 'dep5',
        text: 'How often have you felt uncharacteristically angry or frustrated by minor inconveniences that normally wouldn\'t bother you?',
      ),
      QuizQuestion(
        id: 'dep6',
        isCritical: true,
        text: 'How often has the future felt like a \'blank wall\' or a \'fog,\' where you find it impossible to imagine things getting better or feeling excited about upcoming events?',
      ),
      QuizQuestion(
        id: 'dep7',
        text: 'How often have you skipped basic hygiene (showering, brushing teeth, tidying your space) because it felt like too much effort?',
      ),
    ],
  ),

  QuizCategory(
    key: 'dyslexia',
    title: 'Processing\n& Literacy',
    fullName: 'Processing & Literacy',
    subtitle: 'Dyslexia',
    icon: Icons.menu_book_rounded,
    color: const Color(0xFFF97B6B),
    weight: 0.15,
    maxScore: 18, // 6 questions × max 3
    threshold: 9,
    options: const [
      QuizOption(label: 'No', value: 0),
      QuizOption(label: 'Occasionally', value: 1),
      QuizOption(label: 'Frequently', value: 2),
      QuizOption(label: 'Always', value: 3),
    ],
    questions: const [
      QuizQuestion(
        id: 'dys1',
        text: 'Do you find yourself reading the same paragraph multiple times to understand it?',
      ),
      QuizQuestion(
        id: 'dys2',
        text: 'Do you feel more comfortable expressing your ideas out loud than writing them down?',
      ),
      QuizQuestion(
        id: 'dys3',
        text: 'Do you find it difficult to tell \'left\' from \'right\' quickly or follow multi-step directions?',
      ),
      QuizQuestion(
        id: 'dys4',
        text: 'Do you struggle with spelling, even for common words, or rely heavily on spell-check?',
      ),
      QuizQuestion(
        id: 'dys5',
        text: 'Do you find it exhausting to read for long periods of time?',
      ),
      QuizQuestion(
        id: 'dys6',
        text: 'When reading aloud, do you skip over words or lose your place on the page?',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers used by StudentQuizStart (options list for current category)
// ─────────────────────────────────────────────────────────────────────────────

List<String> getOptionsForCategory(String categoryKey) {
  final cat = quizCategories.firstWhere((c) => c.key == categoryKey);
  return cat.options.map((o) => o.label).toList();
}

/// Maps option label index → actual score value for a category
int getScoreValueForIndex(String categoryKey, int index) {
  final cat = quizCategories.firstWhere((c) => c.key == categoryKey);
  return cat.options[index].value;
}