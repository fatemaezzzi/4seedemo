import 'package:flutter/material.dart';
import 'package:forsee_demo_one/auth_wrapper.dart';
import 'package:forsee_demo_one/student_quiz_page.dart';
import 'package:forsee_demo_one/welcome_page_first.dart';
import 'input_test_page.dart';
import 'scan_attendance.dart'; // Import your new file
// import 'welcome_page_first.dart';
import 'simple_api_test.dart';
import 'welcome_page_seond.dart';
import 'auth_service.dart';
import 'sign_up_page.dart';
import 'login_page.dart';
import 'student_quiz_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const AuthWrapper(),
    routes: {
      '/sign_up':           (_) => const SignUpPage(),
      '/login_page':        (_) => const LoginPage(),
      '/account_selection': (_) => const AccountSelectionPage(),
      '/home_page':         (_) => const HomeScreen(),
    },
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
    child: Column(
    mainAxisSize: MainAxisSize.min, // keeps column tight
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanAttendanceScreen(),
              ),
            );
          },
          child: const Text("Go to Attendance Scanner"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePageFirst(),
              ),
            );
          },
          child: const Text("WelcomePage"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InputTestPage(),
              ),
            );
          },
          child: const Text("Testing Page"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimpleAPITest(),
              ),
            );
          },
          child: const Text("API Testing Page"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentQuizPage(),
              ),
            );
          },
          child: const Text("Quiz"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignUpPage(),
              ),
            );
          },
          child: const Text("Signup"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
          child: const Text("LoginPage"),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WelcomePageSecond(),
              ),
            );
          },
          child: const Text("welcome2"),
        ),
      ],
    ),
    ),
    );
  }
}