import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_page_student.dart';
import 'signup_page_teacher.dart';
import 'signup_page_admin.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E2A34),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoleCard(context, "Admin", "assets/admin_ill.png"),
                const SizedBox(width: 40),
                _buildRoleCard(context, "Teacher", "assets/teacher_ill.png"),
                const SizedBox(width: 40),
                _buildRoleCard(context, "Student", "assets/student_ill.png"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, String imagePath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 250,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (c, o, s) => const Icon(Icons.person, size: 80, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 160,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (title == "Student") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPageStudent()),
                );
              } else if (title == "Teacher") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPageTeacher()),
                );
              } else if (title == "Admin") {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPageAdmin()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8C4D8),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}