import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _emailNotif = true;
  bool _pushNotif = true;

  final _messages = [
    {'from': 'Admin', 'msg': 'Please submit semester reports by Friday.', 'time': '10:30 AM', 'read': false},
    {'from': 'Rohan Sharma', 'msg': 'Sir, I had a doubt about the assignment.', 'time': '9:15 AM', 'read': true},
    {'from': 'Admin', 'msg': 'Staff meeting rescheduled to 3 PM today.', 'time': 'Yesterday', 'read': true},
    {'from': 'Priya Nair', 'msg': 'Thank you for the extra help session!', 'time': 'Yesterday', 'read': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [Tab(text: 'Inbox'), Tab(text: 'Notification Settings')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Inbox tab
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = _messages[i];
              final unread = m['read'] == false;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: unread
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: unread
                      ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white54, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(m['from']! as String,
                                  style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: unread
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 14)),
                              const Spacer(),
                              Text(m['time']! as String,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              if (unread) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(m['msg']! as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Notification Settings tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Message Notifications',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(children: [
                          const Expanded(
                              child: Text('Email Notifications',
                                  style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500))),
                          Switch(
                              value: _emailNotif,
                              activeThumbColor: AppColors.accent,
                              onChanged: (v) =>
                                  setState(() => _emailNotif = v)),
                        ]),
                      ),
                      const Divider(
                          height: 1, color: AppColors.divider, indent: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(children: [
                          const Expanded(
                              child: Text('Push Notifications',
                                  style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500))),
                          Switch(
                              value: _pushNotif,
                              activeThumbColor: AppColors.accent,
                              onChanged: (v) =>
                                  setState(() => _pushNotif = v)),
                        ]),
                      ),
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