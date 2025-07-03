// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrx_app/login_and%20signup/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _textGlowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _textGlowAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
    ));

    // Navigate after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildScanner() {
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(180, 180),
            painter: _ScannerCornerPainter(),
          ),
          // VRx text with mathematical style
          AnimatedBuilder(
            animation: _textGlowAnimation,
            builder: (context, child) {
              final glowOpacity = 1.0 - _textGlowAnimation.value;
              final textOpacity = _textGlowAnimation.value;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect (blurred version)
                  Opacity(
                    opacity: glowOpacity,
                    child: buildFractionText(0.7),
                  ),
                  // Clear text
                  Opacity(
                    opacity: textOpacity,
                    child: buildFractionText(1.0),
                  ),
                ],
              );
            },
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: 180 * _animation.value,
                child: Container(
                  width: 160,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 216, 214, 214),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildFractionText(double opacity) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'V',
            style: GoogleFonts.
            abrilFatface(
              fontSize: 45,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 87, 136, 241).withOpacity(opacity),
            ),
          ),
          WidgetSpan(
            child: Transform.translate(
              offset: const Offset(0, 15),
              child: Text(
                'Rx',
                style: GoogleFonts.abrilFatface(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 87, 136, 241).withOpacity(opacity),
                ),
              ),
            ),
          ),
          WidgetSpan(
            child: Container(
              width: 2,
              height: 2,
              color: const Color.fromARGB(255, 87, 136, 241).withOpacity(opacity),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: buildScanner(),
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 216, 214, 214)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const double cornerLength = 30;
    const double cornerThickness = 8;

    // Draw top-left corner (Γ shape)
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(0, cornerLength),
      paint..strokeWidth = cornerThickness,
    );

    // Draw top-right corner (L shape)
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint..strokeWidth = cornerThickness,
    );

    // Draw bottom-left corner (Γ shape rotated 180°)
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLength),
      paint..strokeWidth = cornerThickness,
    );

    // Draw bottom-right corner (L shape rotated 180°)
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint..strokeWidth = cornerThickness,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLength),
      paint..strokeWidth = cornerThickness,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}