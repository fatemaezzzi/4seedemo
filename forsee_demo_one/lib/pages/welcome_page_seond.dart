import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME PAGE SECOND
// ─────────────────────────────────────────────────────────────────────────────

class WelcomePageSecond extends StatefulWidget {
  const WelcomePageSecond({super.key});

  @override
  State<WelcomePageSecond> createState() => _WelcomePageSecondState();
}

class _WelcomePageSecondState extends State<WelcomePageSecond>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/welcome-page-second.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _anim,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _WelcomeButton(
                          label: 'Already have an account?',
                          onTap: () =>
                              Navigator.pushNamed(context, '/login_page'),
                        ),
                        const SizedBox(height: 16),
                        _WelcomeButton(
                          label: 'Create an account',
                          filled: true,
                          onTap: () =>
                              Navigator.pushNamed(context, '/account_selection'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.06),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT SELECTION PAGE
// ─────────────────────────────────────────────────────────────────────────────

class AccountSelectionPage extends StatelessWidget {
  const AccountSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/account-selection-page.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Scrollable role cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    children: [
                      _RoleCard(
                        role: 'Admin',
                        clipartPath: 'assets/admin.png',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'admin',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _RoleCard(
                        role: 'Teacher',
                        clipartPath: 'assets/teacher.png',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'teacher',
                        ),
                      ),
                      const SizedBox(height: 28),
                      _RoleCard(
                        role: 'Student',
                        clipartPath: 'assets/student.png',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'student',
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _WelcomeButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFFF4B8C8)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: filled ? const Color(0xFFF4B8C8) : Colors.white38,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filled ? const Color(0xFF3B1A2E) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Role card: clipart image on top, pink label button below ──────────────────

class _RoleCard extends StatelessWidget {
  final String role;
  final String clipartPath;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.clipartPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Clipart image ────────────────────────────────────────────
          Image.asset(
            clipartPath,
            width: screenWidth * 0.60,
            height: 170,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: screenWidth * 0.60,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person, color: Colors.white30, size: 64),
            ),
          ),

          const SizedBox(height: 12),

          // ── Pink pill label ──────────────────────────────────────────
          Container(
            width: screenWidth * 0.70,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4B8C8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              role,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3B1A2E),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}