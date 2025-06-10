import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _pickImage(BuildContext context, bool fromCamera) async {
    Uint8List? imageData;

    if (ui.PlatformDispatcher.instance.platformBrightness == Brightness.light) {
      // Web
      if (fromCamera) {
        final mediaDevices = html.window.navigator.mediaDevices;
        if (mediaDevices != null) {
          html.VideoElement video = html.VideoElement();
          video.setAttribute('autoplay', 'true');
          html.document.body?.append(video);
          await mediaDevices.getUserMedia({'video': true}).then((stream) {
            video.srcObject = stream;
          });
        }
      } else {
        final input = html.FileUploadInputElement()..accept = 'image/*';
        input.click();
        await input.onChange.first;
        final file = input.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;
          imageData = reader.result as Uint8List?;
        }
      }
    } else {
      // Mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);
      if (pickedFile != null) {
        imageData = await pickedFile.readAsBytes();
      }
    }

    if (imageData != null) {
      Navigator.pushNamed(context, '/loading', arguments: imageData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/welcome_page_coconut.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Coconut Tree Disease Prediction",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _pickImage(context, false),
                child: const Text("Upload Image"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(context, true),
                child: const Text("Capture Image"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
