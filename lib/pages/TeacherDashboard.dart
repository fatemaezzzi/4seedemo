import 'package:flutter/material.dart';
// Ensure this import matches your actual filename in the pages folder
import 'package:forc/pages/classroompage.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final String teacherName = "Rupali";
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.7 allows side cards to "peek" in
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38), // Your project plum background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
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

              // Classroom Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    double relativePosition = index - _currentPage;
                    double scale = (1 - (relativePosition.abs() * 0.2)).clamp(0.8, 1.0);
                    double opacity = (1 - (relativePosition.abs() * 0.5)).clamp(0.5, 1.0);

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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Welcome $teacherName!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pridi',
          ),
        ),
        Row(
          children: [
            Image.asset(
              'assets/imagesfor4see/mingcute_notification-fill.png',
              height: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 15),
            Image.asset(
              'assets/imagesfor4see/iconamoon_profile-fill.png',
              height: 24,
              color: Colors.white,
            ),
          ],
        )
      ],
    );
  }

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
              child: const Center(
                child: Text(
                  "Risky students will appear here",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
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

  // This connects your "Class 12-B" card to the ClassroomPage
  Widget _buildClassCard(int index) {
    final colors = [const Color(0xFF382128), const Color(0xFFA6768B), const Color(0xFFF4BFDB)];
    final titles = ["Class 12-B", "Class 10-A", "Class 9-C"];

    return GestureDetector(
      onTap: () {
        // Navigates to the ClassroomPage when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClassroomPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors[index],
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
              child: Text(
                titles[index],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pridi',
                  color: colors[index] == const Color(0xFFF4BFDB) ? Colors.black : Colors.white,
                ),
              ),
            ),
            const Positioned(
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