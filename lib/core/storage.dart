import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._internal();
  static final TokenStorage instance = TokenStorage._internal();

  static const String _swContextTokenKey = 'sw-context-token';
  static const String _languageIdKey = 'sw-language-id';
  static const String _currencyIdKey = 'sw-currency-id';
  static const String _localeTagKey = 'app-locale-tag';
  static const String _flutterConfigKey = 'flutter-app-config';
  static const String _flutterConfigTimestampKey =
      'flutter-app-config-timestamp';

  // Config cache TTL: 1 hour (3600 seconds)
  static const int _configCacheTTL = 3600;

  Future<void> saveContextToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_swContextTokenKey, token);
  }

  Future<void> saveContextTokenFromResponse(Response<dynamic> response) async {
    final fromHeader = response.headers.value('sw-context-token');
    if (fromHeader != null && fromHeader.isNotEmpty) {
      await saveContextToken(fromHeader);
      return;
    }

    final data = response.data;
    if (data is Map) {
      final token = data['token'] ?? data['contextToken'];
      if (token is String && token.isNotEmpty) {
        await saveContextToken(token);
      }
    }
  }

  Future<String?> loadContextToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_swContextTokenKey);
  }

  Future<void> clearContextToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_swContextTokenKey);
  }

  Future<void> saveLanguageId(String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageIdKey, languageId);
  }

  Future<String?> loadLanguageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageIdKey);
  }

  Future<void> saveCurrencyId(String currencyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyIdKey, currencyId);
  }

  Future<String?> loadCurrencyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyIdKey);
  }

  Future<void> saveLocaleTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeTagKey, tag);
  }

  Future<String?> loadLocaleTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeTagKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_swContextTokenKey);
    await prefs.remove(_languageIdKey);
    await prefs.remove(_currencyIdKey);
    await prefs.remove(_localeTagKey);
  }

  Future<bool> getCookieConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cookie_consent') ?? false;
  }

  Future<void> setCookieConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cookie_consent', value);
  }

  /// Save Flutter app config to cache
  Future<void> saveFlutterConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_flutterConfigKey, configJson);
      await prefs.setInt(_flutterConfigTimestampKey, timestamp);
    } catch (e) {
      // Cache save error is not critical, silent pass
    }
  }

  /// Load Flutter app config from cache
  /// If cache is not present or TTL has expired, return null
  Future<Map<String, dynamic>?> loadFlutterConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_flutterConfigKey);
      final timestamp = prefs.getInt(_flutterConfigTimestampKey);

      if (configJson == null || timestamp == null) {
        return null;
      }

      // TTL control
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = (now - timestamp) ~/ 1000; // in seconds

      if (age > _configCacheTTL) {
        // Cache is old, clear
        await clearFlutterConfig();
        return null;
      }

      final config = jsonDecode(configJson) as Map<String, dynamic>;
      return config;
    } catch (e) {
      // Cache read error, clear cache
      await clearFlutterConfig();
      return null;
    }
  }

  /// Clear Flutter app config cache
  Future<void> clearFlutterConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_flutterConfigKey);
      await prefs.remove(_flutterConfigTimestampKey);
    } catch (e) {
      // Cache clear error is not critical
    }
  }

  /// Check if Flutter app config cache is valid
  Future<bool> isFlutterConfigCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_flutterConfigTimestampKey);

      if (timestamp == null) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = (now - timestamp) ~/ 1000; // in seconds

      return age <= _configCacheTTL;
    } catch (e) {
      return false;
    }
  }
}
