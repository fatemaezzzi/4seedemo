import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

// These imports now exactly match your project file structure
import 'package:forc/pages/signuporloginpage.dart';
import 'package:forc/pages/accountselectionpage.dart';
import 'package:forc/pages/TeacherDashboard.dart';
import 'package:forc/pages/classroompage.dart'; // Fixed: removed underscore
import 'package:forc/pages/studentprofile.dart'; // Fixed: removed underscore
import 'package:forc/pages/reportpage.dart';    // Fixed: removed underscore
import 'package:forc/pages/create_marks_entry_page.dart';
import 'package:forc/pages/UploadHubPage.dart'; // Fixed: matching case sensitivity

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '4See',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Pridi', // Setting your project's default font
      ),
      // Starts the app directly on the Classroom Page for testing
      home: const ReportPage(),
    );
  }
}