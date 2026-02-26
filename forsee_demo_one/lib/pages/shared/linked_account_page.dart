import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LinkedAccountPage extends StatefulWidget {
  const LinkedAccountPage({super.key});

  @override
  State<LinkedAccountPage> createState() => _LinkedAccountPageState();
}

class _LinkedAccountPageState extends State<LinkedAccountPage> {
  final List<_LinkedProvider> _providers = [
    _LinkedProvider(name: 'Google', icon: Icons.g_mobiledata, connected: true),
    _LinkedProvider(name: 'Microsoft', icon: Icons.window, connected: false),
    _LinkedProvider(name: 'Apple', icon: Icons.apple, connected: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Account'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Linked Accounts',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage the accounts linked to your profile.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _providers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(p.icon,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Switch(
                              value: p.connected,
                              activeThumbColor: AppColors.accent,
                              onChanged: (val) {
                                setState(() => _providers[i] =
                                    _LinkedProvider(
                                        name: p.name,
                                        icon: p.icon,
                                        connected: val));
                              },
                            ),
                          ],
                        ),
                      ),
                      if (i < _providers.length - 1)
                        const Divider(
                            height: 1, color: AppColors.divider, indent: 70),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedProvider {
  final String name;
  final IconData icon;
  final bool connected;
  _LinkedProvider(
      {required this.name, required this.icon, required this.connected});
}