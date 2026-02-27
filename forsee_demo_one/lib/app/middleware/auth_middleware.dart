import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  // List of roles that are allowed to access this route.
  // e.g. AuthMiddleware(allowed: ['admin'])
  // e.g. AuthMiddleware(allowed: ['teacher', 'admin'])   ← multi-role page
  // e.g. AuthMiddleware(allowed: ['admin','teacher','student']) ← all logged-in
  final List<String> allowed;

  // ✅ FIXED: removed `const` — GetMiddleware's super constructor is not const
  AuthMiddleware({required this.allowed});

  @override
  RouteSettings? redirect(String? route) {
    final auth = AuthController.to;

    // ── Not logged in at all → send to login ──────────────────────────────────
    if (!auth.isLoggedIn) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // ── Logged in but wrong role → send to their own dashboard ───────────────
    if (!allowed.contains(auth.roleString)) {
      return RouteSettings(name: _dashboardForRole(auth.roleString));
    }

    // ── All good → allow access ───────────────────────────────────────────────
    return null;
  }

  String _dashboardForRole(String role) {
    switch (role) {
      case 'admin':   return AppRoutes.ADMIN_DASHBOARD;
      case 'teacher': return AppRoutes.TEACHER_DASHBOARD;
      default:        return AppRoutes.STUDENT_DASHBOARD;
    }
  }
}