import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'classroom_page.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color(0xFF4E2A34); // Dark Maroon
    final Color cardColor = const Color(
      0xFFA66A85,
    ); // Muted Pink/Purple for cards
    final Color tealColor = const Color(0xFF8ACDB8); // Teal for buttons
    final Color logoPink = const Color(0xFFF5C3DE); // Logo Pink

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Center(
          // Constrain width for large web screens so it doesn't stretch too much
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= TOP NAVIGATION =================
                Row(
                  children: [
                    // Logo
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(
                            text: '4',
                            style: TextStyle(color: logoPink),
                          ),
                          const TextSpan(
                            text: 'see',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 60),

                    // Nav Links
                    _buildNavLink("Dashboard", isActive: true),
                    _buildNavLink("Classrooms"),
                    _buildNavLink("Students"),
                    _buildNavLink("Reports"),

                    const Spacer(),

                    // Profile Section
                    Text(
                      "Welcome Rupali!",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 20),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ================= MAIN CONTENT GRID =================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------- LEFT COLUMN (Attention & Classrooms) -----------
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ATTENTION CARD
                          Container(
                            width: double.infinity,
                            height: 250,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "ATTENTION",
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4E2A34),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ],
                                ),
                                // Placeholder for potential content inside the card
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // MY CLASSROOMS HEADER
                          Text(
                            "My Classrooms",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CLASSROOM CARDS ROW
                          Row(
                            children: [
                              HoverableClassroomCard(
                                color: cardColor,
                                title: "Class X A",
                                // Add your destination page here
                                destination: const WebClassroomPage(),
                              ),
                              const SizedBox(width: 20),
                              HoverableClassroomCard(
                                color: cardColor,
                                title: "Class IX B",
                                destination: const WebClassroomPage(),
                              ),
                              const SizedBox(width: 20),
                              HoverableClassroomCard(
                                color: cardColor,
                                title: "Class XI C",
                                destination: const WebClassroomPage(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // VIEW ALL BUTTON
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: tealColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "View all classrooms",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4E2A34),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 40),

                    // ----------- RIGHT COLUMN (Calendar & Activities) -----------
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // CALENDAR WIDGET
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5D3540,
                              ), // Slightly lighter than bg
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white70,
                                    ),
                                    Text(
                                      "February 2026",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Simplified Calendar Grid Mockup
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                      ),
                                  itemCount: 28, // Just for mockup look
                                  itemBuilder: (context, index) {
                                    bool isSelected =
                                        index == 16; // Random selected date
                                    return Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cardColor
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // RECENT ACTIVITIES SECTION
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D3540),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Recent Activities",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildAnnouncementCard(cardColor),
                                const SizedBox(height: 10),
                                _buildAnnouncementCard(cardColor),
                                const SizedBox(height: 10),
                                _buildAnnouncementCard(cardColor),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildNavLink(String text, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: isActive ? Colors.white : Colors.white60,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Announcements",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF4E2A34),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Lorem ipsum dolor sit amet, concoatiad wz qiite nood as it",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            "November 27, 2025",
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ================= NEW HOVERABLE CARD WIDGET =================
class HoverableClassroomCard extends StatefulWidget {
  final Color color;
  final String title;
  final Widget destination;

  const HoverableClassroomCard({
    super.key,
    required this.color,
    required this.title,
    required this.destination,
  });

  @override
  State<HoverableClassroomCard> createState() => _HoverableClassroomCardState();
}

class _HoverableClassroomCardState extends State<HoverableClassroomCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        cursor: SystemMouseCursors.click, // Changes cursor to a pointer hand
        child: GestureDetector(
          onTap: () {
            // Navigate to the provided destination page when clicked
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => widget.destination),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 200,
            ), // Speed of the pop-up animation
            height: 180,
            padding: const EdgeInsets.all(20),
            // The transform moves the card up by 10 pixels when hovered
            transform: Matrix4.translationValues(0, isHovered ? -10 : 0, 0),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(20),
              // Adds a drop shadow when hovered to make it look elevated
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: const Color(0xFF4E2A34),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Colors.green, // Active status dot
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
