import 'package:cloud_firestore/cloud_firestore.dart';

// ── MODELS ────────────────────────────────────────────────────────────────────

class AdminStats {
  final int totalTeachers;
  final int totalStudents;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int noRiskCount;

  const AdminStats({
    required this.totalTeachers,
    required this.totalStudents,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.noRiskCount,
  });
}

class FirestoreStudent {
  final String id;
  final String name;
  final int age;
  final int absences;
  final int failures;
  final int g1;
  final int g2;
  final int studytime;
  final int health;
  final int dalc;
  final int walc;
  // joined from predictions
  final String riskLevel;
  final double riskScore;
  final double dropoutProbability;
  final String recommendation;
  final List<String> riskFactors;
  final String confidence;

  const FirestoreStudent({
    required this.id,
    required this.name,
    required this.age,
    required this.absences,
    required this.failures,
    required this.g1,
    required this.g2,
    required this.studytime,
    required this.health,
    required this.dalc,
    required this.walc,
    required this.riskLevel,
    required this.riskScore,
    required this.dropoutProbability,
    required this.recommendation,
    required this.riskFactors,
    required this.confidence,
  });

  /// G1/G2 are out of 20 — convert to a 0-100 percentage
  double get avgScore => ((g1 + g2) / 2.0) * 5.0;

  String get attendanceLabel {
    if (absences > 15) return 'Low';
    if (absences > 8) return 'Medium';
    return 'Good';
  }

  bool get isHighRisk   => riskLevel.toUpperCase() == 'HIGH';
  bool get isMediumRisk => riskLevel.toUpperCase() == 'MEDIUM';
  bool get isLowRisk    => riskLevel.toUpperCase() == 'LOW';
}

class FirestoreTeacher {
  final String id;
  final String name;
  final String email;
  final String schoolId;

  const FirestoreTeacher({
    required this.id,
    required this.name,
    required this.email,
    required this.schoolId,
  });
}

class ClassroomRiskData {
  final String classroomId;
  final int totalStudents;
  final int highRiskCount;
  final int mediumRiskCount;

  const ClassroomRiskData({
    required this.classroomId,
    required this.totalStudents,
    required this.highRiskCount,
    required this.mediumRiskCount,
  });
}

// ── SERVICE ───────────────────────────────────────────────────────────────────

class AdminFirebaseService {
  static final _db = FirebaseFirestore.instance;

  // ── TEACHERS ──────────────────────────────────────────────────────────────

  static Stream<List<FirestoreTeacher>> streamTeachers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final d = doc.data();
      return FirestoreTeacher(
        id: doc.id,
        name: d['name'] ?? '',
        email: d['email'] ?? '',
        schoolId: d['schoolId'] ?? '',
      );
    }).toList());
  }

  // ── STUDENTS (joined with latest prediction) ──────────────────────────────

  static Future<List<FirestoreStudent>> fetchAllStudents() async {
    final studentSnap = await _db.collection('students').get();
    final predSnap = await _db.collection('predictions').get();

    // Build map: studentId -> latest prediction
    final Map<String, Map<String, dynamic>> predMap = {};
    for (final doc in predSnap.docs) {
      final d = doc.data();
      final sid = d['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;

      if (!predMap.containsKey(sid)) {
        predMap[sid] = d;
      } else {
        final existing = predMap[sid]!['timestamp'] as Timestamp?;
        final current  = d['timestamp'] as Timestamp?;
        if (current != null && existing != null && current.compareTo(existing) > 0) {
          predMap[sid] = d;
        }
      }
    }

    return studentSnap.docs.map((doc) {
      final d    = doc.data();
      final pred = predMap[doc.id] ?? {};
      final riskFactorsRaw = pred['risk_factors'] as List<dynamic>? ?? [];

      return FirestoreStudent(
        id:                 doc.id,
        name:               d['name'] ?? 'Unknown',
        age:                (d['age']       as num?)?.toInt() ?? 0,
        absences:           (d['absences']  as num?)?.toInt() ?? 0,
        failures:           (d['failures']  as num?)?.toInt() ?? 0,
        g1:                 (d['G1']        as num?)?.toInt() ?? 0,
        g2:                 (d['G2']        as num?)?.toInt() ?? 0,
        studytime:          (d['studytime'] as num?)?.toInt() ?? 0,
        health:             (d['health']    as num?)?.toInt() ?? 0,
        dalc:               (d['Dalc']      as num?)?.toInt() ?? 0,
        walc:               (d['Walc']      as num?)?.toInt() ?? 0,
        riskLevel:          pred['risk_level']           ?? 'UNKNOWN',
        riskScore:          (pred['risk_score']           as num?)?.toDouble() ?? 0.0,
        dropoutProbability: (pred['dropout_probability']  as num?)?.toDouble() ?? 0.0,
        recommendation:     pred['recommendation']        ?? '',
        riskFactors:        riskFactorsRaw.map((e) => e.toString()).toList(),
        confidence:         pred['confidence']            ?? '',
      );
    }).toList();
  }

  // ── CLASSROOMS ────────────────────────────────────────────────────────────

  static Future<List<ClassroomRiskData>> fetchClassroomRiskData() async {
    final classSnap = await _db.collection('classrooms').get();
    final predSnap  = await _db.collection('predictions').get();

    final Map<String, String> latestRiskPerStudent = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = d['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;
      if (!latestRiskPerStudent.containsKey(sid)) {
        latestRiskPerStudent[sid] = d['risk_level'] ?? 'UNKNOWN';
      }
    }

    return classSnap.docs.map((doc) {
      final studentIds = List<String>.from(doc.data()['studentIds'] ?? []);
      int high = 0, medium = 0;
      for (final sid in studentIds) {
        final level = (latestRiskPerStudent[sid] ?? '').toUpperCase();
        if (level == 'HIGH')   high++;
        if (level == 'MEDIUM') medium++;
      }
      return ClassroomRiskData(
        classroomId:    doc.id,
        totalStudents:  studentIds.length,
        highRiskCount:  high,
        mediumRiskCount: medium,
      );
    }).toList();
  }

  // ── ADMIN STATS ───────────────────────────────────────────────────────────

  static Future<AdminStats> fetchAdminStats() async {
    final teachersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();

    final studentsSnap = await _db.collection('students').get();
    final predSnap     = await _db.collection('predictions').get();

    // latest risk per student
    final Map<String, String> latestRisk = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = d['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;
      if (!latestRisk.containsKey(sid)) {
        latestRisk[sid] = d['risk_level'] ?? 'UNKNOWN';
      }
    }

    int high = 0, medium = 0, low = 0, none = 0;
    for (final level in latestRisk.values) {
      switch (level.toUpperCase()) {
        case 'HIGH':   high++;   break;
        case 'MEDIUM': medium++; break;
        case 'LOW':    low++;    break;
        default:       none++;   break;
      }
    }

    return AdminStats(
      totalTeachers:  teachersSnap.size,
      totalStudents:  studentsSnap.size,
      highRiskCount:  high,
      mediumRiskCount: medium,
      lowRiskCount:   low,
      noRiskCount:    none,
    );
  }

  // ── RECENT PREDICTIONS (used as activity log) ─────────────────────────────

  static Stream<List<Map<String, dynamic>>> streamRecentPredictions({int limit = 10}) {
    return _db
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}