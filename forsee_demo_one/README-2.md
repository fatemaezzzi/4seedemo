# Profile Subpages – Flutter Module

## Full File Map

```
lib/
├── theme/
│   └── app_theme.dart
├── widgets/
│   └── shared_widgets.dart          # PrimaryButton, TealCard, InfoRow, ActionTile,
│                                    # EditableField, SectionTitle, BottomNavBar
├── pages/
│   └── profile_subpages/
│       ├── shared/
│       │   ├── edit_personal_info_page.dart   ✅ all 3 roles
│       │   └── logout_dialog.dart             ✅ all 3 roles
│       │
│       ├── student/
│       │   ├── mental_health_quiz_page.dart   → 5-question quiz with scoring
│       │   ├── teacher_remarks_page.dart      → per-subject remarks cards
│       │   └── contact_teacher_page.dart      → select teacher + send message
│       │
│       ├── teacher/
│       │   ├── courses_page.dart              → courses with progress bars
│       │   ├── upload_attendance_page.dart    → tap P/A per student
│       │   ├── upload_result_page.dart        → enter marks per student
│       │   ├── schedule_meet_page.dart        → date/time/invitees picker
│       │   └── check_report_calendar_page.dart → class report + calendar
│       │
│       └── admin/
│           ├── admin_student_profile_page.dart → search + filter + at-risk flags
│           ├── admin_teacher_profile_page.dart → teacher list with stats
│           └── admin_report_account_page.dart  → report dashboard + account settings
```

---

## Navigation Wiring

### Student Profile Page
```dart
import 'profile_subpages/student/mental_health_quiz_page.dart';
import 'profile_subpages/student/teacher_remarks_page.dart';
import 'profile_subpages/student/contact_teacher_page.dart';
import 'profile_subpages/shared/edit_personal_info_page.dart';
import 'profile_subpages/shared/logout_dialog.dart';

// Mental Health Quiz
Navigator.push(context, MaterialPageRoute(builder: (_) => const MentalHealthQuizPage()));

// Teacher Remarks
Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherRemarksPage()));

// Contact Teacher
Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactTeacherPage()));

// Edit Personal Info (student role)
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const EditPersonalInfoPage(role: UserRole.student)));

// Logout
showLogoutDialog(context);
```

### Teacher Profile Page
```dart
import 'profile_subpages/teacher/courses_page.dart';
import 'profile_subpages/teacher/upload_attendance_page.dart';
import 'profile_subpages/teacher/upload_result_page.dart';
import 'profile_subpages/teacher/schedule_meet_page.dart';
import 'profile_subpages/teacher/check_report_calendar_page.dart';
import 'profile_subpages/shared/edit_personal_info_page.dart';
import 'profile_subpages/shared/logout_dialog.dart';

// Courses
Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesPage()));

// Quick Actions
Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadAttendancePage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadResultPage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleMeetPage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckReportPage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage()));

// Edit Personal Info (teacher role)
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const EditPersonalInfoPage(role: UserRole.teacher)));

// Logout
showLogoutDialog(context);
```

### Admin Profile Page
```dart
import 'profile_subpages/admin/admin_student_profile_page.dart';
import 'profile_subpages/admin/admin_teacher_profile_page.dart';
import 'profile_subpages/admin/admin_report_account_page.dart';
import 'profile_subpages/teacher/check_report_calendar_page.dart'; // shared CalendarPage
import 'profile_subpages/shared/edit_personal_info_page.dart';
import 'profile_subpages/shared/logout_dialog.dart';

// Quick Actions
Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentProfilePage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTeacherProfilePage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportPage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountPage()));
Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())); // shared!

// Edit Personal Info (admin role)
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const EditPersonalInfoPage(role: UserRole.admin)));

// Logout
showLogoutDialog(context);
```

---

## Shared vs Role-Specific

| Page                     | Student | Teacher | Admin |
|--------------------------|---------|---------|-------|
| Edit Personal Info       | ✅      | ✅      | ✅    |
| Logout Dialog            | ✅      | ✅      | ✅    |
| Calendar                 | —       | ✅      | ✅ (shared) |
| Mental Health Quiz       | ✅      | —       | —     |
| Teacher Remarks          | ✅      | —       | —     |
| Contact Teacher          | ✅      | —       | —     |
| Courses                  | —       | ✅      | —     |
| Upload Attendance        | —       | ✅      | —     |
| Upload Result            | —       | ✅      | —     |
| Schedule Meet            | —       | ✅      | —     |
| Check Report             | —       | ✅      | —     |
| Student Profile List     | —       | —       | ✅    |
| Teacher Profile List     | —       | —       | ✅    |
| Admin Report Dashboard   | —       | —       | ✅    |
| Admin Account            | —       | —       | ✅    |
