import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../constants/app_config.dart';

/// Central state management via ChangeNotifier / Provider
class AppProvider extends ChangeNotifier {
  bool _darkMode = false;
  String _languageCode = 'en';
  String _sessionId = '';
  String _apiBaseUrl = '';

  AppProvider() {
    _loadPreferences();
  }

  bool get darkMode => _darkMode;
  String get languageCode => _languageCode;
  String get sessionId => _sessionId;
  String get apiBaseUrl =>
      _apiBaseUrl.isNotEmpty ? _apiBaseUrl : ApiConfig.baseUrl;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _languageCode = prefs.getString('language_code') ?? 'en';
    _sessionId = prefs.getString('session_id') ?? _generateSessionId();
    await prefs.setString('session_id', _sessionId);

    // Ensure release & production mode never use local LAN or old cached development URLs
    final storedUrl = prefs.getString('api_base_url') ?? '';
    final isLanOrLocal = storedUrl.startsWith('http://10.') ||
        storedUrl.startsWith('http://192.168.') ||
        storedUrl.startsWith('http://127.0.0.1') ||
        storedUrl.startsWith('http://localhost') ||
        storedUrl.contains(':8000') ||
        storedUrl.isEmpty;

    if (ApiConfig.isProduction || isLanOrLocal) {
      _apiBaseUrl = ApiConfig.productionBaseUrl;
      if (isLanOrLocal && storedUrl.isNotEmpty) {
        // Actively migrate and purge old LAN IP from device storage
        await prefs.setString('api_base_url', _apiBaseUrl);
      }
    } else {
      _apiBaseUrl = storedUrl;
    }

    AppConfig.setCustomApiBaseUrl(_apiBaseUrl);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String url) async {
    _apiBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    AppConfig.setCustomApiBaseUrl(_apiBaseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _apiBaseUrl);
    notifyListeners();
  }

  String _generateSessionId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts * 1234567 % 999999).toString();
    return 'session-$ts-$rand';
  }

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
  ];
}
