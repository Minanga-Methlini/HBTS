import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'token_store.dart';

class UserApi {
  // 🔴 CHANGE this to your backend base URL
  static const String baseUrl = "http://localhost:8080";

  // 🔴 CHANGE if your endpoint is different
  static const String profileEndpoint = "/api/users/me";

  static Future<AppUser> fetchLoggedInUser() async {
  final token = await TokenStore.getAccessToken();
 // <-- tell me if method name differs

    final res = await http.get(
      Uri.parse("$baseUrl$profileEndpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['user'] ?? json;
      return AppUser.fromJson(Map<String, dynamic>.from(data));
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("AUTH_EXPIRED");
    }

    throw Exception("Failed to load user profile");
  }
}
