// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:vrx_app/image_scanner/label_check_ui.dart';
import 'package:vrx_app/scanner/ScanProductScreen.dart';

class VerificationScreen extends StatefulWidget {
  final int userId; // Add userId parameter

  const VerificationScreen({super.key, required this.userId});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? selectedOption;

  void handleOptionSelect(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "2 Step Verification",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "1. Follow the provided verification steps.\n"
                    "2. Data will be automatically shared with the\n"
                    "   relevant pharmaceutical company to ensure\n"
                    "   your health is protected.\n"
                    "3. Personal details will remain confidential.",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20), // Left and right margins for the card
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12), // Only top corners rounded
                ),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF28303F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Center(
                      child: Text(
                        "Begin Scan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OptionCard(
                          icon: Icons.qr_code_scanner,
                          value: 'scanner',
                          groupValue: selectedOption,
                          onChanged: handleOptionSelect,
                        ),
                        const SizedBox(width: 16),
                        OptionCard(
                          imagePath: 'assets/bottle.png',
                          value: 'image',
                          groupValue: selectedOption,
                          onChanged: handleOptionSelect,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: selectedOption != null
                          ? () {
                              if (selectedOption == 'scanner') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanProductScreen(userId: widget.userId), // Pass userId
                                  ),
                                );
                              } else if (selectedOption == 'image') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LabelCheckScreen(),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("BEGIN SCAN",
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onChanged;

  const OptionCard({
    super.key,
    this.icon,
    this.imagePath,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Stack(
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      height: 50,
                      width: 50,
                      color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                    )
                  : Icon(
                      icon,
                      size: 50,
                      color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                    ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: const Color(0xFF4A90E2),
            ),
          ),
        ],
      ),
    );
  }
}