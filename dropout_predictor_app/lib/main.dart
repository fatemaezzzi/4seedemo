import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropout Predictor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PredictorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PredictorScreen extends StatefulWidget {
  const PredictorScreen({super.key});

  @override
  State<PredictorScreen> createState() => _PredictorScreenState();
}

class _PredictorScreenState extends State<PredictorScreen> {
  String _result = 'Tap Predict to test API';
  bool _loading = false;

  /// Same JSON as in your screenshot
  final Map<String, dynamic> _features = {
    "absences": 1,
    "G1": 1,
    "G2": 2,
    "G3": 2,
    "failures": 6,
    "age": 18,
    "Medu": 2,
    "Fedu": 2,
    "famsize": 0,
    "Pstatus": 1,
    "famsup": 0,
    "studytime": 2,
    "goout": 4,
    "Dalc": 2,
    "Walc": 3,
    "health": 3,
    "school": 0,
    "address": 1,
    "internet": 1,
  };

  Future<void> _predict() async {
    setState(() => _loading = true);

    try {
      final response = await http.post(
        // For Flutter WEB use localhost; for Android emulator use 10.0.2.2
        Uri.parse('http://localhost:5000/predict'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'features': _features}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result =
              'Risk: ${(data['dropout_risk'] * 100).toStringAsFixed(1)}%\n'
              'Prediction: ${data['prediction'] == 1 ? "DROPOUT" : "Safe"}';
        });
      } else {
        setState(() => _result = 'Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _result = 'Connection failed: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dropout Predictor')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Features sent to API (example values):\n'
                'absences=1, G1=1, G2=2, G3=2, failures=6, age=18,\n'
                'Medu=2, Fedu=2, famsize=0, Pstatus=1, famsup=0,\n'
                'studytime=2, goout=4, Dalc=2, Walc=3, health=3,\n'
                'school=0, address=1, internet=1',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _predict,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Predict Dropout Risk',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
