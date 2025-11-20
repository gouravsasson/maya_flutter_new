// lib/core/cache/cache_helper.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static const _prefix = 'cache_';

  static Future<void> set(String key, Map<String, dynamic> data, {Duration ttl = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'data': data,
      'expires_at': DateTime.now().add(ttl).millisecondsSinceEpoch,
    };
    await prefs.setString(_prefix + key, jsonEncode(cacheData));
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefix + key);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> cache = jsonDecode(raw);
      final expiresAt = cache['expires_at'] as int?;
      if (expiresAt == null || DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await prefs.remove(_prefix + key); // expired
        return null;
      }
      return cache['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefix + key);
  }
}