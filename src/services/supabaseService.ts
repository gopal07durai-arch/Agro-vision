/**
 * supabaseService.ts
 * All Supabase operations for the AI Agriculture Platform.
 *
 * Schema: prediction_history now includes crop_confidence + disease_confidence
 * from the two-stage model inference.
 */

import { createClient } from '@supabase/supabase-js';
import type { PredictionResult, FertilizerRecommendation, DiseaseInfo, PredictionHistoryEntry } from '../types';

const supabaseUrl     = import.meta.env.VITE_SUPABASE_URL    as string;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase environment variables missing — running in local mode.');
}

export const supabase = (supabaseUrl && supabaseAnonKey)
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

// ─── Save prediction ──────────────────────────────────────────────────────────

export interface SavePredictionInput {
  sessionId: string;
  imageDataUrl?: string;
  prediction: PredictionResult;
  fertilizers: FertilizerRecommendation[];
  diseaseInfo?: DiseaseInfo | null;
}

export async function savePrediction(input: SavePredictionInput): Promise<string | null> {
  if (!supabase) return null;

  const primaryFertilizer = input.prediction.fertilizer
    ?? input.fertilizers[0]?.name
    ?? 'General Bio Fertilizer';

  const primaryDosage = input.prediction.dosage
    ?? input.fertilizers[0]?.dosage
    ?? '';

  try {
    const { data, error } = await supabase
      .from('prediction_history')
      .insert({
        session_id:          input.sessionId,
        image_url:           input.imageDataUrl ? '[base64_image]' : null,
        crop_name:           input.prediction.crop,
        disease_name:        input.prediction.disease,
        // Two-stage confidence values
        crop_confidence:     input.prediction.crop_confidence,
        disease_confidence:  input.prediction.disease_confidence,
        // Legacy column — keep backward compat using disease_confidence
        confidence:          input.prediction.disease_confidence,
        severity:            input.prediction.severity,
        fertilizer_name:     primaryFertilizer,
        recommendation: {
          fertilizers:         input.fertilizers,
          dosage:              primaryDosage,
          application:         input.prediction.application,
          frequency:           input.prediction.frequency,
          spreadMethod:        input.diseaseInfo?.spreadMethod,
          recoveryTime:        input.diseaseInfo?.recoveryTime,
          preventiveMeasures:  input.diseaseInfo?.preventiveMeasures,
          mock:                input.prediction.mock ?? false,
        },
        prediction_time_ms:  input.prediction.prediction_time_ms,
        created_at:          new Date().toISOString(),
      })
      .select('id')
      .single();

    if (error) {
      console.error('Failed to save prediction:', error.message);
      return null;
    }
    return data?.id ?? null;
  } catch (err) {
    console.warn('Supabase save prediction error:', err);
    return null;
  }
}

// ─── Save rating ──────────────────────────────────────────────────────────────

export async function saveRating(
  sessionId: string,
  crop: string,
  disease: string,
  fertilizerName: string,
  rating: number
): Promise<void> {
  if (!supabase) return;
  try {
    await supabase.from('fertilizer_ratings').insert({
      session_id:      sessionId,
      fertilizer_name: fertilizerName,
      crop_type:       crop,
      disease_type:    disease,
      rating,
      created_at:      new Date().toISOString(),
    });
  } catch (err) {
    console.warn('Save rating error:', err);
  }
}

// ─── Get session history ──────────────────────────────────────────────────────

export async function getSessionHistory(
  sessionId: string,
  limit = 20
): Promise<PredictionHistoryEntry[]> {
  if (!supabase) return [];
  try {
    const { data, error } = await supabase
      .from('prediction_history')
      .select('id, session_id, crop_name, disease_name, crop_confidence, disease_confidence, confidence, severity, fertilizer_name, created_at, user_rating')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: false })
      .limit(limit);
    if (error) throw error;

    // Map response: prefer crop/disease_confidence; fall back to legacy confidence
    return ((data ?? []) as Record<string, unknown>[]).map(row => ({
      id:                  String(row.id ?? ''),
      session_id:          String(row.session_id ?? ''),
      crop_name:           String(row.crop_name ?? ''),
      disease_name:        String(row.disease_name ?? ''),
      crop_confidence:     typeof row.crop_confidence    === 'number' ? row.crop_confidence    : typeof row.confidence === 'number' ? row.confidence : 0,
      disease_confidence:  typeof row.disease_confidence === 'number' ? row.disease_confidence : typeof row.confidence === 'number' ? row.confidence : 0,
      severity:            String(row.severity ?? 'Medium'),
      fertilizer_name:     String(row.fertilizer_name ?? ''),
      created_at:          String(row.created_at ?? ''),
      user_rating:         typeof row.user_rating === 'number' ? row.user_rating : undefined,
    })) as PredictionHistoryEntry[];
  } catch {
    return [];
  }
}

// ─── Update prediction rating ─────────────────────────────────────────────────

export async function updatePredictionRating(
  predictionId: string,
  rating: number
): Promise<void> {
  if (!supabase) return;
  try {
    await supabase
      .from('prediction_history')
      .update({ user_rating: rating })
      .eq('id', predictionId);
  } catch (err) {
    console.warn('Update prediction rating error:', err);
  }
}
