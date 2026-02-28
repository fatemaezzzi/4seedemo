// lib/pages/support/mental_health_page.dart
// =========================================================
// Full Mental Health Resources page – opened from StudentProfilePage
// Awareness content, red-flag checklist, resources, ADHD/LD info
// =========================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MentalHealthPage extends StatefulWidget {
  final StudentModel student;
  const MentalHealthPage({super.key, required this.student});

  @override
  State<MentalHealthPage> createState() => _MentalHealthPageState();
}

class _MentalHealthPageState extends State<MentalHealthPage>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  late TabController _tabCtrl;
  final Set<int> _checkedFlags = {};
  bool _reportGenerated = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _anim.dispose(); _tabCtrl.dispose(); super.dispose(); }

  // ── Red flag checklist ─────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _redFlags = [
    {'text': 'Sudden withdrawal from friends / class activities', 'severity': 'medium', 'icon': Icons.people_outlined},
    {'text': 'Persistent sadness or tearfulness in school', 'severity': 'high', 'icon': Icons.sentiment_very_dissatisfied_outlined},
    {'text': 'Extreme difficulty concentrating on tasks', 'severity': 'medium', 'icon': Icons.psychology_outlined},
    {'text': 'Frequent unexplained physical complaints (headaches, stomachaches)', 'severity': 'medium', 'icon': Icons.sick_outlined},
    {'text': 'Marked decline in academic performance', 'severity': 'high', 'icon': Icons.trending_down_outlined},
    {'text': 'Mentions of hopelessness, worthlessness, or self-harm', 'severity': 'critical', 'icon': Icons.warning_rounded},
    {'text': 'Extreme mood swings or outbursts', 'severity': 'high', 'icon': Icons.bolt_outlined},
    {'text': 'Irregular sleep patterns reported by parent/guardian', 'severity': 'medium', 'icon': Icons.bedtime_outlined},
    {'text': 'Refusing to come to school / increased absenteeism', 'severity': 'high', 'icon': Icons.school_outlined},
    {'text': 'Avoidance of eating or overeating', 'severity': 'medium', 'icon': Icons.no_meals_outlined},
  ];

  // ── Learning differences info ──────────────────────────────────────────────
  static const List<Map<String, dynamic>> _conditions = [
    {
      'name': 'ADHD',
      'full': 'Attention-Deficit/Hyperactivity Disorder',
      'signs': ['Difficulty staying focused', 'Impulsive behaviour', 'Excessive movement', 'Forgets daily tasks', 'Loses things often'],
      'strategies': ['Break tasks into small chunks', 'Use visual schedules', 'Frequent movement breaks', 'Positive reinforcement', 'Seat near teacher'],
      'color': Color(0xFF4FC3F7),
      'icon': Icons.flash_on_outlined,
    },
    {
      'name': 'Dyslexia',
      'full': 'Reading & Language Processing Difficulty',
      'signs': ['Reading slowly or inaccurately', 'Difficulty spelling', 'Confuses similar letters (b/d, p/q)', 'Avoids reading aloud', 'Struggles with phonics'],
      'strategies': ['Use larger fonts, extra spacing', 'Allow audio versions of texts', 'Extra time for reading tasks', 'Coloured overlays', 'Praise effort not accuracy'],
      'color': Color(0xFFFF8A65),
      'icon': Icons.menu_book_outlined,
    },
    {
      'name': 'Learning Disability (LD)',
      'full': 'Specific Learning Disability',
      'signs': ['Gap between intelligence and achievement', 'Struggles with math or writing', 'Slow processing speed', 'Poor working memory', 'Difficulty organising work'],
      'strategies': ['Multi-sensory teaching', 'Graphic organisers', 'Reduce written output demands', 'Peer buddy system', 'Refer to remedial educator'],
      'color': Color(0xFFA5D6A7),
      'icon': Icons.lightbulb_outline,
    },
    {
      'name': 'Anxiety',
      'full': 'School / Social Anxiety Disorder',
      'signs': ['Excessive worry before tests or presentations', 'Avoidance of group activities', 'Physical complaints before school', 'Seeking reassurance frequently', 'Perfectionism / fear of failure'],
      'strategies': ['Predictable classroom routine', 'Pre-warn about changes', 'Allow opt-out from public speaking', 'Breathing exercises', 'Refer to counselor for CBT'],
      'color': Color(0xFFCE93D8),
      'icon': Icons.self_improvement_outlined,
    },
  ];

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return Colors.redAccent;
      case 'high': return Colors.orangeAccent;
      default: return const Color(0xFFFFD54F);
    }
  }

  void _generateReport() {
    if (_checkedFlags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF3B2028),
        behavior: SnackBarBehavior.floating,
        content: const Text('Please check at least one observation', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _reportGenerated = true);
    final hasCritical = _checkedFlags.any((i) => _redFlags[i]['severity'] == 'critical');
    final highCount = _checkedFlags.where((i) => _redFlags[i]['severity'] == 'high').length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(hasCritical ? Icons.warning_rounded : Icons.check_circle_outline,
              color: hasCritical ? Colors.redAccent : const Color(0xFFFABFDB), size: 22),
          const SizedBox(width: 8),
          const Text('Observation Report', style: TextStyle(color: Colors.white, fontFamily: 'Pridi', fontSize: 17)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Student: ${widget.student.name}', style: const TextStyle(color: Color(0xFFE9C2D7), fontFamily: 'Pridi', fontSize: 13)),
          const SizedBox(height: 8),
          Text('${_checkedFlags.length} flags observed (${highCount} high, ${hasCritical ? '1 critical' : 'none critical'})',
              style: TextStyle(color: hasCritical ? Colors.redAccent : Colors.orangeAccent, fontFamily: 'Pridi', fontSize: 12)),
          const SizedBox(height: 12),
          if (hasCritical) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Text('⚠ Critical flag detected. Please contact the school counselor and parent/guardian immediately.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
            const SizedBox(height: 8),
          ],
          const Text('Recommended next steps:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('• Log in Behaviour Incidents section', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const Text('• Schedule counselor referral', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const Text('• Notify parent/guardian via SMS', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss', style: TextStyle(color: Colors.white54, fontFamily: 'Pridi'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9C2D7), foregroundColor: const Color(0xFF512D38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Done', style: TextStyle(fontFamily: 'Pridi', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mental Health', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                Text('Awareness tools for ${widget.student.name.split(' ').first}', style: const TextStyle(color: Color(0xFFE9C2D7), fontSize: 12, fontFamily: 'Pridi')),
              ])),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Tab Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF512D38),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi'),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Red Flags'),
                  Tab(text: 'Conditions'),
                  Tab(text: 'Resources'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Tab Views ─────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRedFlagsTab(),
                _buildConditionsTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Tab 1: Red Flags Checklist ─────────────────────────────────────────────

  Widget _buildRedFlagsTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline, color: Color(0xFFE9C2D7), size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Check all behaviours you have observed in this student. Generate a report to log findings.', style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Pridi'))),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _redFlags.length,
          itemBuilder: (_, i) {
            final flag = _redFlags[i];
            final checked = _checkedFlags.contains(i);
            final sc = _severityColor(flag['severity'] as String);
            return GestureDetector(
              onTap: () => setState(() => checked ? _checkedFlags.remove(i) : _checkedFlags.add(i)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: checked ? sc.withOpacity(0.1) : const Color(0xFF3B2028),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: checked ? sc : Colors.transparent, width: 1.5),
                ),
                child: Row(children: [
                  Icon(flag['icon'] as IconData, color: sc, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(flag['text'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Pridi'))),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: checked ? sc : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: checked ? sc : Colors.white30)),
                    child: checked ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                  ),
                ]),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(children: [
          Text('${_checkedFlags.length} selected', style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Pridi')),
          const Spacer(),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.summarize_outlined, size: 16),
              label: const Text('Generate Report', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9C2D7), foregroundColor: const Color(0xFF512D38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Tab 2: Conditions (ADHD, Dyslexia etc.) ───────────────────────────────

  Widget _buildConditionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _conditions.length,
      itemBuilder: (_, i) {
        final cond = _conditions[i];
        final c = cond['color'] as Color;
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final t = ((_anim.value - i * 0.1) / 0.7).clamp(0.0, 1.0);
            return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(16)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(cond['icon'] as IconData, color: c, size: 20)),
                title: Text(cond['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pridi', fontSize: 15)),
                subtitle: Text(cond['full'] as String, style: TextStyle(color: c, fontSize: 10, fontFamily: 'Pridi')),
                iconColor: c,
                collapsedIconColor: Colors.white38,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      _ConditionSection(label: 'Signs to watch for', items: (cond['signs'] as List).cast<String>(), color: c),
                      const SizedBox(height: 12),
                      _ConditionSection(label: 'Teacher strategies', items: (cond['strategies'] as List).cast<String>(), color: Colors.greenAccent, isStrategy: true),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Resources ──────────────────────────────────────────────────────

  Widget _buildResourcesTab() {
    final resources = [
      {'title': 'Snehi (suicide prevention)', 'phone': '044-24640050', 'desc': 'Emotional support helpline, Mon–Sat 8AM–10PM', 'color': const Color(0xFFFF8A65)},
      {'title': 'Parivarthan Counselling', 'phone': '07676602602', 'desc': 'Counselling helpline, Mon–Fri 4–10PM', 'color': const Color(0xFF80CBC4)},
      {'title': 'NIMHANS Bangalore', 'phone': '08046110007', 'desc': 'National mental health helpline', 'color': const Color(0xFF90CAF9)},
      {'title': 'iCall – TISS Mumbai', 'phone': '9152987821', 'desc': 'Mon–Sat 8AM–10PM · English, Hindi, Marathi', 'color': const Color(0xFFCE93D8)},
      {'title': 'Vandrevala Foundation', 'phone': '18602662345', 'desc': '24/7 · 11 Indian languages', 'color': const Color(0xFFA5D6A7)},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text('In case of crisis / self-harm risk', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
            ]),
            const SizedBox(height: 6),
            const Text('Contact school counselor immediately and notify parents. Call iCall or Vandrevala below for professional support.', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
        const Text('Helplines & Support Centres', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Pridi')),
        const SizedBox(height: 10),
        ...resources.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (r['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.phone_in_talk_outlined, color: r['color'] as Color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi')),
              Text(r['desc'] as String, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text(r['phone'] as String, style: TextStyle(color: r['color'] as Color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            ])),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('tel:${r['phone']}');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (r['color'] as Color).withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.call, color: r['color'] as Color, size: 18),
              ),
            ),
          ]),
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Condition Signs / Strategies Section ─────────────────────────────────────

class _ConditionSection extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  final bool isStrategy;
  const _ConditionSection({required this.label, required this.items, required this.color, this.isStrategy = false});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi')),
    const SizedBox(height: 6),
    ...items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isStrategy ? Icons.check_circle_outline : Icons.arrow_right, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(item, style: const TextStyle(color: Colors.white60, fontSize: 11))),
      ]),
    )),
  ]);
}