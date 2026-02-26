// lib/models/student_model.dart
//
// This is your single source of truth for a student.
// Pass one StudentModel through Navigator and every page
// (ClassroomPage → StudentProfilePage → ReportPage → BehaviourIncidentPage)
// will always show the correct name, ID, class, phone, and risk level.
//
// In a real app you would fetch this from Firebase/your backend and
// construct a StudentModel from the JSON — the rest of the app stays identical.

class StudentModel {
  final String name;
  final String studentId;   // e.g. "#01245"
  final String standard;    // e.g. "Std 5th"
  final String phone;       // parent contact
  final String className;   // e.g. "Class 12-B"
  final String subject;
  final RiskLevel riskLevel;

  const StudentModel({
    required this.name,
    required this.studentId,
    required this.standard,
    required this.phone,
    required this.className,
    required this.subject,
    this.riskLevel = RiskLevel.none,
  });

  // Convenience: first letter for avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  // Display string for the info pill
  String get infoPill => '$standard  |  $phone';
}

enum RiskLevel { none, low, medium, high }