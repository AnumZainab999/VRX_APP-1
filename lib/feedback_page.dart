import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackPage extends StatefulWidget {
  final int userId; // Add userId as a required prop

  const FeedbackPage({super.key, required this.userId});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String? _selectedFeeling;
  final TextEditingController _thoughtsController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  List<dynamic> _userFeedback = [];

  final List<Map<String, dynamic>> _feelings = [
    {'emoji': '😍', 'label': 'Loved it'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😕', 'label': 'Not Great'},
    {'emoji': '😡', 'label': 'Terrible'},
  ];

  bool get isSubmitEnabled =>
      _selectedFeeling != null && _thoughtsController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _thoughtsController.addListener(() => setState(() {}));
    _fetchFeedback(); // Fetch feedback for the specific user
  }

  void _submitFeedback() async {
    final feedback = {
      'user_id': widget.userId, // Use prop userId
      'feeling': _selectedFeeling,
      'thoughts': _thoughtsController.text.trim(),
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null, // Send null if email is empty
    };

    final url = Uri.parse(
        'https://pharmacy-backend-plb6d36wt-komal-anums-projects.vercel.app/api/feedback');

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(feedback),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog();
        _thoughtsController.clear();
        _emailController.clear(); // Fixed typo: changed _letterController to _emailController
        setState(() => _selectedFeeling = null);
        _fetchFeedback();
      } else {
        final error = json.decode(response.body)['error'] ?? 'Something went wrong.';
        _showErrorDialog(error);
      }
    } catch (e) {
      _showErrorDialog('Could not submit feedback. Please check your internet.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _fetchFeedback() async {
    final url = Uri.parse(
        'https://pharmacy-backend-plb6d36wt-komal-anums-projects.vercel.app/api/feedback/${widget.userId}');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _userFeedback = data['feedback'] ?? []);
      } else {
        print('❌ Failed to fetch feedback: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thank you!'),
        content: const Text('Your feedback has been submitted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _thoughtsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Share Your Experience',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('How did you feel using the app?'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 15,
                  children: _feelings.map((feeling) {
                    final isSelected = _selectedFeeling == feeling['emoji'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedFeeling = feeling['emoji'];
                      }),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.blue.shade200
                                  : Colors.transparent,
                            ),
                            child: Text(feeling['emoji'], style: const TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(height: 4),
                          Text(feeling['label'], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Any thoughts or suggestions?'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _thoughtsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Write here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Your email (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: isSubmitEnabled && !_isSubmitting ? _submitFeedback : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubmitEnabled ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const Text('Your Feedback History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._userFeedback.map((item) => ListTile(
                      leading: Text(item['feeling'], style: const TextStyle(fontSize: 20)),
                      title: Text(item['thoughts']),
                      subtitle: Text(item['email'] ?? ''),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}