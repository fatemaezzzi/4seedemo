import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Call showLogoutDialog(context) from any of the three profile pages.
/// Handle actual logout logic in the onPressed callback below.
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () {
            // Close the dialog first
            Navigator.pop(ctx);
            // Then clear the entire navigation stack and go to your login screen.
            // Replace LoginPage with your actual login route:
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   MaterialPageRoute(builder: (_) => const LoginPage()),
            //   (route) => false,
            // );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}