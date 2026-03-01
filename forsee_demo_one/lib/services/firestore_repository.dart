// lib/services/firestore_repository.dart
// =========================================
// All Firestore streams and reads — built around your existing StudentModel.
// Use Get.find<FirestoreRepository>() anywhere after registering in main.dart.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forsee_demo_one/model/student_model.dart';

class FirestoreRepository {
  final _db = FirebaseFirestore.instance;

  // ── STUDENTS BY CLASS ─────────────────────────────────────────────────────
  // ✅ No .orderBy() here — sorting done in Dart to avoid composite index.

  Stream<List<StudentModel>> streamStudentsByClass(String classroomId) {
    return _db
        .collection('students')
        .where('classroomId', isEqualTo: classroomId)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return <StudentModel>[];

      // Fetch latest prediction for each student to get live riskLevel.
      // predictions stores risk_level as uppercase e.g. 'HIGH' — normalise to lowercase.
      final docIds = snap.docs.map((d) => d.id).toList();
      final Map<String, RiskLevel> riskMap = {};

      // Firestore whereIn limit is 30 — chunk if needed
      for (var i = 0; i < docIds.length; i += 30) {
        final chunk = docIds.sublist(i, (i + 30).clamp(0, docIds.length));
        final predSnap = await _db
            .collection('predictions')
            .where('studentId', whereIn: chunk)
            .get();

        // Keep only the most recent prediction per student
        final Map<String, DateTime> latestTime = {};
        for (final doc in predSnap.docs) {
          final d   = doc.data();
          final sid = d['studentId'] as String? ?? '';
          final raw = (d['risk_level'] as String? ?? '').toLowerCase();
          final ts  = (d['timestamp'] as Timestamp?)?.toDate()
              ?? (d['createdAt'] as Timestamp?)?.toDate()
              ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (!latestTime.containsKey(sid) || ts.isAfter(latestTime[sid]!)) {
            latestTime[sid] = ts;
            riskMap[sid] = _riskFromString(raw);
          }
        }
      }

      final list = snap.docs.map((doc) {
        final base = StudentModel.fromFirestore(doc.data(), doc.id);
        final live = riskMap[doc.id];
        if (live != null) {
          return StudentModel(
            firestoreId: base.firestoreId,
            studentId:   base.studentId,
            name:        base.name,
            standard:    base.standard,
            phone:       base.phone,
            className:   base.className,
            subject:     base.subject,
            riskLevel:   live,
          );
        }
        return base;
      }).toList();

      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  static RiskLevel _riskFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':   return RiskLevel.high;
      case 'medium': return RiskLevel.medium;
      case 'low':    return RiskLevel.low;
      default:       return RiskLevel.none;
    }
  }

  // ── SINGLE STUDENT ────────────────────────────────────────────────────────

  Stream<StudentModel?> streamStudent(String firestoreId) {
    return _db
        .collection('students')
        .doc(firestoreId)
        .snapshots()
        .map((doc) => doc.exists
        ? StudentModel.fromFirestore(doc.data()!, doc.id)
        : null);
  }

  // ── HIGH RISK STUDENTS ────────────────────────────────────────────────────

  Stream<List<StudentModel>> streamHighRiskStudents({String? classroomId}) {
    Query<Map<String, dynamic>> q = _db
        .collection('students')
        .where('riskLevel', isEqualTo: 'high');

    if (classroomId != null) {
      q = q.where('classroomId', isEqualTo: classroomId);
    }

    return q.snapshots().map((snap) => snap.docs
        .map((doc) => StudentModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // ── MARKS HISTORY ─────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamStudentMarks(String firestoreId) {
    return _db
        .collection('students')
        .doc(firestoreId)
        .collection('marks')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ── BEHAVIOUR INCIDENTS ───────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamIncidents(String firestoreId) {
    return _db
        .collection('students')
        .doc(firestoreId)
        .collection('incidents')
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ── ATTENDANCE HISTORY ────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamAttendance(String firestoreId) {
    return _db
        .collection('students')
        .doc(firestoreId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ── RISK LEVEL COUNTS ─────────────────────────────────────────────────────

  Stream<Map<String, int>> streamRiskCounts() {
    return _db.collection('students').snapshots().map((snap) {
      final counts = {'none': 0, 'low': 0, 'medium': 0, 'high': 0};
      for (final doc in snap.docs) {
        final level = doc.data()['riskLevel'] as String? ?? 'none';
        counts[level] = (counts[level] ?? 0) + 1;
      }
      return counts;
    });
  }
}