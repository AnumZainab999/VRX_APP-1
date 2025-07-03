import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'medicine_form.dart';

class PurchaseFormStep2 extends StatefulWidget {
  const PurchaseFormStep2({super.key});

  @override
  State<PurchaseFormStep2> createState() => _PurchaseFormStep2State();
}

class _PurchaseFormStep2State extends State<PurchaseFormStep2> {
  final _formKey = GlobalKey<FormState>();
  String? _source;
  String? _city = 'Lahore';
  String? _country = 'Pakistan';
  // ignore: unused_field
  String? _purchaseDate;
  // ignore: unused_field
  String? _amountPaid;
  String? _attachmentName;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final List<String> cities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
    'Sialkot',
    'Hyderabad',
  ];

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachmentName = result.files.single.name;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _purchaseDate = formattedDate;
        _dateController.text = formattedDate;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _source != null && _attachmentName != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );
    } else {
      if (_source == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a source')),
        );
      } else if (_attachmentName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an attachment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Step 2 of 2', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  onPressed: () {
    Navigator.pop(context);
  },
),

        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.menu, color: Colors.black))],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _requiredFieldLabel('Source'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Website', 'E-commerce app', 'Social Media', 'Other'].map((source) {
                    return OutlinedButton(
                      onPressed: () => setState(() => _source = source),
                      style: OutlinedButton.styleFrom(
                         side: BorderSide(
      color: _source == source ? Colors.blue : Colors.grey, // Set the border color based on selection
   width: 2 ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Added border radius
                      ),
                      child: Text(source,style: const TextStyle(color: Colors.black),),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // If 'Other' is selected, show a text area for remarks
                if (_source == 'Other') ...[
                  const SizedBox(height: 8),
                  const Text('If Other:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter remarks here...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Remarks are required' : null,
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: dropdownField(
                        'City',
                        _city,
                        cities,
                        (val) => setState(() => _city = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: dropdownField(
                        'Country',
                        _country,
                        ['Pakistan'],
                        (val) => setState(() => _country = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: dateField(context, 'Purchased Date')),
                    const SizedBox(width: 10),
                    Expanded(child: inputField('Amount Paid')),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Attachment (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _pickAttachment,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Added border radius
                  ),
                  child: Text(_attachmentName ?? 'Upload a file', style: const TextStyle(color: Colors.blue)),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push( context,MaterialPageRoute(builder: (context)=> MedicineForm()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0057FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                    ),
                    child: const Text('NEXT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _requiredFieldLabel(String label) {
    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(
          '*',
          style: TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  Widget dropdownField(String label, String? selectedValue, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredFieldLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: options.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget dateField(BuildContext context, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredFieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today),
            isDense: true,
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget inputField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requiredFieldLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          onSaved: (val) => _amountPaid = val,
        ),
      ],
    );
  }
}
