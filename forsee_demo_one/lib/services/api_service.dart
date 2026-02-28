// api_service.dart
// ==================
// Place in: lib/services/api_service.dart
// Calls FastAPI backend + saves to Firebase matching your team's structure

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

const String BASE_URL = 'https://varlett-4seedemo.hf.space';

// ============================================================================
// PREDICTION RESULT — matches your Firestore predictions structure
// ============================================================================

class PredictionResult {
  final String riskLevel;          // "LOW", "MEDIUM", "HIGH"
  final double riskScore;          // 0-1
  final String confidence;         // "High", "Medium", "Low"
  final double dropoutProbability; // percentage e.g. 4.44
  final List<String> riskFactors;  // ["Multiple past failures", ...]
  final String recommendation;     // AI counselor text
  final double mentalHealthScore;  // 0-100
  final double behaviourScore;     // 0-100

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

    // Map risk level to confidence
    String confidence;
    switch (json['risk_level']) {
      case 'HIGH': confidence = 'High'; break;
      case 'MEDIUM': confidence = 'Medium'; break;
      default: confidence = 'Low';
    }

    // Build risk factors list from map
    final factorsMap = json['risk_factors'] as Map<String, dynamic>? ?? {};
    final factorsList = factorsMap.entries
        .map((e) => '${e.key}: ${e.value}')
        .toList();

    // Build recommendation from AI counselor
    final recommendation = [
      ai['risk_summary'] ?? '',
      ai['teacher_action'] ?? '',
      ai['long_term_plan'] ?? '',
    ].where((s) => s.isNotEmpty).join('\n\n');

    return PredictionResult(
      riskLevel: json['risk_level'] ?? 'UNKNOWN',
      riskScore: riskScore / 100, // convert % to 0-1 to match your structure
      confidence: confidence,
      dropoutProbability: riskScore, // e.g. 44.4
      riskFactors: factorsList,
      recommendation: recommendation,
      mentalHealthScore: (json['mental_health_score'] ?? 0).toDouble(),
      behaviourScore: (json['behaviour_score'] ?? 0).toDouble(),
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

  // Run prediction AND save to Firebase — matches your existing structure
  Future<PredictionResult> predictAndSave({
    required String studentId,
    required Map<String, dynamic> studentData, // your existing student fields
  }) async {
    // Step 1: Build API request from your student data
    final apiPayload = _mapStudentToApiInput(studentData);

    // Step 2: Call FastAPI backend
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

    // Step 3: Save to Firebase — matching your existing predictions structure
    await _firebase.savePrediction(
      studentId: studentId,
      riskLevel: result.riskLevel,
      riskScore: result.riskScore,
      confidence: result.confidence,
      dropoutProbability: result.dropoutProbability,
      riskFactors: result.riskFactors,
      recommendation: result.recommendation,
      inputFeatures: studentData, // save raw input too, just like your existing docs
    );

    return result;
  }

  // Maps your Firestore student fields → FastAPI expected fields
  Map<String, dynamic> _mapStudentToApiInput(Map<String, dynamic> s) {
    return {
      'current_grade': (s['G2'] ?? s['G1'] ?? 10).toDouble(),
      'previous_grade': (s['G1'] ?? 10).toDouble(),
      'failures': s['failures'] ?? 0,
      'studytime': s['studytime'] ?? 2,
      'absences': s['absences'] ?? 0,
      'age': s['age'] ?? 18,
      'health': s['health'] ?? 3,
      'famrel': s['famrel'] ?? 3,
      'internet': s['internet'] ?? 0,
      'schoolsup': s['schoolsup'] ?? 0,
      'famsup': s['famsup'] ?? 0,
      'famsize': s['famsize'] ?? 1,
      'debtor': 0,
      'tuition_paid': 1,
      'scholarship': 0,
      'sex': 1,
      'activities': 1,
      'higher': 1,
      'paid': 0,
      'guardian': 0,
      'pstatus': s['Pstatus'] ?? 1,
      'attendance_type': 1,
      'prev_qual': 1,
      'mjob': 5,
      'fjob': 5,
      'course': 9500,
    };
  }
}


// ============================================================================
// USAGE IN YOUR FLUTTER WIDGETS
// ============================================================================

/*

final _api = ApiService();
final _firebase = FirebaseService();

// 1. SIGN IN
final error = await _firebase.signIn(email, password);
if (error != null) showError(error);

// 2. GET STUDENTS IN A CLASSROOM
StreamBuilder<List<String>>(
  stream: _firebase.getClassroomStudentIds('001'),
  builder: (context, snapshot) {
    final ids = snapshot.data ?? [];
    // then load each student with getStudentsByIds(ids)
  }
)

// 3. RUN PREDICTION + AUTO SAVE
final student = await _firebase.getStudent(studentId);
final result = await _api.predictAndSave(
  studentId: studentId,
  studentData: student!.toJson(),
);

// result.riskLevel    → "HIGH"
// result.confidence   → "High"
// result.riskFactors  → ["Multiple past failures: 6 failures", ...]
// result.recommendation → "Student shows high risk..."

// 4. GET PREDICTION HISTORY
StreamBuilder<List<PredictionModel>>(
  stream: _firebase.getStudentPredictions(studentId),
  builder: (context, snapshot) {
    final predictions = snapshot.data ?? [];
    // show history list
  }
)

*/