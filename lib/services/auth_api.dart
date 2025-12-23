import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthApi {
  static Uri _u(String path) => Uri.parse("${AppConfig.baseUrl}$path");

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {"message": res.body};
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      _u("/api/auth/passenger/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
      }),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body["message"] ?? "Signup failed");
  }

  // NOW returns tokens too (after backend update)
  static Future<Map<String, dynamic>> verifySignupOtp({
    required int challengeId,
    required String otp,
  }) async {
    final res = await http.post(
      _u("/api/auth/passenger/signup/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"challengeId": challengeId, "otp": otp}),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body["message"] ?? "OTP verification failed");
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _u("/api/auth/passenger/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body["message"] ?? "Login failed");
  }

  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String tempToken,
    required int challengeId,
    required String otp,
  }) async {
    final res = await http.post(
      _u("/api/auth/passenger/login/verify-otp"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $tempToken",
      },
      body: jsonEncode({"challengeId": challengeId, "otp": otp}),
    );

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body["message"] ?? "Login OTP verification failed");
  }
}
