// lib/pages/support/financial_support_page.dart
// =========================================================
// Full Financial Support page – opened from StudentProfilePage
// Displays scholarships, schemes, eligibility & apply flow
// =========================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/model/student_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FinancialSupportPage extends StatefulWidget {
  final StudentModel student;
  const FinancialSupportPage({super.key, required this.student});

  @override
  State<FinancialSupportPage> createState() => _FinancialSupportPageState();
}

class _FinancialSupportPageState extends State<FinancialSupportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  String _selectedCategory = 'All';
  final List<String> _appliedSchemes = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  static const List<Map<String, dynamic>> _schemes = [
    {
      'name': 'National Means-cum-Merit Scholarship',
      'short': 'NMMSS',
      'amount': '₹12,000/year',
      'category': 'Central Government',
      'eligibility': 'Class 7–8, family income < ₹1.5 lakh/year, 55%+ marks',
      'deadline': 'November 30',
      'website': 'https://scholarships.gov.in',
      'icon': Icons.workspace_premium_outlined,
      'color': Color(0xFFFFD54F),
      'tags': ['Central', 'Merit', 'Need-Based'],
    },
    {
      'name': 'Pre-Matric Scholarship (SC/ST)',
      'short': 'PM-SC/ST',
      'amount': '₹3,500–₹7,000/year',
      'category': 'Central Government',
      'eligibility': 'SC/ST students in Class 9–10, family income < ₹2 lakh/year',
      'deadline': 'October 31',
      'website': 'https://scholarships.gov.in',
      'icon': Icons.account_balance_outlined,
      'color': Color(0xFF80CBC4),
      'tags': ['Central', 'SC/ST', 'Pre-Matric'],
    },
    {
      'name': 'PM Scholarship Scheme',
      'short': 'PMSS',
      'amount': '₹25,000–₹36,000/year',
      'category': 'Central Government',
      'eligibility': 'Ex-servicemen / paramilitary wards, merit-based',
      'deadline': 'December 15',
      'website': 'https://desw.gov.in',
      'icon': Icons.military_tech_outlined,
      'color': Color(0xFF90CAF9),
      'tags': ['Central', 'Defence', 'Merit'],
    },
    {
      'name': 'Maharashtra Scholarship (State)',
      'short': 'MH-State',
      'amount': '₹5,000–₹10,000/year',
      'category': 'State Government',
      'eligibility': 'Maharashtra domicile, family income < ₹6 lakh/year',
      'deadline': 'February 28',
      'website': 'https://mahadbt.maharashtra.gov.in',
      'icon': Icons.location_city_outlined,
      'color': Color(0xFFF48FB1),
      'tags': ['State', 'Maharashtra', 'Need-Based'],
    },
    {
      'name': 'Inspire Scholarship – DST',
      'short': 'INSPIRE',
      'amount': '₹80,000/year',
      'category': 'Central Government',
      'eligibility': 'Top 1% in Class 10/12 board exams, science stream',
      'deadline': 'August 31',
      'website': 'https://online-inspire.gov.in',
      'icon': Icons.science_outlined,
      'color': Color(0xFFCE93D8),
      'tags': ['Central', 'Science', 'Top Merit'],
    },
    {
      'name': 'NSP Minority Scholarship',
      'short': 'NSP-Min',
      'amount': '₹10,000–₹20,000/year',
      'category': 'Central Government',
      'eligibility': 'Minority community students, 50%+ marks in last exam',
      'deadline': 'October 31',
      'website': 'https://scholarships.gov.in',
      'icon': Icons.diversity_1_outlined,
      'color': Color(0xFFA5D6A7),
      'tags': ['Central', 'Minority', 'Need-Based'],
    },
  ];

  List<Map<String, dynamic>> get _filtered =>
      _selectedCategory == 'All' ? _schemes : _schemes.where((s) => s['category'] == _selectedCategory).toList();

  void _logApplication(String schemeName) {
    if (_appliedSchemes.contains(schemeName)) return;
    setState(() => _appliedSchemes.add(schemeName));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF3B2028),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xFFFFD54F), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('Application for $schemeName logged for ${widget.student.name}',
            style: const TextStyle(color: Colors.white, fontSize: 13))),
      ]),
    ));
  }

  void _showSchemeDetail(Map<String, dynamic> scheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SchemeDetailSheet(
        scheme: scheme,
        student: widget.student,
        isApplied: _appliedSchemes.contains(scheme['name']),
        onApply: () => _logApplication(scheme['name'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Central Government', 'State Government'];
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ────────────────────────────────────────────────
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
                Text('Financial Support', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                Text('Scholarships & government schemes', style: TextStyle(color: Color(0xFFE9C2D7), fontSize: 12, fontFamily: 'Pridi')),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Summary Strip ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _SummaryTile(label: 'Schemes Available', value: '${_schemes.length}', color: const Color(0xFFFFD54F)),
              const SizedBox(width: 10),
              _SummaryTile(label: 'Applications Logged', value: '${_appliedSchemes.length}', color: const Color(0xFF80CBC4)),
              const SizedBox(width: 10),
              _SummaryTile(label: 'Max Award', value: '₹80K/yr', color: const Color(0xFFCE93D8)),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Category filter ───────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFD54F) : const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat, style: TextStyle(color: selected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi')),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Scheme Cards ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final scheme = _filtered[i];
                return AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) {
                    final t = ((_anim.value - i * 0.08) / (1 - i * 0.08)).clamp(0.0, 1.0);
                    return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child));
                  },
                  child: _SchemeCard(
                    scheme: scheme,
                    isApplied: _appliedSchemes.contains(scheme['name']),
                    onTap: () => _showSchemeDetail(scheme),
                    onApply: () => _logApplication(scheme['name'] as String),
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

// ── Summary Tile ─────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF3B2028), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Pridi'), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Scheme Card ──────────────────────────────────────────────────────────────

class _SchemeCard extends StatelessWidget {
  final Map<String, dynamic> scheme;
  final bool isApplied;
  final VoidCallback onTap, onApply;
  const _SchemeCard({required this.scheme, required this.isApplied, required this.onTap, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final c = scheme['color'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B2028),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isApplied ? c.withOpacity(0.6) : Colors.transparent, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(scheme['icon'] as IconData, color: c, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(scheme['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Pridi'))),
                if (isApplied) Icon(Icons.check_circle, color: c, size: 16),
              ]),
              Text(scheme['category'] as String, style: TextStyle(color: c, fontSize: 11, fontFamily: 'Pridi')),
            ])),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.currency_rupee, color: c, size: 12),
                Text(scheme['amount'] as String, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi')),
              ]),
            ),
            const SizedBox(width: 10),
            Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 12),
            const SizedBox(width: 4),
            Text('Deadline: ${scheme['deadline']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Text(scheme['eligibility'] as String, style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Pridi'), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isApplied ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: isApplied ? c.withOpacity(0.2) : c,
                foregroundColor: isApplied ? c : Colors.black87,
                disabledBackgroundColor: c.withOpacity(0.2),
                disabledForegroundColor: c,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(isApplied ? '✓ Application Logged' : 'Log Application', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Pridi')),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Scheme Detail Sheet ───────────────────────────────────────────────────────

class _SchemeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> scheme;
  final StudentModel student;
  final bool isApplied;
  final VoidCallback onApply;
  const _SchemeDetailSheet({required this.scheme, required this.student, required this.isApplied, required this.onApply});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = scheme['color'] as Color;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFF3B2028), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(scheme['icon'] as IconData, color: c, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(scheme['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            Text(scheme['amount'] as String, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
          ])),
        ]),
        const SizedBox(height: 16),
        _DetailRow(label: 'Eligibility', value: scheme['eligibility'] as String),
        const SizedBox(height: 8),
        _DetailRow(label: 'Deadline', value: scheme['deadline'] as String),
        const SizedBox(height: 8),
        _DetailRow(label: 'Category', value: scheme['category'] as String),
        const SizedBox(height: 16),
        // Student applying for
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF512D38), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.person_outline, color: Color(0xFFE9C2D7), size: 16),
            const SizedBox(width: 8),
            Text('Applying for: ${student.name}', style: const TextStyle(color: Color(0xFFE9C2D7), fontSize: 13, fontFamily: 'Pridi')),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch(scheme['website'] as String),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Official Portal', style: TextStyle(fontFamily: 'Pridi')),
              style: OutlinedButton.styleFrom(foregroundColor: c, side: BorderSide(color: c), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: isApplied ? null : () { onApply(); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApplied ? c.withOpacity(0.25) : c,
                foregroundColor: isApplied ? c : Colors.black87,
                disabledBackgroundColor: c.withOpacity(0.25),
                disabledForegroundColor: c,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(isApplied ? '✓ Applied' : 'Log Application', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 90, child: Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 12))),
    Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
  ]);
}