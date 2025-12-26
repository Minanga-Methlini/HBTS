import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_store.dart'; // adjust path if needed

class AdminApi {
  // 🔗 Backend base URL
  //static const String baseUrl = "http://10.0.2.2:4000";
   static const String baseUrl = "http://localhost:4000";  //Chrome emulator local

  // =======================
  // AUTH HEADERS
  // =======================
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStore.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated. Please login again.");
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // =======================
  // GET PASSENGERS (SEARCH)
  // GET /admin/passengers?search=
  // =======================
  static Future<List<dynamic>> getPassengers(String search) async {
    final uri = Uri.parse(
      "$baseUrl/admin/passengers?search=${Uri.encodeQueryComponent(search)}",
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load passengers (${response.statusCode})",
      );
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  // =======================
  // GET CUSTOMER DETAILS
  // GET /admin/passengers/:id
  // =======================
  static Future<Map<String, dynamic>> fetchCustomerDetails(int userId) async {
    final uri = Uri.parse("$baseUrl/admin/passengers/$userId");

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load customer (${response.statusCode})",
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // =======================
  // GET CUSTOMER BOOKINGS
  // GET /admin/passengers/:id/bookings
  // =======================
  static Future<List<dynamic>> fetchCustomerBookings(int userId) async {
    final uri =
        Uri.parse("$baseUrl/admin/passengers/$userId/bookings");

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load bookings (${response.statusCode})",
      );
    }

    return jsonDecode(response.body) as List<dynamic>;
  }
}
