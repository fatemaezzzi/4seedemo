// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

const String BASE_URL = 'https://varlett-4seedemo.hf.space';

// ============================================================================
// PREDICTION RESULT
// ============================================================================

class PredictionResult {
  final String riskLevel;
  final double riskScore;
  final String confidence;
  final double dropoutProbability;
  final List<String> riskFactors;
  final String recommendation;
  final double mentalHealthScore;
  final double behaviourScore;

  PredictionResult({
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
    final ai = json['ai_counselor'] ?? {};
    final riskScore = (json['risk_score'] ?? 0).toDouble();

    String confidence;
    switch (json['risk_level']) {
      case 'HIGH':   confidence = 'High';   break;
      case 'MEDIUM': confidence = 'Medium'; break;
      default:       confidence = 'Low';
    }

    final factorsMap = json['risk_factors'] as Map<String, dynamic>? ?? {};
    final factorsList = factorsMap.entries
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    final recommendation = [
      ai['risk_summary']   ?? '',
      ai['teacher_action'] ?? '',
      ai['long_term_plan'] ?? '',
    ].where((s) => s.isNotEmpty).join('\n\n');

    return PredictionResult(
      riskLevel:          json['risk_level'] ?? 'UNKNOWN',
      riskScore:          riskScore / 100,
      confidence:         confidence,
      dropoutProbability: riskScore,
      riskFactors:        factorsList,
      recommendation:     recommendation,
      mentalHealthScore:  (json['mental_health_score'] ?? 0).toDouble(),
      behaviourScore:     (json['behaviour_score']     ?? 0).toDouble(),
    );
  }
}

// ============================================================================
// INSIGHTS RESULT  — NEW
// ============================================================================

class InsightsResult {
  final String       tab;
  final List<String> insights;

  const InsightsResult({required this.tab, required this.insights});

  factory InsightsResult.fromJson(Map<String, dynamic> json) {
    return InsightsResult(
      tab:      json['tab']      as String? ?? '',
      insights: List<String>.from(json['insights'] as List? ?? []),
    );
  }
}

// ============================================================================
// API SERVICE
// ============================================================================

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _firebase = FirebaseService();

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$BASE_URL/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── PREDICT + SAVE ────────────────────────────────────────────────────────

  Future<PredictionResult> predictAndSave({
    required String studentId,
    required Map<String, dynamic> studentData,
  }) async {
    final apiPayload = _mapStudentToApiInput(studentData);

    final response = await http
        .post(
      Uri.parse('$BASE_URL/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(apiPayload),
    )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Prediction failed');
    }

    final result = PredictionResult.fromJson(jsonDecode(response.body));

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

  // ── GET INSIGHTS  (NEW) ───────────────────────────────────────────────────
  // Called by ReportPage._loadInsights() when a tab becomes active.
  // Returns LLM-written insight strings for that specific tab.

  Future<InsightsResult> getInsights({
    required String studentName,
    required String tab,               // "Mental Health" | "Academics" | "Attendance"
    required String riskLevel,
    required List<String> riskFactors,
    // Mental Health inputs
    double mentalHealthScore        = 50.0,
    Map<String, double> categoryScores = const {},
    double behaviourScore           = 50.0,
    int behaviourIncidents          = 0,
    int negativeIncidents           = 0,
    // Academics inputs
    double g1                       = 10.0,
    double g2                       = 10.0,
    int failures                    = 0,
    int studytime                   = 2,
    double dropoutProbability       = 0.0,
    // Attendance inputs
    double attendancePct            = 75.0,
    int presentDays                 = 0,
    int totalDays                   = 0,
    int absences                    = 0,
  }) async {
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
    };

    try {
      final response = await http
          .post(
        Uri.parse('$BASE_URL/insights'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return InsightsResult.fromJson(jsonDecode(response.body));
      }
      debugPrint('Insights API ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Insights network error: $e');
    }

    return InsightsResult(tab: tab, insights: _fallbackInsights(tab));
  }

  List<String> _fallbackInsights(String tab) {
    switch (tab) {
      case 'Mental Health':
        return [
          'Review student\'s recent behaviour for signs of stress.',
          'Consider scheduling a one-on-one check-in.',
          'Coordinate with the school counselor if issues persist.',
        ];
      case 'Academics':
        return [
          'Monitor grade trend closely over the next two weeks.',
          'Consider assigning a peer study partner.',
          'Review homework submission records for gaps.',
        ];
      case 'Attendance':
      default:
        return [
          'Contact parents if absences exceed 10 days.',
          'Check if absences cluster around specific subjects.',
          'Remind student of the 75% minimum attendance requirement.',
        ];
    }
  }

  Map<String, dynamic> _mapStudentToApiInput(Map<String, dynamic> s) {
    return {
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
      'debtor':         0,
      'tuition_paid':   1,
      'scholarship':    0,
      'sex':            1,
      'activities':     1,
      'higher':         1,
      'paid':           0,
      'guardian':       0,
      'pstatus':        s['Pstatus']   ?? 1,
      'attendance_type':1,
      'prev_qual':      1,
      'mjob':           5,
      'fjob':           5,
      'course':         9500,
    };
  }
}