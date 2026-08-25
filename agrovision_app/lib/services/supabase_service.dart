import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_result.dart';
import '../models/history_entry.dart';

/// Handles all Supabase database operations with an offline-first local cache fallback.
/// Uses the anon key (safe for client-side) — never the service-role key.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _localHistoryKey = 'agrovision_local_history_v2';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _client != null;

  // ─── Save prediction to history (Offline First + Supabase Sync) ───────────

  Future<String> savePrediction({
    required String sessionId,
    required PredictionResult prediction,
  }) async {
    final now = DateTime.now();
    final localId = 'local-${now.millisecondsSinceEpoch}';

    final dosage = prediction.recommendation?.fertilizerSection?.dosage ??
        prediction.recommendation?.dosage ??
        prediction.fertilizer.dosage;
    final application = prediction.recommendation?.fertilizerSection?.applicationMethod ??
        prediction.recommendation?.applicationMethod ??
        prediction.fertilizer.application;
    final frequency = prediction.recommendation?.fertilizerSection?.frequency ??
        prediction.recommendation?.frequency ??
        prediction.fertilizer.frequency;
    final fertName = prediction.recommendation?.fertilizerSection?.name ??
        prediction.recommendation?.productName ??
        prediction.fertilizer.name;

    final entry = HistoryEntry(
      id: localId,
      sessionId: sessionId,
      cropName: prediction.crop,
      diseaseName: prediction.disease,
      cropConfidence: prediction.cropConfidence,
      diseaseConfidence: prediction.diseaseConfidence,
      severity: prediction.severity,
      fertilizerName: fertName,
      dosage: dosage,
      application: application,
      frequency: frequency,
      createdAt: now,
    );

    // 1. Immediately save to local persistent cache for instant 0ms UI update
    await _saveToLocalCache(entry);

    // 2. Sync to Supabase in the background if available
    final client = _client;
    if (client != null) {
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
          'fertilizer_name': fertName,
          'recommendation': {
            'dosage': dosage,
            'application': application,
            'frequency': frequency,
            'mock': false,
          },
          'prediction_time_ms': prediction.predictionTimeMs,
          'created_at': now.toIso8601String(),
        }).select('id').single();

        final remoteId = response['id']?.toString();
        if (remoteId != null && remoteId.isNotEmpty) {
          // Update local cache record ID with remote ID
          await _updateLocalId(localId, remoteId);
          return remoteId;
        }
      } catch (e) {
        debugPrint('[SupabaseService] Background Supabase insert skipped: $e');
      }
    }

    return localId;
  }

  // ─── Get session history ──────────────────────────────────────────────────

  Future<List<HistoryEntry>> getSessionHistory(String sessionId,
      {int limit = 50}) async {
    // 1. Load from local cache first for instant display
    final localEntries = await _loadFromLocalCache(sessionId);

    // 2. Fetch latest from Supabase if connected
    final client = _client;
    if (client != null) {
      try {
        final data = await client
            .from('prediction_history')
            .select(
                'id, session_id, crop_name, disease_name, crop_confidence, disease_confidence, confidence, severity, fertilizer_name, recommendation, created_at, user_rating')
            .eq('session_id', sessionId)
            .order('created_at', ascending: false)
            .limit(limit);

        final remoteEntries = (data as List)
            .map((row) => HistoryEntry.fromJson(row as Map<String, dynamic>))
            .toList();

        if (remoteEntries.isNotEmpty) {
          // Merge local and remote
          final merged = _mergeHistory(localEntries, remoteEntries);
          await _overwriteLocalCache(sessionId, merged);
          return merged;
        }
      } catch (e) {
        debugPrint('[SupabaseService] Supabase fetch error, using local cache: $e');
      }
    }

    return localEntries;
  }

  // ─── Delete a prediction from history ─────────────────────────────────────

  Future<bool> deletePrediction(String id, String sessionId) async {
    // 1. Remove from local cache
    await _removeFromLocalCache(id, sessionId);

    // 2. Remove from Supabase if not a local-only ID
    final client = _client;
    if (client != null && !id.startsWith('local-')) {
      try {
        await client.from('prediction_history').delete().eq('id', id);
        return true;
      } catch (e) {
        debugPrint('[SupabaseService] Supabase delete error: $e');
      }
    }
    return true;
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
    if (client == null || predictionId.startsWith('local-')) return;

    try {
      await client
          .from('prediction_history')
          .update({'user_rating': rating}).eq('id', predictionId);
    } catch (_) {
      // Non-fatal
    }
  }

  // ─── Local Storage Helpers ────────────────────────────────────────────────

  Future<List<HistoryEntry>> _loadFromLocalCache(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_localHistoryKey}_$sessionId') ?? '[]';
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveToLocalCache(HistoryEntry entry) async {
    try {
      final entries = await _loadFromLocalCache(entry.sessionId);
      // Avoid duplicate insert
      if (!entries.any((e) => e.id == entry.id)) {
        entries.insert(0, entry);
      }
      await _overwriteLocalCache(entry.sessionId, entries);
    } catch (_) {}
  }

  Future<void> _updateLocalId(String oldId, String newId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_localHistoryKey));
      for (final key in keys) {
        final raw = prefs.getString(key) ?? '[]';
        final list = jsonDecode(raw) as List;
        bool modified = false;
        final updated = list.map((item) {
          if (item['id'] == oldId) {
            item['id'] = newId;
            modified = true;
          }
          return item;
        }).toList();
        if (modified) {
          await prefs.setString(key, jsonEncode(updated));
        }
      }
    } catch (_) {}
  }

  Future<void> _removeFromLocalCache(String id, String sessionId) async {
    try {
      final entries = await _loadFromLocalCache(sessionId);
      entries.removeWhere((e) => e.id == id);
      await _overwriteLocalCache(sessionId, entries);
    } catch (_) {}
  }

  Future<void> _overwriteLocalCache(
      String sessionId, List<HistoryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString('${_localHistoryKey}_$sessionId', encoded);
    } catch (_) {}
  }

  List<HistoryEntry> _mergeHistory(
      List<HistoryEntry> local, List<HistoryEntry> remote) {
    final Map<String, HistoryEntry> map = {};
    for (final r in remote) {
      map[r.id] = r;
    }
    for (final l in local) {
      if (!map.containsKey(l.id)) {
        map[l.id] = l;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}

