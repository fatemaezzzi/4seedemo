import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 4SEE SHARED DESIGN WIDGETS
// Used by login_page.dart, sign_up_page.dart, welcome_page_second.dart
// ─────────────────────────────────────────────────────────────────────────────

// ── Logo ──────────────────────────────────────────────────────────────────────

class FourSeeLogo extends StatelessWidget {
  final double size;
  const FourSeeLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '4',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE8A0B4),
            height: 1,
          ),
        ),
        Text(
          'see',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Pink input field ───────────────────────────────────────────────────────────

class PinkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const PinkField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF3B1A2E),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8B5E6A), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E6A), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF4B8C8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE8A0B4), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFB3C1)),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}

// ── Continue / submit button ───────────────────────────────────────────────────

class ContinueButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const ContinueButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF4B8C8),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Color(0xFF3B1A2E),
              strokeWidth: 2.5,
            ),
          )
              : Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3B1A2E),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ── OR divider ─────────────────────────────────────────────────────────────────

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
      ],
    );
  }
}

// ── Social login buttons ───────────────────────────────────────────────────────

class SocialButtons extends StatelessWidget {
  final VoidCallback? onGoogleTap;

  const SocialButtons({
    super.key,
    this.onGoogleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SocialCircle(
        onTap: onGoogleTap ?? () {},
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class SocialCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const SocialCircle({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2A0F20),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFFB3C1), fontSize: 13),
      ),
    );
  }
}

// ── Organic mint blob (used as background decoration) ─────────────────────────

class MintBlob extends StatelessWidget {
  final double width, height;
  final bool flip;

  const MintBlob({
    super.key,
    required this.width,
    required this.height,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: CustomPaint(
        size: Size(width, height),
        painter: _MintBlobPainter(),
      ),
    );
  }
}

class _MintBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF8FBF9F);
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.3, 0);
    path.cubicTo(w * 0.7, 0, w, h * 0.15, w, h * 0.45);
    path.cubicTo(w, h * 0.78, w * 0.75, h, w * 0.35, h);
    path.cubicTo(0, h, 0, h * 0.6, 0, h * 0.3);
    path.cubicTo(0, h * 0.05, w * 0.05, 0, w * 0.3, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}