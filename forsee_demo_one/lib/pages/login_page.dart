import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/app_design_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Email/password login ──────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });
    try {
      await AuthController.to.login(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      final controllerError = AuthController.to.error.value;
      if (controllerError.isNotEmpty) {
        setState(() => _errorMessage = controllerError);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Google sign in ────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        setState(() => _loading = false);
        return;
      }

      if (!result.isNewUser) {
        return;
      }

      setState(() => _loading = false);
      await _showRoleDialog(result.firebaseUser);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      setState(() => _errorMessage = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Role selection dialog for new social users ────────────────────────────
  Future<void> _showRoleDialog(User firebaseUser) async {
    UserRole selectedRole = UserRole.student;
    final classroomCtrl = TextEditingController();
    final schoolIdCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF3B1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('One last step!',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Choose your role to complete sign up',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),

              Row(
                children: UserRole.values.map((role) {
                  final labels = {
                    UserRole.student: 'Student',
                    UserRole.teacher: 'Teacher',
                    UserRole.admin: 'Admin',
                  };
                  final icons = {
                    UserRole.student: Icons.person_outline,
                    UserRole.teacher: Icons.school_outlined,
                    UserRole.admin: Icons.admin_panel_settings_outlined,
                  };
                  final selected = selectedRole == role;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedRole = role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF4B8C8)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFF4B8C8)
                                  : Colors.white24,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icons[role]!, size: 22,
                                  color: selected
                                      ? const Color(0xFF3B1A2E)
                                      : Colors.white70),
                              const SizedBox(height: 4),
                              Text(labels[role]!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? const Color(0xFF3B1A2E)
                                        : Colors.white70,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              if (selectedRole == UserRole.student)
                PinkField(
                  controller: classroomCtrl,
                  hint: 'Classroom Code',
                  icon: Icons.class_outlined,
                ),
              if (selectedRole == UserRole.teacher ||
                  selectedRole == UserRole.admin)
                PinkField(
                  controller: schoolIdCtrl,
                  hint: 'School ID',
                  icon: Icons.domain_outlined,
                ),

              const SizedBox(height: 20),

              ContinueButton(
                label: 'Complete Sign Up',
                loading: false,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _loading = true);
                  try {
                    await AuthController.to.completeSocialSignUp(
                      firebaseUser: firebaseUser,
                      role: selectedRole,
                      classroomId: selectedRole == UserRole.student
                          ? classroomCtrl.text.trim() : null,
                      schoolId: selectedRole != UserRole.student
                          ? schoolIdCtrl.text.trim() : null,
                    );
                  } catch (e) {
                    setState(() => _errorMessage = e.toString());
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-credential': return 'Invalid email or password.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false, // ← Prevents layout shift on keyboard open
      body: Stack(
        children: [
          // Background — completely isolated, never affected by form rebuilds
          Positioned.fill(
            child: Image.asset('assets/login-page.png', fit: BoxFit.cover),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06), end: Offset.zero,
                ).animate(_anim),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // ← No bouncy overscroll
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.42),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            PinkField(
                              controller: _emailCtrl,
                              hint: 'Username',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email' : null,
                            ),
                            const SizedBox(height: 12),
                            PinkField(
                              controller: _passwordCtrl,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF8B5E6A), size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Min 6 characters' : null,
                            ),
                          ],
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            if (_emailCtrl.text.isEmpty) return;
                            await _authService.sendPasswordReset(_emailCtrl.text);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reset email sent!')));
                          },
                          child: const Text('Forgot password?',
                              style: TextStyle(color: Colors.white60, fontSize: 13)),
                        ),
                      ),

                      // AnimatedSize prevents layout jump when error appears/disappears
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _errorMessage != null
                            ? Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ErrorBanner(message: _errorMessage!),
                        )
                            : const SizedBox.shrink(),
                      ),

                      ContinueButton(
                          label: 'Continue', loading: _loading, onTap: _submit),
                      const SizedBox(height: 20),
                      const OrDivider(),
                      const SizedBox(height: 16),

                      SocialButtons(
                        onGoogleTap: _loading ? null : _googleSignIn,
                      ),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: Colors.white60, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.SIGN_UP),
                            child: const Text('Sign Up',
                                style: TextStyle(
                                  color: Color(0xFFE8A0B4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}