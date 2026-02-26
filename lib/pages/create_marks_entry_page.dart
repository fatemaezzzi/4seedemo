import 'package:flutter/material.dart';
import 'package:forc/pages/UploadHubPage.dart';
import 'package:intl/intl.dart'; // Add this to pubspec.yaml for date formatting

class CreateMarksEntryPage extends StatefulWidget {
  const CreateMarksEntryPage({super.key});

  @override
  State<CreateMarksEntryPage> createState() => _CreateMarksEntryPageState();
}

class _CreateMarksEntryPageState extends State<CreateMarksEntryPage> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF512D38), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Color(0xFF3B2F2F), // Body text
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF512D38),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Create New Marks Entry", style: TextStyle(fontFamily: 'Pridi', color: Colors.white)),
        actions: [const Icon(Icons.add_circle_outline, color: Colors.white), const SizedBox(width: 20)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildField("Exam Title:", "e.g. Mid-Term I"),

            // --- CALENDAR PICKER FIELD ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Date of Exam:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate == null ? "Select Date" : DateFormat('dd/MM/yyyy').format(selectedDate!),
                          style: TextStyle(color: selectedDate == null ? Colors.black45 : Colors.black),
                        ),
                        const Icon(Icons.calendar_month, color: Color(0xFF512D38)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),

            _buildField("Maximum Marks:", "50"),
            const Spacer(),
            _bottomButton(context, "Next: Enter Scores", const UploadHubPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

Widget _bottomButton(BuildContext context, String text, Widget destination) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFCC80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    ),
  );
}