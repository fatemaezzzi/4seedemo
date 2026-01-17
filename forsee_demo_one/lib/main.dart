import 'package:flutter/material.dart';
import 'package:forsee_demo_one/welcome_page_first.dart';
import 'input_test_page.dart';
import 'scan_attendance.dart'; // Import your new file
// import 'welcome_page_first.dart';
import 'simple_api_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
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
      ],
    ),
    ),
    );
  }
}