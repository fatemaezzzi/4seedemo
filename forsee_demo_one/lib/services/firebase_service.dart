// firebase_service.dart
// ======================
// Place in: lib/services/firebase_service.dart
// Matches EXACTLY your team's existing Firestore structure

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// DATA MODELS — matched to your exact Firestore fields
// ============================================================================

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;       // "teacher"
  final String schoolId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.schoolId,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? 'teacher',
      schoolId: d['schoolId'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


class StudentModel {
  final String id;
  final String name;
  final int age;
  final int g1;
  final int g2;
  final int absences;
  final int failures;
  final int studytime;
  final int health;
  final int internet;
  final int schoolsup;
  final int famsup;
  final int famsize;
  final int address;
  final int school;
  final int pstatus;
  final int medu;
  final int fedu;
  final int dalc;
  final int walc;
  final int goout;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.age,
    required this.g1,
    required this.g2,
    required this.absences,
    required this.failures,
    required this.studytime,
    required this.health,
    required this.internet,
    required this.schoolsup,
    required this.famsup,
    required this.famsize,
    required this.address,
    required this.school,
    required this.pstatus,
    required this.medu,
    required this.fedu,
    required this.dalc,
    required this.walc,
    required this.goout,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: d['name'] ?? '',
      age: d['age'] ?? 0,
      g1: d['G1'] ?? 0,
      g2: d['G2'] ?? 0,
      absences: d['absences'] ?? 0,
      failures: d['failures'] ?? 0,
      studytime: d['studytime'] ?? 0,
      health: d['health'] ?? 0,
      internet: d['internet'] ?? 0,
      schoolsup: d['schoolsup'] ?? 0,
      famsup: d['famsup'] ?? 0,
      famsize: d['famsize'] ?? 0,
      address: d['address'] ?? 0,
      school: d['school'] ?? 0,
      pstatus: d['Pstatus'] ?? 0,
      medu: d['Medu'] ?? 0,
      fedu: d['Fedu'] ?? 0,
      dalc: d['Dalc'] ?? 0,
      walc: d['Walc'] ?? 0,
      goout: d['goout'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'G1': g1,
    'G2': g2,
    'absences': absences,
    'failures': failures,
    'studytime': studytime,
    'health': health,
    'internet': internet,
    'schoolsup': schoolsup,
    'famsup': famsup,
    'famsize': famsize,
    'address': address,
    'school': school,
    'Pstatus': pstatus,
    'Medu': medu,
    'Fedu': fedu,
    'Dalc': dalc,
    'Walc': walc,
    'goout': goout,
  };
}


class PredictionModel {
  final String id;
  final String studentId;
  final String riskLevel;
  final double riskScore;
  final String confidence;
  final double dropoutProbability;
  final List<String> riskFactors;
  final String recommendation;
  final Map<String, dynamic> inputFeatures;
  final DateTime createdAt;

  PredictionModel({
    required this.id,
    required this.studentId,
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.dropoutProbability,
    required this.riskFactors,
    required this.recommendation,
    required this.inputFeatures,
    required this.createdAt,
  });

  factory PredictionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PredictionModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      riskLevel: d['risk_level'] ?? 'UNKNOWN',
      riskScore: (d['risk_score'] ?? 0).toDouble(),
      confidence: d['confidence'] ?? '',
      dropoutProbability: (d['dropout_probability'] ?? 0).toDouble(),
      riskFactors: List<String>.from(d['risk_factors'] ?? []),
      recommendation: d['recommendation'] ?? '',
      inputFeatures: Map<String, dynamic>.from(d['input_features'] ?? {}),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


class ClassroomModel {
  final String id;
  final List<String> studentIds;

  ClassroomModel({required this.id, required this.studentIds});

  factory ClassroomModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClassroomModel(
      id: doc.id,
      studentIds: List<String>.from(d['studentIds'] ?? []),
    );
  }
}


// ============================================================================
// FIREBASE SERVICE
// ============================================================================

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // AUTH
  // ============================================================================

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String schoolId,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'teacher',
        'schoolId': schoolId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;
    final doc = await _db.collection('users').doc(currentUserId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'Account already exists with this email.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email.';
      default: return 'Something went wrong. Please try again.';
    }
  }

  // ============================================================================
  // STUDENTS
  // ============================================================================

  Future<String> addStudent(Map<String, dynamic> studentData) async {
    final doc = await _db.collection('students').add({
      ...studentData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<StudentModel?> getStudent(String studentId) async {
    final doc = await _db.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromFirestore(doc);
  }

  Future<List<StudentModel>> getStudentsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final List<StudentModel> students = [];
    for (final id in ids) {
      final s = await getStudent(id);
      if (s != null) students.add(s);
    }
    return students;
  }

  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    await _db.collection('students').doc(studentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // CLASSROOMS
  // ============================================================================

  Stream<List<String>> getClassroomStudentIds(String classroomId) {
    return _db.collection('classrooms').doc(classroomId).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['studentIds'] ?? []);
    });
  }

  Future<void> addStudentToClassroom(String classroomId, String studentId) async {
    await _db.collection('classrooms').doc(classroomId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  // ============================================================================
  // PREDICTIONS
  // ============================================================================

  Future<String> savePrediction({
    required String studentId,
    required String riskLevel,
    required double riskScore,
    required String confidence,
    required double dropoutProbability,
    required List<String> riskFactors,
    required String recommendation,
    required Map<String, dynamic> inputFeatures,
  }) async {
    final doc = await _db.collection('predictions').add({
      'studentId': studentId,
      'risk_level': riskLevel,
      'risk_score': riskScore,
      'confidence': confidence,
      'dropout_probability': dropoutProbability,
      'risk_factors': riskFactors,
      'recommendation': recommendation,
      'input_features': inputFeatures,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<PredictionModel>> getStudentPredictions(String studentId) {
    return _db
        .collection('predictions')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PredictionModel.fromFirestore).toList());
  }

  Future<PredictionModel?> getLatestPrediction(String studentId) async {
    final snap = await _db
        .collection('predictions')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PredictionModel.fromFirestore(snap.docs.first);
  }

  Future<List<PredictionModel>> getHighRiskPredictions(List<String> studentIds) async {
    if (studentIds.isEmpty) return [];
    final snap = await _db
        .collection('predictions')
        .where('studentId', whereIn: studentIds)
        .where('risk_level', isEqualTo: 'HIGH')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(PredictionModel.fromFirestore).toList();
  }
}