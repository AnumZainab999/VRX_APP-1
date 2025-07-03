import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vrx_app/fake_medicine_screen.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async' show unawaited;

import 'medicine_verified_screen.dart';

// Main application widget
class MedicineSafetyScannerApp extends StatelessWidget {
  const MedicineSafetyScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Safety Scanner',
      theme: ThemeData(
        primaryColor: const Color(0xFF3498DB),
        scaffoldBackgroundColor: const Color(0xFF1A5276),
        fontFamily: 'Segoe UI',
      ),
      home: const MedicineSafetyScannerScreen(),
    );
  }
}

// Main screen widget
class MedicineSafetyScannerScreen extends StatefulWidget {
  const MedicineSafetyScannerScreen({super.key});

  @override
  _MedicineSafetyScannerScreenState createState() =>
      _MedicineSafetyScannerScreenState();
}

class _MedicineSafetyScannerScreenState
    extends State<MedicineSafetyScannerScreen> {
  int currentStep = 0;
  Map<String, String> formData = {};
  File? uploadedImage;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isTyping = false;
  bool reportSubmitted = false;
  // ignore: unused_field
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Questions configuration
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Where was it purchased?',
      'key': 'source',
      'options': [
        {'text': 'Online Pharmacy', 'icon': Icons.laptop},
        {'text': 'Local Pharmacy', 'icon': Icons.store},
        {'text': 'Hospital', 'icon': Icons.local_hospital},
        {'text': 'Friend', 'icon': Icons.group},
        {'text': 'Other', 'icon': Icons.more_horiz},
      ],
    },
    {
      'question': 'From which city?',
      'key': 'city',
      'options': [
        {'text': 'Lahore', 'icon': Icons.location_city},
        {'text': 'Karachi', 'icon': Icons.location_city},
        {'text': 'Islamabad', 'icon': Icons.location_city},
        {'text': 'Rawalpindi', 'icon': Icons.location_city},
        {'text': 'Other', 'icon': Icons.more_horiz},
      ],
    },
    {
      'question': 'When did you make the purchase?\n(DD/MM/YYYY)',
      'key': 'date',
      'validation': (String value) =>
          RegExp(r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$')
              .hasMatch(value),
      'error': 'Please enter a valid date in DD/MM/YYYY format',
    },
    {
      'question': 'How much did you pay for it?\n(Enter numbers only)',
      'key': 'amount',
      'validation': (String value) =>
          !value.isEmpty &&
          double.tryParse(value) != null &&
          double.parse(value) > 0,
      'error': 'Please enter a valid amount (numbers only)',
    },
    {
      'question': 'Want to know if the scanned medicine is present in the receipt?',
      'key': 'scanReceipt',
      'options': [
        {'text': 'Yes', 'icon': Icons.check_circle},
        {'text': 'No', 'icon': Icons.cancel},
      ],
      'upload': true,
    },
    {
      'question': 'Thank you for providing that information! Here\'s important safety guidance:',
      'key': 'safety_info',
      'info': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Start with the first question
    unawaited(Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _addBotMessage();
    }));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      unawaited(_scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ));
    }
  }

  void _addBotMessage() {
    setState(() {
      isTyping = true;
      messages.add({'isBot': true, 'isTyping': true});
    });
    _scrollToBottom();

    unawaited(Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.removeLast();
        messages.add({
          'isBot': true,
          'content': questions[currentStep]['question'],
          'options': questions[currentStep]['options'],
          'showUpload': questions[currentStep]['upload'] == true,
        });
      });
      _scrollToBottom();
    }));
  }

  void _handleOptionSelect(String option, IconData icon) {
    final question = questions[currentStep];
    setState(() {
      formData[question['key']] = option;
      messages.add({
        'isBot': false,
        'content': option,
        'icon': icon,
      });
    });
    _scrollToBottom();

    _proceedToNextStep();
  }

  void _handleOtherInput(String input) {
    if (input.isEmpty) return;
    _handleOptionSelect(input, Icons.more_horiz);
  }

  void _handleUserInput() {
    final input = _textController.text.trim();
    if (input.isEmpty) return;

    final currentQuestion = questions[currentStep];

    // Check for irrelevant questions
    if (_isIrrelevantQuestion(input)) {
      setState(() {
        messages.add({
          'isBot': true,
          'content':
              'For more information, please contact thepharmasenz123@gmail.com. Now, please answer the current question.',
        });
      });
      _textController.clear();
      _scrollToBottom();
      return;
    }

    // Validate input
    if (currentQuestion['validation'] != null &&
        !currentQuestion['validation'](input)) {
      setState(() {
        messages.add({
          'isBot': false,
          'content': currentQuestion['error'],
          'icon': Icons.warning,
        });
      });
      _textController.clear();
      _scrollToBottom();
      return;
    }

    setState(() {
      formData[currentQuestion['key']] = input;
      messages.add({
        'isBot': false,
        'content': input,
      });
    });
    _textController.clear();
    _scrollToBottom();

    _proceedToNextStep();
  }

  void _proceedToNextStep() {
    setState(() {
      currentStep++;
    });
    if (currentStep < questions.length) {
      if (questions[currentStep]['info'] == true) {
        _showSafetyInfo();
      } else {
        _addBotMessage();
      }
    }
  }

  bool _isIrrelevantQuestion(String input) {
    final irrelevantKeywords = [
      'what', 'why', 'how', 'when', 'where', 'who', 'explain',
      'tell me', 'help', '?', 'assist', 'info', 'information',
      'question', 'support', 'advice', 'guidance', 'help me'
    ];
    final lowerInput = input.toLowerCase();
    return irrelevantKeywords.any((keyword) => lowerInput.contains(keyword));
  }

  void _handleImageUpload(XFile? image) async {
    if (image != null) {
      setState(() {
        uploadedImage = File(image.path);
        messages.add({
          'isBot': false,
          'content': 'Receipt uploaded for verification',
        });
      });
      _scrollToBottom();

      // Simulate verification
      await Future.delayed(const Duration(seconds: 1));
      final verificationResult = Random().nextBool()
          ? '<span style="color:#27ae60;"><i class="fas fa-check-circle"></i> Medicine verified as authentic!</span>'
          : '<span style="color:#e74c3c;"><i class="fas fa-exclamation-triangle"></i> Warning: Suspicious medicine detected!</span>';

      setState(() {
        messages.add({
          'isBot': true,
          'content': verificationResult,
        });
      });
      _scrollToBottom();

      unawaited(Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _proceedToNextStep();
      }));
    }
  }

  void _showSafetyInfo() {
    setState(() {
      isTyping = true;
      messages.add({'isBot': true, 'isTyping': true});
    });
    _scrollToBottom();

    unawaited(Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        isTyping = false;
        messages.removeLast();
        messages.add({
          'isBot': true,
          'content':
              '✅ Thank you for your report and for helping keep our communities safe!\n\nYour information has been recorded and will be reviewed by our team.',
          'showSubmit': true,
        });
      });
      _scrollToBottom();
    }));
  }

  void _submitReport() {
    setState(() {
      reportSubmitted = true;
      messages.add({
        'isBot': true,
        'content':
            '📬 Report submitted successfully! Thank you for contributing to medication safety.\n\nA confirmation has been sent to your records.',
      });
    });
    _scrollToBottom();

    // Wait for 10 seconds, then show the analyzing modal
    unawaited(Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _showAnalyzingModal();
    }));
  }

  void _showAnalyzingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Analyzing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.83,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
                  minHeight: 8,
                ),
                const SizedBox(height: 10),
                const Text(
                  '83% Complete',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate loading completion after 5 seconds
    unawaited(Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) {
        debugPrint('Widget is not mounted, skipping navigation');
        return;
      }
      try {
        Navigator.of(context, rootNavigator: true).pop(); // Close the modal
        debugPrint('Dialog closed, navigating to MedicineVerifiedScreen');
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MedicineVerifiedScreen(),
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('Navigation error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }));
  }

  double _calculateProgress() {
    return (currentStep / questions.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A5276), Color(0xFF2980B9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with cross icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF2C80B9)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Your Vrx Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              content: const Text(
                                "Do you want to cancel chat?",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the pop-up
                                      },
                                      child: const Text(
                                        "Keep Chat",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Navigator.of(context).pop(); // Close the pop-up
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(
                                        //     builder: (context) => FakeMedicineScreen(),
                                        //   ),
                                        // );
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Main content (Chat container only)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              'Progress: ${(_calculateProgress()).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                              value: _calculateProgress() / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2ECC71),
                              ),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                      // Chat messages
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: messages.length + (reportSubmitted ? 3 : 0),
                          itemBuilder: (context, index) {
                            if (index < messages.length) {
                              final message = messages[index];
                              if (message['isTyping'] == true) {
                                return const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      _TypingDot(),
                                      _TypingDot(delay: 0.2),
                                      _TypingDot(delay: 0.4),
                                    ],
                                  ),
                                );
                              }
                              return _buildMessage(message);
                            } else {
                              // Add info sections as messages after report is submitted
                              if (index == messages.length) {
                                return _buildInfoSection(
                                  title: 'Safe Disposal Guide',
                                  icon: Icons.delete,
                                  iconColor: const Color(0xFF2ECC71),
                                  items: [
                                    {
                                      'icon': Icons.block,
                                      'text': 'Don\'t flush - Avoid contaminating water sources'
                                    },
                                    {
                                      'icon': Icons.fastfood,
                                      'text': 'Mix with substance - Use coffee grounds or kitty litter'
                                    },
                                    {
                                      'icon': Icons.lock,
                                      'text': 'Seal securely - Place in a sealed container'
                                    },
                                    {
                                      'icon': Icons.delete,
                                      'text': 'Dispose properly - In trash or at pharmacy drop-off'
                                    },
                                  ],
                                );
                              } else if (index == messages.length + 1) {
                                return _buildInfoSection(
                                  title: 'Emergency Response',
                                  icon: Icons.warning,
                                  iconColor: const Color(0xFFE74C3C),
                                  items: [
                                    {
                                      'icon': Icons.stop,
                                      'text': 'Stop immediately - Do not take any more doses'
                                    },
                                    {
                                      'icon': Icons.local_hospital,
                                      'text': 'Seek medical help - Contact poison control or your doctor'
                                    },
                                    {
                                      'icon': Icons.description,
                                      'text': 'Preserve evidence - Keep packaging and remaining medicine'
                                    },
                                    {
                                      'icon': Icons.report,
                                      'text': 'Report it - Contact authorities and provide details'
                                    },
                                  ],
                                );
                              } else {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF3498DB)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.email, color: Color(0xFF4DA6FF)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Contact us: thepharmasenz123@gmail.com',
                                          style: const TextStyle(color: Color(0xFF2C3E50)),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      // Input or upload area
                      if (!reportSubmitted)
                        if (messages.isNotEmpty && messages.last['showUpload'] == true)
                          _buildUploadContainer()
                        else
                          _buildInputContainer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3498DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['text'],
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isBot = message['isBot'] == true;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isBot ? const Radius.circular(5) : const Radius.circular(15),
            bottomRight: isBot ? const Radius.circular(15) : const Radius.circular(5),
          ),
          color: isBot ? const Color(0xFFE3F2FD) : const Color(0xFF3498DB),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message['content'] != null && message['icon'] == null)
                  Text(
                    message['content'],
                    style: TextStyle(
                      color: isBot ? const Color(0xFF2C3E50) : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                if (message['icon'] != null)
                  Row(
                    children: [
                      Icon(message['icon'],
                          color: isBot ? const Color(0xFF2C3E50) : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        message['content'],
                        style: TextStyle(
                          color: isBot ? const Color(0xFF2C3E50) : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                if (message['options'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: (message['options'] as List<dynamic>).map((opt) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            if (opt['text'] == 'Other') {
                              setState(() {
                                messages.add({
                                  'isBot': true,
                                  'showOtherInput': true,
                                });
                              });
                              _scrollToBottom();
                            } else {
                              _handleOptionSelect(opt['text'], opt['icon']);
                            }
                          },
                          icon: Icon(opt['icon'], color: const Color(0xFF3498DB)),
                          label: Text(opt['text']),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF3498DB),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                              side: const BorderSide(color: Color(0xFF3498DB)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (message['showOtherInput'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Please specify...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(25)),
                              ),
                            ),
                            onSubmitted: (value) {
                              _handleOtherInput(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            _handleOtherInput(_textController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                if (message['showSubmit'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: reportSubmitted ? null : _submitReport,
                        icon: const Icon(Icons.check_circle),
                        label: Text(reportSubmitted ? 'Submitted' : 'Submit Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF5FF),
        border: Border(top: BorderSide(color: Color(0xFFD4E6F1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !reportSubmitted,
              decoration: InputDecoration(
                hintText: reportSubmitted ? 'Report complete' : 'Type your answer here...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4E6F1)),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3498DB)),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
              ),
              onSubmitted: (_) => _handleUserInput(),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: reportSubmitted ? null : _handleUserInput,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadContainer() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3498DB)),
      ),
      child: Column(
        children: [
          const Text(
            'Upload Receipt for Verification',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Want to know if the scanned medicine is present in the receipt?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    _handleImageUpload(image);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3498DB),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.folder_open, size: 40, color: Color(0xFF3498DB)),
                        SizedBox(height: 10),
                        Text('From Gallery'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera);
                    _handleImageUpload(image);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3498DB),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Color(0xFF3498DB)),
                        SizedBox(height: 10),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (uploadedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      uploadedImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      _handleImageUpload(XFile(uploadedImage!.path));
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Verify Medicine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final double delay;

  const _TypingDot({this.delay = 0});

  @override
  _TypingDotState createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    _controller.addListener(() {
      if (_controller.value >= 0.6) {
        _controller.value = 0;
      }
    });
    unawaited(Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: Color(0xFF3498DB),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}