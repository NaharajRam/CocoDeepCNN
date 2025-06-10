import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File



import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Page')),
      body: Center(child: const Text('Welcome to Coconut Disease Detector!')),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  late XFile? _image;

  // Function to select an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = pickedFile;
    });

    if (_image != null) {
      // Convert image to Uint8List and navigate to loading screen
      final imageBytes = await _image!.readAsBytes();
      Navigator.pushNamed(context, '/loading', arguments: imageBytes);
    }
  }

  // Display the selected image depending on the platform
  Widget _displayImage() {
    if (_image == null) {
      return const Text('No image selected.');
    }

    // If it's a web platform, use Image.memory, otherwise use Image.file for mobile
    if (kIsWeb) {
      // For Web, use asynchronous readAsBytes
      return FutureBuilder<Uint8List>(
        future: _image!.readAsBytes(), // Asynchronous for web
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading while fetching image
          } else if (snapshot.hasError) {
            return const Text('Error loading image.');
          } else if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            );
          } else {
            return const Text('Error loading image.');
          }
        },
      );
    } else {
      // For Mobile, use Image.file for native platforms
      return Image.file(
        File(_image!.path),
        height: 150,
        width: 150,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coconut Disease Detector")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            _displayImage(), // Display the selected image
          ],
        ),
      ),
    );
  }
}
