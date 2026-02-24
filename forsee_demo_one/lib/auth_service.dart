import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// ENUMS & MODELS
// ─────────────────────────────────────────────

enum UserRole { student, teacher, admin }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? classroomId; // for students
  final String? schoolId;    // for teachers & admins

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.classroomId,
    this.schoolId,
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
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'role': role.name,
    if (classroomId != null) 'classroomId': classroomId,
    if (schoolId != null) 'schoolId': schoolId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ─────────────────────────────────────────────
// AUTH SERVICE
// ─────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream: listen to auth state changes ──────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Get current Firebase user ─────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Fetch AppUser profile from Firestore ─────────────────────────────────
  Future<AppUser?> fetchCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!, user.uid);
  }

  // ─────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────

  /// Creates a Firebase Auth account + writes a Firestore user document.
  /// [role] must be passed explicitly so every new account is categorised.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? classroomId, // students: join code / classroom ID
    String? schoolId,    // teachers & admins: school ID
  }) async {
    // 1. Create the Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    // 2. Build the AppUser object
    final appUser = AppUser(
      uid: uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      classroomId: classroomId,
      schoolId: schoolId,
    );

    // 3. Write to Firestore /users/{uid}
    await _db.collection('users').doc(uid).set(appUser.toMap());

    // 4. For students: register them in the classroom document as well.
    //    Use set+merge so it works even if the classroom doc doesn't exist yet.
    if (role == UserRole.student && classroomId != null && classroomId.isNotEmpty) {
      await _db.collection('classrooms').doc(classroomId).set({
        'studentIds': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    }

    return appUser;
  }

  // ─────────────────────────────────────────────
  // LOG IN
  // ─────────────────────────────────────────────

  /// Signs in and returns the full AppUser (including role).
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
      // Auth record exists but no Firestore doc – rare edge case
      await _auth.signOut();
      throw Exception('User profile not found. Please contact support.');
    }

    return AppUser.fromMap(doc.data()!, uid);
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() => _auth.signOut();

  // ─────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ─────────────────────────────────────────────
  // ADMIN HELPERS
  // ─────────────────────────────────────────────

  /// Elevate an existing user to admin – call from a secure Cloud Function
  /// or directly only if you're already authenticated as an admin.
  Future<void> setUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }
}