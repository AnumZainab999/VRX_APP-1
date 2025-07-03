import 'package:flutter/material.dart';
import 'package:vrx_app/login_and%20signup/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationPage extends StatefulWidget {
  final String email;
  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
  bool isLoading = false;

  void _showSnack(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> verifyOtp() async {
    String otpCode = controllers.map((e) => e.text).join();

    if (otpCode.length != 6 || otpCode.contains(RegExp(r'[^0-9]'))) {
      _showSnack("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("https://pharmacy-backend-5zrp03yuu-komal-anums-projects.vercel.app/api/verify-otp");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email.trim(), "otp": otpCode}),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        _showSnack("Invalid server response (not JSON)");
        return;
      }

      if (response.statusCode == 200) {
        _showSnack("Verification successful", Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _showSnack(data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text(
                  "Email Verification",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00A7D2)),
                ),
                const SizedBox(height: 8),
                Text(
                  "An OTP has been sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // ✅ Custom OTP Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 40,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        decoration: const InputDecoration(counterText: ''),
                        onChanged: (value) {
                          if (value.length == 1 && index < 5) {
                            focusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A7D2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify OTP", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}