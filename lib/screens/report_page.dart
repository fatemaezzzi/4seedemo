import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int selectedIndex = 0;

  final Color backgroundColor = const Color(0xFF4E2A34);
  final Color cardColor = const Color(0xFFD6A8BD);
  final Color activeTabColor = const Color(0xFF9EC3B0);
  final Color inactiveTabColor = const Color(0xFFB57A93);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              /// Name
              const Text(
                "Dhruv Rathee",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Text(
                "#01245",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 25),

              /// NAV BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTab("Mental Health", 0),
                  _buildTab("Academics", 1),
                  _buildTab("Attendance", 2),
                ],
              ),

              const SizedBox(height: 30),

              /// Dynamic Page Content
              Expanded(
                child: selectedIndex == 0
                    ? _mentalHealthPage()
                    : selectedIndex == 1
                        ? _academicsPage()
                        : _attendancePage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= TAB BUTTON =================
  Widget _buildTab(String title, int index) {
    bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeTabColor : inactiveTabColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ================= MENTAL HEALTH PAGE =================
  Widget _mentalHealthPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Mental Health Score",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Center(
                  child: CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 18,
                    percent: 0.84,
                    animation: true,
                    progressColor: Colors.green,
                    backgroundColor: Colors.redAccent,
                    circularStrokeCap: CircularStrokeCap.round,
                    center: const Text(
                      "84%",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _insightsCard(),
        ],
      ),
    );
  }

  /// ================= ACADEMICS PAGE =================
  Widget _academicsPage() {
    List<String> subjects = ["Mat", "SS", "IP", "LAN", "CS"];

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Courses",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: subjects
                      .map((subject) => Column(
                            children: [
                              Container(
                                width: 20,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.brown[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(subject),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _insightsCard(),
        ],
      ),
    );
  }

  /// ================= ATTENDANCE PAGE =================
  Widget _attendancePage() {
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May"];

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Month",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months
                      .map((month) => Column(
                            children: [
                              Container(
                                width: 20,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.brown[400],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(month),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _insightsCard(),
        ],
      ),
    );
  }

  /// ================= INSIGHTS CARD =================
  Widget _insightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Insights",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text("• factors or stuff"),
          Text("• related to the mental health"),
          Text("• notes"),
          Text("• other suggestions"),
          Text("• IIM result"),
          Text("• quiz taken"),
          Text("• other factors"),
        ],
      ),
    );
  }
}