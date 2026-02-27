import 'package:flutter/material.dart';
import 'student_pfp_page.dart'; // 👈 Make sure this file exists

void main() {
  runApp(const ForseeWebApp());
}

class ForseeWebApp extends StatelessWidget {
  const ForseeWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebClassroomPage(),
    );
  }
}

class WebClassroomPage extends StatelessWidget {
  const WebClassroomPage({super.key});

  // Colors
  static const Color headerColor = Color(0xFF88C3B3);
  static const Color backgroundColor = Color(0xFF54363D);
  static const Color pinkColor = Color(0xFFF9C9D9);
  static const Color textColor = Color(0xFF54363D);
  static const double contentMaxWidth = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildWebHeader(),
            const SizedBox(height: 40),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Top Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Upload Attendance',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: _buildSearchBar()),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Student Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 5,
                        children: [
                          _buildStudentCard(context,
                              name: 'Dhruv Rathee',
                              statusColor: Colors.red),
                          _buildStudentCard(context,
                              name: 'Sourav Joshi',
                              statusColor: Colors.red),
                          _buildStudentCard(context,
                              name: 'Dhinchak Pooja',
                              statusColor: Colors.amber),
                          _buildStudentCard(context,
                              name: 'Nishchay Malhan',
                              statusColor: Colors.green),
                        ],
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: 400,
                        child: _buildActionButton(
                          label: 'Upload Marks',
                          onTap: () {},
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildWebHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Science',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Semester II',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'STD 5th',
                    style: TextStyle(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'No. of Participants ',
                        style: TextStyle(fontSize: 24, color: textColor),
                      ),
                      Text(
                        '24',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BUTTON ----------------

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: pinkColor,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Icon(Icons.arrow_forward, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SEARCH ----------------

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(40),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search Student',
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  // ---------------- STUDENT CARD ----------------

  Widget _buildStudentCard(BuildContext context,
      {required String name, required Color statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: pinkColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined,
              color: textColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),

          // 🔥 NAVIGATION ON ARROW CLICK
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentPfpPage(studentName: name),
                ),
              );
            },
            child: const Icon(Icons.arrow_forward, color: textColor),
          ),
        ],
      ),
    );
  }
}