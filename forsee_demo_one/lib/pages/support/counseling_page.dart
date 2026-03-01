// lib/pages/support/counseling_page.dart
// =========================================================
// Full Counseling Services page – opened from StudentProfilePage
// In-school counselor, booking requests, external helplines
// =========================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CounselingPage extends StatefulWidget {
  final StudentModel student;
  const CounselingPage({super.key, required this.student});

  @override
  State<CounselingPage> createState() => _CounselingPageState();
}

class _CounselingPageState extends State<CounselingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  String? _selectedSlot;
  bool _requestSent = false;
  String _selectedConcern = 'Academic';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  static const List<String> _concerns = ['Academic', 'Behavioural', 'Social', 'Family', 'Mental Health', 'Attendance'];

  static const List<Map<String, dynamic>> _timeSlots = [
    {'time': '9:00 AM', 'day': 'Mon', 'available': true},
    {'time': '10:00 AM', 'day': 'Mon', 'available': false},
    {'time': '11:00 AM', 'day': 'Tue', 'available': true},
    {'time': '2:00 PM', 'day': 'Tue', 'available': true},
    {'time': '3:00 PM', 'day': 'Wed', 'available': true},
    {'time': '4:00 PM', 'day': 'Wed', 'available': false},
    {'time': '9:00 AM', 'day': 'Thu', 'available': true},
    {'time': '11:00 AM', 'day': 'Fri', 'available': true},
  ];

  static const List<Map<String, dynamic>> _externalCounselors = [
    {
      'name': 'iCall – TISS',
      'role': 'Psychosocial Helpline',
      'phone': '9152987821',
      'hours': 'Mon–Sat, 8AM–10PM',
      'languages': 'English, Hindi, Marathi',
      'free': true,
      'icon': Icons.support_agent_outlined,
      'color': Color(0xFFFF8A65),
    },
    {
      'name': 'Vandrevala Foundation',
      'role': '24/7 Mental Health Helpline',
      'phone': '18602662345',
      'hours': '24 hours, 7 days',
      'languages': 'English, Hindi + 9 regional',
      'free': true,
      'icon': Icons.phone_in_talk_outlined,
      'color': Color(0xFF80CBC4),
    },
    {
      'name': 'NIMHANS Helpline',
      'role': 'National Mental Health Helpline',
      'phone': '08046110007',
      'hours': '8AM–8PM daily',
      'languages': 'English, Hindi, Kannada',
      'free': true,
      'icon': Icons.local_hospital_outlined,
      'color': Color(0xFF90CAF9),
    },
    {
      'name': 'Mann Talks',
      'role': 'Youth Focused Counselling',
      'phone': '8686139139',
      'hours': 'Mon–Sat, 9AM–9PM',
      'languages': 'English, Hindi',
      'free': false,
      'icon': Icons.chat_bubble_outline,
      'color': Color(0xFFCE93D8),
    },
  ];

  void _sendRequest() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF3B2028),
        behavior: SnackBarBehavior.floating,
        content: const Text('Please select a time slot', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _requestSent = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF3B2028),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xFFFF8A65), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('Session requested for ${widget.student.name} at $_selectedSlot', style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    ));
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),

            // ── Header ────────────────────────────────────────────
            Row(children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Counseling Services', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                Text('Book sessions & helplines', style: TextStyle(color: Color(0xFFE9C2D7), fontSize: 12, fontFamily: 'Pridi')),
              ]),
            ]),

            const SizedBox(height: 20),

            // ── In-School Counselor Card ──────────────────────────
            _buildCounselorCard(),

            const SizedBox(height: 20),

            // ── Concern selector ──────────────────────────────────
            const Text('Type of Concern', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _concerns.map((c) {
                final sel = _selectedConcern == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedConcern = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFFF8A65) : const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(c, style: TextStyle(color: sel ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi')),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Time Slot Picker ──────────────────────────────────
            const Text('Available Slots', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6),
              itemCount: _timeSlots.length,
              itemBuilder: (_, i) {
                final slot = _timeSlots[i];
                final available = slot['available'] as bool;
                final slotKey = '${slot['day']} ${slot['time']}';
                final selected = _selectedSlot == slotKey;
                return GestureDetector(
                  onTap: available ? () => setState(() => _selectedSlot = slotKey) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: !available ? const Color(0xFF2A1A1E)
                          : selected ? const Color(0xFFFF8A65)
                          : const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(10),
                      border: selected ? Border.all(color: const Color(0xFFFF8A65), width: 2) : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(slot['day'] as String, style: TextStyle(color: selected ? Colors.black87 : available ? const Color(0xFFE9C2D7) : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(slot['time'] as String, style: TextStyle(color: selected ? Colors.black : available ? Colors.white70 : Colors.white24, fontSize: 10)),
                    ]),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Request Button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _requestSent ? null : _sendRequest,
                icon: Icon(_requestSent ? Icons.check : Icons.send_outlined, size: 18),
                label: Text(
                  _requestSent ? 'Session Request Sent ✓' : 'Request Session for ${widget.student.name.split(' ').first}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _requestSent ? const Color(0xFFFF8A65).withOpacity(0.25) : const Color(0xFFFF8A65),
                  foregroundColor: _requestSent ? const Color(0xFFFF8A65) : Colors.black87,
                  disabledBackgroundColor: const Color(0xFFFF8A65).withOpacity(0.25),
                  disabledForegroundColor: const Color(0xFFFF8A65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── External Helplines ────────────────────────────────
            const Text('External Helplines', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
            const SizedBox(height: 4),
            const Text('Free, confidential support for students & families', style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Pridi')),
            const SizedBox(height: 12),

            ..._externalCounselors.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return AnimatedBuilder(
                animation: _anim,
                builder: (_, child) {
                  final t = ((_anim.value - i * 0.12) / 0.6).clamp(0.0, 1.0);
                  return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child));
                },
                child: _HelplinesCard(counselor: c, onCall: () => _call(c['phone'] as String)),
              );
            }),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildCounselorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2028),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8A65).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFF8A65).withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.person_outlined, color: Color(0xFFFF8A65), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ms. Priya Sharma', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pridi')),
            Text('School Counselor · Certified Psychologist', style: TextStyle(color: Color(0xFFFF8A65), fontSize: 11, fontFamily: 'Pridi')),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              CircleAvatar(backgroundColor: Colors.greenAccent, radius: 4),
              SizedBox(width: 5),
              Text('Available', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.access_time, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          const Text('Mon–Fri  ·  9AM–4PM', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.room_outlined, color: Colors.white38, size: 14),
          const SizedBox(width: 4),
          const Text('Room 204', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.psychology_outlined, color: Color(0xFFFF8A65), size: 14),
          const SizedBox(width: 6),
          const Text('Specialises in: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
          const Expanded(child: Text('Academic stress, Social anxiety, Family issues', style: TextStyle(color: Colors.white60, fontSize: 11), overflow: TextOverflow.ellipsis)),
        ]),
      ]),
    );
  }
}

// ── Helplines Card ───────────────────────────────────────────────────────────

class _HelplinesCard extends StatelessWidget {
  final Map<String, dynamic> counselor;
  final VoidCallback onCall;
  const _HelplinesCard({required this.counselor, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final c = counselor['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(counselor['icon'] as IconData, color: c, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(counselor['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
            const SizedBox(width: 6),
            if (counselor['free'] as bool)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('FREE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ]),
          Text(counselor['role'] as String, style: TextStyle(color: c, fontSize: 10, fontFamily: 'Pridi')),
          const SizedBox(height: 2),
          Text(counselor['hours'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          GestureDetector(
            onTap: onCall,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.phone, color: c, size: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text(counselor['phone'] as String, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ]),
      ]),
    );
  }
}