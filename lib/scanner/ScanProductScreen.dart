import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ScanResultScreen.dart';

class ScanProductScreen extends StatefulWidget {
    final int userId; // Add userId parameter
  const ScanProductScreen({super.key,required this.userId});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _availableCameras = [];
  late int userId;
  @override
  void initState() {
    super.initState();
    userId = widget.userId; 
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Fetch available cameras when initializing the screen
      _availableCameras = await availableCameras();

      if (_availableCameras.isEmpty) {
        print('No cameras found on this device.');
        // Optionally show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found on this device.')),
          );
        }
        return;
      }

      // Select the first available camera (usually the back camera)
      _controller = CameraController(
        _availableCameras[0],
        ResolutionPreset.medium, // Adjust resolution as needed
        enableAudio: false, // No audio needed for product scanning
      );

      // Initialize the controller
      _initializeControllerFuture = _controller!.initialize();

      // Ensure the widget is still mounted before calling setState
      if (mounted) {
        setState(() {}); // Rebuild to show the camera preview
      }
    } on CameraException catch (e) {
      print('Error initializing camera: ${e.code}\nError Message: ${e.description}');
      // Handle camera initialization errors (e.g., permissions denied)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: ${e.description}')),
        );
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture(BuildContext context) async {
    // Check if the controller is initialized and ready
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera not initialized yet.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready. Please wait.')),
      );
      return;
    }

    try {
      // Ensure the camera is initialized before taking a picture
      await _initializeControllerFuture;

      // Attempt to take a picture and get the file `image`
      final XFile imageFile = await _controller!.takePicture();

      // If the picture was taken, display it on the ScanResultScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(imageFile: File(imageFile.path),userId: userId),
          ),
        );
      }
    } catch (e) {
      // If an error occurs, log it to the console and show a SnackBar.
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color from the image
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "SCAN PRODUCT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Scanner UI with Camera Preview
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // If the Future is complete, display the preview.
                        // Check if controller is not null and initialized
                        if (_controller != null && _controller!.value.isInitialized) {
                          // Define the inner padding for the camera preview
                          const double innerPadding = 20.0; // Adjust as needed
                          return Container(
                            width: 280, // Adjust width as needed
                            height: 280, // Adjust height as needed
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomPaint(
                              // Pass the inner padding to the painter
                              painter: ScannerFramePainter(innerPadding: innerPadding),
                              child: Center( // Center the camera preview
                                child: ClipRRect( // Clip the camera preview to the rounded corners
                                  borderRadius: BorderRadius.circular(5), // Match inner container's border radius
                                  child: Container(
                                    width: 280 - (innerPadding * 2), // Calculate actual width for preview
                                    height: 280 - (innerPadding * 2), // Calculate actual height for preview
                                    child: AspectRatio(
                                      aspectRatio: _controller!.value.aspectRatio,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Fallback if controller is null or not initialized after Future.done
                          return Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'Camera not available',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        }
                      } else {
                        // Otherwise, display a loading indicator.
                        return Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              child: GestureDetector(
                onTap: () => _takePicture(context), // Call _takePicture
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw the scanner frame
class ScannerFramePainter extends CustomPainter {
  final double innerPadding;

  ScannerFramePainter({this.innerPadding = 0.0}); // Add innerPadding parameter

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white // White lines for the scanner frame
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    const double cornerLength = 30.0; // Length of the corner lines
    const double outerBorderRadius = 10.0; // Should match the container's border radius

    // --- Draw Outer Corners (around the grey container) ---
    // Top-left corner
    canvas.drawLine(Offset(outerBorderRadius, outerBorderRadius), Offset(outerBorderRadius + cornerLength, outerBorderRadius), paint);
    canvas.drawLine(Offset(outerBorderRadius, outerBorderRadius), Offset(outerBorderRadius, outerBorderRadius + cornerLength), paint);

    // Top-right corner
    canvas.drawLine(Offset(size.width - outerBorderRadius, outerBorderRadius), Offset(size.width - outerBorderRadius - cornerLength, outerBorderRadius), paint);
    canvas.drawLine(Offset(size.width - outerBorderRadius, outerBorderRadius), Offset(size.width - outerBorderRadius, outerBorderRadius + cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(outerBorderRadius, size.height - outerBorderRadius), Offset(outerBorderRadius + cornerLength, size.height - outerBorderRadius), paint);
    canvas.drawLine(Offset(outerBorderRadius, size.height - outerBorderRadius), Offset(outerBorderRadius, size.height - outerBorderRadius - cornerLength), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width - outerBorderRadius, size.height - outerBorderRadius), Offset(size.width - outerBorderRadius - cornerLength, size.height - outerBorderRadius), paint);
    canvas.drawLine(Offset(size.width - outerBorderRadius, size.height - outerBorderRadius), Offset(size.width - outerBorderRadius, size.height - outerBorderRadius - cornerLength), paint);


    // --- Draw Inner Corners (around the camera preview) ---
    final double innerRectLeft = innerPadding;
    final double innerRectTop = innerPadding;
    final double innerRectRight = size.width - innerPadding;
    final double innerRectBottom = size.height - innerPadding;

    // Inner Top-left corner
    canvas.drawLine(Offset(innerRectLeft, innerRectTop), Offset(innerRectLeft + cornerLength, innerRectTop), paint);
    canvas.drawLine(Offset(innerRectLeft, innerRectTop), Offset(innerRectLeft, innerRectTop + cornerLength), paint);

    // Inner Top-right corner
    canvas.drawLine(Offset(innerRectRight, innerRectTop), Offset(innerRectRight - cornerLength, innerRectTop), paint);
    canvas.drawLine(Offset(innerRectRight, innerRectTop), Offset(innerRectRight, innerRectTop + cornerLength), paint);

    // Inner Bottom-left corner
    canvas.drawLine(Offset(innerRectLeft, innerRectBottom), Offset(innerRectLeft + cornerLength, innerRectBottom), paint);
    canvas.drawLine(Offset(innerRectLeft, innerRectBottom), Offset(innerRectLeft, innerRectBottom - cornerLength), paint);

    // Inner Bottom-right corner
    canvas.drawLine(Offset(innerRectRight, innerRectBottom), Offset(innerRectRight - cornerLength, innerRectBottom), paint);
    canvas.drawLine(Offset(innerRectRight, innerRectBottom), Offset(innerRectRight, innerRectBottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if the innerPadding changes
    return oldDelegate is ScannerFramePainter && oldDelegate.innerPadding != innerPadding;
  }
}