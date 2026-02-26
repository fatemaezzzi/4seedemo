
import 'package:flutter/material.dart';
import 'package:forc/pages/TeacherDashboard.dart';
import 'package:forc/pages/AdminDashboard.dart';
import 'package:forc/pages/StudentDashboard.dart';

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
                children: [
                  const SizedBox(height: 60),

                  _AdminSection(),

                  const SizedBox(height: 18),

                  _TeacherSection(),

                  const SizedBox(height: 8),

                  _StudentSection(),
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
        roleButton(context, 'Admin'),
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
        roleButton(context, 'Teacher'),
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
        roleButton(context, 'Student'),
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
        if (title == 'Admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (title == 'Teacher') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherDashboard()),
          );
        } else if (title == 'Student') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
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