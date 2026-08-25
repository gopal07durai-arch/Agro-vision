import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_result.dart';
import '../models/history_entry.dart';

/// Handles all Supabase database operations.
/// Uses the anon key (safe for client-side) — never the service-role key.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _client != null;

  // ─── Save prediction to history ───────────────────────────────────────────

  Future<String?> savePrediction({
    required String sessionId,
    required PredictionResult prediction,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.from('prediction_history').insert({
        'session_id': sessionId,
        'image_url': null,
        'crop_name': prediction.crop,
        'disease_name': prediction.disease,
        'crop_confidence': prediction.cropConfidence,
        'disease_confidence': prediction.diseaseConfidence,
        'confidence': prediction.diseaseConfidence, // legacy column
        'severity': prediction.severity,
        'fertilizer_name': prediction.fertilizer.name,
        'recommendation': {
          'dosage': prediction.fertilizer.dosage,
          'application': prediction.fertilizer.application,
          'frequency': prediction.fertilizer.frequency,
          'mock': false,
        },
        'prediction_time_ms': prediction.predictionTimeMs,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return response['id']?.toString();
    } catch (e) {
      // Non-fatal — prediction still succeeded
      return null;
    }
  }

  // ─── Get session history ──────────────────────────────────────────────────

  Future<List<HistoryEntry>> getSessionHistory(String sessionId,
      {int limit = 20}) async {
    final client = _client;
    if (client == null) return [];

    try {
      final data = await client
          .from('prediction_history')
          .select(
              'id, session_id, crop_name, disease_name, crop_confidence, disease_confidence, confidence, severity, fertilizer_name, created_at, user_rating')
          .eq('session_id', sessionId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List)
          .map((row) => HistoryEntry.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Save star rating ─────────────────────────────────────────────────────

  Future<void> saveRating({
    required String sessionId,
    required String crop,
    required String disease,
    required String fertilizerName,
    required int rating,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.from('fertilizer_ratings').insert({
        'session_id': sessionId,
        'fertilizer_name': fertilizerName,
        'crop_type': crop,
        'disease_type': disease,
        'rating': rating,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal
    }
  }

  // ─── Update prediction user rating ────────────────────────────────────────

  Future<void> updatePredictionRating(String predictionId, int rating) async {
    final client = _client;
    if (client == null) return;

    try {
      await client
          .from('prediction_history')
          .update({'user_rating': rating}).eq('id', predictionId);
    } catch (_) {
      // Non-fatal
    }
  }
}
