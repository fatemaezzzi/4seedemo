import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────────
// ENUMS & MODELS
// ─────────────────────────────────────────────

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
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      classroomId: map['classroomId'],
      schoolId: map['schoolId'],
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role.name,
    if (classroomId != null) 'classroomId': classroomId,
    if (schoolId != null) 'schoolId': schoolId,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ─────────────────────────────────────────────
// SOCIAL AUTH RESULT
// ─────────────────────────────────────────────

class SocialAuthResult {
  final AppUser? appUser;   // null = new user, needs role selection
  final User firebaseUser;
  final bool isNewUser;

  const SocialAuthResult({
    required this.appUser,
    required this.firebaseUser,
    required this.isNewUser,
  });
}

// ─────────────────────────────────────────────
// AUTH SERVICE
// ─────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Streams & getters ─────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> fetchCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, user.uid);
  }

  // ─────────────────────────────────────────────
  // EMAIL SIGN UP
  // ─────────────────────────────────────────────

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final appUser = AppUser(
      uid: uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      classroomId: classroomId,
      schoolId: schoolId,
    );

    await _db.collection('users').doc(uid).set(appUser.toMap());

    if (role == UserRole.student &&
        classroomId != null &&
        classroomId.isNotEmpty) {
      await _db.collection('classrooms').doc(classroomId).set(
        {'studentIds': FieldValue.arrayUnion([uid])},
        SetOptions(merge: true),
      );
    }

    return appUser;
  }

  // ─────────────────────────────────────────────
  // EMAIL LOG IN
  // ─────────────────────────────────────────────

  Future<AppUser> logIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('User profile not found. Please contact support.');
    }

    return AppUser.fromMap(doc.data()!, uid);
  }

  // ─────────────────────────────────────────────
  // GOOGLE SIGN IN
  // ─────────────────────────────────────────────

  /// Returns null if user cancelled the Google picker.
  /// Returns SocialAuthResult with isNewUser=true if no Firestore profile yet
  /// — UI should then call completeSocialSignUp() after role selection.
  Future<SocialAuthResult?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Check if Firestore profile already exists
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      return SocialAuthResult(
        appUser: AppUser.fromMap(doc.data()!, firebaseUser.uid),
        firebaseUser: firebaseUser,
        isNewUser: false,
      );
    }

    // New Google user — profile not yet created
    return SocialAuthResult(
      appUser: null,
      firebaseUser: firebaseUser,
      isNewUser: true,
    );
  }

  // ─────────────────────────────────────────────
  // COMPLETE SOCIAL SIGN UP
  // Call after role selection for new Google users
  // ─────────────────────────────────────────────

  Future<AppUser> completeSocialSignUp({
    required User firebaseUser,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'User',
      role: role,
      classroomId: classroomId,
      schoolId: schoolId,
      photoUrl: firebaseUser.photoURL,
    );

    await _db.collection('users').doc(firebaseUser.uid).set(appUser.toMap());

    if (role == UserRole.student &&
        classroomId != null &&
        classroomId.isNotEmpty) {
      await _db.collection('classrooms').doc(classroomId).set(
        {'studentIds': FieldValue.arrayUnion([firebaseUser.uid])},
        SetOptions(merge: true),
      );
    }

    return appUser;
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ─────────────────────────────────────────────
  // ADMIN HELPERS
  // ─────────────────────────────────────────────

  Future<void> setUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }
}