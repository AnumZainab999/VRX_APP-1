import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../error_dialog.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRX Medicine Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const ComparePage(),
    );
  }
}

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  _ComparePageState createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Uint8List? _originalImage;
  Uint8List? _referenceImage;
  String? _verdict;
  bool _isFetching = false;
  String _backendMessage = '';
  String? _medicineName;
  final _nameController = TextEditingController();
  String? _selectedSide;
  final _formKey = GlobalKey<FormState>();

  final List<String> _sides = ['Front', 'Back', 'Left', 'Right'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> pickAndVerifyImage() async {
    if (_selectedSide == null) {
      showSnack('Please select a side');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        showSnack('No image selected');
        return;
      }

      final Uint8List? imageBytes = await image.readAsBytes();
      if (imageBytes == null) {
        showSnack('Failed to load image bytes');
        return;
      }

      setState(() {
        _originalImage = imageBytes;
        _referenceImage = null;
        _verdict = null;
        _backendMessage = '';
        _medicineName = null;
      });

      await fetchBackendResult(imageBytes);
    } catch (e) {
      showSnack('Error picking image: $e');
    }
  }

  Future<void> fetchBackendResult(Uint8List imageBytes) async {
    setState(() {
      _isFetching = true;
      _backendMessage = '';
    });

    try {
      final uri = Uri.parse('https://pharmacy-backend-qqwedwvhq-komal-anums-projects.vercel.app/api/verify');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );

      request.fields['side'] = _selectedSide!.toLowerCase();
      request.fields['name'] = _nameController.text.trim().toLowerCase();

      final response = await request.send();
      final responseStr = await response.stream.bytesToString();
      final data = json.decode(responseStr) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final verdict = data['verdict'] as String?;
        final blurry = data['blurry'] as bool?;
        final referenceImage = data['filename'] as String?;
        final medicineName = data['medicineName'] as String?;

        if (blurry == true) {
          ErrorDialog.showByCode(context, 'VRX-010');
        }

        if (verdict != null && referenceImage != null) {
          final referenceImageUrl =
              'https://kzhbzvkfpjftklzcydze.supabase.co/storage/v1/object/public/medicine-sideimages/$referenceImage';
          final imageResponse = await http.get(Uri.parse(referenceImageUrl));
          if (imageResponse.statusCode == 200) {
            setState(() {
              _verdict = verdict;
              _referenceImage = imageResponse.bodyBytes;
              _backendMessage = blurry == true
                  ? 'Image is blurry, result may be unreliable'
                  : 'Verification completed';
              _medicineName = medicineName;
            });
          } else {
            ErrorDialog.showByCode(context, 'VRX-012');
          }
        } else {
          ErrorDialog.showByCode(context, 'VRX-004');
        }
      } else {
        final err = data['error']?.toString().toLowerCase();
        if (err?.contains("blurry") == true || err?.contains("corrupt") == true) {
          ErrorDialog.showByCode(context, 'VRX-010');
        } else if (err?.contains("sync") == true) {
          ErrorDialog.showByCode(context, 'VRX-012');
        } else {
          showSnack(data['error'] ?? 'Verification failed');
        }
      }
    } catch (e) {
      ErrorDialog.showByCode(context, 'VRX-007');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void showSnack(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Widget _buildImageCard(Uint8List? imageBytes, String label) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              )
            : Center(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
      ),
    );
  }

  Widget _buildResultWidget() {
    if (_verdict == null) return const SizedBox();

    return Column(
      children: [
        Icon(
          _verdict == "Authentic" ? Icons.verified : Icons.warning_amber_rounded,
          color: _verdict == "Authentic" ? Colors.green : Colors.red,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          _verdict == "Authentic" ? "Authentic Medicine" : "Authentication Failed!",
          style: TextStyle(
            fontSize: 20,
            color: _verdict == "Authentic" ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_medicineName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Medicine: $_medicineName',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
        if (_backendMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _backendMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VRX Medicine Check"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Verify Medicine",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: _selectedSide,
                      hint: const Text("Select Side"),
                      items: _sides.map((side) {
                        return DropdownMenuItem(value: side, child: Text(side));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSide = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a side' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        hintText: 'e.g., Panadol',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter medicine name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(children: [_buildImageCard(_originalImage, 'Uploaded'), const SizedBox(height: 8), const Text("Uploaded Image")]),
                        Column(children: [_buildImageCard(_referenceImage, 'AI Result'), const SizedBox(height: 8), const Text("AI Result")]),
                      ],
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Image"),
                      onPressed: _isFetching ? null : pickAndVerifyImage,
                    ),
                    const SizedBox(height: 30),
                    _isFetching
                        ? const Column(
                            children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Processing...")],
                          )
                        : _buildResultWidget(),
                  ],
                ),
              ),
            ),
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DISCLAIMER", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                SizedBox(height: 8),
                Text(
                  "This tool uses AI to assist in identifying medicine images. It does not replace professional medical advice.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}