import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

class AdminApi {
  // =======================
  // INTERNAL AUTH HEADER
  // =======================
static Future<Map<String, String>> _authHeaders() async {
  final token = await TokenStore.getAccessToken();

  // 🔍 DEBUG: CHECK IF TOKEN EXISTS
  print("ADMIN API TOKEN: $token");

  if (token == null || token.isEmpty) {
    throw Exception("Not authenticated. Please login again.");
  }

  return {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };
}

  // =======================
  // GET ALL CUSTOMERS
  // =======================
  static Future<List<dynamic>> fetchCustomers() async {
    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/customers"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load customers (${response.statusCode})",
      );
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  // =======================
  // GET CUSTOMER DETAILS
  // =======================
  static Future<Map<String, dynamic>> fetchCustomerDetails(int userId) async {
    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/customers/$userId"),
      headers: await _authHeaders(),
    );

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
  // =======================
  static Future<List<dynamic>> fetchCustomerBookings(int userId) async {
    final response = await http.get(
      Uri.parse(
        "${AppConfig.baseUrl}/api/admin/customers/$userId/bookings",
      ),
      headers: await _authHeaders(),
    );

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
