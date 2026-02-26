import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class QuizCategory {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<QuizQuestion> questions;

  const QuizCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.questions,
  });
}

class QuizQuestion {
  final int id;         // global question ID for backend scoring
  final String text;

  const QuizQuestion({required this.id, required this.text});
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer options per category
// ─────────────────────────────────────────────────────────────────────────────

// ADHD & Anxiety share: Never / Sometimes / Often / Very Often  → score 0-3
const List<String> optionsFrequency = [
  'Never',
  'Sometimes',
  'Often',
  'Very Often',
];

// Depression shares: Not at all / Several days / More than half the days / Nearly every day → 0-3
const List<String> optionsDays = [
  'Not at all',
  'Several days',
  'More than half\nthe days',
  'Nearly every day',
];

// Dyslexia: No / Sometimes / Yes → 0-2 (map: No=0, Sometimes=1, Yes=2)
const List<String> optionsDyslexia = [
  'No',
  'Sometimes',
  'Yes',
];

// Anxiety uses same days scale
const List<String> optionsAnxiety = [
  'Not at all',
  'Several days',
  'Over half the days',
  'Nearly every day',
];

// ─────────────────────────────────────────────────────────────────────────────
// All quiz categories & questions  (IDs match backend question_id mapping)
// ─────────────────────────────────────────────────────────────────────────────

final List<QuizCategory> quizCategories = [
  // ── Part 1: ADHD ──────────────────────────────────────────────────────────
  QuizCategory(
    key: 'adhd',
    title: 'Focus &\nEnergy',
    subtitle: 'ADHD Patterns',
    icon: Icons.bolt_rounded,
    questions: const [
      QuizQuestion(
        id: 1,
        text: 'When I have to do a boring or difficult assignment, I find it really hard to just get started.',
      ),
      QuizQuestion(
        id: 2,
        text: 'I make careless mistakes on tests or homework, even when I actually know the answers.',
      ),
      QuizQuestion(
        id: 3,
        text: 'I have trouble listening when someone is speaking to me directly; my mind feels like it\'s somewhere else.',
      ),
      QuizQuestion(
        id: 4,
        text: 'I lose important things I need for school (like my ID, keys, wallet, or notebooks).',
      ),
      QuizQuestion(
        id: 5,
        text: 'I fidget, tap my hands/feet, or feel like I can\'t sit still in class for long periods.',
      ),
      QuizQuestion(
        id: 6,
        text: 'I interrupt others or blurt out answers before the teacher finishes the question.',
      ),
      QuizQuestion(
        id: 7,
        text: 'I feel restless inside, like I\'m driven by a motor that won\'t stop.',
      ),
    ],
  ),

  // ── Part 2: Depression ────────────────────────────────────────────────────
  QuizCategory(
    key: 'depression',
    title: 'Mood &\nMotivation',
    subtitle: 'Depression Patterns',
    icon: Icons.sentiment_satisfied_alt_rounded,
    questions: const [
      QuizQuestion(
        id: 8,
        text: 'I feel little interest or pleasure in doing things I used to enjoy (gaming, sports, hanging out).',
      ),
      QuizQuestion(
        id: 9,
        text: 'I feel down, depressed, or hopeless.',
      ),
      QuizQuestion(
        id: 10,
        text: 'I have trouble falling asleep, or I sleep way too much.',
      ),
      QuizQuestion(
        id: 11,
        text: 'I feel tired or have little energy, even if I rested.',
      ),
      QuizQuestion(
        id: 12,
        text: 'I have a poor appetite (not hungry) or I am overeating.',
      ),
      QuizQuestion(
        id: 13,
        text: 'I feel bad about myself — like I am a failure or I have let my family or myself down.',
      ),
      QuizQuestion(
        id: 14,
        text: 'I have trouble concentrating on things like reading, watching movies, or listening in class.',
      ),
    ],
  ),

  // ── Part 3: Dyslexia ──────────────────────────────────────────────────────
  QuizCategory(
    key: 'dyslexia',
    title: 'Reading &\nWords',
    subtitle: 'Dyslexia Patterns',
    icon: Icons.menu_book_rounded,
    questions: const [
      QuizQuestion(
        id: 15,
        text: 'Do I read slowly and have to re-read lines to understand them?',
      ),
      QuizQuestion(
        id: 16,
        text: 'Do words seem to move, blur, or jump around on the page when I\'m tired?',
      ),
      QuizQuestion(
        id: 17,
        text: 'Is my spelling really inconsistent? (For example, I might spell the same word two different ways in one essay).',
      ),
      QuizQuestion(
        id: 18,
        text: 'Do I confuse words that sound similar or look similar?',
      ),
      QuizQuestion(
        id: 19,
        text: 'When I read aloud, do I skip small words (like "the", "of", "and") or guess the word based on the first letter?',
      ),
      QuizQuestion(
        id: 20,
        text: 'Is my handwriting messy or hard to read, even when I try?',
      ),
      QuizQuestion(
        id: 21,
        text: 'Do I struggle to tell "left" from "right" quickly?',
      ),
    ],
  ),

  // ── Part 4: Anxiety ───────────────────────────────────────────────────────
  QuizCategory(
    key: 'anxiety',
    title: 'Worry &\nStress',
    subtitle: 'ADHD Patterns',
    icon: Icons.self_improvement_rounded,
    questions: const [
      QuizQuestion(
        id: 22,
        text: 'I feel nervous, anxious, or on edge.',
      ),
      QuizQuestion(
        id: 23,
        text: 'I can\'t seem to stop or control my worrying.',
      ),
      QuizQuestion(
        id: 24,
        text: 'I worry too much about different things (grades, friends, future) all at once.',
      ),
      QuizQuestion(
        id: 25,
        text: 'I have trouble relaxing; I feel tense.',
      ),
      QuizQuestion(
        id: 26,
        text: 'I get physical symptoms like stomach aches or headaches before school or exams.',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helper: get answer options list for a given category key
// ─────────────────────────────────────────────────────────────────────────────

List<String> getOptionsForCategory(String key) {
  switch (key) {
    case 'depression':
      return optionsDays;
    case 'dyslexia':
      return optionsDyslexia;
    case 'anxiety':
      return optionsAnxiety;
    case 'adhd':
    default:
      return optionsFrequency;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Response model — passed to backend
// ─────────────────────────────────────────────────────────────────────────────

class QuizResponse {
  final int questionId;
  final int score;

  const QuizResponse({required this.questionId, required this.score});

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'score': score,
  };
}