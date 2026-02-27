import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:forsee_demo_one/app/routes/app_pages.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/theme/app_theme.dart';
import 'services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register AuthController globally before app starts.
  // permanent: true → never destroyed while app is alive.
  Get.put(AuthController(), permanent: true);

  runApp(const FourSeeApp());
}

class FourSeeApp extends StatelessWidget {
  const FourSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '4See',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // App always starts at welcome-one.
      // AuthController's onInit() fires immediately and redirects
      // to the correct dashboard if the user is already logged in.
      initialRoute: AppRoutes.WELCOME_ONE,

      getPages: AppPages.pages,

      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}