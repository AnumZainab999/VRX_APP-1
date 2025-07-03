// ScanResultScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'label_check_service.dart';
import 'medicine_details_page.dart'; // Ensure this import is correct

class ScanResultScreen extends StatefulWidget {
  final File imageFile;
  final int userId; // Add userId parameter
  const ScanResultScreen({super.key, required this.imageFile,required this.userId});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  String? _result;
  String? _reason;
  String? _medicineInfo;
  String _medicineName = "Unknown Medicine";
  String? _potency; // New state variable for potency
  String? _price;   // New state variable for price
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLabel();
  }

  Future<void> _checkLabel() async {
    final result = await LabelCheckService.checkLabel(widget.imageFile);
    setState(() {
      _result = result['result'];
      _reason = result['reason'];
      _medicineInfo = result['info'];

      if (_result == 'real') {
        _medicineName = result['medicineName'] ?? "Augmentin Tablet"; // Default if API doesn't return
        _potency = result['potency']; // Extract potency
        _price = result['price'];     // Extract price
      } else {
        _medicineName = "Unknown Medicine";
        _potency = null; // Clear potency if not real
        _price = null;   // Clear price if not real
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _result == 'real';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Step 1 of 2"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.file(widget.imageFile, height: 150),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TagChip(text: "Clear"),
                SizedBox(width: 8),
                _TagChip(text: "Focus"),
                SizedBox(width: 8),
                _TagChip(text: "Detected"),
              ],
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.verified,
              color: isVerified ? Colors.blue : Colors.red,
              size: 50,
            ),
            const SizedBox(height: 5),
            Text(
              isVerified ? "Verified" : "Not Verified",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isVerified ? Colors.blue : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (isVerified)
              Column(
                children: [
                  Text(
                    _medicineName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_potency != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Potency: $_potency',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  if (_price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Price: $_price',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const _ChecklistItem(text: "External packaging and labeling"),
                  const _ChecklistItem(text: "No evidence of counterfeit"),
                  const _ChecklistItem(text: "Barcode conforms to vendor criteria"),
                ],
              )
            else
              Text(
                _reason ?? 'Could not verify the product.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: isVerified
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineDetailsPage(
                          medicineName: _medicineName,
                          medicineInfo: _medicineInfo,
                          potency: _potency??"No data", // Pass potency
                          price: _price??"No data",     // Pass price
                          isVerified: isVerified,
                          userId: widget.userId,         // Pass userId
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVerified ? Colors.blue : Colors.grey,
                  ),
                  child: const Text("Medicine Details"),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Scan Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.blue.shade50,
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}