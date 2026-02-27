import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A3439),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A3439),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome, Student!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'Pridi',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}