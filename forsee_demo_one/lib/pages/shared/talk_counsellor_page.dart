import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TalkToCounsellorPage extends StatelessWidget {
  const TalkToCounsellorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk to a Counsellor'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "We're here\nfor you",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect with a counsellor anonymously. Your conversation is private.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _CounsellorCard(
              name: 'Dr. Priya Mehta',
              role: 'Student Wellness',
              available: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _CounsellorCard(
              name: 'Mr. Arjun Kapoor',
              role: 'Academic Stress',
              available: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _CounsellorCard(
              name: 'Ms. Sunita Rao',
              role: 'Career Guidance',
              available: false,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Need immediate help?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                      'Call the national student helpline: 1800-599-0019',
                      style:
                      TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounsellorCard extends StatelessWidget {
  final String name;
  final String role;
  final bool available;
  final VoidCallback onTap;

  const _CounsellorCard({
    required this.name,
    required this.role,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white54),
                ),
                if (available)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(role,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: available ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                available ? AppColors.accent : Colors.grey.shade300,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(available ? 'Chat' : 'Away',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}