
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrx_app/chat_screen.dart';
import 'error_dialog.dart'; // Import the ErrorDialog class

// Temporary SSL bypass for debugging
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ScanProductPage(),
    );
  }
}

// Constants
const kScanAreaPercentage = 0.8;
const kCornerSize = 40.0;
const kCornerLength = 30.0;
const kAnimationDuration = Duration(milliseconds: 300);

class ScanProductPage extends StatefulWidget {
  const ScanProductPage({super.key});

  @override
  _ScanProductPageState createState() => _ScanProductPageState();
}

class _ScanProductPageState extends State<ScanProductPage> with TickerProviderStateMixin {
  // State variables
  String? scannedCode;
  bool _isScanning = true;
  bool _showResultOptions = false;
  bool _torchEnabled = false;
  String _scanStatus = 'Focus';
  bool _isDesktop = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  bool _hasCameraPermission = false;
  bool _isCameraInitialized = false; // Track camera initialization

  // Controllers
  late MobileScannerController cameraController;
  late AnimationController _scanLineController;
  late AnimationController _flashController;
  late AnimationController _resultController;

  // Animations
  late Animation<double> _flashAnimation;
  late Animation<double> _resultAnimation;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _checkCameraPermission();
  }

  void _initializeControllers() {
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _flashController = AnimationController(
      duration: kAnimationDuration,
      vsync: this,
    );

    _resultController = AnimationController(
      duration: kAnimationDuration,
      vsync: this,
    );
  }

  void _initializeAnimations() {
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutBack),
    );

    _scanLineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
      if (mounted) {
        try {
          await cameraController.start();
          setState(() => _isCameraInitialized = true); // Mark camera as initialized
        } catch (e) {
          setState(() => _hasCameraPermission = false);
          ErrorDialog.showByCode(context, 'VRX-001');
        }
      }
    } else {
      setState(() => _hasCameraPermission = false);
      if (mounted) {
        ErrorDialog.showByCode(context, 'VRX-001');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDesktop = !(Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _flashController.dispose();
    _resultController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Skip processing if not scanning, not mounted, or camera not initialized
    if (!_isScanning || !mounted || !_isCameraInitialized) return;

    try {
      final barcode = capture.barcodes.firstOrNull;
      final rawValue = barcode?.rawValue;

      // Log for debugging
      if (kDebugMode) {
        print('Barcode Capture: ${capture.barcodes}');
        print('Raw Value: $rawValue');
      }

      // Check if barcode is valid and non-empty
      if (rawValue == null || rawValue.isEmpty) {
        // Silently return instead of showing error
        return;
      }

      setState(() {
        scannedCode = rawValue;
        _isScanning = false;
        _showResultOptions = true;
        _scanStatus = 'Detected';
      });

      _flashController.forward(from: 0.0);
      _resultController.forward(from: 0.0);
      cameraController.stop();
    } catch (e) {
      if (e.toString().contains('VRX-001')) {
        ErrorDialog.showByCode(context, 'VRX-001');
      } else {
        ErrorDialog.showByCode(context, 'VRX-002');
      }
    }
  }

  void _resetScan() {
    if (!mounted) return;

    setState(() {
      scannedCode = null;
      _isScanning = true;
      _showResultOptions = false;
      _scanStatus = 'Focus';
    });
    if (_hasCameraPermission) {
      cameraController.start().catchError((e) {
        ErrorDialog.showByCode(context, 'VRX-001');
      });
    } else {
      _checkCameraPermission();
    }
  }

  void _toggleTorch() {
    if (!mounted || _isDesktop || !_hasCameraPermission) return;
    setState(() => _torchEnabled = !_torchEnabled);
    cameraController.toggleTorch();
  }

  void _toggleCamera() {
    if (!mounted || _isDesktop || !_hasCameraPermission) return;
    setState(() {
      _cameraFacing = _cameraFacing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
    });
    cameraController.switchCamera();
  }

  void _proceedToNextPage() {
    if (!mounted || scannedCode == null) {
      ErrorDialog.showByCode(context, 'VRX-002');
      return;
    }

    cameraController.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineInfoPage(scannedCode: scannedCode!),
      ),
    ).then((_) => _resetScan());
  }

  void _manualInputBarcode() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode Manually'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter barcode number',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => _handleManualInput(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _handleManualInput(controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _handleManualInput(String value) {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a barcode!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      scannedCode = value;
      _isScanning = false;
      _showResultOptions = true;
      _scanStatus = 'Detected';
    });

    Navigator.pop(context);
    _flashController.forward(from: 0.0);
    _resultController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * kScanAreaPercentage;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        actions: _buildAppBarActions(),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: const Color(0xFFD3D8E8),
        child: Stack(
          children: [
            _buildScannerView(scanArea),
            _buildScannerOverlay(scanArea),
            if (_isScanning && _hasCameraPermission && _isCameraInitialized)
              _buildScanLineAnimation(scanArea),
            _buildFlashAnimation(),
            if (_showResultOptions) _buildResultOptions(scanArea),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (!_isDesktop && _hasCameraPermission)
        IconButton(
          icon: Icon(
            _torchEnabled ? Icons.flash_off : Icons.flash_on,
            color: Colors.white,
          ),
          onPressed: _toggleTorch,
        ),
      if (!_isDesktop && _hasCameraPermission)
        IconButton(
          icon: Icon(
            _cameraFacing == CameraFacing.back ? Icons.camera_front : Icons.camera_rear,
            color: Colors.white,
          ),
          onPressed: _toggleCamera,
        ),
    ];
  }

  Widget _buildScannerView(double scanArea) {
    if (!_hasCameraPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Camera permission is required to scan barcodes.',
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkCameraPermission,
              child: const Text('Request Permission'),
            ),
          ],
        ),
      );
    }
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              'Initializing camera...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: scanArea,
        height: scanArea,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            scanWindow: Rect.fromLTWH(0, 0, scanArea, scanArea), // Restrict scan area
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(double scanArea) {
    return Center(
      child: SizedBox(
        width: scanArea,
        height: scanArea,
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, child: _buildCorner(CornerAlignment.topLeft)),
            Positioned(top: 0, right: 0, child: _buildCorner(CornerAlignment.topRight)),
            Positioned(bottom: 0, left: 0, child: _buildCorner(CornerAlignment.bottomLeft)),
            Positioned(bottom: 0, right: 0, child: _buildCorner(CornerAlignment.bottomRight)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(CornerAlignment alignment) {
    return SizedBox(
      width: kCornerSize,
      height: kCornerSize,
      child: CustomPaint(
        painter: CornerPainter(alignment),
      ),
    );
  }

  Widget _buildScanLineAnimation(double scanArea) {
    return Center(
      child: SizedBox(
        width: scanArea,
        height: scanArea,
        child: AnimatedBuilder(
          animation: _scanLineAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: ScanLinePainter(
                position: _scanLineAnimation.value,
                color: Colors.green.withOpacity(0.7),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlashAnimation() {
    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _flashAnimation.value * 0.4,
          child: Container(color: Colors.white),
        );
      },
    );
  }

  Widget _buildResultOptions(double scanArea) {
    return AnimatedBuilder(
      animation: _resultAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _resultAnimation.value,
          child: Center(
            child: Container(
              width: scanArea,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildScanSuccessIcon(),
                  const SizedBox(height: 16),
                  const Text(
                    'Barcode Scanned',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scannedCode ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildResultButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanSuccessIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 50,
      ),
    );
  }

  Widget _buildResultButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton(
          onPressed: _resetScan,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Scan Again', style: TextStyle(color: Colors.blue)),
        ),
        ElevatedButton(
          onPressed: _proceedToNextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Proceed', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showResultOptions) _buildStatusButtons(),
            _buildActionIcons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusButton('Clear', Colors.grey, _resetScan),
          _buildStatusButton('Focus', Colors.blue, () {
            setState(() => _scanStatus = 'Focus');
          }),
          _buildStatusButton('Detected', Colors.green, _proceedToNextPage),
        ],
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 28),
          onPressed: _proceedToNextPage,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 28),
          onPressed: _resetScan,
        ),
        IconButton(
          icon: const Icon(Icons.keyboard, color: Colors.blue, size: 28),
          onPressed: _manualInputBarcode,
        ),
      ],
    );
  }

  Widget _buildStatusButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(
            label == 'Clear'
                ? Icons.clear
                : label == 'Focus'
                    ? Icons.center_focus_strong
                    : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: label == _scanStatus ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanLinePainter extends CustomPainter {
  final double position;
  final Color color;

  ScanLinePainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * (position + 1) / 2)
      ..lineTo(size.width, size.height * (position + 1) / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum CornerAlignment { topLeft, topRight, bottomLeft, bottomRight }

class CornerPainter extends CustomPainter {
  final CornerAlignment alignment;
  final Paint _paint;

  CornerPainter(this.alignment)
      : _paint = Paint()
          ..color = Colors.white
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    switch (alignment) {
      case CornerAlignment.topLeft:
        path.moveTo(0, kCornerLength);
        path.lineTo(0, 0);
        path.lineTo(kCornerLength, 0);
        break;
      case CornerAlignment.topRight:
        path.moveTo(size.width - kCornerLength, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, kCornerLength);
        break;
      case CornerAlignment.bottomLeft:
        path.moveTo(0, size.height - kCornerLength);
        path.lineTo(0, size.height);
        path.lineTo(kCornerLength, size.height);
        break;
      case CornerAlignment.bottomRight:
        path.moveTo(size.width - kCornerLength, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width, size.height - kCornerLength);
        break;
    }

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MedicineInfoPage extends StatefulWidget {
  final String scannedCode;

  const MedicineInfoPage({super.key, required this.scannedCode});

  @override
  State<MedicineInfoPage> createState() => _MedicineInfoPageState();
}

class _MedicineInfoPageState extends State<MedicineInfoPage> {
  late Future<MedicineInfo> futureMedicine;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    futureMedicine = MedicineApi.fetchMedicineInfo(widget.scannedCode);
  }

  Future<void> _retryFetch() async {
    setState(() {
      _isRetrying = true;
      futureMedicine = MedicineApi.fetchMedicineInfo(widget.scannedCode);
    });
    try {
      await futureMedicine;
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Medicine Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<MedicineInfo>(
        future: futureMedicine,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isRetrying) {
            return _buildLoadingIndicator();
          } else if (snapshot.hasError) {
            String errorCode = 'VRX-007'; // Network Error
            if (snapshot.error.toString().contains('TimeoutException')) {
              errorCode = 'VRX-008'; // Server Timeout
            } else if (snapshot.error.toString().contains('HandshakeException')) {
              errorCode = 'VRX-007'; // Network Error (SSL issues fall under this)
            } else if (snapshot.error.toString().contains('No medicine information found')) {
              errorCode = 'VRX-004'; // Medicine Not Found
            }
            return _buildErrorView(errorCode);
          } else if (!snapshot.hasData) {
            return _buildNoDataView();
          }

          return _buildMedicineInfo(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Fetching medicine information...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ErrorDialog.errorData[errorCode]!['name']!, // Use public getter
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              ErrorDialog.errorData[errorCode]!['message']!, // Use public getter
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _retryFetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Try Again',
              style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No medicine information found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfo(MedicineInfo medicine) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerificationBadge(medicine),
          const SizedBox(height: 20),
          _buildMedicineCard(medicine),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Purpose',
            value: medicine.purpose,
            icon: Icons.medical_information,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Additional Information',
            value: medicine.description ?? 'No additional information available.',
            icon: Icons.info,
            iconColor: Colors.amber,
          ),
          const SizedBox(height: 30),
          _buildPurchaseLocationButton(),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(MedicineInfo medicine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: medicine.isVerified ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            medicine.isVerified ? Icons.verified : Icons.warning,
            color: medicine.isVerified ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            medicine.isVerified ? 'Verified Product' : 'Unverified Product',
            style: TextStyle(
              color: medicine.isVerified ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(MedicineInfo medicine) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    medicine.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  'Price',
                  'AED. ${medicine.price.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildDetailItem(
                  'Potency',
                  medicine.potency,
                  Icons.battery_full,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => const ChatScreen(),
          //   ),
          // );
        },
        child: const Text(
          'Find Purchase Locations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class MedicineApi {
  static const String _apiBaseUrl = 'https://pharmacy-backend-5zrp03yuu-komal-anums-projects.vercel.app';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  static Future<MedicineInfo> fetchMedicineInfo(String barcode) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final medicine = await _tryRemoteApi(barcode);
        if (medicine != null) return medicine;
        throw Exception('No medicine information found for barcode: $barcode');
      } catch (e, stackTrace) {
        print('Attempt $attempt failed: $e\nStackTrace: $stackTrace');
        if (attempt == _maxRetries) {
          throw Exception('Failed to fetch medicine info after $_maxRetries attempts: $e');
        }
        await Future.delayed(_retryDelay);
      }
    }
    throw Exception('Unexpected error in fetchMedicineInfo');
  }

  static Future<MedicineInfo?> _tryRemoteApi(String code) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/medicines/$code');
      print('Attempting to fetch medicine from: $uri');
      final client = http.Client();
      try {
        final response = await client.get(uri).timeout(const Duration(seconds: 15));

        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');
        print('API Response Headers: ${response.headers}');

        if (response.statusCode != 200) {
          throw Exception('API request failed with status ${response.statusCode}: ${response.body}');
        }

        final data = json.decode(response.body);
        print('Parsed JSON: $data');

        if (data == null || (data is List && data.isEmpty) || (data is Map && data.isEmpty)) {
          throw Exception('No valid medicine data returned from API');
        }

        final medicineData = data is List ? data.first : data;

        return MedicineInfo(
          name: medicineData['name']?.toString() ?? 'Unknown Medicine',
          price: double.tryParse(medicineData['price']?.toString() ?? '0.0') ?? 0.0,
          potency: medicineData['mg']?.toString() ?? 'Unknown',
          purpose: medicineData['purpose']?.toString() ?? 'Not specified',
          description: medicineData['additionalinformation']?.toString(),
          isVerified: medicineData['fakeorreal']?.toString().toLowerCase() == 'real',
        );
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('Error in _tryRemoteApi: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }
}

class MedicineInfo {
  final String name;
  final double price;
  final String potency;
  final String purpose;
  final String? description;
  final bool isVerified;

  MedicineInfo({
    required this.name,
    required this.price,
    required this.potency,
    required this.purpose,
    this.description,
    required this.isVerified,
  });
}