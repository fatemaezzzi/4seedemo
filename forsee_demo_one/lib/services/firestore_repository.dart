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
        .map((snap) {
      final list = snap.docs
          .map((doc) => StudentModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
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