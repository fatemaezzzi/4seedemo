import 'package:flutter/material.dart';
import 'package:forsee_demo_one/auth_wrapper.dart';
import 'package:forsee_demo_one/pages/profile/admin_profile_page.dart';
import 'package:forsee_demo_one/pages/profile/student_profile_page.dart';
import 'package:forsee_demo_one/pages/profile/teacher_profile_page.dart';
import 'package:forsee_demo_one/pages/settings/admin_settings_page.dart';
import 'package:forsee_demo_one/pages/settings/student_settings_page.dart';
import 'package:forsee_demo_one/pages/settings/teacher_settings_page.dart';
import 'package:forsee_demo_one/pages/student_quiz_page.dart';
import 'package:forsee_demo_one/pages/welcome_page_first.dart';
import 'package:forsee_demo_one/theme/app_theme.dart';
import 'pages/input_test_page.dart';
import 'scan_attendance.dart'; // Import your new file
// import 'welcome_page_first.dart';
import 'pages/simple_api_test.dart';
import 'pages/welcome_page_seond.dart';
import 'pages/sign_up_page.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    theme: AppTheme.theme,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child : Center(
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminSettingsPage(),
                    ),
                  );
                },
                child: const Text("adminSettingsPage"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherSettingsPage(),
                    ),
                  );
                },
                child: const Text("teacherSettingsPage"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentSettingsPage(),
                    ),
                  );
                },
                child: const Text("studentSettingsPage"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProfilePage(),
                    ),
                  );
                },
                child: const Text("adminProfilePage"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentProfilePage(),
                    ),
                  );
                },
                child: const Text("studentProfilePage"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherProfilePage(),
                    ),
                  );
                },
                child: const Text("teacherProfilePage"),
              ),
              const SizedBox(height: 16)
            ],
          ),
        ),
      )
    );
  }
}