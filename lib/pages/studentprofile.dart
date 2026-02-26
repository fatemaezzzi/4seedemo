import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38), // Your plum background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. HEADER SECTION (Name and Profile Image)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dhruv Rathee',
                        style: TextStyle(
                          color: Color(0xFFF4BFDB),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pridi',
                        ),
                      ),
                      const Text(
                        '#01245',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      // Info Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA8D0BC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Std 5th | 91+ 9375459378',
                          style: TextStyle(color: Color(0xFF3B2F2F), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  // Profile Picture with Red Border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text('Reports', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // 2. REPORT TABS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTab('Semester'),
                  _buildTab('Weekly'),
                  _buildTab('Monthly'),
                ],
              ),

              const SizedBox(height: 20),

              // 3. BEHAVIOUR INCIDENT BUTTON
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFA6768B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    'Behaviour Incident',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 4. RISK BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFA8D0BC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HIGH RISK; ATTENTION NEEDED',
                      style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF3B2F2F)),
                    ),
                    Text('Attendance < 60%', style: TextStyle(color: Color(0xFF3B2F2F))),
                    Text('Math Scores Declined by 15%', style: TextStyle(color: Color(0xFF3B2F2F))),
                    Text('Behaviour - Low Focus', style: TextStyle(color: Color(0xFF3B2F2F))),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 5. AI SUGGESTIONS BOX
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA6768B), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI Suggestions', style: TextStyle(color: Color(0xFFF4BFDB), fontSize: 20, fontWeight: FontWeight.bold)),
                        Row(
                          children: List.generate(5, (i) => Icon(Icons.star, color: i < 4 ? Colors.orange : Colors.white70, size: 20)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Assign Peer Mentor\nRecommend Remedial Classes\nParent Meeting', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 6. SUPPORT & RESOURCES SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFA6768B),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Support & Resources', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildResourceCard('NGO', 'assets/imagesfor4see/ri_shake-hands-fill.png'),
                        const SizedBox(width: 10),
                        _buildResourceCard('Financial Support', 'assets/imagesfor4see/iconoir_wallet-solid.png', isDoubleLine: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildResourceCard('Counseling', 'assets/imagesfor4see/mage_message-round.png'),
                        const SizedBox(width: 10),
                        _buildResourceCard('Mental Health', null, isTextOnly: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA6768B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResourceCard(String title, String? assetPath, {bool isDoubleLine = false, bool isTextOnly = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4BFDB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (!isTextOnly && assetPath != null)
              Image.asset(assetPath, height: 24, color: const Color(0xFF3B2F2F)),
            if (!isTextOnly) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                textAlign: isTextOnly ? TextAlign.center : TextAlign.left,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B2F2F)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}