import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/api_error.dart';
import '../models/prediction_result.dart';
import 'api_service.dart';
import 'image_service.dart';
import 'on_device_ml_service.dart';
import 'supabase_service.dart';

/// Detection pipeline progress steps shown in the scan UI.
enum DetectionStep {
  idle,
  compressing,   // Preparing & compressing image
  checking,      // Preprocessing
  analyzing,     // On-device ML feature extraction
  identifying,   // Two-stage Crop + Disease model inference
  complete,
  error,
}

/// Orchestrates the full on-device detection pipeline:
///   1. Compress & validate image (client-side)
///   2. Run OnDeviceMLService (Stage 1 Crop Classifier + Stage 2 Disease Model via TFLite)
///   3. Pure Dart leaf quality & non-leaf validation
///   4. Localized enriched fertilizer recommendation from AgriculturalLocalizations
///   5. Save result to Supabase (background, safe when offline)
///
/// Throws [ApiError] for all failure modes.
class DetectionService extends ChangeNotifier {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  final _api          = ApiService();
  final _imageService = ImageService();
  final _supabase     = SupabaseService();

  DetectionStep _step = DetectionStep.idle;
  double        _progress = 0.0;
  String        _statusMessage = '';
  PredictionResult? _lastResult;
  ApiError?         _lastError;
  String?           _savedPredictionId;

  DetectionStep     get step              => _step;
  double            get progress          => _progress;
  String            get statusMessage     => _statusMessage;
  PredictionResult? get lastResult        => _lastResult;
  ApiError?         get lastError         => _lastError;
  String?           get savedPredictionId => _savedPredictionId;

  bool get isAnalyzing =>
      _step != DetectionStep.idle &&
      _step != DetectionStep.complete &&
      _step != DetectionStep.error;

  void _update(DetectionStep step, double progress, String message) {
    _step = step;
    _progress = progress;
    _statusMessage = message;
    notifyListeners();
  }

  /// Full analysis pipeline.
  /// Executes 100% on-device without requiring PC or network connection.
  Future<PredictionResult> analyze(File imageFile, String sessionId) async {
    _lastResult = null;
    _lastError = null;
    _savedPredictionId = null;

    try {
      // ── Step 1: Compress & optimize image ────────────────────────────────────
      _update(DetectionStep.compressing, 0.15, 'Preparing image...');
      final compressedFile = await _imageService.validateAndCompress(imageFile);

      // ── Step 2: On-Device ML Inference ───────────────────────────────────────
      _update(DetectionStep.analyzing, 0.40, 'Analyzing crop leaf on device...');
      _update(DetectionStep.identifying, 0.70, 'Identifying crop & disease...');

      PredictionResult result;
      try {
        result = await OnDeviceMLService.instance.analyzeImage(compressedFile);
      } catch (e) {
        if (kIsWeb) {
          // On web browser target, fallback to HTTP API if TFLite C library is unavailable
          result = await _api.predict(compressedFile);
        } else {
          rethrow;
        }
      }

      // ── Step 3: Save to Supabase (background, non-blocking, safe offline) ────
      _update(DetectionStep.complete, 0.95, 'Finalizing recommendation...');
      _lastResult = result;

      _supabase
          .savePrediction(
            sessionId: sessionId,
            prediction: result,
          )
          .then((id) {
        _savedPredictionId = id;
      }).catchError((e) {
        debugPrint('[DetectionService] Supabase sync skipped (offline): $e');
      });

      _update(DetectionStep.complete, 1.0, 'Analysis complete!');
      return result;
    } on ApiError catch (e) {
      _lastError = e;
      _update(DetectionStep.error, 0.0, e.message);
      rethrow;
    } catch (e) {
      final err = ApiError(
        type: ApiErrorType.unknown,
        message: 'Analysis failed: $e',
      );
      _lastError = err;
      _update(DetectionStep.error, 0.0, err.message);
      throw err;
    }
  }

  /// Reset to idle state (call when user dismisses error or starts new scan).
  void reset() {
    _step = DetectionStep.idle;
    _progress = 0.0;
    _statusMessage = '';
    _lastResult = null;
    _lastError = null;
    _savedPredictionId = null;
    notifyListeners();
  }
}
