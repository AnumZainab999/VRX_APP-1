import 'package:flutter/material.dart';
import 'medicine_not_verified_screen.dart';

// ignore: use_key_in_widget_constructors
class MedicineVerifiedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Medicine Verified",
          style: TextStyle(color: Colors.transparent), // Hides the title text
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/logo.png', // Replace with your logo asset
              height: 32,
              width: 32,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensures the content stays centered
            crossAxisAlignment: CrossAxisAlignment.center, // Centers children horizontally
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xff05a6cf3),
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "Medicine Verified",
                style: TextStyle(
                  color: Color(0xff05a6cf3) ,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "The medicine's external packaging and labeling\n"
                "have been verified as authentic, with no\nevidence of counterfeit or misrepresentation.\n"
                "The barcode also conforms to the vendor's\ncriteria. This verification does not extend to the\ncontents of the medicine itself.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Add end scanning functionality here
                    Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MedicineNotVerifiedScreen()),
                ); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5AE4),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "End Scanning",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add scan next functionality here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "  Scan Next  ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold ,color: Colors.black,),
                ),
              ),
            ],
          ),
        ),
      ),
     
    );
  }
}
