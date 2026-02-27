import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'report_page.dart';
import 'quiz_start_page.dart'; // ✅ NEW IMPORT

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color darkBackground = const Color(0xFF4E2A34);
    final Color cardBlue = const Color(0xFFA8C8D9);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Row(
        children: [
          /// ================= SIDEBAR =================
          Container(
            width: 250,
            color: darkBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "4see",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// My Profile
                const ListTile(
                  leading: Icon(Icons.person, color: Colors.white),
                  title: Text(
                    "My Profile",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                /// REPORT SECTION
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.white),
                  title: const Text(
                    "Report",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportPage(),
                      ),
                    );
                  },
                ),

                /// ✅ NEW SECTION — MY MIND & MOOD
                ListTile(
                  leading: const Icon(Icons.psychology, color: Colors.white),
                  title: const Text(
                    "My Mind & Mood",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizStartPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          /// ================= MAIN CONTENT =================
          Expanded(
            child: Container(
              color: const Color(0xFF5D3540),
              padding: const EdgeInsets.all(40),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBlue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    /// Profile Image Section
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white24,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Rohan Sharma",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Class X A",
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        ],
                      ),
                    ),

                    /// Details Section
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Attendance: 76%",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.black54),

                            _buildRow("Name", "Rohan Sharma"),
                            _buildRow("DOB", "12 Aug 2008"),
                            _buildRow("Roll No", "24"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 16)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
