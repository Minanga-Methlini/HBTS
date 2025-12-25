import 'package:flutter/material.dart';
import '../services/auth_api.dart';
import '../services/token_store.dart';
import 'home_page.dart';
import '/admin/dashboard.dart';

enum OtpFlow { signupVerify, login2fa }

class OtpScreen extends StatefulWidget {
  final OtpFlow flow;
  final int challengeId;
  final String? tempToken; // only for login

  const OtpScreen({
    super.key,
    required this.flow,
    required this.challengeId,
    this.tempToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the 6-digit OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      // 🔹 SIGNUP OTP VERIFY
      if (widget.flow == OtpFlow.signupVerify) {
        result = await AuthApi.verifySignupOtp(
          challengeId: widget.challengeId,
          otp: otp,
        );
      }
      // 🔹 LOGIN OTP VERIFY
      else {
        final temp = widget.tempToken;
        if (temp == null) throw Exception("Missing temp token");

        result = await AuthApi.verifyLoginOtp(
          tempToken: temp,
          challengeId: widget.challengeId,
          otp: otp,
        );
      }

      final accessToken = result["accessToken"] as String?;
      final refreshToken = result["refreshToken"] as String?;
      final role = result["role"] as String?;

      if (accessToken == null || refreshToken == null || role == null) {
        throw Exception("Invalid auth response from server");
      }

      // 🔐 SAVE TOKENS
      await TokenStore.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // 🔐 SAVE ROLE
      await TokenStore.saveRole(role);

      if (!mounted) return;

      // 🧭 ROLE-BASED NAVIGATION
      if (role == "admin") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.flow == OtpFlow.signupVerify
        ? "Verify Your Account"
        : "Two-Factor Verification";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter the 6-digit code sent to your email/phone",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "OTP",
                      hintText: "123456",
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.blue.shade700,
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
