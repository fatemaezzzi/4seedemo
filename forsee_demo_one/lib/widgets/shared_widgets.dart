import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Teal Action Button ───────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const PrimaryButton({required this.label, required this.onTap, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}

// ─── Teal Card Container ─────────────────────────────────────
class TealCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const TealCard({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

// ─── Section Title ───────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Info Row (label + value) ────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const InfoRow({required this.label, required this.value, this.isLast = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ─── Tappable List Tile ──────────────────────────────────────
class ActionTile extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;
  final IconData? leadingIcon;

  const ActionTile(
      {required this.label, this.onTap, this.isLast = false, this.leadingIcon, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 18, color: AppColors.textDark),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38, size: 18),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ─── Editable Field ─────────────────────────────────────────
class EditableField extends StatelessWidget {
  final String label;
  final String initialValue;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;

  const EditableField({
    required this.label,
    required this.initialValue,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: readOnly
                ? null
                : const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Bottom Nav Bar ──────────────────────────────────────────
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home_outlined, color: Colors.black54),
          Icon(Icons.chat_bubble_outline, color: Colors.black54),
          Icon(Icons.school_outlined, color: Colors.black54),
          Icon(Icons.settings, color: Colors.black87),
        ],
      ),
    );
  }
}