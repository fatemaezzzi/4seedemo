import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { student, teacher, admin }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? classroomId;
  final String? schoolId;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.classroomId,
    this.schoolId,
    this.photoUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid:         uid,
      email:       map['email']       ?? '',
      name:        map['name']        ?? '',
      role:        UserRole.values.firstWhere(
            (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      classroomId: map['classroomId'],
      schoolId:    map['schoolId'],
      photoUrl:    map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name':  name,
    'role':  role.name,
    if (classroomId != null) 'classroomId': classroomId,
    if (schoolId    != null) 'schoolId':    schoolId,
    if (photoUrl    != null) 'photoUrl':    photoUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL AUTH RESULT
// ─────────────────────────────────────────────────────────────────────────────

class SocialAuthResult {
  final AppUser? appUser;
  final User     firebaseUser;
  final bool     isNewUser;

  const SocialAuthResult({
    required this.appUser,
    required this.firebaseUser,
    required this.isNewUser,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  final FirebaseAuth     _auth        = FirebaseAuth.instance;
  final FirebaseFirestore _db         = FirebaseFirestore.instance;
  final GoogleSignIn     _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User?         get currentUser       => _auth.currentUser;

  Future<AppUser?> fetchCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // First try direct doc lookup (works for users who signed up normally)
    final directDoc = await _db.collection('users').doc(user.uid).get();
    if (directDoc.exists) {
      return AppUser.fromMap(directDoc.data()!, user.uid);
    }

    // Fallback: query by uid field (works for seeded users like s_ayaan_khan)
    final snap = await _db
        .collection('users')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromMap(snap.docs.first.data(), user.uid);
  }

  // ── EMAIL SIGN UP ──────────────────────────────────────────────────────────

  Future<AppUser> signUp({
    required String   email,
    required String   password,
    required String   name,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email:    email.trim(),
      password: password,
    );

    final uid     = credential.user!.uid;
    final appUser = AppUser(
      uid:         uid,
      email:       email.trim(),
      name:        name.trim(),
      role:        role,
      classroomId: classroomId,
      schoolId:    schoolId,
    );

    // 1) Base user doc — always written for every role
    await _db.collection('users').doc(uid).set(appUser.toMap());

    // 2) Role-specific doc — THIS is what was missing
    await _writeRoleDoc(
      uid:         uid,
      name:        name.trim(),
      email:       email.trim(),
      role:        role,
      classroomId: classroomId,
      schoolId:    schoolId,
    );

    return appUser;
  }

  // ── EMAIL LOG IN ───────────────────────────────────────────────────────────

  Future<AppUser> logIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email:    email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // First try direct doc lookup (works for users who signed up normally)
    final directDoc = await _db.collection('users').doc(uid).get();
    if (directDoc.exists) {
      return AppUser.fromMap(directDoc.data()!, uid);
    }

    // Fallback: query by uid field (works for seeded users like s_ayaan_khan)
    final snap = await _db
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      await _auth.signOut();
      throw Exception('User profile not found. Please contact support.');
    }

    return AppUser.fromMap(snap.docs.first.data(), uid);
  }

  // ── GOOGLE SIGN IN ─────────────────────────────────────────────────────────

  Future<SocialAuthResult?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser   = userCredential.user!;

    final directDoc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (directDoc.exists) {
      return SocialAuthResult(
        appUser:      AppUser.fromMap(directDoc.data()!, firebaseUser.uid),
        firebaseUser: firebaseUser,
        isNewUser:    false,
      );
    }

    // Fallback: query by uid field (seeded users)
    final snap = await _db
        .collection('users')
        .where('uid', isEqualTo: firebaseUser.uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return SocialAuthResult(
        appUser:      AppUser.fromMap(snap.docs.first.data(), firebaseUser.uid),
        firebaseUser: firebaseUser,
        isNewUser:    false,
      );
    }

    return SocialAuthResult(
      appUser:      null,
      firebaseUser: firebaseUser,
      isNewUser:    true,
    );
  }

  // ── COMPLETE SOCIAL SIGN UP ────────────────────────────────────────────────

  Future<AppUser> completeSocialSignUp({
    required User     firebaseUser,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    final appUser = AppUser(
      uid:         firebaseUser.uid,
      email:       firebaseUser.email    ?? '',
      name:        firebaseUser.displayName ?? 'User',
      role:        role,
      classroomId: classroomId,
      schoolId:    schoolId,
      photoUrl:    firebaseUser.photoURL,
    );

    // 1) Base user doc
    await _db.collection('users').doc(firebaseUser.uid).set(appUser.toMap());

    // 2) Role-specific doc
    await _writeRoleDoc(
      uid:         firebaseUser.uid,
      name:        firebaseUser.displayName ?? 'User',
      email:       firebaseUser.email       ?? '',
      role:        role,
      classroomId: classroomId,
      schoolId:    schoolId,
      photoUrl:    firebaseUser.photoURL,
    );

    return appUser;
  }

  // ── ROLE-SPECIFIC DOC WRITER ───────────────────────────────────────────────
  // Called by both signUp() and completeSocialSignUp().
  // Writes to /students/{uid}, /teachers/{uid}, or /admins/{uid}.

  Future<void> _writeRoleDoc({
    required String   uid,
    required String   name,
    required String   email,
    required UserRole role,
    String? classroomId,
    String? schoolId,
    String? photoUrl,
  }) async {
    switch (role) {
      case UserRole.student:
      // ── Auto-generate a unique, readable studentId ──────────────────────
      // Format: {CLASSROOMID}-{4-digit counter} e.g. "12B-0043"
      // Uses a Firestore transaction on the classroom counter doc so that
      // concurrent sign-ups never produce duplicate IDs.
        final studentId = await _generateStudentId(classroomId ?? 'GEN');

        await _db.collection('students').doc(uid).set({
          'uid':         uid,
          'name':        name,
          'email':       email,
          'studentId':   studentId,   // ← now always populated at sign-up
          'className':   classroomId ?? '',
          'classroomId': classroomId ?? '',
          'standard':    '',
          'phone':       '',
          'riskLevel':   'none',
          'photoUrl':    photoUrl ?? '',
          'createdAt':   FieldValue.serverTimestamp(),
          // Prediction inputs — null until data is saved by teacher
          'attendance': null,
          'behaviour':  null,
          'quiz':       null,
          'marks':      null,
          'prediction': null,
        });

        // Add student to classroom doc if classroomId provided
        if (classroomId != null && classroomId.isNotEmpty) {
          await _db.collection('classrooms').doc(classroomId).set(
            {'studentIds': FieldValue.arrayUnion([uid])},
            SetOptions(merge: true),
          );
        }
        break;

      case UserRole.teacher:
        await _db.collection('teachers').doc(uid).set({
          'uid':       uid,
          'name':      name,
          'email':     email,
          'schoolId':  schoolId ?? '',
          'subject':   '',      // teacher fills this in their profile
          'className': '',
          'photoUrl':  photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        break;

      case UserRole.admin:
        await _db.collection('admins').doc(uid).set({
          'uid':      uid,
          'name':     name,
          'email':    email,
          'schoolId': schoolId ?? '',
          'photoUrl': photoUrl ?? '',
          'createdAt':FieldValue.serverTimestamp(),
        });
        break;
    }
  }

  // ── STUDENT ID GENERATOR ──────────────────────────────────────────────────
  // Atomically increments a per-classroom counter and returns a formatted ID.
  // e.g. classroomId "12B" → "12B-0001", "12B-0002", …
  // Uses a Firestore transaction so concurrent sign-ups never collide.

  Future<String> _generateStudentId(String classroomId) async {
    final counterRef = _db
        .collection('_counters')
        .doc('classroom_${classroomId.toUpperCase()}');

    final int nextCount = await _db.runTransaction<int>((txn) async {
      final snap = await txn.get(counterRef);
      final current = snap.exists ? (snap.data()!['count'] as int? ?? 0) : 0;
      final next = current + 1;
      txn.set(counterRef, {'count': next}, SetOptions(merge: true));
      return next;
    });

    // Format: "12B-0043" — classroom prefix + zero-padded 4-digit counter
    final prefix = classroomId.toUpperCase().replaceAll(' ', '');
    return '$prefix-${nextCount.toString().padLeft(4, '0')}';
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── PASSWORD RESET ─────────────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── ADMIN HELPERS ──────────────────────────────────────────────────────────

  Future<void> setUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }
}