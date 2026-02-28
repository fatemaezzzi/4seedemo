// prediction_service.dart
// ========================
// Place in: lib/services/prediction_service.dart
//
// This service collects data from all 4 inputs and triggers the ML prediction.
// Call PredictionService().tryTriggerPrediction() after ANY of the 4 inputs
// are completed for a student. It will auto-run when all 4 are ready.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

// ── What data we collect from each input source ──────────────────────────────

class AttendanceData {
  final String studentId;
  final int totalDays;
  final int presentDays;
  int get absences => totalDays - presentDays;

  AttendanceData({
    required this.studentId,
    required this.totalDays,
    required this.presentDays,
  });

  Map<String, dynamic> toJson() => {
    'totalDays': totalDays,
    'presentDays': presentDays,
    'absences': absences,
  };
}

class BehaviourData {
  final String studentId;
  final List<String> negativeTags; // ['Disruptive', 'Late', ...]
  final List<String> positiveTags; // ['Helpful', 'Punctual', ...]

  BehaviourData({
    required this.studentId,
    required this.negativeTags,
    required this.positiveTags,
  });

  // Converts behaviour tags → behaviour score (0-100, higher = worse)
  // Matches what your ML model expects
  double get behaviourScore {
    const negativeWeight = 10.0;
    const positiveWeight = 10.0;
    const maxScore = 100.0;

    final negScore = (negativeTags.length * negativeWeight).clamp(0.0, maxScore);
    final posScore = (positiveTags.length * positiveWeight).clamp(0.0, maxScore);
    return (negScore - posScore + 50).clamp(0.0, maxScore); // 50 = neutral
  }

  Map<String, dynamic> toJson() => {
    'negativeTags': negativeTags,
    'positiveTags': positiveTags,
    'behaviourScore': behaviourScore,
  };
}

class MarksData {
  final String studentId;
  final int g1; // previous grade (0-20 scale like your ML model uses)
  final int g2; // current grade
  final int maxMarks;
  final bool passed;

  MarksData({
    required this.studentId,
    required this.g1,
    required this.g2,
    required this.maxMarks,
    required this.passed,
  });

  // Normalize to 0-20 scale (what the ML model was trained on)
  int get g1Normalized => ((g1 / maxMarks) * 20).round().clamp(0, 20);
  int get g2Normalized => ((g2 / maxMarks) * 20).round().clamp(0, 20);

  Map<String, dynamic> toJson() => {
    'g1Raw': g1,
    'g2Raw': g2,
    'maxMarks': maxMarks,
    'G1': g1Normalized,
    'G2': g2Normalized,
    'passed': passed,
  };
}

class QuizData {
  final String studentId;
  final double overallScore; // 0-100 from QuizResultPage
  final Map<String, double> categoryScores; // {'anxiety': 0.6, ...}

  QuizData({
    required this.studentId,
    required this.overallScore,
    required this.categoryScores,
  });

  // mental_health_score: higher = better (quiz score directly)
  double get mentalHealthScore => overallScore;

  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'categoryScores': categoryScores,
    'mentalHealthScore': mentalHealthScore,
  };
}


// ── The main prediction service ───────────────────────────────────────────────

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  final _db = FirebaseFirestore.instance;
  final _api = ApiService();

  // ── STEP 1: Save each input to a staging collection in Firestore ──────────
  // This way data persists even if app closes between inputs

  Future<void> saveAttendance(AttendanceData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'attendance': data.toJson(),
      'attendanceAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await tryTriggerPrediction(data.studentId);
  }

  Future<void> saveBehaviour(BehaviourData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'behaviour': data.toJson(),
      'behaviourAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await tryTriggerPrediction(data.studentId);
  }

  Future<void> saveMarks(MarksData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'marks': data.toJson(),
      'marksAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await tryTriggerPrediction(data.studentId);
  }

  Future<void> saveQuiz(QuizData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'quiz': data.toJson(),
      'quizAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await tryTriggerPrediction(data.studentId);
  }

  // ── STEP 2: Check if all 4 inputs exist, then run prediction ─────────────

  Future<PredictionResult?> tryTriggerPrediction(String studentId) async {
    final doc = await _db.collection('staging').doc(studentId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final hasAttendance = data.containsKey('attendance');
    final hasBehaviour  = data.containsKey('behaviour');
    final hasMarks      = data.containsKey('marks');
    final hasQuiz       = data.containsKey('quiz');

    // Only run when ALL 4 are ready
    if (!hasAttendance || !hasBehaviour || !hasMarks || !hasQuiz) return null;

    // Already predicted? Skip
    if (data['predicted'] == true) return null;

    // Mark as in-progress to prevent duplicate runs
    await _db.collection('staging').doc(studentId).update({'predicted': true});

    // Build the combined payload for ML model
    final attendance = data['attendance'] as Map<String, dynamic>;
    final behaviour  = data['behaviour']  as Map<String, dynamic>;
    final marks      = data['marks']      as Map<String, dynamic>;
    final quiz       = data['quiz']       as Map<String, dynamic>;

    // Get student base data from Firestore
    final studentDoc = await _db.collection('students').doc(studentId).get();
    final studentBase = studentDoc.exists
        ? studentDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

    // Merge everything into one payload
    final combinedData = {
      ...studentBase,
      // Grades (normalized 0-20)
      'G1': marks['G1'] ?? 10,
      'G2': marks['G2'] ?? 10,
      // Absences from attendance
      'absences': attendance['absences'] ?? 0,
      // Mental health from quiz
      'mentalHealthScore': quiz['mentalHealthScore'] ?? 50.0,
      // Behaviour score
      'behaviourScore': behaviour['behaviourScore'] ?? 50.0,
      // Raw inputs for audit trail
      'rawAttendance': attendance,
      'rawBehaviour': behaviour,
      'rawMarks': marks,
      'rawQuiz': quiz,
    };

    // Run ML prediction + save to Firebase predictions collection
    final result = await _api.predictAndSave(
      studentId: studentId,
      studentData: combinedData,
    );

    return result;
  }

  // ── STEP 3: Check completion status for a student ────────────────────────
  // Use this to show progress in your UI (e.g. 3/4 inputs done)

  Future<Map<String, bool>> getInputStatus(String studentId) async {
    final doc = await _db.collection('staging').doc(studentId).get();
    if (!doc.exists) {
      return {
        'attendance': false,
        'behaviour': false,
        'marks': false,
        'quiz': false,
      };
    }
    final data = doc.data()!;
    return {
      'attendance': data.containsKey('attendance'),
      'behaviour':  data.containsKey('behaviour'),
      'marks':      data.containsKey('marks'),
      'quiz':       data.containsKey('quiz'),
    };
  }

  // ── Reset staging (call after prediction or new term) ────────────────────

  Future<void> resetStaging(String studentId) async {
    await _db.collection('staging').doc(studentId).delete();
  }
}