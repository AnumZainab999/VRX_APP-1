import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'verification_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPrivacyChecked = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  void _showSnack(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> signupUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    // Validation rules
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }

    // Name validation: minimum 3 characters
    if (name.length < 3) {
      _showSnack("Name must be at least 3 characters long");
      return;
    }

    // Email validation: basic email format check
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      _showSnack("Please enter a valid email address");
      return;
    }

    // Phone validation: exactly 11 digits, no alphabets
    final phoneRegExp = RegExp(r'^\d{11}$');
    if (!phoneRegExp.hasMatch(phone)) {
      _showSnack("Phone number must be exactly 11 digits");
      return;
    }

    // Password validation: minimum 5 characters
    if (password.length < 5) {
      _showSnack("Password must be at least 5 characters long");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
      "https://pharmacy-backend-gdmqvos56-komal-anums-projects.vercel.app/api/signup",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showSnack("Signup successful", Colors.green);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerificationPage(email: email)),
        );
      } else {
        _showSnack(data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void signUpWithGoogle() {
    _showSnack("Google Sign-Up is not available in this version.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
              "Create Your Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Enter your name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Enter your email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Enter your phone number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Enter your password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isPrivacyChecked,
                  onChanged: (value) => setState(() => isPrivacyChecked = value!),
                ),
                const Expanded(
                  child: Text("I agree to the Terms of Service and Privacy Policy."),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A7D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  if (!isPrivacyChecked) {
                    _showSnack("Please accept the Terms and Privacy Policy.");
                  } else {
                    signupUser();
                  }
                },
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: OutlinedButton.icon(
                onPressed: signUpWithGoogle,
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text("Sign Up with Google", style: TextStyle(color: Colors.black)),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}