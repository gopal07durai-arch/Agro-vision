import '../core/l10n/agricultural_localizations.dart';
import 'prediction_result.dart';

/// History entry from Supabase prediction_history table or local cache
class HistoryEntry {
  final String id;
  final String sessionId;
  final String cropName;
  final String diseaseName;
  final double cropConfidence;
  final double diseaseConfidence;
  final String severity;
  final String fertilizerName;
  final String dosage;
  final String application;
  final String frequency;
  final String? imageUrl;
  final DateTime createdAt;
  final int? userRating;

  const HistoryEntry({
    required this.id,
    required this.sessionId,
    required this.cropName,
    required this.diseaseName,
    required this.cropConfidence,
    required this.diseaseConfidence,
    required this.severity,
    required this.fertilizerName,
    this.dosage = '',
    this.application = '',
    this.frequency = '',
    this.imageUrl,
    required this.createdAt,
    this.userRating,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    // Recommendation object if present
    final rec = json['recommendation'] is Map<String, dynamic>
        ? json['recommendation'] as Map<String, dynamic>
        : {};

    return HistoryEntry(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      cropName: json['crop_name']?.toString() ?? '',
      diseaseName: json['disease_name']?.toString() ?? '',
      cropConfidence: _parseDouble(json['crop_confidence']),
      diseaseConfidence: _parseDouble(json['disease_confidence'] ?? json['confidence']),
      severity: json['severity']?.toString() ?? 'Medium',
      fertilizerName: json['fertilizer_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? rec['dosage']?.toString() ?? '',
      application: json['application']?.toString() ?? rec['application']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? rec['frequency']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      userRating: json['user_rating'] is int ? json['user_rating'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'crop_name': cropName,
      'disease_name': diseaseName,
      'crop_confidence': cropConfidence,
      'disease_confidence': diseaseConfidence,
      'confidence': diseaseConfidence,
      'severity': severity,
      'fertilizer_name': fertilizerName,
      'dosage': dosage,
      'application': application,
      'frequency': frequency,
      'image_url': imageUrl,
      'recommendation': {
        'dosage': dosage,
        'application': application,
        'frequency': frequency,
      },
      'created_at': createdAt.toIso8601String(),
      'user_rating': userRating,
    };
  }

  /// Reconstruct full PredictionResult for opening the ResultScreen
  PredictionResult toPredictionResult() {
    final rec = AgriculturalLocalizations.getLocalizedRecommendation(
      cropName,
      diseaseName,
      null,
      'en',
    );

    return PredictionResult(
      crop: cropName,
      cropConfidence: cropConfidence,
      disease: diseaseName,
      diseaseConfidence: diseaseConfidence,
      severity: severity,
      fertilizer: FertilizerData(
        name: fertilizerName.isNotEmpty
            ? fertilizerName
            : (rec?.fertilizerSection?.name ?? rec?.productName ?? ''),
        dosage: dosage.isNotEmpty
            ? dosage
            : (rec?.fertilizerSection?.dosage ?? rec?.dosage ?? ''),
        application: application.isNotEmpty
            ? application
            : (rec?.fertilizerSection?.applicationMethod ?? rec?.applicationMethod ?? ''),
        frequency: frequency.isNotEmpty
            ? frequency
            : (rec?.fertilizerSection?.frequency ?? rec?.frequency ?? ''),
      ),
      recommendation: rec,
      predictionTimeMs: 0,
      modelVersion: 'AgroVision Production',
    );
  }

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String get crop => cropName;
  String get disease => diseaseName;
  bool get isHealthy => diseaseName.toLowerCase() == 'healthy';

  String get cropEmoji {
    switch (cropName.toLowerCase()) {
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

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
  }

  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

