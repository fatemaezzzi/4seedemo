import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors extracted from the design
    final Color backgroundColor = const Color(0xFF38232A); // Darker Maroon Background
    final Color primaryPink = const Color(0xFFD6336C);     // The Hot Pink/Raspberry color
    final Color surfaceDark = const Color(0xFF4A2F3A);     // Slightly lighter for backgrounds
    final Color textWhite = Colors.white;
    final Color textMuted = Colors.white70;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Keeps it web-friendly
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================== TOP BAR ==================
                Row(
                  children: [
                    // Logo
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900),
                        children: [
                          const TextSpan(text: '4', style: TextStyle(color: Color(0xFFF5C3DE))),
                          TextSpan(text: 'see', style: TextStyle(color: textWhite)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // CHANGED TO ADMIN
                    Text(
                      "Admin",
                      style: GoogleFonts.poppins(color: textMuted, fontSize: 18),
                    ),

                    const Spacer(),

                    // Search Bar
                    Container(
                      width: 400,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        style: TextStyle(color: textWhite),
                        decoration: InputDecoration(
                          hintText: "Search here...",
                          hintStyle: TextStyle(color: textMuted),
                          prefixIcon: Icon(Icons.search, color: textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(top: 8),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Profile
                    Icon(Icons.notifications, color: textWhite),
                    const SizedBox(width: 20),
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 20,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "System Admin",
                      style: GoogleFonts.poppins(color: textWhite, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // ================== STATS ROW ==================
                Row(
                  children: [
                    _buildStatCard("124", "Total Students", Icons.school, primaryPink),
                    const SizedBox(width: 20),
                    _buildStatCard("5", "Active Classes", Icons.groups, primaryPink),
                    const SizedBox(width: 20),
                    _buildStatCard("3", "Pending Reports", Icons.description, primaryPink),
                  ],
                ),

                const SizedBox(height: 30),

                // ================== BOTTOM SECTION ==================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----- LEFT: QUICK ACTIONS -----
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 350,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: primaryPink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quick Actions",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildActionItem(Icons.grid_view_rounded, "Manage Classes"),
                            _buildActionItem(Icons.person, "Student Directory"),
                            _buildActionItem(Icons.assessment, "Generate Reports"),
                            _buildActionItem(Icons.announcement, "Global Announcements"),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 30),

                    // ----- RIGHT: RECENT ACTIVITY -----
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 350,
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryPink,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                "Recent Activity",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Activity List
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(25.0),
                                child: Column(
                                  children: [
                                    _buildTimelineItem(
                                      time: "Today, 10:30 AM",
                                      title: "Teacher 'Rupali' submitted grades",
                                      isFirst: true,
                                    ),
                                    _buildTimelineItem(
                                      time: "Yesterday, 2:15 PM",
                                      title: "System backup completed",
                                    ),
                                    _buildTimelineItem(
                                      time: "Yesterday, 9:00 AM",
                                      title: "Downloaded attendance report",
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildStatCard(String count, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Icon(icon, color: Colors.white70, size: 40),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 15),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String time, required String title, bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle)),
            if (!isLast) Container(width: 2, height: 50, color: Colors.white12),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}