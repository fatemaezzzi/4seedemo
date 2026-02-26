import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async'; // Added for timeout handling
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class InputTestPage extends StatefulWidget {
  const InputTestPage({super.key});

  @override
  State<InputTestPage> createState() => _InputTestPageState();
}

class _InputTestPageState extends State<InputTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CHANGED: Using the /gradio_api/call/ endpoint which is standard for Spaces
  static const String API_URL =
      'https://sliverstream8-4seedemo.hf.space/gradio_api/call/predict_dropout';

  bool _isLoading = false;
  String _selectedStudentId = '';
  Map<String, dynamic>? _predictionResult;
  List<DocumentSnapshot> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // Load all students from Firestore
  Future<void> _loadStudents() async {
    try {
      final snapshot = await _firestore.collection('students').get();
      setState(() {
        _students = snapshot.docs;
      });
    } catch (e) {
      _showError('Failed to load students: $e');
    }
  }

  // --- CORE PREDICTION LOGIC START ---

  Future<void> _predictForStudent(String studentId) async {
    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      // 1. Get student data from Firestore
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) throw Exception('Student not found');
      final studentData = studentDoc.data()!;

      // 2. Prepare the inner data Map
      final innerDataMap = {
        "absences": studentData['absences'] ?? 0,
        "G1": studentData['G1'] ?? 0,
        "G2": studentData['G2'] ?? 0,
        "G3": studentData['G3'] ?? 0,
        "failures": studentData['failures'] ?? 0,
        "age": studentData['age'] ?? 0,
        "Medu": studentData['Medu'] ?? 0,
        "Fedu": studentData['Fedu'] ?? 0,
        "studytime": studentData['studytime'] ?? 0,
        "famsup": studentData['famsup'] ?? 0,
        "health": studentData['health'] ?? 0,
        "Dalc": studentData['Dalc'] ?? 0,
        "Walc": studentData['Walc'] ?? 0,
        "goout": studentData['goout'] ?? 0,
        "famsize": studentData['famsize'] ?? 0,
        "Pstatus": studentData['Pstatus'] ?? 0,
        "school": studentData['school'] ?? 0,
        "address": studentData['address'] ?? 0,
        "internet": studentData['internet'] ?? 0,
        "schoolsup": studentData['schoolsup'] ?? 0,
      };

      // 3. Serialize: Map -> String -> List
      // This fixes the 422 Error
      String jsonString = jsonEncode(innerDataMap);
      final apiPayload = { "data": [jsonString] };

      print('Step 1: Submitting Job to $API_URL');

      // 4. Step 1: POST to get Event ID
      final responseStep1 = await http.post(
        Uri.parse(API_URL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(apiPayload),
      ).timeout(const Duration(seconds: 30));

      if (responseStep1.statusCode != 200) {
        throw Exception('Step 1 Failed (${responseStep1.statusCode}): ${responseStep1.body}');
      }

      final step1Result = jsonDecode(responseStep1.body);
      String? eventId = step1Result['event_id'];

      if (eventId != null) {
        print('Step 2: Polling result for Event ID: $eventId');

        // 5. Step 2: GET the result stream
        final responseStep2 = await http.get(
          Uri.parse('$API_URL/$eventId'),
        ).timeout(const Duration(seconds: 45));

        if (responseStep2.statusCode == 200) {
          _parseGradioStream(responseStep2.body, studentId, studentData['name']);
        } else {
          throw Exception('Step 2 Failed: ${responseStep2.statusCode}');
        }
      } else {
        // Fallback for immediate responses
        _processDirectResponse(step1Result, studentId, studentData['name']);
      }

    } catch (e) {
      _showError('Prediction failed: $e');
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Parses the "data: [...]" line from the Gradio stream
  void _parseGradioStream(String body, String studentId, String studentName) {
    // The body usually looks like:
    // event: complete
    // data: ["{\"status\": \"success\", ...}"]

    final lines = body.split('\n');
    bool foundData = false;

    for (var line in lines) {
      if (line.startsWith('data: ')) {
        try {
          // Remove "data: " prefix
          String rawData = line.substring(6);
          final decoded = jsonDecode(rawData);

          // decoded is usually a List: [ "YOUR_RESULT_JSON_STRING" ]
          if (decoded is List && decoded.isNotEmpty) {
            var resultString = decoded[0];
            // If the inner item is a string, decode it again to get the Map
            var resultJson = (resultString is String) ? jsonDecode(resultString) : resultString;

            _saveAndDisplayResult(studentId, studentName, resultJson);
            foundData = true;
            break;
          }
        } catch (e) {
          print('Error parsing stream line: $e');
        }
      }
    }
    if (!foundData) throw Exception('No valid data found in API stream');
  }

  void _processDirectResponse(Map<String, dynamic> data, String sid, String sname) {
    if (data.containsKey('data')) {
      var inner = data['data'][0];
      var result = (inner is String) ? jsonDecode(inner) : inner;
      _saveAndDisplayResult(sid, sname, result);
    }
  }

  Future<void> _saveAndDisplayResult(String sid, String sname, Map<String, dynamic> result) async {
    if (result['status'] == 'success') {
      await _savePredictionToFirestore(sid, sname, result);
      setState(() {
        _predictionResult = result;
      });
      _showSuccess('Prediction saved successfully!');
    } else {
      throw Exception(result['error'] ?? 'Prediction failed');
    }
  }

  // --- CORE PREDICTION LOGIC END ---

  // Save prediction to Firestore
  Future<void> _savePredictionToFirestore(
      String studentId, String studentName, Map<String, dynamic> result) async {
    try {
      await _firestore.collection('predictions').add({
        'studentId': studentId,
        'studentName': studentName,
        'timestamp': FieldValue.serverTimestamp(),
        'risk_level': result['prediction']['risk_level'],
        'dropout_probability': result['prediction']['dropout_probability'],
        'risk_score': result['prediction']['risk_score'],
        'confidence': result['prediction']['confidence'],
        'recommendation': result['prediction']['recommendation'],
        'risk_factors': result['risk_factors'],
        'input_features': result['input_features'],
      });
    } catch (e) {
      print('Error saving prediction: $e');
    }
  }

  // View prediction history
  Future<void> _viewPredictionHistory(String studentId) async {
    final predictions = await _firestore
        .collection('predictions')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prediction History'),
        content: SizedBox(
          width: double.maxFinite,
          child: predictions.docs.isEmpty
              ? const Text('No predictions yet')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: predictions.docs.length,
            itemBuilder: (context, index) {
              final pred = predictions.docs[index].data();
              final timestamp = pred['timestamp'] as Timestamp?;
              return ListTile(
                title: Text('${pred['risk_level']} Risk'),
                subtitle: Text(
                  'Probability: ${pred['dropout_probability']}%\n'
                      '${timestamp != null ? timestamp.toDate().toString() : 'N/A'}',
                ),
                leading: Text(
                  pred['risk_level'] == 'HIGH' ? '🔴' :
                  pred['risk_level'] == 'MEDIUM' ? '🟡' : '🟢',
                  style: const TextStyle(fontSize: 24),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dropout Prediction'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: _students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final data = student.data() as Map<String, dynamic>;
                final isSelected = _selectedStudentId == student.id;

                return Card(
                  color: isSelected ? Colors.blue[50] : null,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(data['name']?[0] ?? '?'),
                    ),
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(
                      'Age: ${data['age']} | Absences: ${data['absences']} | '
                          'G1: ${data['G1']} | G2: ${data['G2']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () => _viewPredictionHistory(student.id),
                          tooltip: 'View History',
                        ),
                        IconButton(
                          icon: const Icon(Icons.analytics),
                          onPressed: _isLoading
                              ? null
                              : () {
                            setState(() => _selectedStudentId = student.id);
                            _predictForStudent(student.id);
                          },
                          tooltip: 'Predict',
                        ),
                      ],
                    ),
                    onTap: () => setState(() => _selectedStudentId = student.id),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Analyzing student data...'),
                ],
              ),
            ),
          if (_predictionResult != null && !_isLoading)
            _buildPredictionResult(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddStudentPage()),
        ).then((_) => _loadStudents()),
        child: const Icon(Icons.person_add),
        tooltip: 'Add Student',
      ),
    );
  }

  Widget _buildPredictionResult() {
    final pred = _predictionResult!['prediction'];
    final Color riskColor = pred['risk_level'] == 'HIGH'
        ? Colors.red
        : pred['risk_level'] == 'MEDIUM'
        ? Colors.orange
        : Colors.green;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "${pred['emoji']} ${pred['risk_level']} RISK",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: pred['risk_score'],
              backgroundColor: Colors.grey[300],
              color: riskColor,
              minHeight: 12,
            ),
            const SizedBox(height: 15),
            Text(
              'Dropout Probability: ${pred['dropout_probability']}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Confidence: ${pred['confidence']}'),
            const Divider(height: 20),
            Text(
              pred['recommendation'],
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 15),
            const Text(
              'Risk Factors:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...(_predictionResult!['risk_factors'] as List)
                .map((f) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('• $f'),
            ))
                .toList(),
          ],
        ),
      ),
    );
  }
}

// Add Student Page
class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {
    "absences": TextEditingController(text: "0"),
    "G1": TextEditingController(text: "0"),
    "G2": TextEditingController(text: "0"),
    "failures": TextEditingController(text: "0"),
    "age": TextEditingController(text: "15"),
    "Medu": TextEditingController(text: "2"),
    "Fedu": TextEditingController(text: "2"),
    "studytime": TextEditingController(text: "2"),
    "famsup": TextEditingController(text: "1"),
    "health": TextEditingController(text: "3"),
    "Dalc": TextEditingController(text: "1"),
    "Walc": TextEditingController(text: "1"),
    "goout": TextEditingController(text: "3"),
    "famsize": TextEditingController(text: "1"),
    "Pstatus": TextEditingController(text: "1"),
    "school": TextEditingController(text: "0"),
    "address": TextEditingController(text: "1"),
    "internet": TextEditingController(text: "1"),
    "schoolsup": TextEditingController(text: "0"),
  };

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final Map<String, dynamic> studentData = {
        'name': _nameController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      _controllers.forEach((key, controller) {
        studentData[key] = int.tryParse(controller.text) ?? 0;
      });

      await _firestore.collection('students').add(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  String key = _controllers.keys.elementAt(index);
                  return TextFormField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: key,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveStudent,
                icon: const Icon(Icons.save),
                label: const Text('Save Student'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}