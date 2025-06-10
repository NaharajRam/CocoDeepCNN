import 'dart:typed_data';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Uint8List imageData;
  final Map? prediction;

  const ResultPage({
    Key? key,
    required this.imageData,
    this.prediction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = prediction?['label'] ?? 'Unknown';
    final confidence = prediction?['confidence'] != null
        ? (prediction!['confidence'] * 100).toStringAsFixed(2)
        : 'N/A';

    final confidenceLevel = double.tryParse(confidence.replaceAll('%', '')) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediction Result"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context, '/home', (route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Predicted Disease:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Label: $label',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 5),
              Text(
                'Confidence: $confidence%',
                style: TextStyle(
                  fontSize: 18,
                  color: confidenceLevel > 70
                      ? Colors.green
                      : confidenceLevel > 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageData,
                  fit: BoxFit.contain,
                  height: 300,
                ),
              ),
              const SizedBox(height: 30),
              if (confidenceLevel < 50)
                Text(
                  'Confidence is low. Please try again with a clearer image.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false,
                  );
                },
                child: const Text("Try Another Image"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
