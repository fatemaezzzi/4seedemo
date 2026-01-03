//Copy this code in your flutter project's main.dart file

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: ScanAttendanceScreen()));
}

class ScanAttendanceScreen extends StatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  State<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends State<ScanAttendanceScreen> {
  File? _selectedImage;
  String _resultText = "Scan an image to see results";
  bool _isLoading = false;

  // IMPORTANT: Change this depending on how you run the app
  // Emulator: 'http://10.0.2.2:8000/scan'
  // Real Device: 'http://192.168.X.X:8000/scan' (Check your laptop's local IP)
  final String apiUrl = 'http://192.168.1.37:8000/scan';

  Future<void> _pickAndScanImage() async {
    final picker = ImagePicker();
    // Pick image from camera
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _isLoading = true;
      _resultText = "Uploading and processing...";
    });

    try {
      // 1. Create the request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // 2. Attach the file (The key 'file' must match your Python code: file: UploadFile)
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // 3. Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // 4. Parse Success Result
        var data = jsonDecode(response.body);
        // data is a list of objects: [{"text": "...", "confidence": ...}]

        // Just listing the text found for now
        List<dynamic> items = data;
        String extractedText = items.map((i) => i['text']).join("\n");

        setState(() {
          _resultText = "Found:\n$extractedText";
        });
      } else {
        setState(() {
          _resultText = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Connection Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forsee Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Preview Area
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _selectedImage == null
                  ? const Icon(Icons.image, size: 100, color: Colors.grey)
                  : Image.file(_selectedImage!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),

            // Scan Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndScanImage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(
                _isLoading ? "Processing..." : "Scan Attendance Sheet",
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Results Area
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _resultText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
