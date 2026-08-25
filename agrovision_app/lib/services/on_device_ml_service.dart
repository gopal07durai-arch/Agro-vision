import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/api_error.dart';
import '../models/prediction_result.dart';
import '../core/l10n/agricultural_localizations.dart';
import 'leaf_validator_service.dart';

/// On-Device ML Service using TensorFlow Lite
/// Runs Stage 1 Crop Classification and Stage 2 Disease Detection directly on Android.
class OnDeviceMLService {
  OnDeviceMLService._();
  static final OnDeviceMLService instance = OnDeviceMLService._();

  // Cached TFLite Interpreters
  Interpreter? _cropInterpreter;
  final Map<String, Interpreter> _diseaseInterpreters = {};

  // Config metadata
  List<String> _cropClasses = [];
  double _cropThreshold = 65.0;
  double _diseaseThreshold = 50.0;
  Map<String, dynamic> _diseaseConfig = {};

  bool _isInitialized = false;

  /// Initialize the Stage 1 model and configs from assets
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // 1. Load Crop Labels Config
      final cropLabelsJson =
          await rootBundle.loadString('assets/models/crop_labels.json');
      final cropData = jsonDecode(cropLabelsJson) as Map<String, dynamic>;
      _cropClasses = List<String>.from(cropData['crops'] as List);
      _cropThreshold = (cropData['threshold'] as num?)?.toDouble() ?? 65.0;

      // 2. Load Disease Config
      final diseaseConfigJson =
          await rootBundle.loadString('assets/models/disease_models_config.json');
      final diseaseData = jsonDecode(diseaseConfigJson) as Map<String, dynamic>;
      _diseaseThreshold =
          (diseaseData['disease_threshold'] as num?)?.toDouble() ?? 50.0;
      _diseaseConfig =
          diseaseData['models'] as Map<String, dynamic>? ?? {};

      // 3. Load Stage 1 Crop Classifier Interpreter
      _cropInterpreter = await Interpreter.fromAsset(
        'assets/models/crop_classifier.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      _isInitialized = true;
      debugPrint('[OnDeviceML] Initialized Stage 1 Crop Classifier with ${_cropClasses.length} crops.');
    } catch (e, stack) {
      debugPrint('[OnDeviceML] Initialization error: $e\n$stack');
    }
  }

  /// Get or lazily load a specific crop's disease interpreter
  Future<Interpreter?> _getDiseaseInterpreter(String crop) async {
    if (_diseaseInterpreters.containsKey(crop)) {
      return _diseaseInterpreters[crop];
    }
    final cropCfg = _diseaseConfig[crop] as Map<String, dynamic>?;
    if (cropCfg == null) return null;

    final tfliteFile = cropCfg['tflite_file'] as String?;
    if (tfliteFile == null) return null;

    try {
      final interpreter = await Interpreter.fromAsset(
        'assets/models/$tfliteFile',
        options: InterpreterOptions()..threads = 2,
      );
      _diseaseInterpreters[crop] = interpreter;
      return interpreter;
    } catch (e) {
      debugPrint('[OnDeviceML] Failed to load disease interpreter for $crop: $e');
      return null;
    }
  }

  /// Preprocess image into a 4D float32 tensor [1, size, size, 3]
  List<List<List<List<double>>>> _preprocessImage(
    img.Image image,
    int targetSize,
    String normType,
  ) {
    final resized = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.linear,
    );

    // Shape: [1, targetSize, targetSize, 3]
    final buffer = List.generate(
      1,
      (_) => List.generate(
        targetSize,
        (y) => List.generate(
          targetSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            final r = pixel.r.toDouble();
            final g = pixel.g.toDouble();
            final b = pixel.b.toDouble();

            if (normType == '0_1') {
              return [r / 255.0, g / 255.0, b / 255.0];
            } else {
              // '0_255' or 'mobilenet_v2' (raw 0..255 float, model handles normalization)
              return [r, g, b];
            }
          },
        ),
      ),
    );

    return buffer;
  }

  /// Complete On-Device Leaf Analysis Pipeline
  Future<PredictionResult> analyzeImage(File imageFile) async {
    await initialize();

    final stopwatch = Stopwatch()..start();

    // ── STEP 1: Decode image ─────────────────────────────────────────────────
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw const ApiError(
        type: ApiErrorType.lowImageQuality,
        message: 'Unable to decode image. Please select a valid JPEG or PNG photo.',
        statusCode: 422,
      );
    }

    // ── STEP 2: Pure Dart Leaf Validation (OOD & Quality) ────────────────────
    final valResult = LeafValidatorService.validateImage(decodedImage);
    if (!valResult.isValid) {
      if (valResult.errorType == LeafValidationError.notLeaf) {
        throw ApiError(
          type: ApiErrorType.notLeaf,
          message: valResult.errorMessage,
          statusCode: 422,
        );
      } else {
        throw ApiError(
          type: ApiErrorType.lowImageQuality,
          message: valResult.errorMessage,
          statusCode: 422,
        );
      }
    }

    if (_cropInterpreter == null) {
      throw const ApiError(
        type: ApiErrorType.modelUnavailable,
        message: 'On-device AI model not ready. Please try again.',
        statusCode: 503,
      );
    }

    // ── STEP 3: Stage 1 Crop Classification ──────────────────────────────────
    final cropInput = _preprocessImage(decodedImage, 224, '0_255');
    final cropOutput = List.generate(1, (_) => List.filled(_cropClasses.length, 0.0));

    _cropInterpreter!.run(cropInput, cropOutput);

    final cropProbs = cropOutput[0];
    int bestCropIdx = 0;
    double maxCropProb = -1.0;
    for (int i = 0; i < cropProbs.length; i++) {
      if (cropProbs[i] > maxCropProb) {
        maxCropProb = cropProbs[i];
        bestCropIdx = i;
      }
    }

    final detectedCrop = _cropClasses[bestCropIdx];
    final cropConfidence = maxCropProb * 100.0;

    // Validate Crop Confidence Threshold
    if (cropConfidence < _cropThreshold) {
      throw ApiError(
        type: ApiErrorType.lowCropConfidence,
        message:
            'This image does not appear to be a supported crop leaf (confidence: ${cropConfidence.toStringAsFixed(1)}%). Please upload a clearer leaf photo.',
        statusCode: 422,
      );
    }

    // ── STEP 4: Stage 2 Disease Detection ───────────────────────────────────
    final cropCfg = _diseaseConfig[detectedCrop] as Map<String, dynamic>?;
    if (cropCfg == null) {
      throw ApiError(
        type: ApiErrorType.unsupportedCrop,
        message: 'No disease classification model found for crop: $detectedCrop',
        statusCode: 422,
      );
    }

    final diseaseInterpreter = await _getDiseaseInterpreter(detectedCrop);
    if (diseaseInterpreter == null) {
      throw ApiError(
        type: ApiErrorType.modelUnavailable,
        message: 'Failed to load disease model for $detectedCrop',
        statusCode: 503,
      );
    }

    final int targetSize = (cropCfg['size'] as num?)?.toInt() ?? 224;
    final String normType = (cropCfg['norm'] as String?) ?? '0_255';
    final List<String> rawClasses =
        List<String>.from(cropCfg['classes'] as List);
    final Map<String, dynamic>? classMap =
        cropCfg['class_map'] as Map<String, dynamic>?;

    final diseaseInput =
        _preprocessImage(decodedImage, targetSize, normType);
    final diseaseOutput =
        List.generate(1, (_) => List.filled(rawClasses.length, 0.0));

    diseaseInterpreter.run(diseaseInput, diseaseOutput);

    final diseaseProbs = diseaseOutput[0];
    int bestDiseaseIdx = 0;
    double maxDiseaseProb = -1.0;
    for (int i = 0; i < diseaseProbs.length; i++) {
      if (diseaseProbs[i] > maxDiseaseProb) {
        maxDiseaseProb = diseaseProbs[i];
        bestDiseaseIdx = i;
      }
    }

    final rawPredictedDisease = rawClasses[bestDiseaseIdx];
    String finalDisease = rawPredictedDisease;
    if (classMap != null && classMap.containsKey(rawPredictedDisease)) {
      finalDisease = classMap[rawPredictedDisease] as String;
    }

    double diseaseConfidence = maxDiseaseProb * 100.0;

    // Check Sunflower wheat-contaminated sentinel
    if (finalDisease == '__WHEAT_CLASS__') {
      throw ApiError(
        type: ApiErrorType.lowDiseaseConfidence,
        message:
            'Unclear leaf symptoms on $detectedCrop. Please upload a clearer crop leaf photo.',
        statusCode: 422,
      );
    }

    // Validate Disease Confidence Threshold
    if (diseaseConfidence < _diseaseThreshold) {
      throw ApiError(
        type: ApiErrorType.lowDiseaseConfidence,
        message:
            'Disease symptoms on $detectedCrop are ambiguous or low confidence (${diseaseConfidence.toStringAsFixed(1)}%). Please upload a clearer leaf image.',
        statusCode: 422,
      );
    }

    stopwatch.stop();

    // ── STEP 5: Build Enriched Recommendation & Result ───────────────────────
    String severity = 'Medium';
    if (finalDisease.toLowerCase() == 'healthy') {
      severity = 'None';
    } else if ([
      'Anthracnose', 'Yellow Mosaic', 'Army Worm', 'Bacterial Blight',
      'Target Spot', 'Mosaic Virus', 'White Mold', 'Wilt Disease',
      'Late Leaf Spot', 'Rust', 'Leaf Blast', 'Leaf Blight', 'Sheath Blight',
      'Red Rot', 'Downy Mildew', 'Rhizopus Head Rot', 'Sclerotinia',
      'Late Blight', 'Yellow Leaf Curl Virus', 'Rhizome Disease',
      'Crown Root Rot', 'Leaf Rust', 'Loose Smut'
    ].contains(finalDisease)) {
      severity = 'High';
    } else if (['Small Leaf', 'Dry Leaf'].contains(finalDisease)) {
      severity = 'Low';
    }

    // Retrieve offline enriched recommendation from AgriculturalLocalizations
    final rec = AgriculturalLocalizations.getLocalizedRecommendation(
      detectedCrop,
      finalDisease,
      null,
      'en',
    );

    final fertData = FertilizerData(
      name: rec?.fertilizerSection?.name ?? rec?.productName ?? '',
      dosage: rec?.fertilizerSection?.dosage ?? rec?.dosage ?? '',
      application: rec?.fertilizerSection?.applicationMethod ?? rec?.applicationMethod ?? '',
      frequency: rec?.fertilizerSection?.frequency ?? rec?.frequency ?? '',
    );

    return PredictionResult(
      crop: detectedCrop,
      cropConfidence: cropConfidence,
      disease: finalDisease,
      diseaseConfidence: diseaseConfidence,
      severity: severity,
      fertilizer: fertData,
      recommendation: rec,
      predictionTimeMs: stopwatch.elapsedMilliseconds,
      modelVersion: 'AgroVision TFLite On-Device v1.0',
    );
  }

  void dispose() {
    _cropInterpreter?.close();
    for (final inter in _diseaseInterpreters.values) {
      inter.close();
    }
    _diseaseInterpreters.clear();
    _isInitialized = false;
  }
}
