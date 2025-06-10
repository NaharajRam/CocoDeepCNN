import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoadingPage extends StatefulWidget {
  final Uint8List imageData;

  const LoadingPage({super.key, required this.imageData});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _uploadImageAndPredict();
  }

  Future<void> _uploadImageAndPredict() async {
    try {
      // ✅ Replace this with the correct URL for your platform
      final uri = Uri.parse('http://127.0.0.1:5000/predict');

      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          widget.imageData,
          filename: 'image.jpg',
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final predictionData = jsonDecode(responseBody);

        final label = predictionData['label'];
        final confidence = predictionData['confidence'];

        Navigator.pushReplacementNamed(
          context,
          '/result',
          arguments: {
            'image': widget.imageData,
            'prediction': {
              'label': label,
              'confidence': confidence,
            },
          },
        );
      } else {
        _showError("Prediction failed: ${response.statusCode}");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Home
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loading...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("Please wait, processing the image..."),
            const SizedBox(height: 20),
            Image.memory(
              widget.imageData,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}