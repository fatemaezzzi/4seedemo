import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;
  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final List<SettingsItem> items;
  const SettingsCard({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _SettingsRow(item: item),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 56,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class SettingsItem {
  final String label;
  final VoidCallback? onTap;
  const SettingsItem({required this.label, this.onTap});
}

class _SettingsRow extends StatelessWidget {
  final SettingsItem item;
  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.iconBg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? gender;
  final int? age;
  final String? birthday;
  final String? studentId;

  const ProfileHeader({
    required this.name,
    this.subtitle,
    this.gender,
    this.age,
    this.birthday,
    this.studentId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                if (gender != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        _InfoChip(label: 'GENDER', value: gender!),
                        const SizedBox(width: 16),
                        _InfoChip(label: 'AGE', value: age.toString()),
                        const SizedBox(width: 16),
                        _InfoChip(label: 'BIRTHDAY', value: birthday!),
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
      ],
    );
  }
}

class StudentIdBadge extends StatelessWidget {
  final String id;
  const StudentIdBadge({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Unique Student ID',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 12),
          Text(id,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

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