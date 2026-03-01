import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forsee_demo_one/pages/teacher/classroom_page.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';
import 'package:forsee_demo_one/pages/teacher/add_classroom_page.dart';

// ── DATA MODELS ───────────────────────────────────────────────────────────────

class _RiskyStudent {
  final String studentId;
  final String name;
  final String classId;
  final String riskLevel;
  final List<String> riskFactors;
  final String recommendation;

  const _RiskyStudent({
    required this.studentId,
    required this.name,
    required this.classId,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendation,
  });

  Color get color {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      default:       return Colors.greenAccent;
    }
  }

  String get reason => riskFactors.isNotEmpty ? riskFactors.first : 'Risk detected';
}

class _ClassroomData {
  final String classId;
  final String title;
  final int totalStudents;
  final int highRiskCount;
  final int mediumRiskCount;

  const _ClassroomData({
    required this.classId,
    required this.title,
    required this.totalStudents,
    required this.highRiskCount,
    required this.mediumRiskCount,
  });

  String get overallRisk {
    if (highRiskCount > 0)   return 'HIGH';
    if (mediumRiskCount > 0) return 'MEDIUM';
    return 'LOW';
  }

  Color get riskDotColor {
    switch (overallRisk) {
      case 'HIGH':   return Colors.redAccent;
      case 'MEDIUM': return Colors.orangeAccent;
      default:       return Colors.greenAccent;
    }
  }
}

class _AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  bool read;

  _AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });
}

// ── COLORS ────────────────────────────────────────────────────────────────────

const _cardColors = [
  Color(0xFF382128),
  Color(0xFFA6768B),
  Color(0xFFF4BFDB),
];
const _cardTextColors = [Colors.white, Colors.white, Colors.black];

// ── DASHBOARD ─────────────────────────────────────────────────────────────────

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late PageController _pageController;
  double _currentPage = 0.0;

  bool    _loading = true;
  String? _error;

  String _teacherName = '';
  String _teacherId   = '';

  List<_ClassroomData>   _classrooms    = [];
  List<_RiskyStudent>    _riskyStudents = [];
  List<_AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7, initialPage: 0);
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page ?? 0.0);
    });
    _loadDashboard();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── DATA LOADING ─────────────────────────────────────────────────────────────

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('Teacher profile not found');

      _teacherName = (userDoc.data()!['name'] as String?) ?? 'Teacher';
      _teacherId   = uid;

      // ── Step 1: Load classrooms (for classroom cards only) ─────────────────
      final classroomsSnap = await _db.collection('classrooms').get();

      final Map<String, List<String>> classStudents   = {};
      final Map<String, String>       classroomTitles = {};

      for (final doc in classroomsSnap.docs) {
        final data      = doc.data();
        final classCode = data['classCode'] as String?;
        final key       = (classCode != null && classCode.isNotEmpty)
            ? classCode : doc.id;
        classStudents[key]   = List<String>.from(
            (data['studentIds'] as List<dynamic>?) ?? []);
        classroomTitles[key] = data['title'] as String? ?? key;
      }

      // ── Step 2: Query students/ DIRECTLY by riskLevel ──────────────────────
      // OLD approach depended on classrooms.studentIds matching exactly —
      // if those IDs were wrong, zero students loaded → Attention always empty.
      // NEW: query Firestore directly for riskLevel field.
      // student_model.dart stores riskLevel as lowercase: 'high','medium','low'

      final highSnap = await _db
          .collection('students')
          .where('riskLevel', isEqualTo: 'high')
          .get();

      final medSnap = await _db
          .collection('students')
          .where('riskLevel', isEqualTo: 'medium')
          .get();

      // ── Step 3: Build risky students list from query results ───────────────
      final Map<String, _RiskyStudent> riskMap = {};

      for (final doc in [...highSnap.docs, ...medSnap.docs]) {
        final data        = doc.data();
        final firestoreId = doc.id;
        final riskStr     = (data['riskLevel'] as String? ?? '').toUpperCase();

        if (riskStr != 'HIGH' && riskStr != 'MEDIUM') continue;

        final name = data['name'] as String? ?? 'Unknown';

        // Find which classroom this student belongs to (best effort)
        final classId = classStudents.entries
            .firstWhere(
              (e) => e.value.contains(firestoreId),
          orElse: () => const MapEntry('', <String>[]),
        )
            .key;

        // Risk factors from student doc (written by prediction service)
        final factors = List<String>.from(
            (data['riskFactors'] as List<dynamic>?) ?? []);

        // Build factors from raw numbers if not stored yet
        if (factors.isEmpty) {
          final totalDays   = (data['totalDays']   as num?)?.toInt() ?? 0;
          final presentDays = (data['presentDays'] as num?)?.toInt() ?? 0;
          final avgMarks    = (data['averageMarks'] as num?)?.toDouble() ?? 100.0;
          final incidents   = (data['incidentCount'] as num?)?.toInt() ?? 0;

          if (totalDays > 0) {
            final pct = (presentDays / totalDays) * 100;
            if (pct < 75) factors.add('Attendance ${pct.toStringAsFixed(0)}% — below threshold');
          }
          if (avgMarks < 65)  factors.add('Marks ${avgMarks.toStringAsFixed(0)}% — below average');
          if (incidents > 0)  factors.add('$incidents behaviour incident${incidents > 1 ? 's' : ''} logged');
          if (factors.isEmpty) factors.add('Risk detected — review student data');
        }

        final rec = data['recommendation'] as String? ?? '';

        riskMap[firestoreId] = _RiskyStudent(
          studentId:      firestoreId,
          name:           name,
          classId:        classId,
          riskLevel:      riskStr,
          riskFactors:    factors,
          recommendation: rec,
        );
      }

      // ── Step 4: Build classroom cards with correct risk counts ─────────────
      final List<_ClassroomData> classrooms = [];
      for (final entry in classStudents.entries) {
        final classId    = entry.key;
        final studentIds = entry.value;

        int highCount = 0, medCount = 0;
        for (final sid in studentIds) {
          final risk = riskMap[sid]?.riskLevel;
          if (risk == 'HIGH')   highCount++;
          if (risk == 'MEDIUM') medCount++;
        }

        classrooms.add(_ClassroomData(
          classId:         classId,
          title:           classroomTitles[classId] ?? classId,
          totalStudents:   studentIds.length,
          highRiskCount:   highCount,
          mediumRiskCount: medCount,
        ));
      }

      classrooms.sort((a, b) {
        const order = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2};
        return (order[a.overallRisk] ?? 3).compareTo(order[b.overallRisk] ?? 3);
      });

      // ── Step 5: Sort risky list — HIGH first ──────────────────────────────
      final riskyList = riskMap.values.toList()
        ..sort((a, b) {
          const order = {'HIGH': 0, 'MEDIUM': 1};
          return (order[a.riskLevel] ?? 2).compareTo(order[b.riskLevel] ?? 2);
        });

      // ── Step 6: Build notifications ───────────────────────────────────────
      final List<_AppNotification> notifications = [];
      for (final s in riskyList.where((s) => s.riskLevel == 'HIGH')) {
        notifications.add(_AppNotification(
          id:    s.studentId,
          title: '⚠️ High Risk Alert',
          body:  '${s.name} has been flagged as HIGH risk. ${s.reason}',
          time:  DateTime.now(),
          read:  false,
        ));
      }
      for (final s in riskyList.where((s) => s.riskLevel == 'MEDIUM')) {
        notifications.add(_AppNotification(
          id:    '${s.studentId}_med',
          title: 'Medium Risk',
          body:  '${s.name} is at medium risk. Monitor closely.',
          time:  DateTime.now().subtract(const Duration(hours: 1)),
          read:  false,
        ));
      }

      setState(() {
        _classrooms    = classrooms;
        _riskyStudents = riskyList;
        _notifications = notifications;
        _loading       = false;
      });

    } catch (e) {
      setState(() {
        _error   = 'Failed to load dashboard: $e';
        _loading = false;
      });
    }
  }

  // ── TEMP: FIX RISK LEVELS FOR DEMO ───────────────────────────────────────────
  // Tap the red FIX button in the top-right header.
  // It directly writes riskLevel='high' to your first real student in Firestore,
  // then reloads the dashboard so Attention section shows them immediately.
  // DELETE _fixRiskLevels() AND the FIX button in _buildHeader after your demo.

  Future<void> _fixRiskLevels() async {
    final snap = await _db.collection('students').get();

    if (snap.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No students found in Firestore!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final docs = snap.docs;

    // First student → HIGH risk
    await _db.collection('students').doc(docs[0].id).set({
      'riskLevel':      'high',
      'riskFactors':    [
        'Attendance 52% — critically low',
        'Marks 35% — failing range',
        '3 behaviour incidents logged',
      ],
      'recommendation': 'URGENT: Call parents immediately. Schedule remedial sessions.',
      'totalDays':      15,
      'presentDays':    8,
      'averageMarks':   35.0,
      'incidentCount':  3,
    }, SetOptions(merge: true));

    // Second student → MEDIUM risk (if exists)
    if (docs.length > 1) {
      await _db.collection('students').doc(docs[1].id).set({
        'riskLevel':      'medium',
        'riskFactors':    [
          'Attendance 73% — below 75% threshold',
          '1 behaviour incident noted',
        ],
        'recommendation': 'Set up weekly check-ins. Send parent SMS update.',
        'totalDays':      15,
        'presentDays':    11,
        'averageMarks':   55.0,
        'incidentCount':  1,
      }, SetOptions(merge: true));
    }

    // Reload dashboard to show updated data immediately
    await _loadDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${docs[0].data()['name'] ?? docs[0].id} is now HIGH risk! Dashboard refreshed.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(
          i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  // ── ADD CLASSROOM ─────────────────────────────────────────────────────────────

  Future<void> _openAddClassroom() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddClassroomPage()),
    );
    if (result != null) {
      await _loadDashboard();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _classrooms.length - 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────────

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          final unread = _notifications.where((n) => !n.read).length;
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize:     0.9,
            minChildSize:     0.4,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF3B2028),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    const Text('Notifications',
                        style: TextStyle(color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold, fontFamily: 'Pridi')),
                    if (unread > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE9C2D7),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('$unread new',
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF512D38))),
                      ),
                    ],
                    const Spacer(),
                    if (unread > 0)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var n in _notifications) n.read = true;
                          });
                          setSheetState(() {});
                        },
                        child: const Text('Mark all read',
                            style: TextStyle(
                                color: Color(0xFFE9C2D7), fontSize: 13)),
                      ),
                  ]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _notifications.isEmpty
                      ? const Center(
                      child: Text('No notifications',
                          style: TextStyle(color: Colors.white38,
                              fontFamily: 'Pridi')))
                      : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _notifications[i].read = true);
                          setSheetState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: n.read
                                ? const Color(0xFF4A3439)
                                : const Color(0xFF6B3F50),
                            borderRadius: BorderRadius.circular(14),
                            border: n.read
                                ? null
                                : Border.all(
                                color: const Color(0xFFE9C2D7),
                                width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: n.read
                                  ? Colors.white12
                                  : const Color(0xFFE9C2D7),
                              child: Icon(
                                n.read
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                                color: n.read
                                    ? Colors.white54
                                    : const Color(0xFF512D38),
                                size: 20,
                              ),
                            ),
                            title: Text(n.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: n.read
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontFamily: 'Pridi',
                                  fontSize: 14,
                                )),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.body,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_timeAgo(n.time),
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── PROFILE ───────────────────────────────────────────────────────────────────

  void _openProfile() {
    Get.toNamed(AppRoutes.TEACHER_PROFILE,
        arguments: {'name': _teacherName});
  }

  // ── RISKY STUDENT DETAIL ──────────────────────────────────────────────────────

  void _showRiskyStudentDetail(_RiskyStudent student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: student.color.withOpacity(0.2),
            child: Icon(Icons.person, color: student.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(student.name,
              style: const TextStyle(color: Colors.white,
                  fontSize: 17, fontFamily: 'Pridi'))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Class',      'Class ${student.classId}'),
            const SizedBox(height: 8),
            _detailRow('Risk Level', student.riskLevel,
                valueColor: student.color),
            const SizedBox(height: 8),
            _detailRow('Reason',     student.reason),
            if (student.recommendation.isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow('Suggestion', student.recommendation),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFFE9C2D7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed(AppRoutes.STUDENT_REPORT, arguments: {
                'name':        student.name,
                'studentId':   student.studentId,
                'firestoreId': student.studentId,
                'standard':    '',
                'phone':       '',
                'className':   'Class ${student.classId}',
                'subject':     '',
                'riskLevel':   _riskLevelString(student.riskLevel),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Report',
                style: TextStyle(fontFamily: 'Pridi')),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(children: [
      Flexible(child: Text('$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 14))),
      Expanded(child: Text(value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold))),
    ]);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF512D38),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE9C2D7))),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF512D38),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontFamily: 'Pridi')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9C2D7)),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF512D38))),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(unreadCount),
              const SizedBox(height: 30),
              _buildAttentionSection(),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Classrooms',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pridi')),
                  GestureDetector(
                    onTap: _openAddClassroom,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA6768B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Expanded(
                child: _classrooms.isEmpty
                    ? Center(
                  child: GestureDetector(
                    onTap: _openAddClassroom,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA6768B).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Color(0xFFA6768B), size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('No classrooms yet',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                                fontFamily: 'Pridi')),
                        const SizedBox(height: 4),
                        const Text('Tap + to create one',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                )
                    : PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: _classrooms.length,
                  itemBuilder: (context, index) {
                    final rel     = index - _currentPage;
                    final scale   = (1 - (rel.abs() * 0.2)).clamp(0.8, 1.0);
                    final opacity = (1 - (rel.abs() * 0.5)).clamp(0.5, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                          opacity: opacity,
                          child: _buildClassCard(index)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text('Welcome $_teacherName!',
              style: const TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.bold, fontFamily: 'Pridi'),
              overflow: TextOverflow.ellipsis),
        ),
        Row(children: [

          // ── RED FIX BUTTON — tap once, then delete after demo ───────────────
          GestureDetector(
            onTap: _fixRiskLevels,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('FIX',
                  style: TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          // ── END FIX BUTTON ──────────────────────────────────────────────────

          GestureDetector(
            onTap: _openNotifications,
            child: Stack(clipBehavior: Clip.none, children: [
              Image.asset(
                  'assets/imagesfor4see/mingcute_notification-fill.png',
                  height: 24, color: Colors.white),
              if (unreadCount > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$unreadCount',
                          style: const TextStyle(fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _openProfile,
            child: Image.asset(
                'assets/imagesfor4see/iconamoon_profile-fill.png',
                height: 24, color: Colors.white),
          ),
        ]),
      ],
    );
  }

  // ── ATTENTION SECTION ─────────────────────────────────────────────────────────

  Widget _buildAttentionSection() {
    final highRiskStudents =
    _riskyStudents.where((s) => s.riskLevel == 'HIGH').toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('ATTENTION',
                style: TextStyle(color: Colors.white70, fontSize: 22,
                    fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            if (highRiskStudents.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  '${highRiskStudents.length} HIGH RISK',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
                color: const Color(0xFFA6768B),
                borderRadius: BorderRadius.circular(15)),
            child: highRiskStudents.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white54, size: 32),
                  const SizedBox(height: 8),
                  const Text('No high-risk students right now',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _loadDashboard,
                    child: const Text('Tap to refresh',
                        style: TextStyle(
                            color: Color(0xFFE9C2D7),
                            fontSize: 12,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 16),
              itemCount: highRiskStudents.length,
              itemBuilder: (_, i) {
                final s = highRiskStudents[i];
                return GestureDetector(
                  onTap: () => _showRiskyStudentDetail(s),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B2028),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: s.color.withOpacity(0.6),
                          width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(s.riskLevel,
                              style: TextStyle(color: s.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        Text(s.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pridi'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(s.reason,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
        Positioned(
          top: -10, right: -15,
          child: Image.asset(
              'assets/imagesfor4see/Curly Arrow.png', height: 60),
        ),
      ],
    );
  }

  // ── CLASS CARD ────────────────────────────────────────────────────────────────

  Widget _buildClassCard(int index) {
    final classroom  = _classrooms[index];
    final colorIndex = index % _cardColors.length;
    final bgColor    = _cardColors[colorIndex];
    final textColor  = _cardTextColors[colorIndex];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassroomPage(
            classTitle:   classroom.title,
            classroomId:  classroom.classId,
            subject:      '',
            semester:     'Semester I',
            std:          '',
            participants: classroom.totalStudents,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10))],
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classroom.title,
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pridi',
                        color: textColor)),
                const SizedBox(height: 6),
                Text('${classroom.totalStudents} students',
                    style: TextStyle(fontSize: 14,
                        color: textColor.withOpacity(0.7),
                        fontFamily: 'Pridi')),
                const SizedBox(height: 4),
                Text(
                  classroom.highRiskCount > 0
                      ? '${classroom.highRiskCount} high risk student${classroom.highRiskCount > 1 ? 's' : ''}'
                      : classroom.mediumRiskCount > 0
                      ? '${classroom.mediumRiskCount} medium risk student${classroom.mediumRiskCount > 1 ? 's' : ''}'
                      : 'All students on track',
                  style: TextStyle(
                      fontSize: 12, color: classroom.riskDotColor),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20, right: 20,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: classroom.riskDotColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: classroom.riskDotColor.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1)],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── HELPER ────────────────────────────────────────────────────────────────────

  String _riskLevelString(String level) {
    switch (level.toUpperCase()) {
      case 'HIGH':   return 'high';
      case 'MEDIUM': return 'medium';
      case 'LOW':    return 'low';
      default:       return 'none';
    }
  }
}