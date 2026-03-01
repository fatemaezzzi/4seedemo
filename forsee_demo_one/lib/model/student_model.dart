// lib/model/student_model.dart
// ================================
// firestoreId = actual Firestore /students/{id} doc ID — used for ALL DB ops
// studentId   = display ID e.g. "#01245" — shown in UI only, never used for DB

enum RiskLevel { none, low, medium, high }

class StudentModel {
  final String name;
  final String studentId;    // display-only e.g. "#01245"
  final String firestoreId;  // Firestore document ID — use for all DB writes
  final String standard;
  final String phone;
  final String className;
  final String subject;
  final RiskLevel riskLevel;

  const StudentModel({
    required this.name,
    required this.studentId,
    required this.firestoreId,
    required this.standard,
    required this.phone,
    required this.className,
    required this.subject,
    this.riskLevel = RiskLevel.none,
  });

  String get initial  => name.isNotEmpty ? name[0].toUpperCase() : '?';
  String get infoPill => '$standard  |  $phone';

  factory StudentModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return StudentModel(
      firestoreId: docId,
      studentId:   data['studentId']  as String? ?? docId,
      name:        data['name']       as String? ?? '',
      standard:    data['standard']   as String? ?? '',
      phone:       data['phone']      as String? ?? '',
      className:   data['className']  as String? ?? '',
      subject:     data['subject']    as String? ?? '',
      riskLevel:   _riskFromString(data['riskLevel'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'name':      name,
    'standard':  standard,
    'phone':     phone,
    'className': className,
    'subject':   subject,
    'riskLevel': riskLevel.name,
  };

  static RiskLevel _riskFromString(String? s) {
    switch (s) {
      case 'high':   return RiskLevel.high;
      case 'medium': return RiskLevel.medium;
      case 'low':    return RiskLevel.low;
      default:       return RiskLevel.none;
    }
  }
}