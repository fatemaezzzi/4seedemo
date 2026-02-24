import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'app_design_widgets.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _authService.logIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home_page');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B1A2E),
      body: Stack(
        children: [
          // Mint blobs
          Positioned(
            top: 0, right: 0,
            child: MintBlob(width: 220, height: 320),
          ),
          Positioned(
            bottom: 0, left: 0,
            child: MintBlob(width: 180, height: 260, flip: true),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(_anim),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 44),
                      const FourSeeLogo(size: 72),
                      const SizedBox(height: 52),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            PinkField(
                              controller: _emailCtrl,
                              hint: 'Username',
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                              (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 14),
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
                                  color: const Color(0xFF8B5E6A),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) =>
                              (v == null || v.length < 6)
                                  ? 'Min 6 characters'
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            if (_emailCtrl.text.isEmpty) return;
                            await _authService
                                .sendPasswordReset(_emailCtrl.text);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Reset email sent!')),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style:
                            TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        ErrorBanner(message: _errorMessage!),
                      ],

                      const SizedBox(height: 16),
                      ContinueButton(
                          label: 'Continue',
                          loading: _loading,
                          onTap: _submit),
                      const SizedBox(height: 28),
                      const OrDivider(),
                      const SizedBox(height: 20),
                      const SocialButtons(),
                      const SizedBox(height: 36),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                                color: Colors.white38, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/sign_up'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFFE8A0B4),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
            ),
          ),
        ],
      ),
    );
  }
}