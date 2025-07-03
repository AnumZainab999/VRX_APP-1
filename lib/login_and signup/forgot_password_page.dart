import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  void _showSnack(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnack("Please enter your email");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      "https://pharmacy-backend-gdmqvos56-komal-anums-projects.vercel.app/api/forgot-password",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnack("Enter your new password", Colors.green);
        _showResetModal(email); // 👉 pass email for reset
      } else {
        _showSnack(data['message'] ?? "Failed to send reset request");
      }
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showResetModal(String email) {
    final TextEditingController passwordController = TextEditingController();
    bool isModalLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Reset Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newPassword = passwordController.text.trim();
                    if (newPassword.isEmpty) {
                      _showSnack("Please enter new password");
                      return;
                    }

                    setModalState(() => isModalLoading = true);

                    final resetUrl = Uri.parse(
                      "https://pharmacy-backend-gdmqvos56-komal-anums-projects.vercel.app/api/reset-password",
                    );

                    try {
                      final resetResponse = await http.post(
                        resetUrl,
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "email": email,
                          "password": newPassword,
                        }),
                      );

                      final result = jsonDecode(resetResponse.body);

                      if (resetResponse.statusCode == 200) {
                        Navigator.pop(context);
                        _showSnack("Password reset successful", Colors.green);
                      } else {
                        _showSnack(result['message'] ?? "Reset failed");
                      }
                    } catch (e) {
                      _showSnack("Error: $e");
                    } finally {
                      setModalState(() => isModalLoading = false);
                    }
                  },
                  child: isModalLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Reset"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Forgot Password", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your email to reset your password",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email Address",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A7D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Reset Password", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}