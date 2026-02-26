import 'package:flutter/material.dart';
// Ensure this matches the exact filename you created for the review page
import 'package:forc/pages/ReviewSubmitPage.dart';

class UploadHubPage extends StatefulWidget {
  const UploadHubPage({super.key});

  @override
  State<UploadHubPage> createState() => _UploadHubPageState();
}

class _UploadHubPageState extends State<UploadHubPage> {
  // Mock data representing your student list
  final List<Map<String, String>> studentMarks = [
    {"roll": "2090013", "name": "Dhruv Rathee"},
    {"roll": "2090014", "name": "Sourav Joshi"},
    {"roll": "2090015", "name": "Dhinchak Pooja"},
    {"roll": "2090016", "name": "Nishchay Malhan"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38), // Your project plum background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // --- HEADER SECTION ---
            const Text(
              "Upload Hub",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pridi',
              ),
            ),
            const Text(
              "Entering marks for: Mid-Term I (Max: 50)",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 25),

            // --- TABLE HEADER ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFA6768B), // Muted pink header
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text("Marks Obtained", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),

            // --- STUDENT LIST (SCROLLABLE TABLE) ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: ListView.builder(
                  itemCount: studentMarks.length,
                  itemBuilder: (context, index) {
                    return _buildMarksRow(
                      studentMarks[index]['roll']!,
                      studentMarks[index]['name']!,
                    );
                  },
                ),
              ),
            ),

            // --- BOTTOM NAVIGATION BUTTON ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _nextButton(context, "Next: Review & Submit"),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE ROW FOR STUDENT MARKS ---
  Widget _buildMarksRow(String roll, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(roll, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 2, child: Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
          Expanded(
            flex: 1,
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "00",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ORANGE BOTTOM BUTTON ---
  Widget _nextButton(BuildContext context, String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // Navigates to the Review and Submit Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReviewSubmitPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFCC80), // Orange/Yellow mirror color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}