import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'medicine_form.dart';

class PurchaseFormPage extends StatefulWidget {
  const PurchaseFormPage({super.key});

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormStep2State();
}

class _PurchaseFormStep2State extends State<PurchaseFormPage> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController amountPaidController = TextEditingController();

  DateTime? purchaseDate;
  String? selectedCity = 'Lahore';
  String? selectedCountry = 'Pakistan';

  File? selectedFile;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  onPressed: () {
    Navigator.pop(context);
  },
),

        centerTitle: true,
        title: const Text('Step 2 of 2', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.menu),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabel('Shop Name *'),
              buildTextField(controller: shopNameController),

              const SizedBox(height: 10),
              buildLabel('Remark'),
              buildTextField(controller: remarkController, maxLines: 3),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: buildDropdown(
                      'City *',
                      [
                        'Lahore', 
                        'Karachi', 
                        'Islamabad', 
                        'Rawalpindi', 
                        'Faisalabad', 
                        'Sialkot', 
                        'Multan', 
                        'Peshawar', 
                        'Quetta', 
                        'Gujranwala'
                      ],
                      selectedCity!,
                      (value) => setState(() => selectedCity = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildDropdown(
                      'Country *',
                      ['Pakistan'],
                      selectedCountry!,
                      (value) => setState(() => selectedCountry = value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: buildDatePicker(context)),
                  const SizedBox(width: 10),
                  Expanded(child: buildLabelledField('Amount Paid *', controller: amountPaidController)),
                ],
              ),

              const SizedBox(height: 10),
              buildLabel('Attachment *'),
              Container(
                width: 150,
                height: 30,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: GestureDetector(
                  onTap: pickFile,
                  child: Text(
                    selectedFile != null ? selectedFile!.path.split('/').last : 'Upload a file',
                    style: TextStyle(color: selectedFile != null ? Colors.black : Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                        Navigator.push( context,MaterialPageRoute(builder: (context)=> MedicineForm()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('NEXT', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    bool isRequired = text.contains('*');
    String labelText = text.replaceAll('*', '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(color: Colors.black,  fontWeight: FontWeight.bold,),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget buildTextField({required TextEditingController controller, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String selectedValue, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            underline: const SizedBox(),
            isExpanded: true,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel('Purchased Date *'),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                purchaseDate = picked;
              });
            }
          },
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  purchaseDate == null
                      ? 'Select Date'
                      : '${purchaseDate!.day}/${purchaseDate!.month}/${purchaseDate!.year}',
                  style: const TextStyle(color: Colors.black),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLabelledField(String label, {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabel(label),
        buildTextField(controller: controller),
      ],
    );
  }
}
