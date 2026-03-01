// lib/scripts/seed_demo_data.dart
// ============================================================
//  4SEE DEMO — Firestore Seed Script (Dart / Flutter)
// ============================================================
//
//  HOW TO RUN:
//  1. Drop this file into lib/scripts/
//  2. In AdminSettingsPage (or any debug screen) add:
//
//       ElevatedButton(
//         onPressed: () async {
//           await SeedDemoData.run();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('✅ Seeding complete!')));
//         },
//         child: const Text('Seed Demo Data'),
//       )
//
//  3. Tap the button ONCE. Check Firestore console.
//  4. Remove or hide the button after seeding.
//
//  ⚠️  IMPORTANT:
//  - This does NOT create Firebase Auth accounts for new students.
//    The teacher/admin views work fully without Auth.
//    To log in AS a student, create their Auth account manually
//    using the email/password in the users doc below.
//  - Safe to re-run: uses set() with merge:false on fixed IDs
//    so it won't double-write. Call SeedDemoData.clear() first
//    if you want a clean slate.
//
//  WHAT IS SEEDED:
//  • users/       → 1 admin + 5 teachers + 25 students
//  • students/    → 25 academic feature docs
//  • classrooms/  → 5 classrooms (one per teacher)
//  • staging/     → 25 × 15-day attendance + marks + quiz
//  • predictions/ → 25 prediction docs
//  • feedback/    → sample feedback for HIGH/MEDIUM students
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDemoData {
  static final _db = FirebaseFirestore.instance;

  // ── BASE DATE — all 15-day logs count back from here ────────────────────
  static final _today = DateTime(2026, 1, 30);

  // ── FIXED DOC IDs so the script is idempotent ────────────────────────────
  // Teachers
  static const _t1 = 'teacher_priya_sharma';
  static const _t2 = 'teacher_rohan_mehta';
  static const _t3 = 'teacher_ananya_gupta';
  static const _t4 = 'teacher_kabir_patel';
  static const _t5 = 'teacher_zara_khan';

  // Classrooms
  static const _c1 = 'classroom_12A_science';
  static const _c2 = 'classroom_12B_maths';
  static const _c3 = 'classroom_11A_english';
  static const _c4 = 'classroom_11B_commerce';
  static const _c5 = 'classroom_10A_science';

  // Admin
  static const _admin = 'admin_demo_001';

  // ── ENTRY POINT ──────────────────────────────────────────────────────────

  static Future<void> run() async {
    print('🌱 4SEE: Starting demo seed...');

    await _seedAdmin();
    await _seedTeachers();
    final studentIds = await _seedStudents();
    await _seedClassrooms(studentIds);
    await _seedStaging(studentIds);
    await _seedPredictions(studentIds);
    await _seedFeedback(studentIds);

    print('✅ 4SEE: Seed complete — ${studentIds.length} students seeded.');
  }

  /// Deletes all seeded collections — call before re-seeding for a clean slate.
  static Future<void> clear() async {
    print('🗑️  4SEE: Clearing seeded data...');
    for (final col in ['students', 'classrooms', 'staging', 'predictions', 'feedback']) {
      final snap = await _db.collection(col).get();
      final batch = _db.batch();
      for (final doc in snap.docs) batch.delete(doc.reference);
      await batch.commit();
    }
    // Remove seeded users (keep real auth users — just delete the docs we created)
    for (final id in [_admin, _t1, _t2, _t3, _t4, _t5, ..._allStudentIds()]) {
      await _db.collection('users').doc(id).delete();
    }
    print('✅ 4SEE: Clear complete.');
  }

  // ── ADMIN ────────────────────────────────────────────────────────────────

  static Future<void> _seedAdmin() async {
    await _db.collection('users').doc(_admin).set({
      'name':     'Fatema Admin',
      'email':    'admin@4see.demo',
      'role':     'admin',
      'schoolId': 'school_demo_001',
      'phone':    '+91 98765 00001',
      'createdAt': _ts(_today.subtract(const Duration(days: 60))),
    });
    print('  ✓ Admin seeded');
  }

  // ── TEACHERS ─────────────────────────────────────────────────────────────

  static Future<void> _seedTeachers() async {
    final teachers = [
      {'id': _t1, 'name': 'Ms. Priya Sharma',  'email': 'priya@4see.demo',  'subject': 'Science'},
      {'id': _t2, 'name': 'Mr. Rohan Mehta',   'email': 'rohan@4see.demo',  'subject': 'Mathematics'},
      {'id': _t3, 'name': 'Ms. Ananya Gupta',  'email': 'ananya@4see.demo', 'subject': 'English'},
      {'id': _t4, 'name': 'Mr. Kabir Patel',   'email': 'kabir@4see.demo',  'subject': 'Commerce'},
      {'id': _t5, 'name': 'Ms. Zara Khan',     'email': 'zara@4see.demo',   'subject': 'Science'},
    ];
    final batch = _db.batch();
    for (final t in teachers) {
      batch.set(_db.collection('users').doc(t['id'] as String), {
        'name':     t['name'],
        'email':    t['email'],
        'role':     'teacher',
        'subject':  t['subject'],
        'schoolId': 'school_demo_001',
        'phone':    '+91 98765 0000${teachers.indexOf(t) + 2}',
        'createdAt': _ts(_today.subtract(const Duration(days: 30))),
      });
    }
    await batch.commit();
    print('  ✓ 5 teachers seeded');
  }

  // ── STUDENTS ─────────────────────────────────────────────────────────────
  // Returns map: studentDocId → full student data map

  static Future<Map<String, Map<String, dynamic>>> _seedStudents() async {
    final students = _studentDefinitions();
    final batch = _db.batch();

    for (final s in students) {
      final sid = s['id'] as String;

      // users collection doc
      batch.set(_db.collection('users').doc(sid), {
        'name':        s['name'],
        'email':       s['email'],
        'role':        'student',
        'className':   s['className'],
        'rollNo':      s['rollNo'],
        'phone':       s['phone'],
        'schoolId':    'school_demo_001',
        'studentDocId': sid,           // links users → students collection
        'quizCompleted': true,
        'createdAt':   _ts(_today.subtract(const Duration(days: 20))),
      });

      // students collection doc (ML features)
      batch.set(_db.collection('students').doc(sid), {
        'name':       s['name'],
        'email':      s['email'],
        'age':        s['age'],
        'G1':         s['g1'],
        'G2':         s['g2'],
        'absences':   s['absences'],
        'failures':   s['failures'],
        'studytime':  s['studytime'],
        'health':     s['health'],
        'Dalc':       s['dalc'],
        'Walc':       s['walc'],
        'internet':   s['internet'],
        'school':     0,
        'schoolsup':  s['schoolsup'],
        'teacherRemark': s['teacherRemark'],
      });
    }

    await batch.commit();
    print('  ✓ ${students.length} students seeded (users + students collections)');

    // Return as map for downstream stages
    return { for (final s in students) s['id'] as String : s };
  }

  // ── CLASSROOMS ───────────────────────────────────────────────────────────

  static Future<void> _seedClassrooms(Map<String, Map<String, dynamic>> studentMap) async {
    // Group students by their classroomId
    final Map<String, List<String>> classStudents = {};
    for (final entry in studentMap.entries) {
      final cid = entry.value['classroomId'] as String;
      classStudents.putIfAbsent(cid, () => []).add(entry.key);
    }

    final classrooms = [
      {'id': _c1, 'title': 'Class 12-A', 'subject': 'Science',    'semester': 'Semester II', 'std': 'STD 12th', 'teacherId': _t1},
      {'id': _c2, 'title': 'Class 12-B', 'subject': 'Mathematics','semester': 'Semester II', 'std': 'STD 12th', 'teacherId': _t2},
      {'id': _c3, 'title': 'Class 11-A', 'subject': 'English',    'semester': 'Semester II', 'std': 'STD 11th', 'teacherId': _t3},
      {'id': _c4, 'title': 'Class 11-B', 'subject': 'Commerce',   'semester': 'Semester II', 'std': 'STD 11th', 'teacherId': _t4},
      {'id': _c5, 'title': 'Class 10-A', 'subject': 'Science',    'semester': 'Semester I',  'std': 'STD 10th', 'teacherId': _t5},
    ];

    final batch = _db.batch();
    for (final c in classrooms) {
      final cid = c['id'] as String;
      batch.set(_db.collection('classrooms').doc(cid), {
        'title':      c['title'],
        'subject':    c['subject'],
        'semester':   c['semester'],
        'std':        c['std'],
        'teacherId':  c['teacherId'],
        'schoolId':   'school_demo_001',
        'studentIds': classStudents[cid] ?? [],
        'createdAt':  _ts(_today.subtract(const Duration(days: 25))),
      });
    }
    await batch.commit();
    print('  ✓ 5 classrooms seeded');
  }

  // ── STAGING (15-day daily logs) ──────────────────────────────────────────

  static Future<void> _seedStaging(Map<String, Map<String, dynamic>> studentMap) async {
    // Firestore batch limit = 500 ops. With 25 students it's fine in one batch.
    final batch = _db.batch();

    for (final entry in studentMap.entries) {
      final sid = entry.key;
      final s   = entry.value;
      final risk = s['risk'] as String;

      // Build 15-day attendance log
      // HIGH risk: lots of absences, MEDIUM: some, LOW/NONE: mostly present
      final attendancePattern = _attendancePattern(risk);
      final Map<String, bool> dailyLog = {};
      int presentCount = 0;
      for (int i = 0; i < 15; i++) {
        final day = _today.subtract(Duration(days: 14 - i));
        final dateKey = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
        final present = attendancePattern[i];
        dailyLog[dateKey] = present;
        if (present) presentCount++;
      }

      batch.set(_db.collection('staging').doc(sid), {
        'attendance': {
          'totalDays':   15,
          'presentDays': presentCount,
          'dailyLog':    dailyLog,
        },
        'marks': {
          'G1': s['g1'],
          'G2': s['g2'],
          'lastUpdated': _ts(_today.subtract(const Duration(days: 5))),
        },
        'quiz': {
          'mentalHealthScore': s['mentalHealthScore'],
          'stressLevel':       s['stressLevel'],
          'focusLevel':        s['focusLevel'],
          'motivationLevel':   s['motivationLevel'],
          'quizCompleted':     true,
          'completedAt':       _ts(_today.subtract(const Duration(days: 10))),
        },
        'behaviour': {
          'incidentCount': s['incidentCount'],
          'lastIncident':  s['lastIncident'],
        },
        'updatedAt': _ts(_today),
      });
    }

    await batch.commit();
    print('  ✓ Staging (15-day logs) seeded for ${studentMap.length} students');
  }

  // ── PREDICTIONS ──────────────────────────────────────────────────────────

  static Future<void> _seedPredictions(Map<String, Map<String, dynamic>> studentMap) async {
    final batch = _db.batch();

    for (final entry in studentMap.entries) {
      final sid = entry.key;
      final s   = entry.value;
      final risk = s['risk'] as String;
      final pred = _db.collection('predictions').doc(); // auto-id

      batch.set(pred, {
        'studentId':           sid,
        'studentName':         s['name'],
        'risk_level':          risk,
        'risk_score':          s['riskScore'],
        'dropout_probability': s['dropoutProbability'],
        'risk_factors':        s['riskFactors'],
        'recommendation':      s['recommendation'],
        'confidence':          risk == 'HIGH' ? 'HIGH' : risk == 'MEDIUM' ? 'MEDIUM' : 'LOW',
        'timestamp':           _ts(_today.subtract(const Duration(days: 1))),
      });
    }

    await batch.commit();
    print('  ✓ Predictions seeded for ${studentMap.length} students');
  }

  // ── FEEDBACK (sample entries for HIGH + MEDIUM students) ─────────────────

  static Future<void> _seedFeedback(Map<String, Map<String, dynamic>> studentMap) async {
    final highMedium = studentMap.entries
        .where((e) => e.value['risk'] == 'HIGH' || e.value['risk'] == 'MEDIUM')
        .toList();

    // Pick teacher based on classroom
    String _teacherForClass(String cid) {
      switch (cid) {
        case _c1: return 'Ms. Priya Sharma';
        case _c2: return 'Mr. Rohan Mehta';
        case _c3: return 'Ms. Ananya Gupta';
        case _c4: return 'Mr. Kabir Patel';
        default:  return 'Ms. Zara Khan';
      }
    }

    String _teacherIdForClass(String cid) {
      switch (cid) {
        case _c1: return _t1;
        case _c2: return _t2;
        case _c3: return _t3;
        case _c4: return _t4;
        default:  return _t5;
      }
    }

    // 2 feedback entries per high/medium student
    final sampleActions = [
      {
        'suggestion':      'Schedule Parent Meeting',
        'actionTaken':     'Called parents on Jan 20th, discussed attendance and performance concerns.',
        'studentResponse': 'Student showed slight improvement in attendance the following week.',
        'responseOutcome': 'positive',
        'followUpNeeded':  false,
        'followUpNote':    '',
        'daysAgo':         10,
      },
      {
        'suggestion':      'Recommend Remedial Classes',
        'actionTaken':     'Enrolled student in after-school maths support sessions.',
        'studentResponse': 'Initially reluctant but attended 3 out of 5 sessions.',
        'responseOutcome': 'neutral',
        'followUpNeeded':  true,
        'followUpNote':    'Check attendance at remedial sessions next week.',
        'daysAgo':         5,
      },
    ];

    final batch = _db.batch();
    for (final entry in highMedium) {
      final sid  = entry.key;
      final s    = entry.value;
      final cid  = s['classroomId'] as String;

      for (final action in sampleActions) {
        final ref = _db.collection('feedback').doc();
        batch.set(ref, {
          'studentId':       sid,
          'studentName':     s['name'],
          'teacherId':       _teacherIdForClass(cid),
          'teacherName':     _teacherForClass(cid),
          'suggestion':      action['suggestion'],
          'actionTaken':     action['actionTaken'],
          'studentResponse': action['studentResponse'],
          'responseOutcome': action['responseOutcome'],
          'followUpNeeded':  action['followUpNeeded'],
          'followUpNote':    action['followUpNote'],
          'createdAt':       _ts(_today.subtract(Duration(days: action['daysAgo'] as int))),
          'updatedAt':       _ts(_today.subtract(Duration(days: action['daysAgo'] as int))),
        });
      }
    }

    await batch.commit();
    print('  ✓ Feedback seeded for ${highMedium.length} HIGH/MEDIUM students (${highMedium.length * 2} entries)');
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STUDENT DEFINITIONS
  //  25 students across 5 classrooms:
  //   12-A Science  (c1/t1): s01–s05  → 2H 1M 1L 1N
  //   12-B Maths    (c2/t2): s06–s10  → 2H 1M 1L 1N
  //   11-A English  (c3/t3): s11–s15  → 1H 2M 1L 1N
  //   11-B Commerce (c4/t4): s16–s20  → 2H 2M 1L 0N
  //   10-A Science  (c5/t5): s21–s25  → 1H 2M 2L 0N
  //  TOTAL: 8H  8M  6L  3N
  // ═══════════════════════════════════════════════════════════════════════

  static List<String> _allStudentIds() => _studentDefinitions().map((s) => s['id'] as String).toList();

  static List<Map<String, dynamic>> _studentDefinitions() => [

    // ── CLASS 12-A SCIENCE (Ms. Priya Sharma) ───────────────────────────

    // HIGH
    _student('s_ayaan_khan',     'Ayaan Khan',    'ayaan@demo.com',    '+91 91234 00001',
      className: '12-A Science',  classroomId: _c1, rollNo: '#01201',
      risk: 'HIGH',  age: 17, g1: 7,  g2: 6,  absences: 13, failures: 2,
      studytime: 1, health: 2, dalc: 3, walc: 4, internet: 1, schoolsup: 0,
      riskScore: 84, dropoutProb: 84.2,
      riskFactors: ['Low attendance', 'Declining grades', 'Multiple past failures'],
      recommendation: 'Immediate parent meeting required. Assign peer mentor and enroll in remedial classes.',
      teacherRemark: 'Frequently distracted. Rarely submits homework.',
      mentalHealth: 38, stress: 4, focus: 2, motivation: 2, incidents: 3, lastIncident: 'Aggressive behaviour in class',
    ),
    // HIGH
    _student('s_riya_sharma',    'Riya Sharma',   'riya@demo.com',     '+91 91234 00002',
      className: '12-A Science',  classroomId: _c1, rollNo: '#01202',
      risk: 'HIGH',  age: 17, g1: 6,  g2: 5,  absences: 14, failures: 2,
      studytime: 1, health: 2, dalc: 2, walc: 3, internet: 0, schoolsup: 0,
      riskScore: 81, dropoutProb: 81.5,
      riskFactors: ['Very low grades', 'High absenteeism', 'No internet access'],
      recommendation: 'Connect family with NGO support. Provide printed study materials.',
      teacherRemark: 'Often absent. Struggles to keep up with syllabus.',
      mentalHealth: 42, stress: 4, focus: 2, motivation: 1, incidents: 2, lastIncident: 'No homework repeatedly',
    ),
    // MEDIUM
    _student('s_meera_nair',     'Meera Nair',    'meera@demo.com',    '+91 91234 00003',
      className: '12-A Science',  classroomId: _c1, rollNo: '#01203',
      risk: 'MEDIUM', age: 17, g1: 11, g2: 10, absences: 9,  failures: 1,
      studytime: 2, health: 3, dalc: 1, walc: 2, internet: 1, schoolsup: 1,
      riskScore: 54, dropoutProb: 54.0,
      riskFactors: ['Attendance slipping', 'Mild grade decline'],
      recommendation: 'Monitor attendance closely. Schedule check-in with student.',
      teacherRemark: 'Capable student but losing focus lately.',
      mentalHealth: 58, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Distracted in class',
    ),
    // LOW
    _student('s_arjun_iyer',     'Arjun Iyer',    'arjun@demo.com',    '+91 91234 00004',
      className: '12-A Science',  classroomId: _c1, rollNo: '#01204',
      risk: 'LOW', age: 17, g1: 14, g2: 13, absences: 5, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 22, dropoutProb: 22.0,
      riskFactors: ['Minor attendance concern'],
      recommendation: 'Continue current support. Monitor grades at next assessment.',
      teacherRemark: 'Generally on track. Small dip in last test.',
      mentalHealth: 70, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),
    // NONE
    _student('s_tanvi_desai',    'Tanvi Desai',   'tanvi@demo.com',    '+91 91234 00005',
      className: '12-A Science',  classroomId: _c1, rollNo: '#01205',
      risk: 'NONE', age: 16, g1: 18, g2: 19, absences: 1, failures: 0,
      studytime: 4, health: 5, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 5, dropoutProb: 5.0,
      riskFactors: [],
      recommendation: 'Continue current support level. Maintain regular monitoring.',
      teacherRemark: 'Star student. Consistent performance.',
      mentalHealth: 88, stress: 1, focus: 5, motivation: 5, incidents: 0, lastIncident: '',
    ),

    // ── CLASS 12-B MATHS (Mr. Rohan Mehta) ──────────────────────────────

    // HIGH
    _student('s_kabir_singh',    'Kabir Singh',   'kabir.s@demo.com',  '+91 91234 00006',
      className: '12-B Maths',    classroomId: _c2, rollNo: '#01206',
      risk: 'HIGH', age: 18, g1: 8, g2: 7, absences: 12, failures: 2,
      studytime: 1, health: 2, dalc: 3, walc: 4, internet: 1, schoolsup: 0,
      riskScore: 79, dropoutProb: 79.3,
      riskFactors: ['Multiple failures', 'Low focus', 'High stress score'],
      recommendation: 'Refer to school counselor. Schedule parent meeting.',
      teacherRemark: 'Seems stressed. Does not participate in class.',
      mentalHealth: 35, stress: 5, focus: 2, motivation: 2, incidents: 2, lastIncident: 'Walked out of class',
    ),
    // HIGH
    _student('s_sneha_joshi',    'Sneha Joshi',   'sneha@demo.com',    '+91 91234 00007',
      className: '12-B Maths',    classroomId: _c2, rollNo: '#01207',
      risk: 'HIGH', age: 17, g1: 7, g2: 6, absences: 11, failures: 1,
      studytime: 1, health: 3, dalc: 1, walc: 2, internet: 0, schoolsup: 0,
      riskScore: 76, dropoutProb: 76.8,
      riskFactors: ['No internet access', 'Declining grades', 'Low attendance'],
      recommendation: 'Connect with NGO for digital access support. Assign remedial classes.',
      teacherRemark: 'Struggles without digital resources. Falls behind quickly.',
      mentalHealth: 45, stress: 4, focus: 2, motivation: 2, incidents: 1, lastIncident: 'Did not submit assignment',
    ),
    // MEDIUM
    _student('s_dev_malhotra',   'Dev Malhotra',  'dev@demo.com',      '+91 91234 00008',
      className: '12-B Maths',    classroomId: _c2, rollNo: '#01208',
      risk: 'MEDIUM', age: 17, g1: 12, g2: 10, absences: 8, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 2, internet: 1, schoolsup: 0,
      riskScore: 51, dropoutProb: 51.5,
      riskFactors: ['Grade declining trend', 'Behaviour incidents noted'],
      recommendation: 'Monitor closely. Recommend peer mentor.',
      teacherRemark: 'Shows potential but inconsistent effort.',
      mentalHealth: 60, stress: 3, focus: 3, motivation: 3, incidents: 2, lastIncident: 'Arguing with classmates',
    ),
    // LOW
    _student('s_priya_iyer',     'Priya Iyer',    'priya.s@demo.com',  '+91 91234 00009',
      className: '12-B Maths',    classroomId: _c2, rollNo: '#01209',
      risk: 'LOW', age: 17, g1: 14, g2: 13, absences: 4, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 19, dropoutProb: 19.5,
      riskFactors: ['Minor grade dip'],
      recommendation: 'Continue current support level.',
      teacherRemark: 'Good student. Slight decline last month.',
      mentalHealth: 72, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),
    // NONE
    _student('s_aditya_bose',    'Aditya Bose',   'aditya@demo.com',   '+91 91234 00010',
      className: '12-B Maths',    classroomId: _c2, rollNo: '#01210',
      risk: 'NONE', age: 17, g1: 17, g2: 18, absences: 2, failures: 0,
      studytime: 4, health: 5, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 7, dropoutProb: 7.0,
      riskFactors: [],
      recommendation: 'Continue current support level. Maintain regular monitoring.',
      teacherRemark: 'High performer. Class representative.',
      mentalHealth: 85, stress: 1, focus: 5, motivation: 5, incidents: 0, lastIncident: '',
    ),

    // ── CLASS 11-A ENGLISH (Ms. Ananya Gupta) ───────────────────────────

    // HIGH
    _student('s_zara_ali',       'Zara Ali',      'zara.a@demo.com',   '+91 91234 00011',
      className: '11-A English',  classroomId: _c3, rollNo: '#01211',
      risk: 'HIGH', age: 16, g1: 8, g2: 7, absences: 12, failures: 1,
      studytime: 1, health: 2, dalc: 2, walc: 3, internet: 1, schoolsup: 0,
      riskScore: 77, dropoutProb: 77.4,
      riskFactors: ['High mental health risk score', 'Attendance below threshold', 'Low grades'],
      recommendation: 'Refer to mental health counseling immediately. Notify parents.',
      teacherRemark: 'Appears withdrawn. Rarely interacts with peers.',
      mentalHealth: 28, stress: 5, focus: 1, motivation: 1, incidents: 3, lastIncident: 'Crying in class',
    ),
    // MEDIUM
    _student('s_rohan_verma',    'Rohan Verma',   'rohan.v@demo.com',  '+91 91234 00012',
      className: '11-A English',  classroomId: _c3, rollNo: '#01212',
      risk: 'MEDIUM', age: 16, g1: 11, g2: 10, absences: 8, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 2, internet: 1, schoolsup: 1,
      riskScore: 48, dropoutProb: 48.2,
      riskFactors: ['Attendance slipping', 'Stress levels elevated'],
      recommendation: 'Check in with student weekly. Monitor quiz scores.',
      teacherRemark: 'Decent student but showing early warning signs.',
      mentalHealth: 55, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Skipped afternoon session',
    ),
    // MEDIUM
    _student('s_ananya_singh',   'Ananya Singh',  'ananya.s@demo.com', '+91 91234 00013',
      className: '11-A English',  classroomId: _c3, rollNo: '#01213',
      risk: 'MEDIUM', age: 16, g1: 12, g2: 11, absences: 7, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 46, dropoutProb: 46.0,
      riskFactors: ['Grade decline trend', 'Moderate absenteeism'],
      recommendation: 'Assign peer mentor. Schedule parent check-in call.',
      teacherRemark: 'Previously strong student. Gradual decline over past month.',
      mentalHealth: 60, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Incomplete assignment',
    ),
    // LOW
    _student('s_kiran_reddy',    'Kiran Reddy',   'kiran@demo.com',    '+91 91234 00014',
      className: '11-A English',  classroomId: _c3, rollNo: '#01214',
      risk: 'LOW', age: 16, g1: 14, g2: 14, absences: 4, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 20, dropoutProb: 20.0,
      riskFactors: ['Mild stress noted'],
      recommendation: 'Continue current support level.',
      teacherRemark: 'Consistent and hardworking.',
      mentalHealth: 74, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),
    // NONE
    _student('s_fatema_ali',     'Fatema Ali',    'fatema.s@demo.com', '+91 91234 00015',
      className: '11-A English',  classroomId: _c3, rollNo: '#01215',
      risk: 'NONE', age: 16, g1: 19, g2: 18, absences: 0, failures: 0,
      studytime: 4, health: 5, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 3, dropoutProb: 3.2,
      riskFactors: [],
      recommendation: 'Continue current support level. Maintain regular monitoring.',
      teacherRemark: 'Top of class. Excellent work ethic.',
      mentalHealth: 92, stress: 1, focus: 5, motivation: 5, incidents: 0, lastIncident: '',
    ),

    // ── CLASS 11-B COMMERCE (Mr. Kabir Patel) ───────────────────────────

    // HIGH
    _student('s_mohit_kumar',    'Mohit Kumar',   'mohit@demo.com',    '+91 91234 00016',
      className: '11-B Commerce', classroomId: _c4, rollNo: '#01216',
      risk: 'HIGH', age: 17, g1: 7, g2: 5, absences: 14, failures: 3,
      studytime: 1, health: 1, dalc: 4, walc: 5, internet: 0, schoolsup: 0,
      riskScore: 91, dropoutProb: 91.0,
      riskFactors: ['Critical absenteeism', 'Multiple failures', 'Very low grades', 'High alcohol consumption risk'],
      recommendation: 'Urgent family intervention required. Refer to counselor and NGO support.',
      teacherRemark: 'Rarely attends. When present, appears disengaged and troubled.',
      mentalHealth: 22, stress: 5, focus: 1, motivation: 1, incidents: 4, lastIncident: 'Found sleeping in class repeatedly',
    ),
    // HIGH
    _student('s_pooja_rao',      'Pooja Rao',     'pooja@demo.com',    '+91 91234 00017',
      className: '11-B Commerce', classroomId: _c4, rollNo: '#01217',
      risk: 'HIGH', age: 16, g1: 9, g2: 7, absences: 11, failures: 1,
      studytime: 1, health: 2, dalc: 1, walc: 2, internet: 1, schoolsup: 0,
      riskScore: 75, dropoutProb: 75.5,
      riskFactors: ['Attendance below threshold', 'Significant grade decline'],
      recommendation: 'Schedule parent meeting. Assign remedial support.',
      teacherRemark: 'Shows effort occasionally but cannot keep up.',
      mentalHealth: 40, stress: 4, focus: 2, motivation: 2, incidents: 2, lastIncident: 'Left exam early',
    ),
    // MEDIUM
    _student('s_rahul_nair',     'Rahul Nair',    'rahul@demo.com',    '+91 91234 00018',
      className: '11-B Commerce', classroomId: _c4, rollNo: '#01218',
      risk: 'MEDIUM', age: 16, g1: 12, g2: 11, absences: 8, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 2, internet: 1, schoolsup: 0,
      riskScore: 50, dropoutProb: 50.0,
      riskFactors: ['Grade slipping', 'Moderate absences'],
      recommendation: 'Assign peer mentor. Weekly check-ins.',
      teacherRemark: 'Trying hard but needs more support.',
      mentalHealth: 62, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Late to class repeatedly',
    ),
    // MEDIUM
    _student('s_sara_khan',      'Sara Khan',     'sara@demo.com',     '+91 91234 00019',
      className: '11-B Commerce', classroomId: _c4, rollNo: '#01219',
      risk: 'MEDIUM', age: 16, g1: 11, g2: 10, absences: 9, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 1, internet: 1, schoolsup: 1,
      riskScore: 52, dropoutProb: 52.3,
      riskFactors: ['Attendance slipping', 'Quiz scores declining'],
      recommendation: 'Monitor quiz performance. Recommend counseling check-in.',
      teacherRemark: 'Generally good attitude but struggling this semester.',
      mentalHealth: 55, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Missed group project submission',
    ),
    // LOW
    _student('s_nikhil_gupta',   'Nikhil Gupta',  'nikhil@demo.com',   '+91 91234 00020',
      className: '11-B Commerce', classroomId: _c4, rollNo: '#01220',
      risk: 'LOW', age: 16, g1: 15, g2: 14, absences: 3, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 18, dropoutProb: 18.0,
      riskFactors: ['Minor stress elevation'],
      recommendation: 'Continue current support level.',
      teacherRemark: 'Strong student. Small dip in quiz scores.',
      mentalHealth: 76, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),

    // ── CLASS 10-A SCIENCE (Ms. Zara Khan) ──────────────────────────────

    // HIGH
    _student('s_ishaan_pillai',  'Ishaan Pillai', 'ishaan@demo.com',   '+91 91234 00021',
      className: '10-A Science',  classroomId: _c5, rollNo: '#01221',
      risk: 'HIGH', age: 15, g1: 8, g2: 6, absences: 13, failures: 2,
      studytime: 1, health: 2, dalc: 2, walc: 3, internet: 0, schoolsup: 0,
      riskScore: 83, dropoutProb: 83.1,
      riskFactors: ['Very high absenteeism', 'Multiple failures', 'No internet at home'],
      recommendation: 'Financial and digital access support needed. Parent intervention urgent.',
      teacherRemark: 'Comes from difficult home background. Needs holistic support.',
      mentalHealth: 30, stress: 5, focus: 1, motivation: 1, incidents: 3, lastIncident: 'Did not appear for unit test',
    ),
    // MEDIUM
    _student('s_deepa_menon',    'Deepa Menon',   'deepa@demo.com',    '+91 91234 00022',
      className: '10-A Science',  classroomId: _c5, rollNo: '#01222',
      risk: 'MEDIUM', age: 15, g1: 12, g2: 11, absences: 7, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 1, internet: 1, schoolsup: 1,
      riskScore: 47, dropoutProb: 47.0,
      riskFactors: ['Grade slipping', 'Moderate absenteeism'],
      recommendation: 'Schedule parent meeting. Assign remedial support if grades drop further.',
      teacherRemark: 'Capable student going through a rough patch.',
      mentalHealth: 58, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Submitted late work',
    ),
    // MEDIUM
    _student('s_vikram_chandra', 'Vikram Chandra','vikram@demo.com',   '+91 91234 00023',
      className: '10-A Science',  classroomId: _c5, rollNo: '#01223',
      risk: 'MEDIUM', age: 15, g1: 11, g2: 10, absences: 8, failures: 0,
      studytime: 2, health: 3, dalc: 1, walc: 2, internet: 1, schoolsup: 0,
      riskScore: 49, dropoutProb: 49.5,
      riskFactors: ['Attendance dipping', 'Grades under pressure'],
      recommendation: 'Peer mentor assignment recommended. Weekly attendance check.',
      teacherRemark: 'Tries hard but easily distracted.',
      mentalHealth: 56, stress: 3, focus: 3, motivation: 3, incidents: 1, lastIncident: 'Distracted during practicals',
    ),
    // LOW
    _student('s_layla_sheikh',   'Layla Sheikh',  'layla@demo.com',    '+91 91234 00024',
      className: '10-A Science',  classroomId: _c5, rollNo: '#01224',
      risk: 'LOW', age: 15, g1: 15, g2: 15, absences: 3, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 16, dropoutProb: 16.5,
      riskFactors: ['Minor quiz dip'],
      recommendation: 'Continue current support level.',
      teacherRemark: 'Reliable student. Maintains good attendance.',
      mentalHealth: 78, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),
    // LOW
    _student('s_omar_farooq',    'Omar Farooq',   'omar@demo.com',     '+91 91234 00025',
      className: '10-A Science',  classroomId: _c5, rollNo: '#01225',
      risk: 'LOW', age: 15, g1: 13, g2: 13, absences: 4, failures: 0,
      studytime: 3, health: 4, dalc: 1, walc: 1, internet: 1, schoolsup: 0,
      riskScore: 21, dropoutProb: 21.0,
      riskFactors: ['Slight attendance concern'],
      recommendation: 'Continue current support level. Monitor attendance.',
      teacherRemark: 'Good student. Punctual and attentive.',
      mentalHealth: 73, stress: 2, focus: 4, motivation: 4, incidents: 0, lastIncident: '',
    ),
  ];

  // ── ATTENDANCE PATTERN (15 bools: true=present, false=absent) ──────────

  static List<bool> _attendancePattern(String risk) {
    switch (risk) {
      case 'HIGH':
      // ~7 present out of 15
        return [true,false,false,true,false,true,false,false,true,false,true,false,false,true,false];
      case 'MEDIUM':
      // ~10 present out of 15
        return [true,true,false,true,true,false,true,false,true,true,false,true,true,false,true];
      case 'LOW':
      // ~12 present out of 15
        return [true,true,true,false,true,true,true,true,false,true,true,true,false,true,true];
      default: // NONE
      // ~14-15 present out of 15
        return [true,true,true,true,true,true,false,true,true,true,true,true,true,true,true];
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  static Timestamp _ts(DateTime dt) => Timestamp.fromDate(dt);

  /// Convenience factory so each student definition stays on one readable block.
  static Map<String, dynamic> _student(
      String id,
      String name,
      String email,
      String phone, {
        required String className,
        required String classroomId,
        required String rollNo,
        required String risk,
        required int    age,
        required int    g1,
        required int    g2,
        required int    absences,
        required int    failures,
        required int    studytime,
        required int    health,
        required int    dalc,
        required int    walc,
        required int    internet,
        required int    schoolsup,
        required int    riskScore,
        required double dropoutProb,
        required List<String> riskFactors,
        required String recommendation,
        required String teacherRemark,
        required int    mentalHealth,
        required int    stress,
        required int    focus,
        required int    motivation,
        required int    incidents,
        required String lastIncident,
      }) =>
      {
        'id':               id,
        'name':             name,
        'email':            email,
        'phone':            phone,
        'className':        className,
        'classroomId':      classroomId,
        'rollNo':           rollNo,
        'risk':             risk,
        'age':              age,
        'g1':               g1,
        'g2':               g2,
        'absences':         absences,
        'failures':         failures,
        'studytime':        studytime,
        'health':           health,
        'dalc':             dalc,
        'walc':             walc,
        'internet':         internet,
        'schoolsup':        schoolsup,
        'riskScore':        riskScore,
        'dropoutProbability': dropoutProb,
        'riskFactors':      riskFactors,
        'recommendation':   recommendation,
        'teacherRemark':    teacherRemark,
        'mentalHealthScore': mentalHealth,
        'stressLevel':      stress,
        'focusLevel':       focus,
        'motivationLevel':  motivation,
        'incidentCount':    incidents,
        'lastIncident':     lastIncident,
      };
}