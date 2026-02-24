import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login_page.dart';

/// Drop this as `home:` in your MaterialApp.
/// - Not signed in  → LoginPage
/// - Signed in      → fetches role from Firestore → HomeScreen (via named route)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {

        // Still waiting for Firebase to respond
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // Not signed in → show Login
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // Signed in → fetch Firestore profile then go to HomeScreen
        return FutureBuilder<AppUser?>(
          future: AuthService().fetchCurrentAppUser(),
          builder: (context, userSnap) {

            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final appUser = userSnap.data;

            // Profile missing → force sign out back to Login
            if (appUser == null) {
              AuthService().signOut();
              return const LoginPage();
            }

            // ✅ All roles go to HomeScreen for now.
            // Use post-frame callback so Navigator is ready before we push.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home_page');
            });

            return const _LoadingScreen();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}