import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vrx_app/home_screen..dart';
import 'package:vrx_app/login_and%20signup/forgot_password_page.dart';
import 'package:vrx_app/login_and%20signup/signup/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

 Future<void> _login() async {
  final loginId = _loginIdController.text.trim();
  final password = _passwordController.text;

  if (loginId.isEmpty || password.isEmpty) {
    _showDialog('Please fill in all fields.');
    return;
  }

  setState(() => _isLoading = true);

  final url = Uri.parse(
      'https://pharmacy-backend-gdmqvos56-komal-anums-projects.vercel.app/api/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'loginId': loginId, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setInt('userId', data['id']); // Save the id

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showDialog(data['message'] ?? 'Login failed. Please try again.');
    }
  } catch (e) {
    _showDialog('An error occurred. Please check your connection.');
  } finally {
    setState(() => _isLoading = false);
  }
}
  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Login',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _loginIdController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                hintText: 'Enter your email or phone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: _obscurePassword
                        ? Colors.grey
                        : const Color(0xFF00A7D2),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                hintText: 'Enter your password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage()),
                ),
                child: const Text('Forgot Password?',
                    style: TextStyle(color: Color(0xFF00A7D2))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A7D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupPage())),
                    child: const Text('Sign Up',
                        style: TextStyle(color: Color(0xFF00A7D2))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            SocialButton(
                icon: Icons.g_mobiledata,
                text: 'Sign in with Google',
                onPressed: () {}),
            SocialButton(
                icon: Icons.facebook,
                text: 'Sign in with Facebook',
                onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const SocialButton(
      {super.key,
      required this.icon,
      required this.text,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Color iconColor = icon == Icons.facebook
        ? Colors.blue
        : (icon == Icons.g_mobiledata ? Colors.red : Colors.black);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text(text, style: const TextStyle(color: Colors.black)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
    );
  }
}