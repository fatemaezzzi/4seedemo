# Settings Pages – Flutter Module

## Architecture Decision: One Module, Role-Specific Screens

Shared pages are reused across all three roles (Student, Teacher, Admin).
Role-specific settings pages render only the sections relevant to that role.

---

## File Structure

```
lib/
├── main.dart                          # Entry point + role selector demo
├── theme/
│   └── app_theme.dart                 # Colors, ThemeData
├── widgets/
│   └── settings_widgets.dart          # Reusable: SettingsCard, ProfileHeader,
│                                      #   SettingsSectionTitle, BottomNavBar, etc.
├── pages/
│   ├── settings/                      # Role-specific settings screens
│   │   ├── student_settings_page.dart
│   │   ├── teacher_settings_page.dart
│   │   └── admin_settings_page.dart
│   │
│   ├── shared/                        # ✅ SHARED across all roles
│   │   ├── change_password_page.dart
│   │   ├── linked_account_page.dart
│   │   ├── faqs_page.dart
│   │   ├── report_problem_page.dart
│   │   └── talk_counsellor_page.dart
│   │
│   └── teacher_only/                  # 🔒 Teacher role only
│       ├── download_class_reports_page.dart
│       ├── view_past_semester_page.dart
│       ├── alerts_high_risk_page.dart
│       └── messages_page.dart
```

---

## What's Shared vs Role-Specific

| Page                     | Student | Teacher | Admin |
|--------------------------|---------|---------|-------|
| Change Password          | ✅      | ✅      | ✅    |
| Linked Account           | ✅      | ✅      | ✅    |
| FAQs                     | ✅      | ✅      | ✅    |
| Report a Problem         | ✅      | ✅      | ✅    |
| Talk to a Counsellor     | ✅      | ✅      | ✅    |
| Download Class Reports   | ❌      | ✅      | ❌    |
| View Past Semester Data  | ❌      | ✅      | ❌    |
| Alerts for High Risk     | ❌      | ✅      | ❌    |
| Messages (Admin/Student) | ❌      | ✅      | ❌    |

---

## Color Reference

| Name       | Hex       | Usage                        |
|------------|-----------|------------------------------|
| background | #3D1A1F   | App background (dark maroon) |
| surface    | #2A1014   | Cards, inputs, overlays      |
| card       | #EFECE8   | Settings item rows           |
| accent     | #8ECFC4   | Teal — buttons, nav bar      |
| textPrimary| #FFFFFF   | Headings on dark background  |
| textMuted  | #BBBBBB   | Subtitles, labels            |

---

## How to Add a New Role Section

1. Create the page in `pages/shared/` if reusable, or `pages/<role>_only/` if not.
2. Import it in the relevant `*_settings_page.dart`.
3. Add a `SettingsItem` entry inside `SettingsCard`.

That's it — no routing config needed, uses `Navigator.push`.
