import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SimpleAPITest extends StatefulWidget {
  const SimpleAPITest({super.key});

  @override
  State<SimpleAPITest> createState() => _SimpleAPITestState();
}

class _SimpleAPITestState extends State<SimpleAPITest> {
  // Base URL for your Hugging Face Space
  static const String BASE_URL = 'https://sliverstream8-4seedemo.hf.space/gradio_api';

  bool _isLoading = false;
  String _result = '';
  String _error = '';
  String _currentEndpoint = '';

  // Test multiple possible endpoints
  final List<String> _possibleEndpoints = [
    '/api/predict_student',
    '/call/predict_student',
    '/run/predict_student',
  ];

  Future<void> _testAPI() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    // Sample student data - formatted as plain JSON string for Gradio
    final testData = jsonEncode({
      "data": {
        "absences": 15,
        "G1": 8,
        "G2": 7,
        "failures": 2,
        "age": 18,
        "Medu": 2,
        "Fedu": 2,
        "studytime": 1,
        "famsup": 0,
        "health": 3,
        "Dalc": 4,
        "Walc": 4,
        "goout": 5,
        "famsize": 0,
        "Pstatus": 1,
        "school": 0,
        "address": 1,
        "internet": 1,
        "schoolsup": 0
      }
    });

    // Try each endpoint
    for (String endpoint in _possibleEndpoints) {
      final url = '$BASE_URL$endpoint';
      _currentEndpoint = url;

      try {
        print('\n📤 Trying: $url');

        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({"data": [testData]}), // Gradio expects array format
        ).timeout(const Duration(seconds: 30));

        print('📥 Status: ${response.statusCode}');
        print('📥 Body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          setState(() {
            _result = '✅ SUCCESS with endpoint: $endpoint\n\n'
                'Full URL: $url\n\n'
                'Response:\n${JsonEncoder.withIndent('  ').convert(jsonResponse)}';
          });
          setState(() => _isLoading = false);
          return; // Success! Stop trying
        }
      } catch (e) {
        print('❌ Failed with $endpoint: $e');
      }
    }

    // If all endpoints failed, try the Gradio prediction API format
    try {
      final gradioUrl = '$BASE_URL/api/predict';
      print('\n📤 Trying Gradio format: $gradioUrl');

      final response = await http.post(
        Uri.parse(gradioUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "data": [testData]
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _result = '✅ SUCCESS!\n\nFull Response:\n'
              '${JsonEncoder.withIndent('  ').convert(jsonResponse)}';
        });
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      print('❌ Gradio format failed: $e');
    }

    // All attempts failed
    setState(() {
      _error = '❌ All API endpoints failed!\n\n'
          'Tried:\n'
          '${_possibleEndpoints.map((e) => '  • $BASE_URL$e').join('\n')}\n\n'
          'Possible issues:\n'
          '1. Space is not running (check Hugging Face)\n'
          '2. Model not loaded (check logs)\n'
          '3. API endpoint changed\n\n'
          'Try opening this URL in browser:\n'
          '$BASE_URL';
      _isLoading = false;
    });
  }

  Future<void> _testSpaceStatus() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      print('📤 Checking if space is accessible: $BASE_URL');

      final response = await http.get(
        Uri.parse(BASE_URL),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _result = '✅ Space is accessible!\n\n'
              'Status Code: ${response.statusCode}\n'
              'The Hugging Face Space is running.\n\n'
              'Now try "Test API" to check the prediction endpoint.';
        });
      } else {
        setState(() {
          _error = '⚠️ Space returned status: ${response.statusCode}\n\n'
              'The space might be loading or having issues.';
        });
      }
    } catch (e) {
      setState(() {
        _error = '❌ Cannot reach space: $e\n\n'
            'Check if:\n'
            '1. You have internet connection\n'
            '2. The Hugging Face Space is running\n'
            '3. URL is correct: $BASE_URL';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 Hugging Face Space',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      BASE_URL,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Will test multiple API endpoints automatically',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Space Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSpaceStatus,
              icon: const Icon(Icons.public),
              label: const Text('1. Check Space Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 10),

            // Test API Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAPI,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : '2. Test API Prediction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Results
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Result
                    if (_result.isNotEmpty)
                      Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Result',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              SelectableText(
                                _result,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Error Result
                    if (_error.isNotEmpty)
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Error',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              SelectableText(
                                _error,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Instructions Card
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💡 Troubleshooting Steps:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. First click "Check Space Status"\n'
                                  '2. If successful, click "Test API Prediction"\n'
                                  '3. If both fail, check your Hugging Face Space:\n'
                                  '   • Is it showing "Running" (green)?\n'
                                  '   • Check the logs for errors\n'
                                  '   • Make sure model file is uploaded',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}