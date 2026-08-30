import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../core/constants/app_config.dart';
import '../models/prediction_result.dart';
import '../models/api_error.dart';
import 'image_service.dart';

/// Centralized API Service for AgroVision AI.
///
/// Handles network requests to the cloud FastAPI backend:
/// - Connect timeout: 30s
/// - Send timeout: 60s
/// - Receive timeout: 120s
/// - Automatic health check probe at /health and /api/v1/health
/// - Typed errors for no internet, timeout, server warming up, and domain validation.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  List<String> get _candidateUrls {
    final configured = ApiConfig.baseUrl;
    final list = <String>[configured];

    if (!ApiConfig.isProduction) {
      if (kIsWeb) {
        if (!list.contains('http://127.0.0.1:8000')) {
          list.add('http://127.0.0.1:8000');
        }
        if (!list.contains('http://localhost:8000')) {
          list.add('http://localhost:8000');
        }
      } else {
        if (!list.contains('http://10.0.2.2:8000')) {
          list.add('http://10.0.2.2:8000');
        }
      }
    }
    return list;
  }

  // ── Health Check ─────────────────────────────────────────────────────────────

  /// Probes the backend health via GET /health or GET /api/v1/health.
  Future<bool> checkHealth() async {
    for (final base in _candidateUrls) {
      try {
        // Try root /health first
        final uriRoot = Uri.parse('$base/health');
        debugPrint('[ApiService] Health check → $uriRoot');
        try {
          final res = await http
              .get(uriRoot)
              .timeout(ApiConfig.healthCheckTimeout);
          debugPrint('[ApiService] Health check status: ${res.statusCode}');
          if (res.statusCode == 200) {
            return true;
          }
        } catch (e) {
          debugPrint('[ApiService] Health /health failed: $e');
          // Fallback to /api/v1/health
        }

        final uriV1 = Uri.parse('$base/api/v1/health');
        debugPrint('[ApiService] Health check fallback → $uriV1');
        final response = await http
            .get(uriV1)
            .timeout(ApiConfig.healthCheckTimeout);
        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            return data['startup_ready'] as bool? ?? true;
          } catch (_) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Health check base=$base failed: $e');
        // Continue to fallback
      }
    }
    return false;
  }

  /// Returns full health details dictionary.
  Future<Map<String, dynamic>?> getHealthDetails() async {
    for (final base in _candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$base/api/v1/health'))
            .timeout(ApiConfig.healthCheckTimeout);
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {
        // Continue to fallback
      }
    }
    return null;
  }

  // ── Predict from File ─────────────────────────────────────────────────────────

  /// POST /api/v1/predict — upload a [File] as multipart form data.
  Future<PredictionResult> predict(File imageFile) async {
    final bytes = await ImageService.readFileBytes(imageFile);
    final filename = imageFile.path.split(RegExp(r'[\\/]')).last.isEmpty
        ? 'leaf_image.jpg'
        : imageFile.path.split(RegExp(r'[\\/]')).last;

    return predictFromBytes(bytes, filename);
  }

  // ── Predict from Bytes ────────────────────────────────────────────────────────

  /// POST /api/v1/predict using raw bytes (supports Android, Web, iOS).
  Future<PredictionResult> predictFromBytes(
      Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'png'  => 'image/png',
      'webp' => 'image/webp',
      _      => 'image/jpeg',
    };

    ApiError? lastError;

    for (final backendUrl in _candidateUrls) {
      try {
        final uri = Uri.parse('$backendUrl/api/v1/predict');
        final request = http.MultipartRequest('POST', uri);

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: _parseMimeType(mimeType),
        ));
        request.headers['Accept'] = 'application/json';

        final streamedResponse = await request
            .send()
            .timeout(ApiConfig.receiveTimeout, onTimeout: () {
          throw TimeoutException(
              'Prediction request timed out after ${ApiConfig.receiveTimeout.inSeconds}s');
        });

        final response = await http.Response.fromStream(streamedResponse);
        return _handleResponse(response, backendUrl);
      } on ApiError catch (e) {
        if (!e.isNetworkError) {
          rethrow;
        }
        lastError = e;
      } on SocketException {
        lastError = ApiError.noInternet();
      } on TimeoutException {
        lastError = ApiError.timeout(backendUrl);
      } catch (e) {
        final str = e.toString().toLowerCase();
        if (str.contains('timeout')) {
          lastError = ApiError.timeout(backendUrl);
        } else if (str.contains('socket') || str.contains('connection refused') || str.contains('network is unreachable')) {
          lastError = ApiError.noInternet();
        } else {
          lastError = const ApiError(
            type: ApiErrorType.networkError,
            message: 'Unable to complete analysis. Please check your network connection and try again.',
          );
        }
      }
    }

    throw lastError ?? ApiError.network();
  }

  // ── Internal ──────────────────────────────────────────────────────────────────

  PredictionResult _handleResponse(http.Response response, String backendUrl) {
    if (response.statusCode == 503) {
      final data = _parseJsonSafe(response.body);
      final errType = data['error_type'] as String? ?? '';
      if (errType == 'BACKEND_STARTING') {
        throw ApiError.backendStarting();
      }
      throw const ApiError(
        type: ApiErrorType.modelUnavailable,
        message: 'The AI service is temporarily warming up. Please try again shortly.',
        statusCode: 503,
      );
    }

    final data = _parseJsonSafe(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] == false) {
      final errorType = data['error_type'] as String? ?? AppConfig.errServerError;
      final message   = data['message']    as String? ?? 'An unexpected error occurred.';
      throw ApiError.fromErrorType(errorType, message, statusCode: response.statusCode);
    }

    return PredictionResult.fromJson(data);
  }

  Map<String, dynamic> _parseJsonSafe(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  http.MediaType _parseMimeType(String mimeType) {
    final parts = mimeType.split('/');
    return http.MediaType(
      parts.first,
      parts.length > 1 ? parts[1] : 'jpeg',
    );
  }
}
