import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dropout Predictor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PredictorScreen(),
    );
  }
}

class PredictorScreen extends StatefulWidget {
  @override
  _PredictorScreenState createState() => _PredictorScreenState();
}

class _PredictorScreenState extends State<PredictorScreen> {
  String _result = 'Tap Predict to test API';
  bool _loading = false;

  // 6 features: [absences, G1, G2, G3, studytime, failures]
  Future<void> _predict() async {
    setState(() => _loading = true);
    
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.102flu:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'features': [5, 15, 16, 14, 2, 0]}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = 'Risk: ${(data['dropout_risk'] * 100).toStringAsFixed(1)}%\nPrediction: ${data['prediction'] == 1 ? "DROPOUT" : "Safe"}';
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
      appBar: AppBar(title: Text('Student Dropout Predictor')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Features: absences=5, G1=15, G2=16, G3=14, studytime=2, failures=0', 
                   textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _predict,
                child: _loading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Predict Dropout Risk', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
