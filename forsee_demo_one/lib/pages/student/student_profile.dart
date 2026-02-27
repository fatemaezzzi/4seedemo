import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import 'package:forsee_demo_one/pages/teacher/behaviour_incident_page.dart';

class StudentProfilePage extends StatefulWidget {
  // ✅ Receives a real StudentModel — name, ID, class, etc. all come from here
  final StudentModel student;

  const StudentProfilePage({super.key, required this.student});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final List<BehaviourIncident> _incidents = [];

  // Shorthand getters so the rest of the code stays clean
  StudentModel get _s => widget.student;

  // ── RISK LEVEL ─────────────────────────────────────────────────────────────

  Color get _riskBorderColor {
    switch (_s.riskLevel) {
      case RiskLevel.high:   return Colors.red;
      case RiskLevel.medium: return Colors.orange;
      case RiskLevel.low:    return Colors.yellow;
      case RiskLevel.none:   return Colors.green;
    }
  }

  bool get _isHighRisk =>
      _s.riskLevel == RiskLevel.high ||
          _incidents.where((i) => i.behaviourType == 'Negative').length >= 2;

  // ── NAVIGATION ─────────────────────────────────────────────────────────────

  Map<String, dynamic> get _studentArgs => {
    'name':      _s.name,
    'studentId': _s.studentId,
    'standard':  _s.standard,
    'phone':     _s.phone,
    'className': _s.className,
    'subject':   _s.subject,
    'riskLevel': _s.riskLevel,
  };

  void _openReport(String type) {
    Get.toNamed(
      AppRoutes.STUDENT_REPORT,
      arguments: {
        ..._studentArgs,
        'reportType': type,
        'incidents':  _incidents,
      },
    );
  }

  void _openBehaviourIncidentPage() async {
    final result = await Get.toNamed(
      AppRoutes.BEHAVIOUR_INCIDENT,
      arguments: _studentArgs,
    );
    if (result is BehaviourIncident) {
      setState(() => _incidents.add(result));
    }
  }

  // ── RESOURCE DIALOG ────────────────────────────────────────────────────────

  void _showResource(String type) {
    final Map<String, Map<String, dynamic>> info = {
      'NGO':              {'title': 'NGO Support',              'icon': Icons.handshake_outlined,               'color': Colors.tealAccent,   'details': ['Pratham Education Foundation', 'CRY – Child Rights and You', 'Teach For India'],                               'action': 'Contact NGO'},
      'Financial Support':{'title': 'Financial Support',        'icon': Icons.account_balance_wallet_outlined,  'color': Colors.amberAccent,  'details': ['PM Scholarship Scheme', 'National Means-cum-Merit Scholarship', 'State Government Scholarship'],             'action': 'Apply for Support'},
      'Counseling':       {'title': 'Counseling Services',      'icon': Icons.chat_bubble_outline,              'color': Colors.orangeAccent, 'details': ['School Counselor – Ms. Priya', 'iCall Helpline: 9152987821', 'Vandrevala Foundation: 1860-2662-345'],         'action': 'Book Session'},
      'Mental Health':    {'title': 'Mental Health Resources',  'icon': Icons.favorite_border,                  'color': Colors.pinkAccent,   'details': ['iCall: 9152987821', 'Vandrevala Foundation: 1860-2662-345', 'NIMHANS Helpline: 080-46110007'],               'action': 'Get Help'},
    };
    final r = info[type]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF3B2028), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(backgroundColor: (r['color'] as Color).withOpacity(0.15), child: Icon(r['icon'] as IconData, color: r['color'] as Color)),
              const SizedBox(width: 12),
              Text(r['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            ]),
            const SizedBox(height: 16),
            ...(r['details'] as List<String>).map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [Icon(Icons.arrow_forward_ios, size: 12, color: r['color'] as Color), const SizedBox(width: 8), Text(d, style: const TextStyle(color: Colors.white70, fontSize: 14))]),
            )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE9C2D7), foregroundColor: const Color(0xFF512D38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text(r['action'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI SUGGESTIONS ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _aiSuggestions {
    final s = <Map<String, dynamic>>[
      {'icon': Icons.people_alt_outlined,  'text': 'Assign Peer Mentor'},
      {'icon': Icons.school_outlined,      'text': 'Recommend Remedial Classes'},
      {'icon': Icons.family_restroom,      'text': 'Schedule Parent Meeting'},
    ];
    final negCount = _incidents.where((i) => i.behaviourType == 'Negative').length;
    final tags = _incidents.expand((i) => i.tags).toList();
    if (negCount >= 2)                      s.add({'icon': Icons.warning_amber_rounded,      'text': '$negCount negative incidents logged — counselling recommended',    'highlight': true});
    if (tags.contains('Aggressive'))        s.add({'icon': Icons.psychology_outlined,         'text': 'Aggression noted — refer to school counselor',                     'highlight': true});
    if (tags.contains('No Homework'))       s.add({'icon': Icons.assignment_late_outlined,    'text': 'Repeated homework issues — check home environment'});
    if (tags.contains('Distracted'))        s.add({'icon': Icons.visibility_off_outlined,     'text': 'Focus issues observed — consider seating change'});
    if (_incidents.any((i) => i.behaviourType == 'Positive')) s.add({'icon': Icons.star_outline, 'text': 'Positive behaviour noted — acknowledge in class', 'positive': true});
    return s;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── HEADER ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(children: [
                            Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 16),
                            SizedBox(width: 4),
                            Text('Back', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        // ✅ Name from StudentModel
                        Text(_s.name, style: const TextStyle(color: Color(0xFFF4BFDB), fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                        Text(_s.studentId, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFA8D0BC), borderRadius: BorderRadius.circular(20)),
                          // ✅ Standard and phone from StudentModel
                          child: Text(_s.infoPill, style: const TextStyle(color: Color(0xFF3B2F2F), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Border colour driven by RiskLevel
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _riskBorderColor, width: 3)),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.black,
                      child: Text(_s.initial, style: const TextStyle(color: Colors.white54, fontSize: 36, fontFamily: 'Pridi')),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ── REPORTS ─────────────────────────────────────────────────
              const Text('Reports', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildTab('Semester'), _buildTab('Weekly'), _buildTab('Monthly')],
              ),

              const SizedBox(height: 20),

              // ── BEHAVIOUR INCIDENT BUTTON ────────────────────────────────
              GestureDetector(
                onTap: _openBehaviourIncidentPage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: const Color(0xFFA6768B), borderRadius: BorderRadius.circular(15)),
                  child: Center(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Behaviour Incident', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                      if (_incidents.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                          child: Text('${_incidents.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),

              if (_incidents.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Recent Incidents', style: TextStyle(color: Color(0xFFE9C2D7), fontWeight: FontWeight.bold, fontFamily: 'Pridi', fontSize: 13)),
                    const SizedBox(height: 6),
                    ..._incidents.reversed.take(3).map((inc) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(inc.behaviourType == 'Positive' ? Icons.check_circle : Icons.cancel, size: 14, color: inc.behaviourType == 'Positive' ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(width: 6),
                        Expanded(child: Text(inc.summary, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 25),

              // ── RISK BANNER ──────────────────────────────────────────────
              if (_isHighRisk)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(color: Color(0xFFA8D0BC), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.warning_rounded, color: Color(0xFF3B2F2F), size: 18), SizedBox(width: 6), Text('HIGH RISK; ATTENTION NEEDED', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF3B2F2F)))]),
                    const SizedBox(height: 6),
                    const Text('• Attendance < 60%', style: TextStyle(color: Color(0xFF3B2F2F))),
                    const Text('• Math Scores Declined by 15%', style: TextStyle(color: Color(0xFF3B2F2F))),
                    const Text('• Behaviour - Low Focus', style: TextStyle(color: Color(0xFF3B2F2F))),
                    if (_incidents.any((i) => i.tags.contains('Aggressive')))
                      const Text('• Aggression incident logged', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    if (_incidents.where((i) => i.behaviourType == 'Negative').length >= 2)
                      Text('• ${_incidents.where((i) => i.behaviourType == 'Negative').length} negative behaviour incidents', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ]),
                ),

              const SizedBox(height: 25),

              // ── AI SUGGESTIONS ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFA6768B), width: 2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('AI Suggestions', style: TextStyle(color: Color(0xFFF4BFDB), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    Row(children: List.generate(5, (i) => Icon(Icons.star, color: i < 4 ? Colors.orange : Colors.white30, size: 20))),
                  ]),
                  const SizedBox(height: 12),
                  ..._aiSuggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(s['icon'] as IconData, color: s['highlight'] == true ? Colors.orangeAccent : s['positive'] == true ? Colors.greenAccent : const Color(0xFFF4BFDB), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s['text'] as String, style: TextStyle(color: s['highlight'] == true ? Colors.orangeAccent : s['positive'] == true ? Colors.greenAccent : Colors.white, fontSize: 14))),
                    ]),
                  )),
                ]),
              ),

              const SizedBox(height: 25),

              // ── SUPPORT & RESOURCES ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFA6768B), borderRadius: BorderRadius.circular(25)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Support & Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Pridi')),
                  const SizedBox(height: 15),
                  Row(children: [_buildResourceCard('NGO', Icons.handshake_outlined), const SizedBox(width: 10), _buildResourceCard('Financial Support', Icons.account_balance_wallet_outlined)]),
                  const SizedBox(height: 10),
                  Row(children: [_buildResourceCard('Counseling', Icons.chat_bubble_outline), const SizedBox(width: 10), _buildResourceCard('Mental Health', Icons.favorite_border)]),
                ]),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    return GestureDetector(
      onTap: () => _openReport(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFA6768B), borderRadius: BorderRadius.circular(15)),
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
      ),
    );
  }

  Widget _buildResourceCard(String title, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showResource(title),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4BFDB), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 22, color: const Color(0xFF3B2F2F)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B2F2F), fontFamily: 'Pridi'))),
          ]),
        ),
      ),
    );
  }
}