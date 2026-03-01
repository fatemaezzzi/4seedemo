// lib/services/feedback_service.dart
// ====================================
// Handles all Firestore reads & writes for the teacher feedback loop.
//
// Firestore Collection: feedback/{feedbackId}
//
// Document schema:
// {
//   feedbackId:       String   — Firestore auto-ID
//   studentId:        String   — firestoreId from students collection
//   studentName:      String
//   teacherId:        String   — uid of the logged-in teacher
//   teacherName:      String
//   suggestion:       String   — the AI suggestion that was acted upon
//   actionTaken:      String   — what the teacher actually did
//   studentResponse:  String   — how the student responded (free text)
//   responseOutcome:  String   — 'positive' | 'neutral' | 'negative'
//   followUpNeeded:   bool     — does this need another follow-up?
//   followUpNote:     String?  — optional note for follow-up
//   createdAt:        Timestamp
//   updatedAt:        Timestamp
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── MODEL ─────────────────────────────────────────────────────────────────────

class TeacherFeedback {
  final String  feedbackId;
  final String  studentId;
  final String  studentName;
  final String  teacherId;
  final String  teacherName;
  final String  suggestion;
  final String  actionTaken;
  final String  studentResponse;
  final String  responseOutcome;   // 'positive' | 'neutral' | 'negative'
  final bool    followUpNeeded;
  final String  followUpNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeacherFeedback({
    required this.feedbackId,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.suggestion,
    required this.actionTaken,
    required this.studentResponse,
    required this.responseOutcome,
    required this.followUpNeeded,
    required this.followUpNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherFeedback.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TeacherFeedback(
      feedbackId:      doc.id,
      studentId:       d['studentId']       as String?  ?? '',
      studentName:     d['studentName']     as String?  ?? '',
      teacherId:       d['teacherId']       as String?  ?? '',
      teacherName:     d['teacherName']     as String?  ?? '',
      suggestion:      d['suggestion']      as String?  ?? '',
      actionTaken:     d['actionTaken']     as String?  ?? '',
      studentResponse: d['studentResponse'] as String?  ?? '',
      responseOutcome: d['responseOutcome'] as String?  ?? 'neutral',
      followUpNeeded:  d['followUpNeeded']  as bool?    ?? false,
      followUpNote:    d['followUpNote']    as String?  ?? '',
      createdAt:       (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:       (d['updatedAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'studentId':       studentId,
    'studentName':     studentName,
    'teacherId':       teacherId,
    'teacherName':     teacherName,
    'suggestion':      suggestion,
    'actionTaken':     actionTaken,
    'studentResponse': studentResponse,
    'responseOutcome': responseOutcome,
    'followUpNeeded':  followUpNeeded,
    'followUpNote':    followUpNote,
    'createdAt':       Timestamp.fromDate(createdAt),
    'updatedAt':       Timestamp.fromDate(updatedAt),
  };

  // Outcome helpers
  bool get isPositive => responseOutcome == 'positive';
  bool get isNegative => responseOutcome == 'negative';

  String get outcomeEmoji {
    switch (responseOutcome) {
      case 'positive': return '✅';
      case 'negative': return '❌';
      default:         return '➖';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

// ── SERVICE ───────────────────────────────────────────────────────────────────

class FeedbackService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Save a new feedback entry. Returns the generated feedbackId.
  Future<String> saveFeedback({
    required String studentId,
    required String studentName,
    required String suggestion,
    required String actionTaken,
    required String studentResponse,
    required String responseOutcome,
    required bool   followUpNeeded,
    String          followUpNote = '',
  }) async {
    final uid  = _auth.currentUser?.uid ?? '';
    final now  = DateTime.now();

    // Fetch teacher name — first try direct doc, then query by uid field
    String teacherName = 'Teacher';
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        final snap = await _db
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) doc = snap.docs.first;
      }
      teacherName = doc.data()?['name'] as String? ?? 'Teacher';
    } catch (_) {}

    final ref = _db.collection('feedback').doc();
    await ref.set({
      'studentId':       studentId,
      'studentName':     studentName,
      'teacherId':       uid,
      'teacherName':     teacherName,
      'suggestion':      suggestion,
      'actionTaken':     actionTaken,
      'studentResponse': studentResponse,
      'responseOutcome': responseOutcome,
      'followUpNeeded':  followUpNeeded,
      'followUpNote':    followUpNote,
      'createdAt':       Timestamp.fromDate(now),
      'updatedAt':       Timestamp.fromDate(now),
    });

    return ref.id;
  }

  /// Update an existing feedback document (e.g. after follow-up).
  Future<void> updateFeedback({
    required String feedbackId,
    required Map<String, dynamic> updates,
  }) async {
    await _db.collection('feedback').doc(feedbackId).update({
      ...updates,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a feedback entry.
  Future<void> deleteFeedback(String feedbackId) async {
    await _db.collection('feedback').doc(feedbackId).delete();
  }

  /// Live stream of all feedback entries for a given student,
  /// ordered by most recent first.
  Stream<List<TeacherFeedback>> streamFeedbackForStudent(String studentId) {
    return _db
        .collection('feedback')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => TeacherFeedback.fromDoc(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// One-time fetch of feedback for a student (used in report page).
  Future<List<TeacherFeedback>> getFeedbackForStudent(String studentId) async {
    final snap = await _db
        .collection('feedback')
        .where('studentId', isEqualTo: studentId)
        .get();
    final list = snap.docs.map((doc) => TeacherFeedback.fromDoc(doc)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Outcome summary counts for a student — used for dashboard stats.
  Future<Map<String, int>> getOutcomeSummary(String studentId) async {
    final entries = await getFeedbackForStudent(studentId);
    return {
      'positive': entries.where((e) => e.responseOutcome == 'positive').length,
      'neutral':  entries.where((e) => e.responseOutcome == 'neutral').length,
      'negative': entries.where((e) => e.responseOutcome == 'negative').length,
      'total':    entries.length,
    };
  }
}