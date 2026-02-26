import 'package:flutter/material.dart';
// Ensure this import matches your TeacherDashboard filename
import 'package:forc/pages/TeacherDashboard.dart';

class AccountSelectionPage extends StatelessWidget {
  const AccountSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A3439),
      body: Stack(
        children: [
          // Header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/imagesfor4see/rectangle01.png',
              fit: BoxFit.fill,
            ),
          ),

          // Main content (NO SCROLL)
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [ // Removed 'const' here because children now use 'context'
                  const SizedBox(height: 60),

                  const _AdminSection(),

                  const SizedBox(height: 18),

                  const _TeacherSection(),

                  const SizedBox(height: 8),

                  const _StudentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- ADMIN ---------------- */

class _AdminSection extends StatelessWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/imagesfor4see/image 63.png',
          height: 190,
        ),
        const SizedBox(height: 6),
        roleButton(context, 'Admin'), // Added context
      ],
    );
  }
}

/* ---------------- TEACHER ---------------- */

class _TeacherSection extends StatelessWidget {
  const _TeacherSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/imagesfor4see/image 65.png',
          height: 190,
        ),
        const SizedBox(height: 6),
        roleButton(context, 'Teacher'), // Added context
      ],
    );
  }
}

/* ---------------- STUDENT ---------------- */

class _StudentSection extends StatelessWidget {
  const _StudentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/imagesfor4see/man with a hearing aid sitting cross legged with a book.png',
          height: 170,
        ),
        const SizedBox(height: 6),
        roleButton(context, 'Student'), // Added context
      ],
    );
  }
}

/* ---------------- BUTTON ---------------- */

Widget roleButton(BuildContext context, String title) {
  return SizedBox(
    width: 150,
    height: 42,
    child: ElevatedButton(
      onPressed: () {
        if (title == 'Teacher') {
          // Navigation logic for 4See Teacher Dashboard
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherDashboard()),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE9C2D7),
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pridi',
        ),
      ),
    ),
  );
}