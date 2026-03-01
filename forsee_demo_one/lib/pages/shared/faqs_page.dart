// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPage extends _FAQsPageState {}

class _FAQsPageState extends State<FAQsPage> {
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I reset my password?',
      'a': 'Go to Settings → Change Password. Enter your current password and set a new one.'
    },
    {
      'q': 'How do I link my Google account?',
      'a': 'Navigate to Settings → Linked Account and toggle on the Google option.'
    },
    {
      'q': 'Where can I view my attendance?',
      'a': 'Attendance can be viewed on your dashboard under the Attendance tab.'
    },
    {
      'q': 'How do I contact my teacher?',
      'a': 'Use the Messages section accessible from the home screen to send a message to your teacher.'
    },
    {
      'q': 'What is my Unique Student ID?',
      'a': 'Your Unique Student ID is shown on your Settings profile page. It starts with a # symbol.'
    },
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Frequently Asked\nQuestions',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _faqs.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) {
                    final isExpanded = _expandedIndex == i;
                    return InkWell(
                      onTap: () => setState(() =>
                      _expandedIndex = isExpanded ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(_faqs[i]['q']!,
                                      style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 10),
                              Text(_faqs[i]['a']!,
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}