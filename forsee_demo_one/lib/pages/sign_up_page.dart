import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import '../widgets/app_design_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _classroomCtrl = TextEditingController();
  final _schoolIdCtrl = TextEditingController();

  final _authService = AuthService();

  UserRole _selectedRole = UserRole.student;
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) {
      final role = UserRole.values.firstWhere(
            (r) => r.name == arg,
        orElse: () => UserRole.student,
      );
      setState(() => _selectedRole = role);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _classroomCtrl.dispose();
    _schoolIdCtrl.dispose();
    super.dispose();
  }

  // ── Google sign in ───────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) { setState(() => _loading = false); return; }
      if (!mounted) return;
      if (!result.isNewUser) {
        Navigator.pushReplacementNamed(context, "/home_page");
        return;
      }
      // New user from social - show role bottom sheet
      setState(() => _loading = false);
      await _showSocialRoleSheet(result.firebaseUser);
    } catch (e) {
      debugPrint("Google error: $e");
      setState(() => _errorMessage = "Google sign-in failed.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Complete social sign up ────────────────────────────────────────────────
  Future<void> _showSocialRoleSheet(firebaseUser) async {
    final classroomCtrl = TextEditingController();
    final schoolIdCtrl = TextEditingController();
    UserRole sheetRole = _selectedRole;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF3B1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text("Choose your role",
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: UserRole.values.map((role) {
                  final labels = {UserRole.student: "Student",
                    UserRole.teacher: "Teacher", UserRole.admin: "Admin"};
                  final sel = sheetRole == role;
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setS(() => sheetRole = role),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: sel ? const Color(0xFFF4B8C8) : Colors.white10,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: sel
                                  ? const Color(0xFFF4B8C8) : Colors.white24)),
                          child: Text(labels[role]!, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? const Color(0xFF3B1A2E) : Colors.white70))),
                    ),
                  ));
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (sheetRole == UserRole.student)
                PinkField(controller: classroomCtrl,
                    hint: "Classroom Code", icon: Icons.class_outlined),
              if (sheetRole == UserRole.teacher || sheetRole == UserRole.admin)
                PinkField(controller: schoolIdCtrl,
                    hint: "School ID", icon: Icons.domain_outlined),
              const SizedBox(height: 16),
              ContinueButton(label: "Complete Sign Up", loading: false,
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    try {
                      await _authService.completeSocialSignUp(
                        firebaseUser: firebaseUser, role: sheetRole,
                        classroomId: sheetRole == UserRole.student
                            ? classroomCtrl.text.trim() : null,
                        schoolId: sheetRole != UserRole.student
                            ? schoolIdCtrl.text.trim() : null,
                      );
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, "/home_page");
                    } catch (e) {
                      setState(() => _errorMessage = e.toString());
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        name: _nameCtrl.text,
        role: _selectedRole,
        classroomId: _selectedRole == UserRole.student
            ? _classroomCtrl.text.trim()
            : null,
        schoolId: _selectedRole != UserRole.student
            ? _schoolIdCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_page');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (e) {
      debugPrint('SignUp error: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Background image ──────────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/sign-up-page.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(_anim),
                child: Column(
                  children: [
                    // ── Back button row ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    // Push form down to match where the bg image's
                    // form section starts (~25% from top for signup)
                    SizedBox(height: screenHeight * 0.08),

                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Role chips ──────────────────────────
                            // const Text(
                            //   'I am a...',
                            //   style: TextStyle(
                            //     color: Colors.white70,
                            //     fontSize: 13,
                            //     letterSpacing: 1,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
                            // const SizedBox(height: 10),
                            // Row(
                            //   children: UserRole.values
                            //       .map((role) => Expanded(
                            //     child: Padding(
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 3),
                            //       child: RoleChip(
                            //         role: role,
                            //         selected:
                            //         _selectedRole == role,
                            //         onTap: () => setState(() =>
                            //         _selectedRole = role),
                            //       ),
                            //     ),
                            //   ))
                            //       .toList(),
                            // ),
                            //
                            const SizedBox(height: 35),

                            // ── Form fields ─────────────────────────
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  PinkField(
                                    controller: _nameCtrl,
                                    hint: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter your name'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  PinkField(
                                    controller: _emailCtrl,
                                    hint: 'Email ID',
                                    icon: Icons.email_outlined,
                                    keyboardType:
                                    TextInputType.emailAddress,
                                    validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Enter a valid email'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  PinkField(
                                    controller: _passwordCtrl,
                                    hint: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePass,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF8B5E6A),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscurePass = !_obscurePass),
                                    ),
                                    validator: (v) =>
                                    (v == null || v.length < 6)
                                        ? 'Min 6 characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  PinkField(
                                    controller: _confirmCtrl,
                                    hint: 'Confirm Password',
                                    icon: Icons.lock_outline,
                                    obscureText: _obscureConfirm,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF8B5E6A),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscureConfirm =
                                      !_obscureConfirm),
                                    ),
                                    validator: (v) =>
                                    v != _passwordCtrl.text
                                        ? 'Passwords do not match'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // ── Role-specific field ────────────
                                  if (_selectedRole == UserRole.student)
                                    PinkField(
                                      controller: _classroomCtrl,
                                      hint: 'Classroom Code',
                                      icon: Icons.class_outlined,
                                      validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Enter classroom code'
                                          : null,
                                    ),
                                  if (_selectedRole == UserRole.teacher ||
                                      _selectedRole == UserRole.admin)
                                    PinkField(
                                      controller: _schoolIdCtrl,
                                      hint: 'School ID',
                                      icon: Icons.domain_outlined,
                                      validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Enter your school ID'
                                          : null,
                                    ),
                                ],
                              ),
                            ),

                            // ── Error ───────────────────────────────
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 10),
                              ErrorBanner(message: _errorMessage!),
                            ],

                            const SizedBox(height: 20),

                            // ── Continue button ──────────────────────
                            ContinueButton(
                              label: 'Continue',
                              loading: _loading,
                              onTap: _submit,
                            ),
                            const SizedBox(height: 18),

                            // ── OR + social ──────────────────────────
                            const OrDivider(),
                            const SizedBox(height: 16),
                            SocialButtons(
                              onGoogleTap: _loading ? null : _googleSignIn,
                            ),
                            const SizedBox(height: 20),

                            // ── Login link ───────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/login_page'),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: Color(0xFFE8A0B4),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE CHIP
// ─────────────────────────────────────────────────────────────────────────────

class RoleChip extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {
    UserRole.student: 'Student',
    UserRole.teacher: 'Teacher',
    UserRole.admin: 'Admin',
  };

  static const _icons = {
    UserRole.student: Icons.person_outline,
    UserRole.teacher: Icons.school_outlined,
    UserRole.admin: Icons.admin_panel_settings_outlined,
  };

  const RoleChip({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF4B8C8)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFF4B8C8)
                : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _icons[role]!,
              size: 22,
              color: selected
                  ? const Color(0xFF3B1A2E)
                  : Colors.white70,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[role]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF3B1A2E)
                    : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}