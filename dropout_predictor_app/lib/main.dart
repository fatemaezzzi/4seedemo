import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const DropoutPredictorApp());

class DropoutPredictorApp extends StatelessWidget {
  const DropoutPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  // Expanded Controllers for ALL requested features
  final Map<String, TextEditingController> _controllers = {
    "absences": TextEditingController(text: "10"),
    "G1": TextEditingController(text: "10"),
    "G2": TextEditingController(text: "7"),
    "failures": TextEditingController(text: "2"),
    "age": TextEditingController(text: "19"),
    "Medu": TextEditingController(text: "1"),
    "Fedu": TextEditingController(text: "1"),
    "studytime": TextEditingController(text: "1"),
    "famsup": TextEditingController(text: "0"),
    "health": TextEditingController(text: "2"),
    "Dalc": TextEditingController(text: "4"),
    "Walc": TextEditingController(text: "4"),
    "goout": TextEditingController(text: "5"),
    "famsize": TextEditingController(text: "0"),
    "Pstatus": TextEditingController(text: "0"),
    "school": TextEditingController(text: "0"),
    "address": TextEditingController(text: "0"),
    "internet": TextEditingController(text: "0"),
    "schoolsup": TextEditingController(text: "1"),
  };

  Future<void> _getPrediction() async {
    setState(() => _isLoading = true);
    
    // Construct the data object dynamically from all controllers
    final Map<String, int> featureMap = {};
    _controllers.forEach((key, controller) {
      featureMap[key] = int.tryParse(controller.text) ?? 0;
    });

    final studentData = {"data": featureMap};

    try {
      // Use 10.0.2.2 for Android Emulator. Use localhost for Web/iOS.
      final response = await http.post(
        Uri.parse('http://localhost:5000/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        setState(() => _result = jsonDecode(response.body));
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Risk Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_result != null) _buildResultCard(),
          ],
        ),
      )
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Comprehensive Student Metrics", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              // Grid for inputs to keep the form compact
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
                onPressed: _getPrediction,
                icon: const Icon(Icons.analytics),
                label: const Text("Run Prediction"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final pred = _result!['prediction'];
    final Color riskColor = pred['risk_level'] == 'HIGH' ? Colors.red : 
                            pred['risk_level'] == 'MEDIUM' ? Colors.orange : Colors.green;

    return Card(
      color: riskColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("${pred['emoji']} ${pred['risk_level']} RISK", 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: riskColor)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: pred['risk_score'],
              backgroundColor: Colors.grey[300],
              color: riskColor,
              minHeight: 12,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Probability: ${pred['dropout_probability']}%"),
                Text("Confidence: ${pred['confidence']}"),
              ],
            ),
            const Divider(),
            Text("Recommendation: ${pred['recommendation']}", 
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Top Risk Factors:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...(_result!['risk_factors'] as List).map((f) => Align(
              alignment: Alignment.centerLeft,
              child: Text("• $f"),
            )).toList(),
          ],
        ),
      ),
    );
  }
}