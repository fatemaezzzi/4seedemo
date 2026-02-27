import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/services/auth_service.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';

// NOTE: We use AuthService's AppUser and UserRole directly here
// so that auth_service.dart, auth_controller.dart, sign_up_page.dart,
// and login_page.dart all share the exact same types — no mismatch.

class AuthController extends GetxController {
  // ── Singleton: AuthController.to from anywhere ─────────────────────────────
  static AuthController get to => Get.find();

  final _auth        = FirebaseAuth.instance;
  final _db          = FirebaseFirestore.instance;
  final _authService = AuthService();

  // ── Observable state ───────────────────────────────────────────────────────
  final Rx<User?>    firebaseUser = Rx<User?>(null);
  final Rx<AppUser?> appUser      = Rx<AppUser?>(null);
  final RxBool       isLoading    = false.obs;
  final RxString     error        = ''.obs;

  // ── Convenience getters ────────────────────────────────────────────────────
  bool       get isLoggedIn => firebaseUser.value != null;
  UserRole?  get role       => appUser.value?.role;
  String     get userName   => appUser.value?.name ?? '';
  String     get userEmail  => appUser.value?.email ?? '';

  // String version for middleware comparisons
  String get roleString {
    switch (role) {
      case UserRole.admin:   return 'admin';
      case UserRole.teacher: return 'teacher';
      case UserRole.student: return 'student';
      default:               return '';
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Bind to Firebase auth stream.
    // Fires on: app start (persisted session), login, logout.
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthStateChanged);
  }

  // ── Core: fires automatically on every auth state change ──────────────────
  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      // Signed out → clear state and go to welcome
      appUser.value = null;
      Get.offAllNamed(AppRoutes.WELCOME_ONE);
      return;
    }

    // Signed in → fetch Firestore profile
    isLoading.value = true;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // No Firestore profile → sign out for safety
        await _auth.signOut();
        return;
      }

      appUser.value = AppUser.fromMap(doc.data()!, user.uid);
      _redirectByRole();

    } catch (e) {
      error.value = 'Could not load profile. Please try again.';
      await _auth.signOut();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Redirect to correct dashboard based on role ───────────────────────────
  void _redirectByRole() {
    switch (role) {
      case UserRole.admin:
        Get.offAllNamed(AppRoutes.ADMIN_DASHBOARD);
        break;
      case UserRole.teacher:
        Get.offAllNamed(AppRoutes.TEACHER_DASHBOARD);
        break;
      case UserRole.student:
        Get.offAllNamed(AppRoutes.STUDENT_DASHBOARD);
        break;
      default:
        error.value = 'Unknown role. Contact support.';
        _auth.signOut();
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  // Call this from login_page.dart instead of _authService.logIn directly.
  // The _onAuthStateChanged listener handles the redirect automatically.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _authService.logIn(email: email, password: password);
      // Stream fires → _onAuthStateChanged → _redirectByRole
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ── SIGN UP ────────────────────────────────────────────────────────────────
  // Call this from sign_up_page.dart instead of _authService.signUp directly.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        classroomId: classroomId,
        schoolId: schoolId,
      );
      // Stream fires → _onAuthStateChanged → _redirectByRole
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ── GOOGLE SIGN IN ─────────────────────────────────────────────────────────
  // Returns true if existing user (auto-redirected), false if new user
  // (caller should show role selection sheet then call completeSocialSignUp).
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _authService.signInWithGoogle();
      if (result == null) return false; // user cancelled picker
      if (!result.isNewUser) {
        // Existing user → stream fires → redirect handled automatically
        return true;
      }
      // New user → caller handles role sheet
      return false;
    } on Exception catch (e) {
      error.value = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── COMPLETE SOCIAL SIGN UP ────────────────────────────────────────────────
  Future<void> completeSocialSignUp({
    required User firebaseUser,
    required UserRole role,
    String? classroomId,
    String? schoolId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _authService.completeSocialSignUp(
        firebaseUser: firebaseUser,
        role: role,
        classroomId: classroomId,
        schoolId: schoolId,
      );
      // Stream fires → _onAuthStateChanged → _redirectByRole
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  // Call from any dashboard's logout button.
  Future<void> logout() async {
    await _authService.signOut();
    // Stream fires → _onAuthStateChanged → user is null → WELCOME_ONE
  }
}