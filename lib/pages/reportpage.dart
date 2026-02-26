import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // activeIndex 0: Mental Health, 1: Academics, 2: Attendance
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38), // Your plum background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // --- HEADER ---
              const Text(
                  'Dhruv Rathee',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
              ),
              const Text(
                  '#01245',
                  style: TextStyle(color: Colors.white70, fontSize: 16)
              ),
              const SizedBox(height: 20),

              // --- TABS SECTION ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                        onTap: () => setState(() => activeIndex = 0),
                        child: _buildReportTab('Mental Health', activeIndex == 0)
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                        onTap: () => setState(() => activeIndex = 1),
                        child: _buildReportTab('Academics', activeIndex == 1)
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                        onTap: () => setState(() => activeIndex = 2),
                        child: _buildReportTab('Attendance', activeIndex == 2)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // --- DYNAMIC CONTENT ---
              if (activeIndex == 0) buildMentalHealthView(),
              if (activeIndex == 1) buildAcademicsView(),
              if (activeIndex == 2) buildAttendanceView(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. MENTAL HEALTH VIEW ---
  Widget buildMentalHealthView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFFE9C2D7), // Light pink card
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Mental Health\nscore',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F))
              ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 180, width: 180,
                      child: CircularProgressIndicator(
                        value: 0.84,
                        strokeWidth: 25,
                        // Fix for opacity warning
                        backgroundColor: Colors.red.withValues(alpha: 0.6),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const Text(
                        "84%",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F))
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInsightsCard(),
      ],
    );
  }

  // --- 2. ACADEMICS VIEW ---
  Widget buildAcademicsView() {
    final Map<String, double> scores = {'Mat': 0.8, 'SS': 0.5, 'IP': 0.9, 'LAN': 0.3, 'CS': 0.7};

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Courses', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Image.asset('assets/imagesfor4see/Arrow right.png', height: 20),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: scores.entries.map((e) => _buildVerticalBar(e.key, e.value)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInsightsCard(),
      ],
    );
  }

  // --- 3. ATTENDANCE VIEW ---
  Widget buildAttendanceView() {
    final Map<String, double> attendance = {
      'Jan': 0.7, 'Feb': 0.5, 'Mar': 0.85, 'Apr': 0.2, 'May': 0.65
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFE9C2D7), borderRadius: BorderRadius.circular(25)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Month', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Image.asset('assets/imagesfor4see/Arrow right.png', height: 20),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: attendance.entries.map((e) => _buildVerticalBar(e.key, e.value)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInsightsCard(),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildReportTab(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFA8D0BC) : const Color(0xFFA6768B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildInsightsCard() {
    final List<String> insights = [
      'factors or stuff', 'related to the mental health', 'notes',
      'other suggestions', 'llm result', 'quiz taken', 'other factors'
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C2D7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Insights',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B2F2F))
          ),
          const SizedBox(height: 10),
          ...insights.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVerticalBar(String label, double value) {
    return Column(
      children: [
        Container(
          height: 150, width: 22,
          decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            heightFactor: value,
            alignment: Alignment.bottomCenter,
            child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF3B2F2F),
                    borderRadius: BorderRadius.circular(10)
                )
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}