import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_store.dart';

class NotificationApi {
  static const String baseUrl =
      "http://10.0.2.2:4000/api/notifications";

  static Future<List<dynamic>> fetchNotifications() async {
    final token = await TokenStore.getAccessToken();

    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load notifications");
  }

  static Future<void> markAsRead(String id) async {
    final token = await TokenStore.getAccessToken();

    await http.patch(
      Uri.parse("$baseUrl/$id/read"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }
}
