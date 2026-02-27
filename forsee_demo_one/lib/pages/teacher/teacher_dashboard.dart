import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:forsee_demo_one/pages/teacher/classroom_page.dart';
import 'package:forsee_demo_one/controllers/auth_controller.dart';
import 'package:forsee_demo_one/app/routes/app_routes.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final String teacherName = "Rupali";
  late PageController _pageController;
  double _currentPage = 0.0;

  // ── DATA ────────────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _riskyStudents = [
    {
      'name': 'Aryan Mehta',
      'class': '12-B',
      'risk': 'High',
      'reason': 'Frequent absences',
      'color': Colors.red,
    },
    {
      'name': 'Priya Sharma',
      'class': '10-A',
      'risk': 'Medium',
      'reason': 'Declining grades',
      'color': Colors.orange,
    },
    {
      'name': 'Rahul Nair',
      'class': '9-C',
      'risk': 'High',
      'reason': 'Behavioural flags',
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New Alert',
      'body': 'Aryan Mehta missed 3 consecutive classes.',
      'time': '10 min ago',
      'read': false,
    },
    {
      'title': 'Grade Drop',
      'body': "Priya Sharma's score dropped below 50%.",
      'time': '1 hr ago',
      'read': false,
    },
    {
      'title': 'Report Ready',
      'body': 'Weekly class report for 12-B is ready.',
      'time': '3 hrs ago',
      'read': true,
    },
    {
      'title': 'Parent Message',
      'body': "Rahul Nair's parent requested a meeting.",
      'time': 'Yesterday',
      'read': true,
    },
  ];

  final List<Map<String, dynamic>> _classrooms = [
    {
      'title': 'Class 12-B',
      'subject': 'Science',
      'semester': 'Semester II',
      'std': 'STD 12th',
      'participants': 24,
      'color': const Color(0xFF382128),
      'textColor': Colors.white,
    },
    {
      'title': 'Class 10-A',
      'subject': 'Mathematics',
      'semester': 'Semester I',
      'std': 'STD 10th',
      'participants': 30,
      'color': const Color(0xFFA6768B),
      'textColor': Colors.white,
    },
    {
      'title': 'Class 9-C',
      'subject': 'English',
      'semester': 'Semester II',
      'std': 'STD 9th',
      'participants': 28,
      'color': const Color(0xFFF4BFDB),
      'textColor': Colors.black,
    },
  ];

  // ── LIFECYCLE ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7, initialPage: 0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── NOTIFICATION PANEL ──────────────────────────────────────────────────────

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final unread = _notifications.where((n) => !n['read']).length;
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B2028),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pridi',
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9C2D7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread new',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF512D38),
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (unread > 0)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    for (var n in _notifications) {
                                      n['read'] = true;
                                    }
                                  });
                                  setSheetState(() {});
                                },
                                child: const Text(
                                  'Mark all read',
                                  style: TextStyle(
                                    color: Color(0xFFE9C2D7),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) {
                            final n = _notifications[i];
                            return GestureDetector(
                              onTap: () {
                                setState(() => _notifications[i]['read'] = true);
                                setSheetState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: n['read']
                                      ? const Color(0xFF4A3439)
                                      : const Color(0xFF6B3F50),
                                  borderRadius: BorderRadius.circular(14),
                                  border: n['read']
                                      ? null
                                      : Border.all(
                                      color: const Color(0xFFE9C2D7),
                                      width: 1),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: n['read']
                                        ? Colors.white12
                                        : const Color(0xFFE9C2D7),
                                    child: Icon(
                                      n['read']
                                          ? Icons.notifications_none
                                          : Icons.notifications_active,
                                      color: n['read']
                                          ? Colors.white54
                                          : const Color(0xFF512D38),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    n['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: n['read']
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontFamily: 'Pridi',
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['body'],
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n['time'],
                                        style: const TextStyle(
                                            color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── PROFILE SHEET ───────────────────────────────────────────────────────────

  void _openProfile() {
    Get.toNamed(AppRoutes.TEACHER_PROFILE, arguments: {'name': teacherName});
  }

  // ── RISKY STUDENT DETAIL ────────────────────────────────────────────────────

  void _showRiskyStudentDetail(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3B2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: student['color'].withOpacity(0.2),
              child: Icon(Icons.person, color: student['color'], size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                student['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontFamily: 'Pridi',
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Class', student['class']),
            const SizedBox(height: 8),
            _detailRow('Risk Level', student['risk'], valueColor: student['color']),
            const SizedBox(height: 8),
            _detailRow('Reason', student['reason']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: Color(0xFFE9C2D7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9C2D7),
              foregroundColor: const Color(0xFF512D38),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Profile',
                style: TextStyle(fontFamily: 'Pridi')),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

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
              const Text(
                'My Classrooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pridi',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: _classrooms.length,
                  itemBuilder: (context, index) {
                    double relativePosition = index - _currentPage;
                    double scale =
                    (1 - (relativePosition.abs() * 0.2)).clamp(0.8, 1.0);
                    double opacity =
                    (1 - (relativePosition.abs() * 0.5)).clamp(0.5, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: _buildClassCard(index),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Welcome $teacherName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pridi',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            // Notification bell with badge
            GestureDetector(
              onTap: _openNotifications,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/imagesfor4see/mingcute_notification-fill.png',
                    height: 24,
                    color: Colors.white,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Profile icon
            GestureDetector(
              onTap: _openProfile,
              child: Image.asset(
                'assets/imagesfor4see/iconamoon_profile-fill.png',
                height: 24,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── ATTENTION SECTION ───────────────────────────────────────────────────────

  Widget _buildAttentionSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ATTENTION',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFA6768B),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _riskyStudents.isEmpty
                  ? const Center(
                child: Text(
                  'No risky students at the moment',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
                itemCount: _riskyStudents.length,
                itemBuilder: (_, i) {
                  final s = _riskyStudents[i];
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
                          color: s['color'].withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: s['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                s['risk'],
                                style: TextStyle(
                                  color: s['color'],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            s['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Pridi',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s['reason'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: -10,
          right: -15,
          child: Image.asset(
            'assets/imagesfor4see/Curly Arrow.png',
            height: 60,
          ),
        ),
      ],
    );
  }

  // ── CLASS CARD ──────────────────────────────────────────────────────────────

  Widget _buildClassCard(int index) {
    final classroom = _classrooms[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassroomPage(
              classTitle: classroom['title'],
              subject: classroom['subject'],
              semester: classroom['semester'],
              std: classroom['std'],
              participants: classroom['participants'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: classroom['color'],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom['title'],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pridi',
                      color: classroom['textColor'],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    classroom['subject'],
                    style: TextStyle(
                      fontSize: 15,
                      color: classroom['textColor'].withOpacity(0.7),
                      fontFamily: 'Pridi',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${classroom['participants']} students',
                    style: TextStyle(
                      fontSize: 13,
                      color: classroom['textColor'].withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 25,
              right: 25,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.greenAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}