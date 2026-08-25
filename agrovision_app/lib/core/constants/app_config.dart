import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_config.dart';

/// Central app configuration loaded from .env and [ApiConfig].
class AppConfig {
  AppConfig._();

  /// Override API base URL at runtime (e.g., from Developer Settings in debug mode)
  static void setCustomApiBaseUrl(String? url) {
    ApiConfig.setCustomBaseUrl(url);
  }

  /// Production deployed backend URL (HTTPS)
  static String get productionApiBaseUrl => ApiConfig.productionBaseUrl;

  /// Development local Wi-Fi backend URL
  static String get developmentApiBaseUrl => ApiConfig.developmentBaseUrl;

  /// Web localhost backend URL
  static String get webApiBaseUrl => ApiConfig.defaultWebBaseUrl;

  /// Default API base URL based on environment
  static String get defaultApiBaseUrl => ApiConfig.baseUrl;

  /// FastAPI backend base URL
  static String get apiBaseUrl => ApiConfig.baseUrl;

  static String get predictEndpoint => ApiConfig.predictEndpoint;
  static String get healthEndpoint  => ApiConfig.healthEndpoint;

  static String get supabaseUrl     => dotenv.env['SUPABASE_URL']      ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Confidence thresholds (percent, 0–100).
  static const double cropConfidenceThreshold    = 65.0;
  static const double diseaseConfidenceThreshold = 50.0;

  /// Request timeout for prediction API call (120s handles cold-start model load)
  static const Duration apiTimeout = ApiConfig.receiveTimeout;

  /// Health check timeout (quick probe)
  static const Duration healthCheckTimeout = ApiConfig.healthCheckTimeout;

  /// Max image file size before upload (bytes)
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB

  /// Max image dimension after compression
  static const int maxImageDimension = 1920;

  /// JPEG compression quality (0–100)
  static const int imageQuality = 85;

  /// Supported crops (matches backend labels.json)
  static const List<String> supportedCrops = [
    'Blackgram',
    'Cotton',
    'Eggplant',
    'Groundnut',
    'Paddy',
    'Sugarcane',
    'Sunflower',
    'Tomato',
    'Turmeric',
    'Wheat',
  ];

  /// Error types from backend
  static const String errInvalidImage       = 'INVALID_IMAGE';
  static const String errNotLeaf            = 'NOT_LEAF';
  static const String errLowQuality         = 'LOW_IMAGE_QUALITY';
  static const String errModelUnavailable   = 'MODEL_UNAVAILABLE';
  static const String errLowCropConf        = 'LOW_CROP_CONFIDENCE';
  static const String errLowDiseaseConf     = 'LOW_DISEASE_CONFIDENCE';
  static const String errUnsupportedCrop    = 'UNSUPPORTED_CROP';
  static const String errServerError        = 'SERVER_ERROR';
  static const String errNetworkError       = 'NETWORK_ERROR';
  static const String errTimeout            = 'TIMEOUT';
  static const String errBackendStarting    = 'BACKEND_STARTING';

  /// App version
  static const String appVersion   = '1.0.0';
  static const String modelVersion = 'v3.0 (Two-Stage ML Pipeline)';
}
