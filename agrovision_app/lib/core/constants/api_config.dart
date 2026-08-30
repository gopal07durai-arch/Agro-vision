import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API and Network Configuration for AgroVision AI.
///
/// Separates PRODUCTION and DEVELOPMENT configurations cleanly:
/// - Production: Uses public HTTPS backend domain (from .env PROD_API_BASE_URL or default).
/// - Development: Uses local development backend URL only during debug mode.
///
/// The release APK never uses local laptop IPs.
class ApiConfig {
  ApiConfig._();

  /// Default production cloud backend base URL (HTTPS).
  ///
  /// To point to your own deployed FastAPI instance, set PROD_API_BASE_URL
  /// in .env or update this constant.
  static const String defaultProductionBaseUrl = 'https://agrovision-ai.onrender.com';

  /// Fallback URL for development mode (Android emulator default).
  static const String defaultDevelopmentBaseUrl = 'http://10.0.2.2:8000';

  /// Web localhost fallback URL (used ONLY in web debug).
  static const String defaultWebBaseUrl = 'http://127.0.0.1:8000';

  static String? _customBaseUrl;

  /// Allows setting a custom URL at runtime (e.g. from developer settings in debug mode).
  static void setCustomBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    } else {
      _customBaseUrl = null;
    }
  }

  /// Production base URL (HTTPS).
  static String get productionBaseUrl {
    final envUrl = dotenv.env['PROD_API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return defaultProductionBaseUrl;
  }

  /// Development base URL (for debug mode only).
  static String get developmentBaseUrl {
    final envUrl = dotenv.env['DEV_API_BASE_URL'];
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return defaultDevelopmentBaseUrl;
  }

  /// Current environment: 'production' in release mode, or explicit APP_ENV in .env.
  static String get environment {
    if (kReleaseMode) return 'production';
    final env = dotenv.env['APP_ENV']?.toLowerCase().trim();
    if (env == 'production' || env == 'development') {
      return env!;
    }
    return 'development';
  }

  /// Is the app running in production mode?
  static bool get isProduction => environment == 'production';

  /// Effective API Base URL.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (kIsWeb) {
      return dotenv.env['API_BASE_URL_WEB'] ?? defaultWebBaseUrl;
    }

    if (!isProduction) {
      return developmentBaseUrl;
    }

    final explicit = dotenv.env['API_BASE_URL'];
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim().replaceAll(RegExp(r'/+$'), '');
    }

    return productionBaseUrl;
  }

  // ── Endpoints ─────────────────────────────────────────────────────────────────────────
  static String get predictEndpoint => '\$baseUrl/api/v1/predict';
  static String get healthEndpoint => '\$baseUrl/api/v1/health';
  static String get rootHealthEndpoint => '\$baseUrl/health';
  static String get chatEndpoint => '\$baseUrl/api/chat';
  static String get chatHealthEndpoint => '\$baseUrl/api/chat/health';

  // ── Network Timeouts ──────────────────────────────────────────────────────
  /// Connect timeout (establishing connection to server)
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Send timeout (uploading leaf image)
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Receive / Total API timeout (running ML inference on backend)
  static const Duration receiveTimeout = Duration(seconds: 120);

  /// Quick health check probe timeout
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  /// Maximum retry attempts on transient network errors
  static const int maxRetries = 2;
}
