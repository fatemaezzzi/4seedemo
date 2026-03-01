// lib/pages/support/ngo_support_page.dart
// =========================================================
// Full NGO Support page – opened from StudentProfilePage
// Displays NGO list, student context, referral logging
// =========================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:url_launcher/url_launcher.dart'; // add to pubspec if needed

class NgoSupportPage extends StatefulWidget {
  final StudentModel student;
  const NgoSupportPage({super.key, required this.student});

  @override
  State<NgoSupportPage> createState() => _NgoSupportPageState();
}

class _NgoSupportPageState extends State<NgoSupportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  final List<String> _referredNgos = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _ngos = [
    {
      'name': 'Pratham Education Foundation',
      'tagline': 'Every child in school and learning well',
      'focus': 'Remedial Learning & Retention',
      'phone': '022-66902000',
      'website': 'https://www.pratham.org',
      'icon': Icons.school_outlined,
      'color': Color(0xFF4FC3F7),
      'tags': ['Learning Support', 'Dropout Prevention', 'Community'],
    },
    {
      'name': 'CRY – Child Rights and You',
      'tagline': 'Advocating child rights since 1979',
      'focus': 'Child Rights & Welfare',
      'phone': '022-23063647',
      'website': 'https://www.cry.org',
      'icon': Icons.child_care_outlined,
      'color': Color(0xFFFF8A65),
      'tags': ['Child Rights', 'Legal Aid', 'Advocacy'],
    },
    {
      'name': 'Teach For India',
      'tagline': 'One day all children will attain an excellent education',
      'focus': 'Quality Teaching & Mentorship',
      'phone': '022-61748800',
      'website': 'https://www.teachforindia.org',
      'icon': Icons.people_alt_outlined,
      'color': Color(0xFFA5D6A7),
      'tags': ['Mentorship', 'Teaching', 'Leadership'],
    },
    {
      'name': 'Room to Read',
      'tagline': 'World change starts with educated children',
      'focus': 'Literacy & Girls Education',
      'phone': '080-41656664',
      'website': 'https://www.roomtoread.org',
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFFCE93D8),
      'tags': ['Literacy', 'Girls Education', 'Libraries'],
    },
    {
      'name': 'Aga Khan Foundation',
      'tagline': 'Improving livelihoods through education',
      'focus': 'Rural Education & Development',
      'phone': '011-24198000',
      'website': 'https://www.akdn.org',
      'icon': Icons.diversity_3_outlined,
      'color': Color(0xFFFFCC80),
      'tags': ['Rural', 'Holistic Development', 'Community'],
    },
  ];

  void _logReferral(String ngoName) {
    if (_referredNgos.contains(ngoName)) return;
    setState(() => _referredNgos.add(ngoName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF3B2028),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.check_circle, color: Color(0xFF4FC3F7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Referral to $ngoName logged for ${widget.student.name}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }

  void _showNgoDetail(Map<String, dynamic> ngo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NgoDetailSheet(
        ngo: ngo,
        student: widget.student,
        isReferred: _referredNgos.contains(ngo['name']),
        onRefer: () => _logReferral(ngo['name'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('NGO Support', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                Text('Connect with local organisations', style: TextStyle(color: Color(0xFFE9C2D7), fontSize: 12, fontFamily: 'Pridi')),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.person_outline, color: Color(0xFFE9C2D7), size: 15),
                  const SizedBox(width: 5),
                  Text(s.name.split(' ').first, style: const TextStyle(color: Color(0xFFE9C2D7), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Student Risk Context Banner ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RiskContextBanner(student: s, referralCount: _referredNgos.length),
          ),

          const SizedBox(height: 16),

          // ── Section label ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Recommended Organisations', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
          ),
          const SizedBox(height: 10),

          // ── NGO Cards ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _ngos.length,
              itemBuilder: (_, i) {
                final ngo = _ngos[i];
                final delay = i * 0.1;
                return AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) {
                    final t = ((_anim.value - delay) / (1 - delay)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: child),
                    );
                  },
                  child: _NgoCard(
                    ngo: ngo,
                    isReferred: _referredNgos.contains(ngo['name']),
                    onTap: () => _showNgoDetail(ngo),
                    onQuickRefer: () => _logReferral(ngo['name'] as String),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Risk Context Banner ──────────────────────────────────────────────────────

class _RiskContextBanner extends StatelessWidget {
  final StudentModel student;
  final int referralCount;
  const _RiskContextBanner({required this.student, required this.referralCount});

  @override
  Widget build(BuildContext context) {
    final isHigh = student.riskLevel == RiskLevel.high;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHigh ? const Color(0xFF6B2D2D) : const Color(0xFF3B2028),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHigh ? Colors.redAccent.withOpacity(0.5) : const Color(0xFFA6768B).withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isHigh ? Colors.red.withOpacity(0.2) : const Color(0xFFA6768B).withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(isHigh ? Icons.warning_rounded : Icons.info_outline, color: isHigh ? Colors.redAccent : const Color(0xFFE9C2D7), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isHigh ? '${student.name} needs urgent support' : 'Connecting ${student.name} to support',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
            ),
            const SizedBox(height: 2),
            Text(
              referralCount > 0 ? '$referralCount referral(s) logged today' : 'Tap a card to log a referral',
              style: TextStyle(color: isHigh ? Colors.orangeAccent : const Color(0xFFE9C2D7), fontSize: 11, fontFamily: 'Pridi'),
            ),
          ]),
        ),
        if (referralCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF4FC3F7).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$referralCount logged', style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

// ── NGO Card ────────────────────────────────────────────────────────────────

class _NgoCard extends StatelessWidget {
  final Map<String, dynamic> ngo;
  final bool isReferred;
  final VoidCallback onTap;
  final VoidCallback onQuickRefer;
  const _NgoCard({required this.ngo, required this.isReferred, required this.onTap, required this.onQuickRefer});

  @override
  Widget build(BuildContext context) {
    final c = ngo['color'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B2028),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isReferred ? c.withOpacity(0.6) : Colors.transparent, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(ngo['icon'] as IconData, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ngo['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
                Text(ngo['focus'] as String, style: TextStyle(color: c, fontSize: 11, fontFamily: 'Pridi')),
              ]),
            ),
            if (isReferred)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.check, color: c, size: 12),
                  const SizedBox(width: 4),
                  Text('Referred', style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
          const SizedBox(height: 10),
          Text(ngo['tagline'] as String, style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Pridi')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (ngo['tags'] as List<String>).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(tag, style: TextStyle(color: c, fontSize: 10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.info_outline, size: 14),
                label: const Text('View Details', style: TextStyle(fontSize: 12, fontFamily: 'Pridi')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isReferred ? null : onQuickRefer,
                icon: Icon(isReferred ? Icons.check : Icons.send_outlined, size: 14),
                label: Text(isReferred ? 'Referred' : 'Refer Student', style: const TextStyle(fontSize: 12, fontFamily: 'Pridi')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReferred ? c.withOpacity(0.2) : c,
                  foregroundColor: isReferred ? c : Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  disabledBackgroundColor: c.withOpacity(0.2),
                  disabledForegroundColor: c,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── NGO Detail Bottom Sheet ──────────────────────────────────────────────────

class _NgoDetailSheet extends StatelessWidget {
  final Map<String, dynamic> ngo;
  final StudentModel student;
  final bool isReferred;
  final VoidCallback onRefer;
  const _NgoDetailSheet({required this.ngo, required this.student, required this.isReferred, required this.onRefer});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = ngo['color'] as Color;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF3B2028),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // drag handle
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),

        // Header
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(ngo['icon'] as IconData, color: c, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ngo['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            Text(ngo['focus'] as String, style: TextStyle(color: c, fontSize: 12, fontFamily: 'Pridi')),
          ])),
        ]),
        const SizedBox(height: 16),

        // Contact info
        _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: ngo['phone'] as String, color: c),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.language_outlined, label: 'Website', value: ngo['website'] as String, color: c, onTap: () => _launch(ngo['website'] as String)),
        const SizedBox(height: 16),

        // Refer for student
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF512D38), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.person_outline, color: Color(0xFFE9C2D7), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Referring ${student.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
              Text('Class ${student.standard} · ${student.className}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch('tel:${ngo['phone']}'),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call Now', style: TextStyle(fontFamily: 'Pridi')),
              style: OutlinedButton.styleFrom(foregroundColor: c, side: BorderSide(color: c), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isReferred ? null : () { onRefer(); Navigator.pop(context); },
              icon: Icon(isReferred ? Icons.check : Icons.send_outlined, size: 16),
              label: Text(isReferred ? 'Referred ✓' : 'Log Referral', style: const TextStyle(fontFamily: 'Pridi')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isReferred ? c.withOpacity(0.25) : c,
                foregroundColor: isReferred ? c : Colors.black87,
                disabledBackgroundColor: c.withOpacity(0.25),
                disabledForegroundColor: c,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(child: Text(value, style: TextStyle(color: onTap != null ? color : Colors.white70, fontSize: 13, decoration: onTap != null ? TextDecoration.underline : null))),
      ]),
    );
  }
}