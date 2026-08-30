import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

class CropDiseaseResult {
  final bool success;
  final String crop;
  final String disease;
  final String overview;
  final String symptoms;
  final String fertilizer;
  final String treatment;
  final String dosage;
  final String timing;
  final String prevention;
  final String precautions;
  final String response;
  final String language;
  final String? errorCode;
  final String? errorMessage;

  const CropDiseaseResult({
    required this.success,
    required this.crop,
    required this.disease,
    this.overview = '',
    this.symptoms = '',
    this.fertilizer = '',
    this.treatment = '',
    this.dosage = '',
    this.timing = '',
    this.prevention = '',
    this.precautions = '',
    this.response = '',
    this.language = 'en',
    this.errorCode,
    this.errorMessage,
  });

  factory CropDiseaseResult.fromJson(Map<String, dynamic> json) {
    return CropDiseaseResult(
      success: json['success'] as bool? ?? false,
      crop: json['crop'] as String? ?? '',
      disease: json['disease'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      symptoms: json['symptoms'] as String? ?? '',
      fertilizer: json['fertilizer'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      timing: json['timing'] as String? ?? '',
      prevention: json['prevention'] as String? ?? '',
      precautions: json['precautions'] as String? ?? '',
      response: json['response'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      errorCode: json['error_code'] as String?,
      errorMessage: json['message'] as String?,
    );
  }

  factory CropDiseaseResult.error(String code, String message) {
    return CropDiseaseResult(
      success: false,
      crop: '',
      disease: '',
      errorCode: code,
      errorMessage: message,
    );
  }
}

class CropDiseaseService {
  static final CropDiseaseService _instance = CropDiseaseService._internal();
  factory CropDiseaseService() => _instance;
  CropDiseaseService._internal();

  static const Duration _timeout = Duration(seconds: 60);

  List<String> get _candidateUrls {
    final configured = ApiConfig.baseUrl;
    final list = <String>[configured];
    if (!ApiConfig.isProduction) {
      if (!list.contains('http://10.0.2.2:8000')) {
        list.add('http://10.0.2.2:8000');
      }
      if (!list.contains('http://localhost:8000')) {
        list.add('http://localhost:8000');
      }
    }
    return list;
  }

  Future<CropDiseaseResult> getRecommendation({
    required String crop,
    required String disease,
    required String language,
  }) async {
    final body = {
      'crop': crop.trim(),
      'disease': disease.trim(),
      'language': language.trim(),
    };

    for (final base in _candidateUrls) {
      final uri = Uri.parse('$base/api/ai/crop-disease');
      debugPrint('[CropDiseaseService] Requesting $uri');

      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        debugPrint('[CropDiseaseService] Response status: ${response.statusCode}');
        final data = _parseJson(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          return CropDiseaseResult.fromJson(data);
        }

        // Retry fallback if server gave 502/503 (Render waking up)
        if (response.statusCode >= 500 &&
            _candidateUrls.length > 1 &&
            base != _candidateUrls.last) {
          continue;
        }

        final code = data['error_code'] as String? ?? 'SERVER_ERROR';
        final msg = data['message'] as String? ?? 'Failed to generate recommendation. Please try again.';
        return CropDiseaseResult.error(code, msg);

      } on SocketException catch (e) {
        debugPrint('[CropDiseaseService] SocketException: $e');
        if (base != _candidateUrls.last) continue;
        return CropDiseaseResult.error('NETWORK_ERROR', 'Cannot reach AI server. Please check your internet connection.');
      } on TimeoutException {
        if (base != _candidateUrls.last) continue;
        return CropDiseaseResult.error('TIMEOUT', 'Request timed out. Please try again.');
      } catch (e) {
        debugPrint('[CropDiseaseService] Error: $e');
        if (base != _candidateUrls.last) continue;
        return CropDiseaseResult.error('SERVER_ERROR', 'An unexpected error occurred. Please try again.');
      }
    }

    return CropDiseaseResult.error('NETWORK_ERROR', 'Could not connect to AgroVision AI server.');
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }
}
