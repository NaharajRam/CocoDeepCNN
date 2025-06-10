import 'package:flutter/services.dart' show rootBundle;

Future<List<String>> loadLabels() async {
  // Load the labels from the asset file
  String labels = await rootBundle.loadString('assets/labels.txt');
  
  // Split the content by new lines and return as a list of strings
  return labels.split('\n');
}
