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

  /// Convenience: percentage of students at some risk level
  double riskPercent(int count) =>
      totalStudents == 0 ? 0 : (count / totalStudents * 100);
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
      name:     d['name']     as String? ?? 'Admin',
      email:    d['email']    as String? ?? '',
      schoolId: d['schoolId'] as String? ?? '',
      role:     d['role']     as String? ?? 'admin',
    );
  }
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
  final String email;
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
    required this.email,
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
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── CURRENT ADMIN PROFILE ─────────────────────────────────────────────────

  static Future<AdminProfile?> fetchCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
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
        .map((doc) => doc.exists
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
        name:     d['name']     as String? ?? '',
        email:    d['email']    as String? ?? '',
        schoolId: d['schoolId'] as String? ?? '',
      );
    }).toList());
  }

  // ── STUDENTS (merged: students collection + users with role=student) ───────
  //
  // Strategy:
  //   1. Fetch all docs from `students` collection (contains academic data).
  //   2. Fetch all docs from `users` where role == 'student' (auth-registered).
  //   3. Merge by uid: if a user-doc uid matches a student-doc id, they are the
  //      same person. Otherwise surface the user as a student with zero academic
  //      data so they are still visible in the DB.
  //   4. Join with latest prediction from `predictions` collection.

  static Future<List<FirestoreStudent>> fetchAllStudents() async {
    // Parallel fetch for speed
    final results = await Future.wait([
      _db.collection('students').get(),
      _db.collection('users').where('role', isEqualTo: 'student').get(),
      _db.collection('predictions').get(),
    ]);

    final studentSnap     = results[0];
    final userStudentSnap = results[1];
    final predSnap        = results[2];

    // Build prediction map: studentId -> latest prediction data
    final Map<String, Map<String, dynamic>> predMap = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = d['studentId'] as String? ?? '';
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

    // Build a map from the students collection
    final Map<String, Map<String, dynamic>> studentDataMap = {};
    for (final doc in studentSnap.docs) {
      studentDataMap[doc.id] = doc.data();
    }

    // Build a set of student-doc IDs so we don't double-add
    final Set<String> usedIds = {};
    final List<FirestoreStudent> out = [];

    // Helper to build a FirestoreStudent from merged data
    FirestoreStudent _build(String id, Map<String, dynamic> d, String email) {
      final pred          = predMap[id] ?? {};
      final riskFactorsRaw = pred['risk_factors'] as List<dynamic>? ?? [];
      return FirestoreStudent(
        id:                 id,
        name:               d['name']       as String? ?? 'Unknown',
        age:                (d['age']        as num?)?.toInt() ?? 0,
        absences:           (d['absences']   as num?)?.toInt() ?? 0,
        failures:           (d['failures']   as num?)?.toInt() ?? 0,
        g1:                 (d['G1']         as num?)?.toInt() ?? 0,
        g2:                 (d['G2']         as num?)?.toInt() ?? 0,
        studytime:          (d['studytime']  as num?)?.toInt() ?? 0,
        health:             (d['health']     as num?)?.toInt() ?? 0,
        dalc:               (d['Dalc']       as num?)?.toInt() ?? 0,
        walc:               (d['Walc']       as num?)?.toInt() ?? 0,
        email:              email,
        riskLevel:          pred['risk_level']            as String? ?? 'UNKNOWN',
        riskScore:          (pred['risk_score']            as num?)?.toDouble() ?? 0.0,
        dropoutProbability: (pred['dropout_probability']   as num?)?.toDouble() ?? 0.0,
        recommendation:     pred['recommendation']         as String? ?? '',
        riskFactors:        riskFactorsRaw.map((e) => e.toString()).toList(),
        confidence:         pred['confidence']             as String? ?? '',
      );
    }

    // 1) Process users with role=student — these are auth-registered students
    for (final doc in userStudentSnap.docs) {
      usedIds.add(doc.id);
      final userData = doc.data();
      // Merge with academic data from students collection if it exists
      final academicData = studentDataMap[doc.id] ?? {};
      final merged = {
        'name':      userData['name'],
        'age':       academicData['age']      ?? userData['age'],
        'absences':  academicData['absences'],
        'failures':  academicData['failures'],
        'G1':        academicData['G1'],
        'G2':        academicData['G2'],
        'studytime': academicData['studytime'],
        'health':    academicData['health'],
        'Dalc':      academicData['Dalc'],
        'Walc':      academicData['Walc'],
      };
      out.add(_build(
        doc.id,
        merged,
        userData['email'] as String? ?? '',
      ));
    }

    // 2) Process students collection entries that weren't in users
    for (final doc in studentSnap.docs) {
      if (usedIds.contains(doc.id)) continue; // already added above
      out.add(_build(doc.id, doc.data(), ''));
    }

    return out;
  }

  // ── CLASSROOMS ────────────────────────────────────────────────────────────

  static Future<List<ClassroomRiskData>> fetchClassroomRiskData() async {
    final results = await Future.wait([
      _db.collection('classrooms').get(),
      _db.collection('predictions').get(),
    ]);

    final classSnap = results[0];
    final predSnap  = results[1];

    final Map<String, String> latestRiskPerStudent = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = d['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;
      if (!latestRiskPerStudent.containsKey(sid)) {
        latestRiskPerStudent[sid] = d['risk_level'] as String? ?? 'UNKNOWN';
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
  //
  // Student count comes from BOTH sources (union) so newly registered students
  // appear in the count even before an ML prediction exists.

  static Future<AdminStats> fetchAdminStats() async {
    final results = await Future.wait([
      _db.collection('users').where('role', isEqualTo: 'teacher').get(),
      _db.collection('students').get(),
      _db.collection('users').where('role', isEqualTo: 'student').get(),
      _db.collection('predictions').get(),
    ]);

    final teachersSnap      = results[0];
    final studentsCollSnap  = results[1];
    final usersStudentSnap  = results[2];
    final predSnap          = results[3];

    // Union of student IDs
    final Set<String> allStudentIds = {
      ...studentsCollSnap.docs.map((d) => d.id),
      ...usersStudentSnap.docs.map((d) => d.id),
    };

    // Latest risk per student
    final Map<String, String> latestRisk = {};
    for (final doc in predSnap.docs) {
      final d   = doc.data();
      final sid = d['studentId'] as String? ?? '';
      if (sid.isEmpty) continue;
      if (!latestRisk.containsKey(sid)) {
        latestRisk[sid] = d['risk_level'] as String? ?? 'UNKNOWN';
      }
    }

    int high = 0, medium = 0, low = 0, none = 0;
    for (final sid in allStudentIds) {
      final level = (latestRisk[sid] ?? 'NONE').toUpperCase();
      switch (level) {
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

  // ── RECENT PREDICTIONS (activity log) ────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> streamRecentPredictions({
    int limit = 10,
  }) {
    return _db
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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