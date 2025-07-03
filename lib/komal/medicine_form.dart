// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'upload_reciept.dart';

// ignore: use_key_in_widget_constructors
class MedicineForm extends StatefulWidget {
  @override
  _MedicineFormState createState() => _MedicineFormState();
}

class _MedicineFormState extends State<MedicineForm> {
  bool? _consumedMedicine; // Set to null to make no option selected by default
  bool? _experiencedDiscomfort; // Set to null to make no option selected by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // Title centered manually
                const Expanded(
                  child: Center(
                    child: Text(
                      'Step 2 of 2',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Menu Icon or Logo
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black), // or use Image.asset(...)
                  onPressed: () {
                    // Add your menu logic here
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'Have you consumed the\n medicine?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _customButton('Yes', _consumedMedicine == true, () {
                        setState(() {
                          _consumedMedicine = true;
                        });
                      }),
                      _customButton('No', _consumedMedicine == false, () {
                        setState(() {
                          _consumedMedicine = false;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Are you experiencing any\n discomfort?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _customButton('Yes', _experiencedDiscomfort == true, () {
                        setState(() {
                          _experiencedDiscomfort = true;
                        });
                      }),
                      _customButton('No', _experiencedDiscomfort == false, () {
                        setState(() {
                          _experiencedDiscomfort = false;
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0), // Space from bottom
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UploadReciept()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5AE4),
                    minimumSize: const Size(180, 45), // Smaller button size
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min, // Shrink to fit content
                    children: [
                      Text(
                        'NEXT',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF0B5AE4) : Colors.grey.shade400,
          width: isSelected ? 2.0 : 1.0, // Thicker border when selected
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        minimumSize: const Size(150, 50),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0B5AE4) : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}