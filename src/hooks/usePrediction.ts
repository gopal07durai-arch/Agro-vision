/**
 * usePrediction.ts
 * Orchestrates the full prediction pipeline with i18n support:
 *   1. Compress image
 *   2. Assess image quality (client-side)
 *   3. Validate leaf via Gemini Vision (passing target language)
 *   4. Call FastAPI /predict (TF model — two-stage confidence)
 *   5. Look up fertilizer recommendations
 *   6. Call Gemini for disease explanation in target language
 *   7. Save to Supabase
 *
 * All status messages use i18n translation keys or are set by caller.
 * No hardcoded English strings.
 */

import { useState, useCallback } from 'react';
import { compressImage, assessImageQuality } from '../utils/imageUtils';
import { predictDisease, PredictionError } from '../services/predictionService';
import { validateLeafImage, getDiseaseExplanation } from '../services/geminiService';
import { getFertilizerRecommendations } from '../services/fertilizerService';
import { savePrediction } from '../services/supabaseService';
import type { PredictionResult, FertilizerRecommendation, DiseaseInfo, ValidationResult } from '../types';

export type PredictionStep =
  | 'idle'
  | 'compressing'
  | 'quality_check'
  | 'validating'
  | 'predicting'
  | 'explaining'
  | 'complete'
  | 'error';

export interface PredictionState {
  step:          PredictionStep;
  progress:      number;          // 0–100
  statusMessage: string;          // i18n key OR already-translated string from backend
  prediction:    PredictionResult | null;
  fertilizers:   FertilizerRecommendation[];
  diseaseInfo:   DiseaseInfo | null;
  validation:    ValidationResult | null;
  error:         string | null;   // i18n key OR server message
  errorType?:    string;          // optional: 'NOT_LEAF' | 'LOW_CONFIDENCE' | etc.
}

const INITIAL_STATE: PredictionState = {
  step:          'idle',
  progress:      0,
  statusMessage: '',
  prediction:    null,
  fertilizers:   [],
  diseaseInfo:   null,
  validation:    null,
  error:         null,
  errorType:     undefined,
};

export function usePrediction(sessionId: string) {
  const [state, setState] = useState<PredictionState>(INITIAL_STATE);

  const setProgress = (step: PredictionStep, progress: number, statusMessage: string) =>
    setState(prev => ({ ...prev, step, progress, statusMessage, error: null }));

  const analyze = useCallback(async (imageDataUrl: string, isCamera = false, targetLanguageName = 'English') => {
    setState(INITIAL_STATE);

    try {
      // Step 1 — Compress image
      setProgress('compressing', 8, 'step_compressing');
      const compressed = await compressImage(imageDataUrl, isCamera);

      // Step 2 — Client-side quality assessment
      setProgress('quality_check', 18, 'step_quality');
      const quality = await assessImageQuality(compressed);

      if (quality.isDark) {
        throw new PredictionError('err_dark');
      }
      if (quality.isLowRes) {
        throw new PredictionError('err_low_res');
      }
      if (quality.isBlurry) {
        throw new PredictionError('err_blurry');
      }

      // Step 3 — Validate leaf via Gemini Vision
      setProgress('validating', 32, 'step_validating');
      const validation = await validateLeafImage(compressed, targetLanguageName);

      setState(prev => ({ ...prev, validation }));

      if (!validation.isLeaf) {
        const errorKeys: Record<string, string> = {
          invalid:  'not_leaf_desc',
          blurry:   'blurry_desc',
          dark:     'dark_desc',
          multiple: 'multiple_desc',
          cropped:  'cropped_desc',
          low_res:  'low_res_desc',
        };
        throw new PredictionError(
          errorKeys[validation.quality] ?? 'not_leaf_desc',
          undefined,
          'NOT_LEAF',
        );
      }

      // Step 4 — Predict with FastAPI TF model (two-stage: crop + disease)
      setProgress('predicting', 48, 'step_predicting');
      const prediction = await predictDisease(compressed);

      setProgress('predicting', 64, 'step_predicting');

      // Step 5 — Fertilizer lookup from local DB
      const fertilizers = getFertilizerRecommendations(prediction.crop, prediction.disease);

      // Step 6 — Gemini disease explanation in target language
      setProgress('explaining', 76, 'step_explaining');
      const diseaseInfo = await getDiseaseExplanation(prediction.crop, prediction.disease, targetLanguageName);

      setProgress('explaining', 92, 'step_explaining');

      // Step 7 — Save to Supabase (non-blocking, fire-and-forget)
      savePrediction({ sessionId, imageDataUrl: compressed, prediction, fertilizers, diseaseInfo })
        .catch(err => console.warn('Background save failed:', err));

      // Complete
      setState({
        step:          'complete',
        progress:      100,
        statusMessage: 'analysis_complete',
        prediction,
        fertilizers,
        diseaseInfo,
        validation,
        error:         null,
        errorType:     undefined,
      });

    } catch (err) {
      // Map errors: PredictionError carries i18n keys or server messages
      let message   = 'err_unexpected';
      let errorType = 'UNKNOWN';

      if (err instanceof PredictionError) {
        // Server messages from backend start with uppercase (real text)
        // i18n keys start with 'err_' or are validation keys
        message   = err.message;
        errorType = err.errorType ?? 'UNKNOWN';
      }

      setState(prev => ({
        ...prev,
        step:          'error',
        progress:      0,
        statusMessage: '',
        error:         message,
        errorType,
      }));
    }
  }, [sessionId]);

  const reset = useCallback(() => setState(INITIAL_STATE), []);

  return { state, analyze, reset };
}
