# Profile Subpages – Flutter Module (v2)

## What Changed from v1

| Issue | Fix |
|---|---|
| `BottomNavBar` present in all subpages | **Removed** — subpages use AppBar back button only |
| `CalendarPage` was inside a teacher file and re-exported for admin | **Extracted** to `shared/calendar_page.dart` |
| Rogue `export` statement in `admin_report_account_page.dart` | **Removed** |
| `check_report_calendar_page.dart` combined two unrelated classes | **Split** into `check_report_page.dart` + `shared/calendar_page.dart` |
| `logout_dialog.dart` had ambiguous TODO comment | **Clarified** with exact `pushAndRemoveUntil` instructions |
| `AdminAccountPage` Change Password had empty `onTap: () {}` | **Commented** with correct wiring to settings module |

---

## Full File Map

```
lib/
├── theme/
│   └── app_theme.dart
│
├── widgets/
│   └── shared_widgets.dart
│       # NOTE: BottomNavBar is defined here but ONLY used by the
│       # 3 profile pages themselves, NOT by any subpage.
│
└── pages/
    └── profile_subpages/
        │
        ├── shared/                       # Safe to import from any role
        │   ├── calendar_page.dart             CalendarPage
        │   ├── edit_personal_info_page.dart   EditPersonalInfoPage + UserRole enum
        │   └── logout_dialog.dart             showLogoutDialog()
        │
        ├── student/                      # Routed ONLY from StudentProfilePage
        │   ├── mental_health_quiz_page.dart   MentalHealthQuizPage
        │   ├── teacher_remarks_page.dart      TeacherRemarksPage
        │   └── contact_teacher_page.dart      ContactTeacherPage
        │
        ├── teacher/                      # Routed ONLY from TeacherProfilePage
        │   ├── courses_page.dart              CoursesPage
        │   ├── upload_attendance_page.dart    UploadAttendancePage
        │   ├── upload_result_page.dart        UploadResultPage
        │   ├── schedule_meet_page.dart        ScheduleMeetPage
        │   └── check_report_page.dart         CheckReportPage
        │
        └── admin/                        # Routed ONLY from AdminProfilePage
            ├── admin_student_profile_page.dart   AdminStudentProfilePage
            ├── admin_teacher_profile_page.dart   AdminTeacherProfilePage
            └── admin_report_account_page.dart    AdminReportPage + AdminAccountPage
```

---

## Navigation Rules

Subpages have NO BottomNavBar and NO internal cross-navigation.
They are pushed by their parent profile page and popped via the AppBar back arrow only.

```
StudentProfilePage  ──push──►  student/* subpages
                    ──push──►  shared/edit_personal_info_page (role: student)
                    ──dialog──► shared/logout_dialog

TeacherProfilePage  ──push──►  teacher/* subpages
                    ──push──►  shared/calendar_page
                    ──push──►  shared/edit_personal_info_page (role: teacher)
                    ──dialog──► shared/logout_dialog

AdminProfilePage    ──push──►  admin/* subpages
                    ──push──►  shared/calendar_page
                    ──push──►  shared/edit_personal_info_page (role: admin)
                    ──dialog──► shared/logout_dialog
```

---

## Exact Navigation Code

### StudentProfilePage

```dart
import 'pages/profile_subpages/student/mental_health_quiz_page.dart';
import 'pages/profile_subpages/student/teacher_remarks_page.dart';
import 'pages/profile_subpages/student/contact_teacher_page.dart';
import 'pages/profile_subpages/shared/edit_personal_info_page.dart';
import 'pages/profile_subpages/shared/logout_dialog.dart';

// Mental Health Quiz button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const MentalHealthQuizPage())),

// Teacher Remarks button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const TeacherRemarksPage())),

// Contact Teacher button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const ContactTeacherPage())),

// Edit Personal Information button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.student))),

// Logout button
onTap: () => showLogoutDialog(context),
```

### TeacherProfilePage

```dart
import 'pages/profile_subpages/teacher/courses_page.dart';
import 'pages/profile_subpages/teacher/upload_attendance_page.dart';
import 'pages/profile_subpages/teacher/upload_result_page.dart';
import 'pages/profile_subpages/teacher/schedule_meet_page.dart';
import 'pages/profile_subpages/teacher/check_report_page.dart';
import 'pages/profile_subpages/shared/calendar_page.dart';
import 'pages/profile_subpages/shared/edit_personal_info_page.dart';
import 'pages/profile_subpages/shared/logout_dialog.dart';

// Courses button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const CoursesPage())),

// Quick Actions — Upload Attendance
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const UploadAttendancePage())),

// Quick Actions — Upload Result
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const UploadResultPage())),

// Quick Actions — Schedule a Meet
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const ScheduleMeetPage())),

// Quick Actions — Check Report
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const CheckReportPage())),

// Quick Actions — Calendar
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const CalendarPage())),

// Edit Personal Information button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.teacher))),

// Logout button
onTap: () => showLogoutDialog(context),
```

### AdminProfilePage

```dart
import 'pages/profile_subpages/admin/admin_student_profile_page.dart';
import 'pages/profile_subpages/admin/admin_teacher_profile_page.dart';
import 'pages/profile_subpages/admin/admin_report_account_page.dart';
import 'pages/profile_subpages/shared/calendar_page.dart';
import 'pages/profile_subpages/shared/edit_personal_info_page.dart';
import 'pages/profile_subpages/shared/logout_dialog.dart';

// Profile button (top)
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.admin))),

// Quick Actions — Student Profile
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const AdminStudentProfilePage())),

// Quick Actions — Teacher Profile
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const AdminTeacherProfilePage())),

// Quick Actions — Report
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const AdminReportPage())),

// Quick Actions — Account
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const AdminAccountPage())),

// Quick Actions — Calendar
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const CalendarPage())),

// Edit Personal Information button
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => const EditPersonalInfoPage(role: UserRole.admin))),

// Logout button
onTap: () => showLogoutDialog(context),
```

---

## Role Access Matrix

| Page | Student | Teacher | Admin |
|---|---|---|---|
| `shared/calendar_page.dart` | — | ✅ | ✅ |
| `shared/edit_personal_info_page.dart` | ✅ | ✅ | ✅ |
| `shared/logout_dialog.dart` | ✅ | ✅ | ✅ |
| `student/mental_health_quiz_page.dart` | ✅ | — | — |
| `student/teacher_remarks_page.dart` | ✅ | — | — |
| `student/contact_teacher_page.dart` | ✅ | — | — |
| `teacher/courses_page.dart` | — | ✅ | — |
| `teacher/upload_attendance_page.dart` | — | ✅ | — |
| `teacher/upload_result_page.dart` | — | ✅ | — |
| `teacher/schedule_meet_page.dart` | — | ✅ | — |
| `teacher/check_report_page.dart` | — | ✅ | — |
| `admin/admin_student_profile_page.dart` | — | — | ✅ |
| `admin/admin_teacher_profile_page.dart` | — | — | ✅ |
| `admin/admin_report_account_page.dart` | — | — | ✅ |

---

## Wiring Logout

In `shared/logout_dialog.dart`, after `Navigator.pop(ctx)`, add:

```dart
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginPage()),
  (route) => false, // clears entire navigation stack
);
```

## Wiring Change Password in AdminAccountPage

`AdminAccountPage` has a commented Change Password tile. Connect it to the
`ChangePasswordPage` already built in your settings module:

```dart
import 'pages/settings/shared/change_password_page.dart';

ActionTile(
  label: 'Change Password',
  onTap: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
),
```
