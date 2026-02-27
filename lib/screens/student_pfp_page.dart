import 'package:flutter/material.dart';

class StudentPfpPage extends StatefulWidget {
  final String studentName;

  const StudentPfpPage({
    super.key,
    required this.studentName,
  });

  @override
  State<StudentPfpPage> createState() => _StudentPfpPageState();
}

class _StudentPfpPageState extends State<StudentPfpPage> {
  String selectedReport = 'Semester';

  // ── Colours ─────────────────────────────────────────────
  static const _bg = Color(0xFF4A1E2E);
  static const _cardBg = Color(0xFF5C2A3A);
  static const _teal = Color(0xFF6BBFAA);
  static const _pink = Color(0xFFCE8FAA);
  static const _chipBorder = Color(0xFF7A3F55);
  static const _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Student Profile',
          style: TextStyle(
            color: _teal,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: _teal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Profile Header ─────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '#01245',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _chipBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Std 5th  |  91+ 9375459378',
                          style: TextStyle(color: _white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 36,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Reports ────────────────────────────────────
            const Text(
              'Reports',
              style: TextStyle(
                color: _white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: ['Semester', 'Weekly', 'Monthly'].map((label) {
                final isSelected = selectedReport == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedReport = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _pink : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? _pink : _chipBorder,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Behaviour Incident',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── HIGH RISK Card ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIGH RISK; ATTENTION NEEDED',
                    style: TextStyle(
                      color: Color(0xFF1A3A30),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  _RiskItem(text: 'Attendance < 60%'),
                  _RiskItem(text: 'Math Scores Declined by 15%'),
                  _RiskItem(text: 'Behaviour - Low Focus'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── AI Suggestions ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _chipBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Suggestions',
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _SuggestionItem(text: 'Assign Peer Mentor'),
                  const _SuggestionItem(text: 'Recommend Remedial Classes'),
                  const _SuggestionItem(text: 'Parent Meeting'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Support & Resources ───────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _chipBorder),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _ResourceChip(
                      icon: Icons.handshake_outlined,
                      label: 'NGO',
                      iconColor: _pink),
                  _ResourceChip(
                      icon: Icons.chat_bubble_outline,
                      label: 'Counseling',
                      iconColor: Colors.amber),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RiskItem extends StatelessWidget {
  final String text;
  const _RiskItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A3A30),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final String text;
  const _SuggestionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A1E2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7A3F55)),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}