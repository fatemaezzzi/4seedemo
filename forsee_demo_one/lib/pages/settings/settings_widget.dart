import 'package:flutter/material.dart';

// ── Settings Section Title ─────────────────────────────────────────────────

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────
// Replaces the old hardcoded ProfileHeader.
// [name] is the user's display name.
// [subtitle] is an optional second line (e.g. email or role).

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;

  const ProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── School / Badge display ─────────────────────────────────────────────────

class SchoolIdBadge extends StatelessWidget {
  final String id;
  const SchoolIdBadge({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        id,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Settings Card ──────────────────────────────────────────────────────────

class SettingsCard extends StatelessWidget {
  final List<SettingsItem> items;
  const SettingsCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _SettingsTile(item: item),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class SettingsItem {
  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final Widget? trailing;

  const SettingsItem({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.trailing,
  });
}

class _SettingsTile extends StatelessWidget {
  final SettingsItem item;
  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (item.leadingIcon != null) ...[
              Icon(item.leadingIcon, size: 20, color: Colors.black54),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            item.trailing ??
                const Icon(Icons.chevron_right,
                    color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}