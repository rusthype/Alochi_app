import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for A'lochi app.
/// - Tokens: FlutterSecureStorage (encrypted) with SharedPreferences fallback
/// - Feature flags (onboarding, theme): SharedPreferences (reliable on all Android)
class AppStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user_data';

  // ─── Tokens (FlutterSecureStorage + SharedPreferences fallback) ──────────

  static Future<void> saveTokens(String access, String refresh) async {
    try {
      await _storage.write(key: _accessKey, value: access);
      await _storage.write(key: _refreshKey, value: refresh);
    } catch (_) {
      // Fallback to SharedPreferences if secure storage fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      await prefs.setString(_refreshKey, refresh);
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final val = await _storage.read(key: _accessKey);
      if (val != null) return val;
    } catch (_) {}
    // Fallback
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    try {
      final val = await _storage.read(key: _refreshKey);
      if (val != null) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> clearAll() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  static Future<void> saveUserData(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json);
  }

  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // ─── Feature flags — SharedPreferences ONLY (reliable on all Android) ────
  // Onboarding flag, theme preference, etc. should NOT use FlutterSecureStorage
  // because encryption can fail silently on some Android devices.

  static Future<String?> readKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> writeKey(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
