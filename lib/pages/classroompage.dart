import 'package:flutter/material.dart';
// These imports allow the classroom to "see" your other pages
import 'package:forc/pages/create_marks_entry_page.dart';
import 'package:forc/pages/studentprofile.dart';

class ClassroomPage extends StatelessWidget {
  const ClassroomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Student data mirroring your UI requirements
    final List<Map<String, dynamic>> students = [
      {"name": "Dhruv Rathee", "color": Colors.red},
      {"name": "Sourav Joshi", "color": Colors.red},
      {"name": "Dhinchak Pooja", "color": Colors.orange},
      {"name": "Nishchay Malhan", "color": Colors.green},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF3B2F2F), // Theme background
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ================= HEADER =================
            // ================= HEADER =================
            Stack(
              children: [
                Image.asset(
                  'assets/imagesfor4see/Ellipse 17.png',
                  width: screenWidth,
                  fit: BoxFit.fill,
                ),
                // --- BACK BUTTON ---
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context), // Takes you back to Teacher Dashboard
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 50, // Shifted left to make room for back button
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            'Science',
                            style: TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              fontFamily: 'Pridi',
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'STD 5th',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Semester II',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Color(0xFF3B2F2F),
                            fontSize: 17,
                          ),
                          children: [
                            TextSpan(text: 'No . of Participants '),
                            TextSpan(
                              text: '24',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ================= ACTIONS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _actionButton(context, 'Upload Attendance'),
                  const SizedBox(height: 10),
                  _searchBar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ================= STUDENT LIST =================
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Navigates to the Mirror UI Student Profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentProfilePage()),
                      );
                    },
                    child: StudentListItem(
                      name: students[index]['name'],
                      statusColor: students[index]['color'],
                    ),
                  );
                },
              ),
            ),

            // ================= BOTTOM BUTTON =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: _actionButton(context, 'Upload Marks'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF4D2DE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Student',
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          border: InputBorder.none,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/imagesfor4see/Trailing-Elements.png'),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        if (title == 'Upload Marks') {
          // Navigates to the Marks Entry Flow
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMarksEntryPage()),
          );
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4BFDB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (title == 'Upload Marks') ...[
              const Icon(Icons.add, color: Color(0xFF3B2F2F), size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontFamily: 'Pridi'),
            ),
            const Spacer(),
            _icon('assets/imagesfor4see/mingcute_camera-fill.png', true),
            const SizedBox(width: 10),
            _icon('assets/imagesfor4see/bi_filetype-csv.png', false),
          ],
        ),
      ),
    );
  }

  Widget _icon(String asset, bool isWhite) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        color: Color(0xFF512D38),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        asset,
        height: 20,
        color: isWhite ? Colors.white : null, // Ensures CSV text is visible
      ),
    );
  }
}

// ================= STUDENT CARD =================

class StudentListItem extends StatelessWidget {
  final String name;
  final Color statusColor;

  const StudentListItem({
    super.key,
    required this.name,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4BFDB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Image.asset(
              'assets/imagesfor4see/account_circle.png',
              height: 22,
            ),
            title: Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            trailing: Image.asset(
              'assets/imagesfor4see/Arrow right.png',
              height: 16,
            ),
          ),
          Container(
            height: 6,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}