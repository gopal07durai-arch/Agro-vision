import 'recommendation_result.dart';

/// Represents a successful prediction from the FastAPI backend.
/// Fields map directly to the /api/v1/predict JSON response.
class PredictionResult {
  final String crop;
  final double cropConfidence; // 0 – 100
  final String disease;
  final double diseaseConfidence; // 0 – 100
  final String severity; // 'High' | 'Medium' | 'Low' | 'None'
  // Legacy flat fertilizer field — preserved for backward compat
  final FertilizerData fertilizer;
  // Enriched structured recommendation (new — null if no verified data exists)
  final RecommendationResult? recommendation;
  final int predictionTimeMs;
  final String modelVersion;

  const PredictionResult({
    required this.crop,
    required this.cropConfidence,
    required this.disease,
    required this.diseaseConfidence,
    required this.severity,
    required this.fertilizer,
    this.recommendation,
    this.predictionTimeMs = 0,
    this.modelVersion = '',
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Handle nested crop/disease objects OR flat fields
    final dynamic cropRaw = json['crop'];
    final dynamic diseaseRaw = json['disease'];

    String cropName;
    double cropConf;
    if (cropRaw is Map<String, dynamic>) {
      cropName = cropRaw['name'] as String? ?? '';
      cropConf = ((cropRaw['confidence'] as num?) ?? 0).toDouble() * 100;
    } else {
      cropName = json['crop_name'] as String? ?? cropRaw?.toString() ?? '';
      cropConf = ((json['crop_confidence'] as num?) ?? 0).toDouble();
    }

    String diseaseName;
    double diseaseConf;
    if (diseaseRaw is Map<String, dynamic>) {
      diseaseName = diseaseRaw['name'] as String? ?? '';
      diseaseConf = ((diseaseRaw['confidence'] as num?) ?? 0).toDouble() * 100;
    } else {
      diseaseName =
          json['disease_name'] as String? ?? diseaseRaw?.toString() ?? '';
      diseaseConf = ((json['disease_confidence'] as num?) ?? 0).toDouble();
    }

    // Parse enriched recommendation (new field — optional)
    RecommendationResult? rec;
    final rawRec = json['recommendation'];
    if (rawRec != null && rawRec is Map<String, dynamic>) {
      rec = RecommendationResult.fromJson(rawRec);
    }

    return PredictionResult(
      crop: cropName,
      cropConfidence: cropConf,
      disease: diseaseName,
      diseaseConfidence: diseaseConf,
      severity: json['severity'] as String? ?? 'Medium',
      fertilizer: FertilizerData.fromJson(
          json['fertilizer'] as Map<String, dynamic>? ?? {}),
      recommendation: rec,
      predictionTimeMs: (json['prediction_time_ms'] as num?)?.toInt() ?? 0,
      modelVersion:
          json['model_version'] as String? ?? 'v3.0 (Two-Stage ML Pipeline)',
    );
  }

  bool get isHealthy => disease.toLowerCase() == 'healthy';

  /// True if we have an enriched recommendation from the verified database
  bool get hasRecommendation => recommendation != null;

  String get cropEmoji {
    switch (crop.toLowerCase()) {
      case 'tomato': return '🍅';
      case 'paddy': case 'rice': return '🌾';
      case 'wheat': return '🌾';
      case 'sugarcane': return '🎋';
      case 'groundnut': return '🥜';
      case 'sunflower': return '🌻';
      case 'cotton': return '☁️';
      case 'blackgram': return '🫘';
      case 'eggplant': return '🍆';
      case 'turmeric': return '🌿';
      default: return '🌱';
    }
  }
}

/// Legacy flat fertilizer data — preserved for backward compatibility
class FertilizerData {
  final String name;
  final String dosage;
  final String application;
  final String frequency;

  const FertilizerData({
    required this.name,
    required this.dosage,
    required this.application,
    required this.frequency,
  });

  factory FertilizerData.fromJson(Map<String, dynamic> json) {
    return FertilizerData(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      application: json['application'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
    );
  }

  bool get isEmpty => name.isEmpty;
}
