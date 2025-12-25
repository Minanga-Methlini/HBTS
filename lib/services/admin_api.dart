import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';


class AdminApi {
  // =======================
  // GET ALL CUSTOMERS
  // =======================
  static Future<List<dynamic>> fetchCustomers() async {
    final token = await TokenStore.getAccessToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/customers"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load customers (${response.statusCode})");
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  // =======================
  // GET CUSTOMER DETAILS
  // =======================
  static Future<Map<String, dynamic>> fetchCustomerDetails(int userId) async {
    final token = await TokenStore.getAccessToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/customers/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load customer (${response.statusCode})");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // =======================
  // GET CUSTOMER BOOKINGS
  // =======================
  static Future<List<dynamic>> fetchCustomerBookings(int userId) async {
    final token = await TokenStore.getAccessToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/customers/$userId/bookings"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load bookings (${response.statusCode})");
    }

    return jsonDecode(response.body) as List<dynamic>;
  }
}
