import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class AdminProfile {
  final String uid;
  final String name;
  final String email;
  final String schoolId;
  final String role;

  const AdminProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.role,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> d, String uid) {
    return AdminProfile(
      uid:      uid,
      name:     (d['name']     as String?) ?? 'Admin',
      email:    (d['email']    as String?) ?? '',
      schoolId: (d['schoolId'] as String?) ?? '',
      role:     (d['role']     as String?) ?? 'admin',
    );
  }
}

class FirestoreStudent {
  final String id;
  final String name;
  final String email;
  final int    age;
  final int    absences;
  final int    failures;
  final int    g1;
  final int    g2;
  final int    studytime;
  final int    health;
  final int    dalc;
  final int    walc;
  final String       riskLevel;
  final double       riskScore;
  final double       dropoutProbability;
  final String       recommendation;
  final List<String> riskFactors;
  final String       confidence;

  const FirestoreStudent({
    required this.id,
    required this.name,
    required this.email,
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

  double get avgScore => ((g1 + g2) / 2.0) * 5.0;

  String get attendanceLabel {
    if (absences > 15) return 'Low';
    if (absences > 8)  return 'Medium';
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
  final int    totalStudents;
  final int    highRiskCount;
  final int    mediumRiskCount;

  const ClassroomRiskData({
    required this.classroomId,
    required this.totalStudents,
    required this.highRiskCount,
    required this.mediumRiskCount,
  });
}

// ── SERVICE ───────────────────────────────────────────────────────────────────

class AdminFirebaseService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _dbl(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Normalises a dropout_probability value to the 0–100 range.
  ///
  /// The ML service stores the value inconsistently across documents:
  ///   • Some docs store it as a fraction  e.g. 0.857  → needs × 100
  ///   • Some docs store it as a percentage e.g. 85.70  → already correct
  /// We detect which format it is by checking whether the raw value > 1.
  static double _normaliseDropout(dynamic raw) {
    final v = _dbl(raw);
    // If the value is already > 1 it has been stored as a percentage (0–100).
    // If it is ≤ 1 it is a fraction that must be converted.
    return v > 1.0 ? v : v * 100.0;
  }

  static FirestoreStudent _buildStudent({
    required String id,
    required String name,
    required String email,
    required Map<String, dynamic> academic,
    required Map<String, Map<String, dynamic>> predMap,
  }) {
    final pred = predMap[id] ?? {};
    final riskFactorsRaw = pred['risk_factors'];
    final List<String> riskFactors = (riskFactorsRaw is List)
        ? riskFactorsRaw.map((e) => e.toString()).toList()
        : [];

    return FirestoreStudent(
      id:                 id,
      name:               name.isNotEmpty ? name : 'Unknown',
      email:              email,
      age:                _int(academic['age']),
      absences:           _int(academic['absences']),
      failures:           _int(academic['failures']),
      g1:                 _int(academic['G1']),
      g2:                 _int(academic['G2']),
      studytime:          _int(academic['studytime']),
      health:             _int(academic['health']),
      dalc:               _int(academic['Dalc']),
      walc:               _int(academic['Walc']),
      riskLevel:          _str(pred['risk_level'],          'UNKNOWN'),
      riskScore:          _dbl(pred['risk_score']),
      dropoutProbability: _normaliseDropout(pred['dropout_probability']),
      recommendation:     _str(pred['recommendation']),
      riskFactors:        riskFactors,
      confidence:         _str(pred['confidence']),
    );
  }

  // ── CURRENT ADMIN PROFILE ─────────────────────────────────────────────────

  static Future<AdminProfile?> fetchCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AdminProfile.fromMap(doc.data()!, user.uid);
    } catch (_) {
      return null;
    }
  }

  static Stream<AdminProfile?> streamCurrentAdmin() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => (doc.exists && doc.data() != null)
        ? AdminProfile.fromMap(doc.data()!, user.uid)
        : null);
  }

  // ── TEACHERS ──────────────────────────────────────────────────────────────

  static Stream<List<FirestoreTeacher>> streamTeachers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final d = doc.data();
      return FirestoreTeacher(
        id:       doc.id,
        name:     (d['name']     as String?) ?? '',
        email:    (d['email']    as String?) ?? '',
        schoolId: (d['schoolId'] as String?) ?? '',
      );
    }).toList());
  }

  // ── STUDENTS ──────────────────────────────────────────────────────────────

  static Future<List<FirestoreStudent>> fetchAllStudents() async {
    final userStudentSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final predSnap = await _db.collection('predictions').get();

    final Map<String, Map<String, dynamic>> predMap = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = (d['studentId'] as String?) ?? '';
      if (sid.isEmpty) continue;
      final existing = predMap[sid];
      if (existing == null) {
        predMap[sid] = d;
      } else {
        final existTs = existing['timestamp'] as Timestamp?;
        final curTs   = d['timestamp']        as Timestamp?;
        if (curTs != null && existTs != null && curTs.compareTo(existTs) > 0) {
          predMap[sid] = d;
        }
      }
    }

    final List<FirestoreStudent> result = [];
    for (final doc in userStudentSnap.docs) {
      final d = doc.data();
      result.add(_buildStudent(
        id:       doc.id,
        name:     (d['name']  as String?) ?? '',
        email:    (d['email'] as String?) ?? '',
        academic: d,
        predMap:  predMap,
      ));
    }
    return result;
  }

  // ── CLASSROOMS ────────────────────────────────────────────────────────────

  static Future<List<ClassroomRiskData>> fetchClassroomRiskData() async {
    final classSnap = await _db.collection('classrooms').get();
    final predSnap  = await _db.collection('predictions').get();

    final Map<String, String> latestRiskPerStudent = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = (d['studentId'] as String?) ?? '';
      if (sid.isEmpty) continue;
      if (!latestRiskPerStudent.containsKey(sid)) {
        latestRiskPerStudent[sid] = (d['risk_level'] as String?) ?? 'UNKNOWN';
      }
    }

    return classSnap.docs.map((doc) {
      final studentIds = List<String>.from(
          (doc.data()['studentIds'] as List<dynamic>?) ?? []);
      int high = 0, medium = 0;
      for (final sid in studentIds) {
        final level = (latestRiskPerStudent[sid] ?? '').toUpperCase();
        if (level == 'HIGH')   high++;
        if (level == 'MEDIUM') medium++;
      }
      return ClassroomRiskData(
        classroomId:     doc.id,
        totalStudents:   studentIds.length,
        highRiskCount:   high,
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

    final usersStudentSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final predSnap = await _db.collection('predictions').get();

    final Set<String> allStudentIds = {
      ...usersStudentSnap.docs.map((d) => d.id),
    };

    final Map<String, String> latestRisk = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = (d['studentId'] as String?) ?? '';
      if (sid.isEmpty) continue;
      if (!latestRisk.containsKey(sid)) {
        latestRisk[sid] = (d['risk_level'] as String?) ?? 'UNKNOWN';
      }
    }

    int high = 0, medium = 0, low = 0, none = 0;
    for (final sid in allStudentIds) {
      switch ((latestRisk[sid] ?? 'NONE').toUpperCase()) {
        case 'HIGH':   high++;   break;
        case 'MEDIUM': medium++; break;
        case 'LOW':    low++;    break;
        default:       none++;   break;
      }
    }

    return AdminStats(
      totalTeachers:   teachersSnap.size,
      totalStudents:   allStudentIds.length,
      highRiskCount:   high,
      mediumRiskCount: medium,
      lowRiskCount:    low,
      noRiskCount:     none,
    );
  }

  // ── RECENT PREDICTIONS (live activity feed) ───────────────────────────────
  //
  // FIX 1 — Student name resolution:
  //   The predictions collection already stores `studentName` on each doc
  //   (written by the ML service). We use that directly.
  //   Only if it is empty/missing do we fall back to looking up users/{studentId},
  //   then students/{studentId}, before giving up and showing the raw ID.
  //
  // FIX 2 — Dropout probability normalisation:
  //   Stored values vary: some docs store 0.857 (fraction), others 85.70
  //   (percentage). _normaliseDropout() detects and converts consistently.

  static Stream<List<Map<String, dynamic>>> streamRecentPredictions({
    int limit = 10,
  }) {
    return _db
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snap) async {
      final enriched = await Future.wait(snap.docs.map((doc) async {
        final data      = Map<String, dynamic>.from(doc.data());
        final studentId = _str(data['studentId']);

        // ── Name resolution ───────────────────────────────────────────────
        // Priority 1: studentName already on the prediction doc (most common).
        final docName = _str(data['studentName']).trim();
        if (docName.isNotEmpty) {
          data['studentName'] = docName;
        } else if (studentId.isNotEmpty) {
          // Priority 2: look up users/{studentId}.
          String resolved = '';
          try {
            final userDoc = await _db.collection('users').doc(studentId).get();
            resolved = _str(userDoc.data()?['name']).trim();
          } catch (_) {}

          // Priority 3: look up students/{studentId}.
          if (resolved.isEmpty) {
            try {
              final stuDoc = await _db.collection('students').doc(studentId).get();
              resolved = _str(stuDoc.data()?['name']).trim();
            } catch (_) {}
          }

          data['studentName'] = resolved.isNotEmpty ? resolved : studentId;
        } else {
          data['studentName'] = 'Unknown';
        }

        // ── Dropout probability normalisation ─────────────────────────────
        data['dropout_probability'] =
            _normaliseDropout(data['dropout_probability']);

        return data;
      }));

      return enriched;
    });
  }

  // ── UPDATE ADMIN PROFILE ──────────────────────────────────────────────────

  static Future<void> updateAdminProfile({
    required String name,
    String? schoolId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{'name': name};
    if (schoolId != null && schoolId.isNotEmpty) {
      updates['schoolId'] = schoolId;
    }
    await _db.collection('users').doc(user.uid).update(updates);
  }
}