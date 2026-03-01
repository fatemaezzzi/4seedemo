// lib/services/prediction_service.dart
// ======================================
// ROOT CAUSE OF ATTENTION SECTION BEING EMPTY:
//
//   _tryTriggerPrediction() called _api.predictAndSave()
//   If API returned null OR threw → the entire Firestore write was skipped
//   _fallbackClassifyAndSave() was defined but NEVER called
//   predictions/{studentId} was never written → dashboard shows nothing
//
// THIS VERSION GUARANTEES Firestore is always written:
//   1. Try real ML model via FastAPI
//   2. If that fails for ANY reason → ABC fallback runs immediately
//   3. Both paths write to predictions/{studentId} AND students/{id}.riskLevel
//   4. Dashboard Attention section will ALWAYS have data after a save

import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES  (unchanged — keep these as-is)
// ─────────────────────────────────────────────────────────────────────────────

class AttendanceData {
  final String studentId;
  final int totalDays;
  final int presentDays;

  const AttendanceData({
    required this.studentId,
    required this.totalDays,
    required this.presentDays,
  });

  int get absences => totalDays - presentDays;

  Map<String, dynamic> toJson() => {
    'totalDays':   totalDays,
    'presentDays': presentDays,
    'absences':    absences,
  };
}

class MarksData {
  final String studentId;
  final int g1;
  final int g2;
  final int maxMarks;
  final bool passed;

  const MarksData({
    required this.studentId,
    required this.g1,
    required this.g2,
    required this.maxMarks,
    required this.passed,
  });

  int get g1Normalized => ((g1 / maxMarks) * 20).round().clamp(0, 20);
  int get g2Normalized => ((g2 / maxMarks) * 20).round().clamp(0, 20);
  double get averagePct => ((g1 + g2) / (maxMarks * 2)) * 100;

  Map<String, dynamic> toJson() => {
    'g1Raw':    g1,
    'g2Raw':    g2,
    'maxMarks': maxMarks,
    'G1':       g1Normalized,
    'G2':       g2Normalized,
    'passed':   passed,
    'avgPct':   averagePct,
  };
}

class BehaviourIncident {
  final String   studentId;
  final String   description;
  final DateTime date;

  const BehaviourIncident({
    required this.studentId,
    required this.description,
    required this.date,
  });
}

class BehaviourData {
  final String       studentId;
  final List<String> negativeTags;
  final List<String> positiveTags;

  const BehaviourData({
    required this.studentId,
    required this.negativeTags,
    required this.positiveTags,
  });

  double get behaviourScore {
    final negScore = (negativeTags.length * 10.0).clamp(0.0, 100.0);
    final posScore = (positiveTags.length * 10.0).clamp(0.0, 100.0);
    return (negScore - posScore + 50).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() => {
    'negativeTags':   negativeTags,
    'positiveTags':   positiveTags,
    'behaviourScore': behaviourScore,
  };
}

class QuizData {
  final String              studentId;
  final double              overallScore;
  final Map<String, double> categoryScores;

  const QuizData({
    required this.studentId,
    required this.overallScore,
    required this.categoryScores,
  });

  double get mentalHealthScore => overallScore;

  Map<String, dynamic> toJson() => {
    'overallScore':      overallScore,
    'categoryScores':    categoryScores,
    'mentalHealthScore': mentalHealthScore,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// PREDICTION SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  final _db  = FirebaseFirestore.instance;
  final _api = ApiService();

  // ── SAVE ATTENDANCE ──────────────────────────────────────────────────────────

  Future<void> saveAttendance(AttendanceData data) async {
    // 1. Accumulate cumulative totals on student doc (source of truth for absences)
    await _db.collection('students').doc(data.studentId).set({
      'totalDays':   FieldValue.increment(data.totalDays),
      'presentDays': FieldValue.increment(data.presentDays),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Stage today's snapshot (used by ML payload builder)
    await _db.collection('staging').doc(data.studentId).set({
      'attendance':   data.toJson(),
      'attendanceAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Classify immediately — guaranteed to write even if API fails
    await _classifyAndWrite(data.studentId);
  }

  // ── SAVE MARKS ───────────────────────────────────────────────────────────────

  Future<void> saveMarks(MarksData data) async {
    // Persist to student doc for riskFactor display
    await _db.collection('students').doc(data.studentId).set({
      'averageMarks': data.averagePct,
      'lastUpdated':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('staging').doc(data.studentId).set({
      'marks':   data.toJson(),
      'marksAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _classifyAndWrite(data.studentId);
  }

  // ── SAVE BEHAVIOUR (tag-based, from behaviour form page) ─────────────────────

  Future<void> saveBehaviour(BehaviourData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'behaviour':   data.toJson(),
      'behaviourAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _classifyAndWrite(data.studentId);
  }

  // ── LOG BEHAVIOUR INCIDENT (one-tap ⚠️ button from student list) ─────────────

  Future<void> saveBehaviourIncident(BehaviourIncident incident) async {
    final studentRef = _db.collection('students').doc(incident.studentId);
    final severity   = _incidentSeverity(incident.description);

    // Log to audit trail
    await studentRef.collection('behaviourLog').add({
      'description': incident.description,
      'date':        Timestamp.fromDate(incident.date),
      'severity':    severity,
    });

    // Accumulate penalty on student doc
    await _db.runTransaction((tx) async {
      final snap     = await tx.get(studentRef);
      final existing = snap.data() ?? {};
      tx.set(studentRef, {
        'incidentCount':    ((existing['incidentCount']    as num?)?.toInt()    ?? 0) + 1,
        'behaviourPenalty': ((existing['behaviourPenalty'] as num?)?.toDouble() ?? 0.0) + severity,
        'lastIncident':     incident.description,
        'lastUpdated':      FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // Sync behaviour penalty → staging so ML payload picks it up
    final updatedSnap  = await studentRef.get();
    final updatedData  = updatedSnap.data() ?? {};
    final totalPenalty = (updatedData['behaviourPenalty'] as num?)?.toDouble() ?? 0.0;
    final count        = (updatedData['incidentCount']    as num?)?.toInt()    ?? 1;

    // behaviourScore: 50 = neutral, each incident pushes it higher
    final behaviourScore = (50.0 + (totalPenalty * 5.0)).clamp(0.0, 100.0);

    await _db.collection('staging').doc(incident.studentId).set({
      'behaviour': {
        'negativeTags':   List.generate(count, (i) => 'Incident ${i + 1}'),
        'positiveTags':   <String>[],
        'behaviourScore': behaviourScore,
        'incidentCount':  count,
        'totalPenalty':   totalPenalty,
      },
      'behaviourAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Classify immediately
    await _classifyAndWrite(incident.studentId);
  }

  // ── SAVE QUIZ ────────────────────────────────────────────────────────────────

  Future<void> saveQuiz(QuizData data) async {
    await _db.collection('staging').doc(data.studentId).set({
      'quiz':   data.toJson(),
      'quizAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _classifyAndWrite(data.studentId);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CORE: CLASSIFY AND WRITE
  // This is the only method that writes to predictions/ and students/.
  // It ALWAYS writes — API success or failure.
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _classifyAndWrite(String studentId) async {
    // Pull the latest student doc (cumulative totals live here)
    final studentSnap = await _db.collection('students').doc(studentId).get();
    final studentData = studentSnap.exists ? studentSnap.data()! : <String, dynamic>{};

    // Pull staging (today's inputs)
    final stagingSnap = await _db.collection('staging').doc(studentId).get();
    final staged      = stagingSnap.exists ? stagingSnap.data()! : <String, dynamic>{};

    // ── Read cumulative attendance from student doc (NOT from staging) ────────
    // staging['attendance'] only has today's 1 day — not the real total.
    final totalDays   = (studentData['totalDays']   as num?)?.toInt()    ?? 0;
    final presentDays = (studentData['presentDays'] as num?)?.toInt()    ?? 0;
    final attendancePct = totalDays > 0
        ? (presentDays / totalDays) * 100.0
        : 100.0; // No data yet = assume fine
    final absences = totalDays - presentDays;

    // ── Marks from student doc (persisted on every saveMarks call) ────────────
    final avgMarksPct = (studentData['averageMarks'] as num?)?.toDouble() ?? 100.0;

    // ── G1/G2 from staging (normalized 0–20 for ML model) ────────────────────
    final marksStaged = staged['marks'] as Map<String, dynamic>?;
    final g1 = (marksStaged?['G1'] as num?)?.toInt() ?? 10;
    final g2 = (marksStaged?['G2'] as num?)?.toInt() ?? 10;

    // ── Behaviour from staging (or neutral if not yet submitted) ─────────────
    final behaviourStaged = staged['behaviour'] as Map<String, dynamic>?;
    final behaviourScore  = (behaviourStaged?['behaviourScore'] as num?)?.toDouble() ?? 50.0;

    // ── Quiz from staging (or neutral if not yet submitted) ───────────────────
    final quizStaged       = staged['quiz'] as Map<String, dynamic>?;
    final mentalHealthScore = (quizStaged?['mentalHealthScore'] as num?)?.toDouble() ?? 50.0;

    final incidentCount    = (studentData['incidentCount']    as num?)?.toInt()    ?? 0;
    final behaviourPenalty = (studentData['behaviourPenalty'] as num?)?.toDouble() ?? 0.0;
    final studentName      = studentData['name'] as String? ?? 'Student';

    // ── Step 1: Try the real ML model ────────────────────────────────────────
    String riskLevel;
    double riskScore;
    bool   usedFallback = false;

    try {
      // Only attempt API if we have meaningful data (not all defaults)
      final hasRealData = totalDays > 0 || avgMarksPct < 100.0;

      PredictionResult? apiResult;
      if (hasRealData) {
        final mlPayload = {
          // Static profile fields
          'Course':                      studentData['course']               ?? 1,
          'age':                         studentData['age']                  ?? 18,
          'Gender':                      studentData['gender']               ?? 1,
          'Scholarship_holder':          studentData['scholarshipHolder']    ?? 0,
          'Debtor':                      studentData['debtor']               ?? 0,
          'Tuition_fees_up_to_date':     studentData['tuitionFeesUpToDate']  ?? 1,
          'Educational_special_needs':   studentData['specialNeeds']         ?? 0,
          'schoolsup':                   studentData['schoolSupport']        ?? 0,
          'famsup':                      studentData['familySupport']        ?? 0,
          'paid':                        studentData['paidClasses']          ?? 0,
          'activities':                  studentData['activities']           ?? 0,
          'higher':                      studentData['higherEducation']      ?? 1,
          'internet':                    studentData['internet']             ?? 1,
          'Mjob':                        studentData['motherJob']            ?? 0,
          'Fjob':                        studentData['fatherJob']            ?? 0,
          'famrel':                      studentData['familyRelation']       ?? 3,
          'health':                      studentData['health']               ?? 3,
          'failures':                    studentData['failures']             ?? 0,
          'studytime':                   studentData['studytime']            ?? 2,
          // Dynamic teacher inputs — HIGH priority
          'G1':                          g1,
          'G2':                          g2,
          'absences':                    absences,
          // Dynamic — MEDIUM priority
          'behaviourScore':              behaviourScore,
          'mentalHealthScore':           mentalHealthScore,
        };

        apiResult = await _api.predictAndSave(
          studentId:   studentId,
          studentData: mlPayload,
        );
      }

      if (apiResult != null) {
        // ── Map ML model output → HIGH / MEDIUM / LOW ──────────────────────
        // ML model returns binary: 1 = Dropout, 0 = Graduate
        // We map that + the riskScore probability to our 3-tier system
        riskLevel = _mapApiResultToRiskLevel(apiResult);
        riskScore = apiResult.riskScore;
      } else {
        throw Exception('API returned null — using fallback');
      }
    } catch (_) {
      // ── Step 2: ABC fallback — always runs if API fails ───────────────────
      usedFallback = true;
      final aScore  = _attendanceRiskScore(attendancePct);
      final bScore  = (behaviourPenalty / 10.0).clamp(0.0, 1.0);
      final cScore  = _marksRiskScore(avgMarksPct);
      riskScore     = (0.40 * aScore) + (0.20 * bScore) + (0.40 * cScore);

      if (riskScore >= 0.60)      riskLevel = 'HIGH';
      else if (riskScore >= 0.35) riskLevel = 'MEDIUM';
      else                        riskLevel = 'LOW';
    }

    // ── Build human-readable risk factors ─────────────────────────────────
    final riskFactors = _buildRiskFactors(
      attendancePct:  attendancePct,
      avgMarksPct:    avgMarksPct,
      incidentCount:  incidentCount,
      behaviourScore: behaviourScore,
    );

    final recommendation = _getRecommendation(riskLevel, riskFactors);

    // ── WRITE 1: predictions/{studentId} ──────────────────────────────────
    // Doc ID = studentId → always 1 doc per student, always latest
    // Dashboard teacher_dashboard.dart queries this collection with:
    //   .where('studentId', whereIn: chunk)
    // and reads: risk_level, risk_factors, recommendation, studentName, timestamp
    await _db.collection('predictions').doc(studentId).set({
      'studentId':       studentId,        // ← queried by dashboard
      'studentName':     studentName,      // ← displayed in Attention card
      'risk_level':      riskLevel,        // ← 'HIGH' / 'MEDIUM' / 'LOW'
      'risk_score':      riskScore,
      'risk_factors':    riskFactors,      // ← shown in detail popup
      'recommendation':  recommendation,   // ← shown in detail popup
      'attendance_pct':  attendancePct,
      'behaviour_score': behaviourScore,
      'marks_avg_pct':   avgMarksPct,
      'timestamp':       FieldValue.serverTimestamp(), // ← dashboard picks latest
      'fallback':        usedFallback,
    });

    // ── WRITE 2: students/{studentId} ─────────────────────────────────────
    // Dashboard falls back to this if predictions/ query returns nothing.
    // student_model.dart RiskLevel enum uses lowercase strings.
    await _db.collection('students').doc(studentId).set({
      'riskLevel':      riskLevel.toLowerCase(), // 'high' / 'medium' / 'low'
      'riskScore':      riskScore,
      'riskFactors':    riskFactors,
      'recommendation': recommendation,
      'lastClassified': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAP ML MODEL OUTPUT → HIGH / MEDIUM / LOW
  // ML model (train_model_two.py) outputs binary: 1 = Dropout, 0 = Graduate
  // plus a probability score. Map both to the 3-tier system.
  // ─────────────────────────────────────────────────────────────────────────────

  String _mapApiResultToRiskLevel(PredictionResult result) {
    // If the model returns a string directly, normalise it
    final raw = result.riskLevel.trim().toUpperCase();

    // Already in correct format
    if (raw == 'HIGH' || raw == 'MEDIUM' || raw == 'LOW') return raw;

    // Binary model output: "1" or "DROPOUT" → use probability for tier
    if (raw == '1' || raw == 'DROPOUT') {
      if (result.riskScore >= 0.75) return 'HIGH';
      return 'MEDIUM';
    }

    // Binary model output: "0" or "GRADUATE" → low risk
    if (raw == '0' || raw == 'GRADUATE') return 'LOW';

    // Probability-only fallback (if riskLevel field is empty/unexpected)
    if (result.riskScore >= 0.60) return 'HIGH';
    if (result.riskScore >= 0.35) return 'MEDIUM';
    return 'LOW';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SCORING HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  double _attendanceRiskScore(double pct) {
    if (pct < 60) return 1.0;
    if (pct < 75) return 0.75;
    if (pct < 85) return 0.40;
    return 0.10;
  }

  double _marksRiskScore(double marks) {
    if (marks < 35) return 1.0;
    if (marks < 50) return 0.75;
    if (marks < 65) return 0.40;
    return 0.10;
  }

  int _incidentSeverity(String description) {
    final d = description.toLowerCase();
    if (d.contains('absent without') || d.contains('withdrawn') || d.contains('conflict'))     return 3;
    if (d.contains('disruptive')     || d.contains('unprepared') || d.contains('unmotivated')
        || d.contains('sleeping'))                                                                 return 2;
    return 1;
  }

  List<String> _buildRiskFactors({
    required double attendancePct,
    required double avgMarksPct,
    required int    incidentCount,
    required double behaviourScore,
  }) {
    final f = <String>[];
    if (attendancePct < 60)
      f.add('Attendance ${attendancePct.toStringAsFixed(0)}% — critically low');
    else if (attendancePct < 75)
      f.add('Attendance ${attendancePct.toStringAsFixed(0)}% — below 75% threshold');
    else if (attendancePct < 85)
      f.add('Attendance ${attendancePct.toStringAsFixed(0)}% — slightly below ideal');

    if (avgMarksPct < 35)
      f.add('Marks ${avgMarksPct.toStringAsFixed(0)}% — failing range');
    else if (avgMarksPct < 50)
      f.add('Marks ${avgMarksPct.toStringAsFixed(0)}% — below passing');
    else if (avgMarksPct < 65)
      f.add('Marks ${avgMarksPct.toStringAsFixed(0)}% — below average');

    if (incidentCount >= 3)
      f.add('$incidentCount behaviour incidents logged');
    else if (incidentCount > 0)
      f.add('$incidentCount behaviour incident${incidentCount > 1 ? 's' : ''} noted');

    if (f.isEmpty) f.add('All indicators within normal range');
    return f;
  }

  String _getRecommendation(String riskLevel, List<String> factors) {
    switch (riskLevel) {
      case 'HIGH':
        if (factors.any((f) => f.contains('Attendance')))
          return 'URGENT: Call parents immediately. Attendance critically low. '
              'Consider home visit or social worker referral. '
              'Create an Individual Attendance Plan with weekly check-ins.';
        if (factors.any((f) => f.contains('Marks')))
          return 'URGENT: Arrange one-on-one remedial sessions this week. '
              'Refer to school counsellor. Consider an IEP. '
              'Explore NGO tutoring support.';
        if (factors.any((f) => f.contains('behaviour') || f.contains('incident')))
          return 'URGENT: Schedule meeting with parents and counsellor. '
              'Develop a formal Behaviour Intervention Plan. '
              'Consider referral to external social services.';
        return 'URGENT: Multi-factor dropout risk. Convene a student support '
            'meeting with parents, counsellor, and class teacher within 48 hours.';
      case 'MEDIUM':
        return 'Set up weekly 10-minute check-ins with this student. '
            'Send a parent SMS update this week. '
            'Assign a peer mentor. Monitor closely for 2 weeks before escalating.';
      default:
        return 'Keep up positive reinforcement. '
            'Ensure student feels included in class activities. '
            'Student is currently on track — maintain engagement.';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────────────────────────────────────

  Future<Map<String, bool>> getInputStatus(String studentId) async {
    final doc = await _db.collection('staging').doc(studentId).get();
    if (!doc.exists) {
      return {'attendance': false, 'behaviour': false, 'marks': false, 'quiz': false};
    }
    final data = doc.data()!;
    return {
      'attendance': data.containsKey('attendance'),
      'behaviour':  data.containsKey('behaviour'),
      'marks':      data.containsKey('marks'),
      'quiz':       data.containsKey('quiz'),
    };
  }

  Future<void> resetStaging(String studentId) async {
    await _db.collection('staging').doc(studentId).delete();
  }
}