import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'label_check_service.dart';

class LabelCheckScreen extends StatefulWidget {
  const LabelCheckScreen({super.key});

  @override
  State<LabelCheckScreen> createState() => _LabelCheckScreenState();
}

class _LabelCheckScreenState extends State<LabelCheckScreen> {
  File? _image;
  String? _result;
  String? _reason;
  bool _loading = false;

  Future<void> _pickImageAndCheck() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _loading = true;
      _result = null;
      _reason = null;
    });

    final result = await LabelCheckService.checkLabel(_image!);

    setState(() {
      _loading = false;
      _result = result['result'];
      _reason = result['reason'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Label Checker')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_result != null)
              Column(
                children: [
                  Text(
                    _result == "real" ? "✅ Real Medicine" : "❌ Fake Medicine",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _result == "real" ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _reason ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _pickImageAndCheck,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Medicine Packaging'),
            ),
          ],
        ),
      ),
    );
  }
}
