// lib/services/api_service.dart
// ============================================================
// LONGITUDINAL CHANGES:
//   • InsightSession model mirrors Firestore llm_insights schema
//   • getInsights() fetches ALL past sessions from Firestore first,
//     passes them to /insights endpoint as history[],
//     then saves the new session back to Firestore automatically
//   • InsightsResult now includes the full updated history
//   • predictAndSave() unchanged

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

const String BASE_URL = 'https://varlett-4seedemo.hf.space';

// ============================================================================
// MODELS
// ============================================================================

class PredictionResult {
  final String       riskLevel;
  final double       riskScore;
  final String       confidence;
  final double       dropoutProbability;
  final List<String> riskFactors;
  final String       recommendation;
  final double       mentalHealthScore;
  final double       behaviourScore;

  const PredictionResult({
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.dropoutProbability,
    required this.riskFactors,
    required this.recommendation,
    required this.mentalHealthScore,
    required this.behaviourScore,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final ai        = json['ai_counselor'] as Map<String, dynamic>? ?? {};
    final riskScore = (json['risk_score'] ?? 0).toDouble();
    final level     = json['risk_level'] as String? ?? 'UNKNOWN';

    final confidence = level == 'HIGH' ? 'High' : level == 'MEDIUM' ? 'Medium' : 'Low';

    final rawFactors = json['risk_factors'];
    List<String> factors = [];
    if (rawFactors is List)              factors = rawFactors.map((e) => e.toString()).toList();
    else if (rawFactors is Map<String, dynamic>)
      factors = rawFactors.entries.map((e) => '${e.key}: ${e.value}').toList();

    final rec = [ai['risk_summary'] ?? '', ai['teacher_action'] ?? '', ai['long_term_plan'] ?? '']
        .where((s) => s.isNotEmpty).join('\n\n');

    return PredictionResult(
      riskLevel:          level,
      riskScore:          riskScore / 100,
      confidence:         confidence,
      dropoutProbability: riskScore,
      riskFactors:        factors,
      recommendation:     rec,
      mentalHealthScore:  (json['mental_health_score'] ?? 0).toDouble(),
      behaviourScore:     (json['behaviour_score']     ?? 0).toDouble(),
    );
  }
}

// ── Insight session  ──────────────────────────────────────────────────────────
// One entry in Firestore: llm_insights/{studentId}/sessions/{autoId}

class InsightSession {
  final String       sessionId;        // Firestore doc ID
  final String       date;             // "DD MMM YYYY"  e.g. "15 Mar 2025"
  final String       tab;              // "Mental Health" | "Academics" | "Attendance"
  final String       riskLevel;
  final List<String> insights;
  final DateTime     timestamp;
  // Metric snapshots — stored so the LLM can compute trends
  final double?      mentalHealthScore;
  final double?      behaviourScore;
  final double?      attendancePct;
  final double?      g1;
  final double?      g2;

  const InsightSession({
    required this.sessionId,
    required this.date,
    required this.tab,
    required this.riskLevel,
    required this.insights,
    required this.timestamp,
    this.mentalHealthScore,
    this.behaviourScore,
    this.attendancePct,
    this.g1,
    this.g2,
  });

  factory InsightSession.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return InsightSession(
      sessionId:          id,
      date:               data['date']       as String? ?? '',
      tab:                data['tab']        as String? ?? '',
      riskLevel:          data['risk_level'] as String? ?? 'LOW',
      insights:           List<String>.from(data['insights'] as List? ?? []),
      timestamp:          dt,
      mentalHealthScore:  (data['mental_health_score'] as num?)?.toDouble(),
      behaviourScore:     (data['behaviour_score']     as num?)?.toDouble(),
      attendancePct:      (data['attendance_pct']      as num?)?.toDouble(),
      g1:                 (data['g1']                  as num?)?.toDouble(),
      g2:                 (data['g2']                  as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toApiJson() => {
    'date':                 date,
    'tab':                  tab,
    'risk_level':           riskLevel,
    'insights':             insights,
    'mental_health_score':  mentalHealthScore,
    'behaviour_score':      behaviourScore,
    'attendance_pct':       attendancePct,
    'g1':                   g1,
    'g2':                   g2,
  };

  Map<String, dynamic> toFirestore() => {
    'date':                 date,
    'tab':                  tab,
    'risk_level':           riskLevel,
    'insights':             insights,
    'timestamp':            Timestamp.fromDate(timestamp),
    'mental_health_score':  mentalHealthScore,
    'behaviour_score':      behaviourScore,
    'attendance_pct':       attendancePct,
    'g1':                   g1,
    'g2':                   g2,
  };
}

// ── Insights result ───────────────────────────────────────────────────────────

class InsightsResult {
  final String            tab;
  final List<String>      insights;
  final List<InsightSession> history;   // full updated history (oldest → newest)

  const InsightsResult({
    required this.tab,
    required this.insights,
    required this.history,
  });
}


// ============================================================================
// API SERVICE
// ============================================================================

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _firebase = FirebaseService();
  final _db       = FirebaseFirestore.instance;

  // ── Firestore path ─────────────────────────────────────────────────────────
  // llm_insights/{studentId}/sessions/{autoId}
  CollectionReference _sessionsRef(String studentId) => _db
      .collection('llm_insights')
      .doc(studentId)
      .collection('sessions');

  // ── Health check ───────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final r = await http.get(Uri.parse('$BASE_URL/health'))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── PREDICT + SAVE (unchanged) ─────────────────────────────────────────────

  Future<PredictionResult> predictAndSave({
    required String studentId,
    required Map<String, dynamic> studentData,
  }) async {
    final resp = await http.post(
      Uri.parse('$BASE_URL/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_mapToApiInput(studentData)),
    ).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception((jsonDecode(resp.body) as Map)['detail'] ?? 'Prediction failed');
    }

    final result = PredictionResult.fromJson(jsonDecode(resp.body));

    await _firebase.savePrediction(
      studentId:          studentId,
      riskLevel:          result.riskLevel,
      riskScore:          result.riskScore,
      confidence:         result.confidence,
      dropoutProbability: result.dropoutProbability,
      riskFactors:        result.riskFactors,
      recommendation:     result.recommendation,
      inputFeatures:      studentData,
    );

    return result;
  }

  // ── GET INSIGHTS  (LONGITUDINAL) ───────────────────────────────────────────
  // 1. Fetch ALL past sessions for this student + tab from Firestore
  // 2. Call /insights with current data + full history
  // 3. Save the new session back to Firestore
  // 4. Return new insights + updated history to the caller

  Future<InsightsResult> getInsights({
    required String studentId,
    required String studentName,
    required String tab,
    required String riskLevel,
    required List<String> riskFactors,
    // Current metrics
    double mentalHealthScore        = 50.0,
    Map<String, double> categoryScores = const {},
    double behaviourScore           = 50.0,
    int    behaviourIncidents        = 0,
    int    negativeIncidents         = 0,
    double g1                       = 10.0,
    double g2                       = 10.0,
    int    failures                  = 0,
    int    studytime                 = 2,
    double dropoutProbability        = 0.0,
    double attendancePct             = 75.0,
    int    presentDays               = 0,
    int    totalDays                 = 0,
    int    absences                  = 0,
  }) async {
    // ── Step 1: load full history from Firestore ───────────────────────────
    List<InsightSession> history = [];
    try {
      final snap = await _sessionsRef(studentId)
          .where('tab', isEqualTo: tab)
          .orderBy('timestamp', descending: false)   // oldest first
          .get();
      history = snap.docs
          .map((d) => InsightSession.fromFirestore(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('History load error: $e');
      // Non-fatal — proceed without history
    }

    // ── Step 2: call /insights with full history ───────────────────────────
    final payload = {
      'student_name':        studentName,
      'tab':                 tab,
      'risk_level':          riskLevel,
      'risk_factors':        riskFactors,
      'mental_health_score': mentalHealthScore,
      'category_scores':     categoryScores,
      'behaviour_score':     behaviourScore,
      'behaviour_incidents': behaviourIncidents,
      'negative_incidents':  negativeIncidents,
      'g1':                  g1,
      'g2':                  g2,
      'failures':            failures,
      'studytime':           studytime,
      'dropout_probability': dropoutProbability,
      'attendance_pct':      attendancePct,
      'present_days':        presentDays,
      'total_days':          totalDays,
      'absences':            absences,
      // Full history as list of JSON objects
      'history':             history.map((s) => s.toApiJson()).toList(),
    };

    List<String> newInsights = [];
    try {
      final resp = await http.post(
        Uri.parse('$BASE_URL/insights'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 35));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        newInsights = List<String>.from(body['insights'] as List? ?? []);
      } else {
        debugPrint('Insights API ${resp.statusCode}: ${resp.body}');
        newInsights = _fallback(tab);
      }
    } catch (e) {
      debugPrint('Insights network error: $e');
      newInsights = _fallback(tab);
    }

    // ── Step 3: save new session to Firestore ─────────────────────────────
    final now     = DateTime.now();
    final dateStr = _formatDate(now);

    final newSession = InsightSession(
      sessionId:          '',           // Firestore will assign ID
      date:               dateStr,
      tab:                tab,
      riskLevel:          riskLevel,
      insights:           newInsights,
      timestamp:          now,
      mentalHealthScore:  mentalHealthScore,
      behaviourScore:     behaviourScore,
      attendancePct:      attendancePct,
      g1:                 g1,
      g2:                 g2,
    );

    String savedId = '';
    try {
      final ref = await _sessionsRef(studentId).add(newSession.toFirestore());
      savedId   = ref.id;
    } catch (e) {
      debugPrint('Session save error: $e');
    }

    // ── Step 4: return updated history ────────────────────────────────────
    final savedSession = InsightSession(
      sessionId:          savedId,
      date:               dateStr,
      tab:                tab,
      riskLevel:          riskLevel,
      insights:           newInsights,
      timestamp:          now,
      mentalHealthScore:  mentalHealthScore,
      behaviourScore:     behaviourScore,
      attendancePct:      attendancePct,
      g1:                 g1,
      g2:                 g2,
    );

    return InsightsResult(
      tab:      tab,
      insights: newInsights,
      history:  [...history, savedSession],
    );
  }

  // ── Load history only (for StudentProfilePage timeline) ───────────────────
  Future<List<InsightSession>> loadInsightHistory({
    required String studentId,
    String? tab,        // null = all tabs
  }) async {
    try {
      Query q = _sessionsRef(studentId).orderBy('timestamp', descending: false);
      if (tab != null) q = q.where('tab', isEqualTo: tab);
      final snap = await q.get();
      return snap.docs
          .map((d) => InsightSession.fromFirestore(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('loadInsightHistory error: $e');
      return [];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
  }

  List<String> _fallback(String tab) {
    switch (tab) {
      case 'Mental Health':
        return ['Review student\'s recent behaviour for signs of stress.',
          'Consider scheduling a one-on-one check-in.',
          'Coordinate with school counselor if issues persist.'];
      case 'Academics':
        return ['Monitor grade trend closely over the next two weeks.',
          'Consider assigning a peer study partner.',
          'Review homework submission records for gaps.'];
      default:
        return ['Contact parents if absences exceed 10 days.',
          'Check if absences cluster around specific subjects.',
          'Remind student of the 75% minimum attendance requirement.'];
    }
  }

  Map<String, dynamic> _mapToApiInput(Map<String, dynamic> s) => {
    'current_grade':  (s['G2'] ?? s['G1'] ?? 10).toDouble(),
    'previous_grade': (s['G1'] ?? 10).toDouble(),
    'failures':       s['failures']  ?? 0,
    'studytime':      s['studytime'] ?? 2,
    'absences':       s['absences']  ?? 0,
    'age':            s['age']       ?? 18,
    'health':         s['health']    ?? 3,
    'famrel':         s['famrel']    ?? 3,
    'internet':       s['internet']  ?? 0,
    'schoolsup':      s['schoolsup'] ?? 0,
    'famsup':         s['famsup']    ?? 0,
    'famsize':        s['famsize']   ?? 1,
    'debtor':         0, 'tuition_paid': 1, 'scholarship': 0,
    'sex': 1, 'activities': 1, 'higher': 1, 'paid': 0, 'guardian': 0,
    'pstatus':        s['Pstatus']   ?? 1,
    'attendance_type':1, 'prev_qual': 1, 'mjob': 5, 'fjob': 5, 'course': 9500,
  };
}