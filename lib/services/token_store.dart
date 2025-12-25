import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _storage = FlutterSecureStorage();

  //Save access & refresh tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: "accessToken", value: accessToken);
    await _storage.write(key: "refreshToken", value: refreshToken);
  }

  // Save role (ADMIN / PASSENGER / etc.)
  static Future<void> saveRole(String role) async {
    await _storage.write(key: "role", value: role);
  }

  // Read role
  static Future<String?> getRole() async {
    return await _storage.read(key: "role");
  }

  // Check admin
  static Future<bool> isAdmin() async {
    final role = await _storage.read(key: "role");
    return role == "admin";
  }

  // Logout / Clear everything
  static Future<void> clear() async {
    await _storage.delete(key: "accessToken");
    await _storage.delete(key: "refreshToken");
    await _storage.delete(key: "role");
  }
}
