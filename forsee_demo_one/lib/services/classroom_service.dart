import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassroomService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── GENERATE A UNIQUE 6-CHARACTER CLASS CODE ─────────────────────────────────
  static String _generateClassCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no ambiguous chars
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // ── ENSURE CLASS CODE IS UNIQUE IN FIRESTORE ─────────────────────────────────
  static Future<String> _uniqueClassCode() async {
    String code;
    bool exists;
    do {
      code = _generateClassCode();
      final snap = await _db
          .collection('classrooms')
          .where('classCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snap.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  // ── CREATE A CLASSROOM ────────────────────────────────────────────────────────
  /// Returns the newly created classroom document ID.
  static Future<Map<String, dynamic>> createClassroom({
    required String title,
    required String subject,
    required String semester,
    required String std,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated teacher found.');

    final classCode = await _uniqueClassCode();

    final docRef = await _db.collection('classrooms').add({
      'title': title,
      'subject': subject,
      'semester': semester,
      'std': std,
      'classCode': classCode,
      'teacherId': user.uid,
      'teacherName': user.displayName ?? 'Teacher',
      'participants': 0,
      'studentIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'id': docRef.id,
      'classCode': classCode,
      'title': title,
      'subject': subject,
      'semester': semester,
      'std': std,
      'participants': 0,
    };
  }

  // ── FETCH ALL CLASSROOMS FOR CURRENT TEACHER ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchTeacherClassrooms() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('classrooms')
        .where('teacherId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: false)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'subject': data['subject'] ?? '',
        'semester': data['semester'] ?? '',
        'std': data['std'] ?? '',
        'classCode': data['classCode'] ?? '',
        'participants': data['participants'] ?? 0,
      };
    }).toList();
  }

  // ── STUDENT: JOIN A CLASSROOM VIA CLASS CODE ──────────────────────────────────
  /// Call this from the student side during onboarding.
  static Future<void> joinClassroom(String classCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated student found.');

    final snap = await _db
        .collection('classrooms')
        .where('classCode', isEqualTo: classCode.toUpperCase().trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Invalid class code. Please check and try again.');
    }

    final doc = snap.docs.first;
    await doc.reference.update({
      'studentIds': FieldValue.arrayUnion([user.uid]),
      'participants': FieldValue.increment(1),
    });

    // Also store classroom reference in the student's own document
    await _db.collection('users').doc(user.uid).update({
      'classroomIds': FieldValue.arrayUnion([doc.id]),
    });
  }

  // ── DELETE A CLASSROOM ────────────────────────────────────────────────────────
  static Future<void> deleteClassroom(String classroomId) async {
    await _db.collection('classrooms').doc(classroomId).delete();
  }
}