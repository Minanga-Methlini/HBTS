import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_store.dart';

class AdminApi {
  // 🌐 Backend base URL
  static const String baseUrl = "http://localhost:4000";
  // Android emulator:
  // static const String baseUrl = "http://10.0.2.2:4000";

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
  // SAFE JSON DECODE
  // =======================
  static dynamic _decode(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  // =======================
  // GET PASSENGERS (SEARCH)
  // GET /admin/passengers?search=
  // =======================
  static Future<List<dynamic>> getPassengers(String search) async {
    final uri = Uri.parse(
      "$baseUrl/admin/passengers?search=${Uri.encodeQueryComponent(search)}",
    );

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (res.statusCode != 200) {
      throw Exception("Failed to load passengers (${res.statusCode})");
    }

    final data = _decode(res);
    return data is List ? data : [];
  }

  // =======================
  // GET PASSENGER DETAILS
  // GET /admin/passengers/:id
  // =======================
  static Future<Map<String, dynamic>> fetchPassengerDetails(
    int userId,
  ) async {
    final uri = Uri.parse("$baseUrl/admin/passengers/$userId");

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (res.statusCode != 200) {
      throw Exception("Failed to load passenger (${res.statusCode})");
    }

    final data = _decode(res);
    if (data is! Map<String, dynamic>) {
      throw Exception("Invalid passenger data");
    }

    return data;
  }

  // =======================
  // GET PASSENGER BOOKINGS
  // GET /admin/passengers/:id/bookings
  // =======================
  static Future<List<dynamic>> fetchPassengerBookings(
    int userId,
  ) async {
    final uri =
        Uri.parse("$baseUrl/admin/passengers/$userId/bookings");

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (res.statusCode == 404) {
      return []; // no bookings
    }

    if (res.statusCode != 200) {
      throw Exception("Failed to load bookings (${res.statusCode})");
    }

    final data = _decode(res);
    return data is List ? data : [];
  }

  // =======================
  // ADD PASSENGER
  // POST /admin/passengers
  // =======================
  static Future<void> addPassenger(
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse("$baseUrl/admin/passengers");

    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      throw Exception("Failed to add passenger (${res.statusCode})");
    }
  }

  // =======================
  // UPDATE PASSENGER
  // PUT /admin/passengers/:id
  // =======================
  static Future<void> updatePassenger(
    int id,
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse("$baseUrl/admin/passengers/$id");

    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update passenger (${res.statusCode})");
    }
  }

  // =======================
  // DELETE PASSENGER
  // DELETE /admin/passengers/:id
  // =======================
  static Future<void> deletePassenger(int id) async {
    final uri = Uri.parse("$baseUrl/admin/passengers/$id");

    final res = await http.delete(
      uri,
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to delete passenger (${res.statusCode})");
    }
  }

  // =======================
  // GET BUS OWNERS (OPERATORS)
  // GET /admin/operators?status=&search=
  // =======================
  static Future<List<dynamic>> getBusOwners({
    String? status,
    String search = "",
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) {
      query["status"] = status;
    }
    if (search.isNotEmpty) {
      query["search"] = search;
    }

    final uri = Uri.parse("$baseUrl/admin/operators")
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (res.statusCode != 200) {
      throw Exception("Failed to load bus owners (${res.statusCode})");
    }

    final data = _decode(res);
    return data is List ? data : [];
  }

  // =======================
  // GET BUSES
  // GET /admin/buses
  // =======================
  static Future<List<dynamic>> getBuses({
    int? busId,
    int? operatorId,
    String? licensePlateNo,
    String? routeNo,
    int? capacity,
    String? serviceType,
  }) async {
    final query = <String, String>{};
    if (busId != null) query["busId"] = busId.toString();
    if (operatorId != null) query["operatorId"] = operatorId.toString();
    if (licensePlateNo != null && licensePlateNo.isNotEmpty) {
      query["licensePlateNo"] = licensePlateNo;
    }
    if (routeNo != null && routeNo.isNotEmpty) {
      query["routeNo"] = routeNo;
    }
    if (capacity != null) query["capacity"] = capacity.toString();
    if (serviceType != null && serviceType.isNotEmpty) {
      query["serviceType"] = serviceType;
    }

    final uri = Uri.parse("$baseUrl/admin/buses")
        .replace(queryParameters: query.isEmpty ? null : query);

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception("Access denied. Admin login required.");
    }

    if (res.statusCode != 200) {
      throw Exception("Failed to load buses (${res.statusCode})");
    }

    final data = _decode(res);
    return data is List ? data : [];
  }
}
