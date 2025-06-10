import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Coconut Disease Detector',
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  XFile? _imageFile;

  /// 1️⃣ Test connectivity to Flask `/ping`
  Future<void> _testPing() async {
    final uri = Uri.parse('http://127.0.0.1:5000/ping');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      print('PING status: ${resp.statusCode}, body: ${resp.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping: ${resp.body}')),
      );
    } catch (e) {
      print('Ping failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping error: $e')),
      );
    }
  }

  /// 2️⃣ Pick an image and navigate to LoadingPage
  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _imageFile = picked);
    final bytes = await picked.readAsBytes();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingPage(imageData: bytes),
      ),
    );
  }

  /// Display the selected image (memory for web, file for mobile)
  Widget _previewImage() {
    if (_imageFile == null) return const Text('No image selected');
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _imageFile!.readAsBytes(),
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          } else if (snap.hasError) {
            return Text('Error: ${snap.error}');
          }
          return Image.memory(snap.data!, height: 150, width: 150);
        },
      );
    }
    return Image.file(File(_imageFile!.path), height: 150, width: 150);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coconut Disease Detector')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testPing,
              child: const Text('Test Server Connection'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickAndUpload,
              child: const Text('Pick Image & Predict'),
            ),
            const SizedBox(height: 20),
            _previewImage(),
          ],
        ),
      ),
    );
  }
}

/// Shows spinner + image, calls `/predict`, logs response, navigates
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
    _uploadAndPredict();
  }

  Future<void> _uploadAndPredict() async {
    final uri = Uri.parse('http://127.0.0.1:5000/predict');
    print('→ Sending POST to $uri ...');
    var req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        widget.imageData,
        filename: 'image.jpg',
      ));
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      print('← Status code: ${streamed.statusCode}');
      final body = await streamed.stream.bytesToString();
      print('← Body: $body');

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              imageData: widget.imageData,
              prediction: data,
            ),
          ),
        );
      } else {
        _showError('Server error: ${streamed.statusCode}');
      }
    } catch (e) {
      print('⚠️ Upload error: $e');
      _showError('Network error: $e');
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Please wait, processing the image...'),
            const SizedBox(height: 20),
            Image.memory(widget.imageData, height: 150, width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Displays the prediction result
class ResultPage extends StatelessWidget {
  final Uint8List imageData;
  final Map<String, dynamic> prediction;
  const ResultPage({
    super.key,
    required this.imageData,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final label = prediction['label'] ?? 'Unknown';
    final conf = prediction['confidence']?.toStringAsFixed(2) ?? '0.00';
    return Scaffold(
      appBar: AppBar(title: const Text('Prediction Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.memory(imageData, height: 200, width: 200),
            const SizedBox(height: 20),
            Text('Label: $label', style: const TextStyle(fontSize: 20)),
            Text('Confidence: $conf', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
