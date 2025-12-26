import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // 🔐 Storage Keys (single source of truth)
  static const String _accessTokenKey = "accessToken";
  static const String _refreshTokenKey = "refreshToken";
  static const String _roleKey = "role";

  // ===== ACCESS TOKEN =====
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // ===== REFRESH TOKEN =====
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // ===== SAVE TOKENS =====
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );
    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  // ===== ROLE =====
  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == "admin";
  }

  // ===== AUTH STATE =====
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ===== LOGOUT =====
  static Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
  }
}
