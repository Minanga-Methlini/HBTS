import 'package:flutter/material.dart';
import 'login_page.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  void _backToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Signup is not configured for the admin app.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _backToLogin(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
