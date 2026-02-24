import 'package:flutter/material.dart';
import 'app_design_widgets.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF3B1A2E),
      body: Stack(
        children: [
          // Mint blob top-right
          Positioned(
            top: 0, right: 0,
            child: MintBlob(width: 220, height: 280),
          ),
          // Mint blob bottom-left
          Positioned(
            bottom: 0, left: 0,
            child: MintBlob(width: 200, height: 240, flip: true),
          ),
          // Leaf accents
          Positioned(
            top: 50, left: 16,
            child: _LeafAccent(color: const Color(0xFF6FAF80), size: 55),
          ),
          Positioned(
            bottom: 110, right: 16,
            child: _LeafAccent(color: const Color(0xFF6FAF80), size: 45),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _anim,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const FourSeeLogo(size: 68),
                  const Spacer(flex: 1),

                  // Illustration
                  Container(
                    width: 220,
                    height: 180,
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF4A2040).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child:
                      Text('🧑‍💻', style: TextStyle(fontSize: 80)),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Buttons
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
                          onTap: () => Navigator.pushNamed(
                              context, '/account_selection'),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
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
    return Scaffold(
      backgroundColor: const Color(0xFF3B1A2E),
      body: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: MintBlob(width: 200, height: 240),
          ),
          Positioned(
            bottom: 0, left: 0,
            child: MintBlob(width: 180, height: 200, flip: true),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const FourSeeLogo(size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Choose your role',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    children: [
                      _RoleCard(
                        role: 'Admin',
                        emoji: '👩‍💼',
                        subtitle: 'Manage school & staff',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'admin',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _RoleCard(
                        role: 'Teacher',
                        emoji: '👩‍🏫',
                        subtitle: 'Monitor & support students',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'teacher',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _RoleCard(
                        role: 'Student',
                        emoji: '🧑‍🎓',
                        subtitle: 'Track your progress',
                        onTap: () => Navigator.pushNamed(
                          context, '/sign_up',
                          arguments: 'student',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL WIDGETS (only used in this file)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WelcomeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A0F20).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String emoji;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.emoji,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A0F20).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _LeafAccent extends StatelessWidget {
  final Color color;
  final double size;
  const _LeafAccent({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafPainter(color),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w, h * 0.5, w * 0.5, h);
    path.quadraticBezierTo(0, h * 0.5, w * 0.5, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}