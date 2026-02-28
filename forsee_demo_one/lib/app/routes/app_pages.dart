import 'package:get/get.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import 'package:forsee_demo_one/app/middleware/auth_middleware.dart';

// ── Public pages ──────────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/welcome_page_first.dart';
import 'package:forsee_demo_one/pages/welcome_page_seond.dart';
import 'package:forsee_demo_one/pages/login_page.dart';
import 'package:forsee_demo_one/pages/sign_up_page.dart';

// ── Admin pages ───────────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/admin/admin_dashboard.dart';
import 'package:forsee_demo_one/pages/profile/admin_profile_page.dart';
import 'package:forsee_demo_one/pages/settings/admin_settings_page.dart';

// ── Teacher pages ─────────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/teacher/teacher_dashboard.dart';
import 'package:forsee_demo_one/pages/profile/teacher_profile_page.dart';
import 'package:forsee_demo_one/pages/settings/teacher_settings_page.dart';
import 'package:forsee_demo_one/pages/teacher/classroom_page.dart';
import 'package:forsee_demo_one/pages/teacher/behaviour_incident_page.dart';
import 'package:forsee_demo_one/pages/teacher/create_marks_entry_page.dart';
import 'package:forsee_demo_one/pages/teacher/review_submit_page.dart';
import 'package:forsee_demo_one/pages/teacher/teacher_analysis_page.dart';
import 'package:forsee_demo_one/pages/teacher/upload_hub_page.dart';

// ── Teacher-only pages ────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/teacher_only/alerts_high_risk_page.dart';
import 'package:forsee_demo_one/pages/teacher_only/download_class_reports_page.dart';
import 'package:forsee_demo_one/pages/teacher_only/messages_page.dart';
import 'package:forsee_demo_one/pages/teacher_only/view_past_semester_page.dart';

// ── Student pages ─────────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/student/student_dashboard.dart';
import 'package:forsee_demo_one/pages/profile/student_profile_page.dart';          // student's own profile
import 'package:forsee_demo_one/pages/student/student_profile.dart' as TeacherView; // teacher's view of a student
import 'package:forsee_demo_one/pages/settings/student_settings_page.dart';
import 'package:forsee_demo_one/pages/student/report_page.dart';
import 'package:forsee_demo_one/pages/student/student_database_page.dart';
import 'package:forsee_demo_one/model/student_model.dart';

// ── Shared pages ──────────────────────────────────────────────────────────────
import 'package:forsee_demo_one/pages/shared/change_password_page.dart';
import 'package:forsee_demo_one/pages/shared/faqs_page.dart';
import 'package:forsee_demo_one/pages/shared/linked_account_page.dart';
import 'package:forsee_demo_one/pages/shared/report_problem_page.dart';
import 'package:forsee_demo_one/pages/shared/talk_counsellor_page.dart';

class AppPages {
  static final pages = [

    // ── PUBLIC ────────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.WELCOME_ONE,
      page: () => const WelcomePageFirst(),
    ),
    GetPage(
      name: AppRoutes.WELCOME_TWO,
      page: () => const WelcomePageSecond(),
    ),
    GetPage(
      name: AppRoutes.ACCOUNT_SELECT,
      page: () => const AccountSelectionPage(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.SIGN_UP,
      page: () => const SignUpPage(),
    ),

    // ── ADMIN ─────────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.ADMIN_DASHBOARD,
      page: () => const AdminDashboard(),
      middlewares: [AuthMiddleware(allowed: ['admin'])],
    ),
    GetPage(
      name: AppRoutes.ADMIN_PROFILE,
      page: () => const AdminProfilePage(),
      middlewares: [AuthMiddleware(allowed: ['admin'])],
    ),
    GetPage(
      name: AppRoutes.ADMIN_SETTINGS,
      page: () => const AdminSettingsPage(),
      middlewares: [AuthMiddleware(allowed: ['admin'])],
    ),

    // ── TEACHER ───────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.TEACHER_DASHBOARD,
      page: () => const TeacherDashboard(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.TEACHER_PROFILE,
      page: () => const TeacherProfilePage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.TEACHER_SETTINGS,
      page: () => const TeacherSettingsPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.CLASSROOM,
      page: () => const ClassroomPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.BEHAVIOUR_INCIDENT,
      page: () => const BehaviourIncidentPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.CREATE_MARKS,
      page: () => const CreateMarksEntryPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.REVIEW_SUBMIT,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ReviewSubmitPage(
          examTitle: args['examTitle'] as String,
          date:      args['date']      as String,
          maxMarks:  args['maxMarks']  as int,
          passMarks: args['passMarks'] as int,
          subject:   args['subject']   as String,
          className: args['className'] as String,
          marksData: List<Map<String, dynamic>>.from(args['marksData']),
        );
      },
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.UPLOAD_HUB,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return UploadHubPage(
          examTitle: args['examTitle'] as String,
          date:      args['date']      as String,
          maxMarks:  args['maxMarks']  as int,
          passMarks: args['passMarks'] as int,
          subject:   args['subject']   as String,
          className: args['className'] as String,
          semester:  args['semester']  as String,
          students:  List<Map<String, dynamic>>.from(args['students']),
        );
      },
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.TEACHER_ANALYSIS,
      page: () => const TeacherAnalysisPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.ALERTS_HIGH_RISK,
      page: () => const AlertsHighRiskPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.DOWNLOAD_CLASS_REPORTS,
      page: () => const DownloadClassReportsPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.MESSAGES,
      page: () => const MessagesPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.VIEW_PAST_SEMESTER,
      page: () => const ViewPastSemesterPage(),
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),

    // ── STUDENT ───────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.STUDENT_DASHBOARD,
      page: () => const StudentDashboard(),
      middlewares: [AuthMiddleware(allowed: ['student'])],
    ),
    // Student's own profile (no args needed)
    GetPage(
      name: AppRoutes.STUDENT_PROFILE,
      page: () => const StudentProfilePage(),
      middlewares: [AuthMiddleware(allowed: ['student'])],
    ),
    // Teacher's view of a student (passes StudentModel via arguments)
    GetPage(
      name: AppRoutes.STUDENT_PROFILE_TEACHER_VIEW,
      page: () {
        final student = Get.arguments as StudentModel;
        return TeacherView.StudentProfilePage(student: student);
      },
      middlewares: [AuthMiddleware(allowed: ['teacher'])],
    ),
    GetPage(
      name: AppRoutes.STUDENT_SETTINGS,
      page: () => const StudentSettingsPage(),
      middlewares: [AuthMiddleware(allowed: ['student'])],
    ),
    // Accessible by both student (own report) and teacher (viewing student report)
    GetPage(
      name: AppRoutes.STUDENT_REPORT,
      page: () => const ReportPage(),
      middlewares: [AuthMiddleware(allowed: ['student', 'teacher'])],
    ),
    GetPage(
      name: AppRoutes.STUDENT_DATABASE,
      page: () => const StudentDatabasePage(),
      middlewares: [AuthMiddleware(allowed: ['student'])],
    ),

    // ── SHARED ────────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.CHANGE_PASSWORD,
      page: () => const ChangePasswordPage(),
      middlewares: [AuthMiddleware(allowed: ['admin', 'teacher', 'student'])],
    ),
    GetPage(
      name: AppRoutes.FAQS,
      page: () => const FAQsPage(),
      middlewares: [AuthMiddleware(allowed: ['admin', 'teacher', 'student'])],
    ),
    GetPage(
      name: AppRoutes.LINKED_ACCOUNT,
      page: () => const LinkedAccountPage(),
      middlewares: [AuthMiddleware(allowed: ['admin', 'teacher', 'student'])],
    ),
    GetPage(
      name: AppRoutes.REPORT_PROBLEM,
      page: () => const ReportProblemPage(),
      middlewares: [AuthMiddleware(allowed: ['admin', 'teacher', 'student'])],
    ),
    GetPage(
      name: AppRoutes.TALK_COUNSELLOR,
      page: () => const TalkToCounsellorPage(),
      middlewares: [AuthMiddleware(allowed: ['admin', 'teacher', 'student'])],
    ),
  ];
}