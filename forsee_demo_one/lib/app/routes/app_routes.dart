abstract class AppRoutes {
  // ── Public (no auth) ────────────────────────────────────────────────────────
  static const WELCOME_ONE    = '/welcome-one';
  static const WELCOME_TWO    = '/welcome-two';
  static const ACCOUNT_SELECT = '/account-select';
  static const LOGIN          = '/login';
  static const SIGN_UP        = '/sign-up';

  // ── Admin ────────────────────────────────────────────────────────────────────
  static const ADMIN_DASHBOARD = '/admin-dashboard';
  static const ADMIN_PROFILE   = '/admin-profile';
  static const ADMIN_SETTINGS  = '/admin-settings';

  // ── Teacher ──────────────────────────────────────────────────────────────────
  static const TEACHER_DASHBOARD  = '/teacher-dashboard';
  static const TEACHER_PROFILE    = '/teacher-profile';
  static const TEACHER_SETTINGS   = '/teacher-settings';
  static const CLASSROOM          = '/classroom';
  static const BEHAVIOUR_INCIDENT = '/behaviour-incident';
  static const CREATE_MARKS       = '/create-marks';
  static const REVIEW_SUBMIT      = '/review-submit';
  static const TEACHER_ANALYSIS   = '/teacher-analysis';
  static const UPLOAD_HUB         = '/upload-hub';

  // ── Teacher-only ─────────────────────────────────────────────────────────────
  static const ALERTS_HIGH_RISK       = '/alerts-high-risk';
  static const DOWNLOAD_CLASS_REPORTS = '/download-class-reports';
  static const MESSAGES               = '/messages';
  static const VIEW_PAST_SEMESTER     = '/view-past-semester';

  // ── Student ──────────────────────────────────────────────────────────────────
  static const STUDENT_DASHBOARD = '/student-dashboard';
  static const STUDENT_PROFILE   = '/student-profile';
  static const STUDENT_SETTINGS  = '/student-settings';
  static const STUDENT_REPORT    = '/student-report';
  static const STUDENT_DATABASE  = '/student-database';
  static const STUDENT_QUIZ_START = '/student-quiz-start';

  // ── Shared (all roles) ───────────────────────────────────────────────────────
  static const CHANGE_PASSWORD  = '/change-password';
  static const FAQS             = '/faqs';
  static const LINKED_ACCOUNT   = '/linked-account';
  static const REPORT_PROBLEM   = '/report-problem';
  static const TALK_COUNSELLOR  = '/talk-counsellor';
}