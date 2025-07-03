import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final int userId; // Add userId parameter
  const ChatScreen({Key? key, required this.userId}) : super(key: key);
  

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String backendUrl = 'https://pharmacy-backend-gdmqvos56-komal-anums-projects.vercel.app';
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Uint8List? receiptImageBytes;
  String? receiptImageName;
  int currentStep = 0;

  final Map<String, dynamic> formData = {
    'medicine_name': '',
    'purchase_city': '',
    'purchase_price': '',
    'purchase_date': '',
    'user_id': '', // Add user_id to formData
  };

  final List<String> questions = [
    "🩺 What is the medicine name?",
    "🏙 Which city did you buy it from?",
    "💰 What was the purchase price?",
    "📅 On what date did you purchase it? (YYYY-MM-DD)",
    "📸 Please upload your receipt image.",
  ];

  @override
  void initState() {
    super.initState();
    formData['user_id'] = widget.userId.toString(); // Initialize user_id in formData
    addMessage("👋 Hello! Let's save your medicine purchase step by step.", 'bot');
    askNextQuestion();
  }

  void addMessage(String text, String type, {dynamic image}) {
    setState(() {
      messages.add({'text': text, 'type': type, 'image': image});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void askNextQuestion() {
    if (currentStep < questions.length) {
      addMessage(questions[currentStep], 'bot');
    }
  }

  Future<void> handleSend() async {
    if (currentStep == 4) {
      if (receiptImageBytes == null || receiptImageName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload the receipt image.")),
        );
        return;
      }

      addMessage("⏳ Submitting your purchase...", 'bot');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/api/purchase/add'),
      );

      request.fields.addAll({
        'medicine_name': formData['medicine_name'],
        'purchase_city': formData['purchase_city'],
        'purchase_price': formData['purchase_price'],
        'purchase_date': formData['purchase_date'],
        'user_id': formData['user_id'], // Include user_id in the request
      });

      request.files.add(http.MultipartFile.fromBytes(
        'receipt_image',
        receiptImageBytes!,
        filename: receiptImageName!,
      ));

      try {
        final response = await request.send();
        final result = await http.Response.fromStream(response);
        final jsonResult = jsonDecode(result.body);

        if (response.statusCode == 200) {
          addMessage("✅ Purchase saved successfully! 🎉", 'bot');
        } else {
          addMessage("❌ Error saving purchase: ${jsonResult['error']}", 'bot');
        }
      } catch (e) {
        addMessage("❌ Network error. Please try again.", 'bot');
      }

      messageController.clear();
      setState(() {
        receiptImageBytes = null;
        receiptImageName = null;
        currentStep = 0;
        formData.updateAll((key, value) => '');
        formData['user_id'] = widget.userId.toString(); // Reset user_id
      });
      askNextQuestion();
      return;
    }

    if (messageController.text.isEmpty) {
      addMessage("⚠ Please enter a value.", 'bot');
      return;
    }

    String input = messageController.text.trim();

    // Validation based on current step
    switch (currentStep) {
      case 0: // Medicine name (only alphabets and spaces)
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(input)) {
          addMessage("⚠ Medicine name should contain only alphabets and spaces.", 'bot');
          return;
        }
        formData['medicine_name'] = input;
        break;

      case 1: // Purchase city (only alphabets and spaces)
        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(input)) {
          addMessage("⚠ City name should contain only alphabets and spaces.", 'bot');
          return;
        }
        formData['purchase_city'] = input;
        break;

      case 2: // Purchase price (only numbers)
        if (!RegExp(r'^\d+$').hasMatch(input)) {
          addMessage("⚠ Purchase price should contain only numbers.", 'bot');
          return;
        }
        formData['purchase_price'] = input;
        break;

      case 3: // Purchase date (YYYY-MM-DD format)
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
          addMessage("⚠ Please enter date in YYYY-MM-DD format (e.g., 2025-07-03).", 'bot');
          return;
        }
        try {
          DateTime.parse(input); // Validate date
        } catch (e) {
          addMessage("⚠ Invalid date format. Use YYYY-MM-DD.", 'bot');
          return;
        }
        formData['purchase_date'] = input;
        break;
    }

    addMessage(input, 'user');
    messageController.clear();
    setState(() {
      currentStep++;
    });
    askNextQuestion();
  }

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      receiptImageBytes = result.files.single.bytes;
      receiptImageName = result.files.single.name;

      addMessage("📷 Image selected", 'user', image: receiptImageBytes);
      await handleSend();
    }
  }

  Future<void> showAllPurchases() async {
    addMessage("📄 Fetching your previous purchases...", 'bot');

    try {
      final response = await http.get(Uri.parse('$backendUrl/api/purchase/:userId'));
      final purchases = jsonDecode(response.body);

      if (purchases is List && purchases.isNotEmpty) {
        for (var p in purchases) {
          Uint8List? imageBytes;
          if (p['image_base64'] != null && p['image_base64'].isNotEmpty) {
            try {
              String base64String = p['image_base64'].startsWith('data:image')
                  ? p['image_base64'].split(',')[1]
                  : p['image_base64'];
              base64String = base64String.replaceAll(RegExp(r'\s+'), '');
              imageBytes = base64Decode(base64String);
            } catch (e) {
              print("Error decoding base64 image for ${p['medicine_name']}: $e");
              addMessage("⚠ Error decoding image for ${p['medicine_name']}: $e", 'bot');
            }
          } else {
            print("No image_base64 for ${p['medicine_name']}");
            addMessage("⚠ No image available for ${p['medicine_name']}.", 'bot');
          }

          String formattedDate = p['purchase_date'];
          try {
            final date = DateTime.parse(p['purchase_date']);
            formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          } catch (e) {
            print("Error parsing date for ${p['medicine_name']}: $e");
            formattedDate = "Invalid date";
          }

          addMessage(
            "${p['medicine_name']}\n📍 ${p['purchase_city']} | 💰 Rs. ${p['purchase_price']}\n📅 $formattedDate",
            'bot',
            image: imageBytes,
          );
        }
      } else {
        addMessage("⚠ No purchases found.", 'bot');
      }
    } catch (err) {
      print("Error fetching purchases: $err");
      addMessage(" Error loading purchase history: $err", 'bot');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message['type'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: message['type'] == 'user'
                          ? const Color(0xFFD1E7FF)
                          : const Color(0xFFE1F3E2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (message['image'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            child: Image.memory(
                              message['image'],
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: currentStep == 4
                      ? ElevatedButton(
                          onPressed: pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Upload Receipt", style: TextStyle(color: Colors.white)),
                        )
                      : TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Type your answer...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onSubmitted: (_) => handleSend(),
                        ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Send", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 20),
              child: FloatingActionButton(
                onPressed: showAllPurchases,
                backgroundColor: const Color(0xFF28A745),
                child: const Icon(Icons.list, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}