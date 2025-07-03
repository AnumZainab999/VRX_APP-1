import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrx_app/fake_medicine_screen.dart';
import 'package:vrx_app/login_and%20signup/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vrx_app/profile_screen.dart';
import 'package:vrx_app/feedback_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? userId;
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _launchWhatsApp() async {
    final whatsappNumber = "923099780690";
    final message = Uri.encodeComponent("Hello! I want to buy authentic medicine.");
    final url = Uri.parse("https://wa.me/$whatsappNumber?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );
    } else {
      debugPrint("⚠ Could not launch WhatsApp");
    }
  }

  Future<void> _fetchUserProfileAndNavigate() async {
    if (userId == null) {
      _showDialog('User ID not found. Please log in again.');
      return;
    }

    final url = Uri.parse(
        'https://pharmacy-backend-1xeuluooj-komal-anums-projects.vercel.app/api/user/$userId');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userId: userId!,
            ),
          ),
        );
      } else {
        _showDialog(data['message'] ?? 'Failed to fetch user profile.');
      }
    } catch (e) {
      _showDialog('Error fetching profile. Please try again.');
    }
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    int? dialogRating; // Local state for dialog

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text('Rate Our App'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How would you rate your experience?'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        dialogRating != null && dialogRating! >= starValue
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          dialogRating = starValue;
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: dialogRating == null
                    ? null
                    : () async {
                        if (userId == null) {
                          Navigator.pop(context);
                          _showDialog('User ID not found. Please log in again.');
                          return;
                        }

                        final url = Uri.parse(
                            'https://pharmacy-backend-6zk9f2a77-komal-anums-projects.vercel.app/api/rating');

                        try {
                          final response = await http.post(
                            url,
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'user_id': userId,
                              'rating': dialogRating,
                            }),
                          );

                          if (response.statusCode == 201) {
                            Navigator.pop(context);
                            _showDialog('Thank you for your rating!');
                          } else {
                            Navigator.pop(context);
                            final error = jsonDecode(response.body)['message'] ??
                                'Failed to submit rating.';
                            _showDialog(error);
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          _showDialog('Error submitting rating. Please try again.');
                        }
                      },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('VRX'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            padding: const EdgeInsets.only(top: 6.0),
            offset: const Offset(0, 40),
            onSelected: (String value) {
              if (value == 'Feedback') {
                if (userId == null) {
                  _showDialog('User ID not found. Please log in again.');
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackPage(userId: userId!),
                    ),
                  );
                }
              } else if (value == 'Profile') {
                _fetchUserProfileAndNavigate();
              } else if (value == 'Rating') {
                _showRatingDialog();
              } else if (value == 'Logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'Feedback',
                child: Text('Feedback'),
              ),
              const PopupMenuItem<String>(
                value: 'Rating',
                child: Text('Rating'),
              ),
              const PopupMenuItem<String>(
                value: 'Logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to VRX',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your trusted app to verify and buy authentic medicines',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Choose what you want to do:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        InkWell(
                         onTap: () {
    if (userId == null) {
      _showDialog('User ID not found. Please log in again.');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FakeMedicineScreen(userId: userId!), // Pass userId
        ),
      );
    }
  },
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.verified, color: Colors.black, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'Check Authentic Medicine',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: _launchWhatsApp,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.shopping_cart, color: Colors.black, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'Buy Authentic Medicine',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}