import 'package:flutter/material.dart';

class ReviewSubmitPage extends StatelessWidget {
  const ReviewSubmitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Review & Submit", style: TextStyle(fontFamily: 'Pridi')),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Review Before Saving", style: TextStyle(color: Colors.white70)),
          ),
          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildStatCard("Total Students", "45"),
                const SizedBox(width: 15),
                _buildStatCard("Average Score", "38/50"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Summary Table
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                children: [
                  _row("2090013", "Dhruv Rathee", "45"),
                  _row("2090012", "Alph Sanan", "45"),
                ],
              ),
            ),
          ),
          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC80),
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text("Confirm & Publish Marks", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _row(String roll, String name, String marks) {
    return ListTile(
      title: Text(name),
      leading: Text(roll),
      trailing: Text(marks, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}