/**
 * predictionService.ts
 * Calls FastAPI /api/v1/predict with the uploaded image.
 *
 * Input Validation & OOD Rejection Pipeline:
 *   1. Send FormData ('file') to FastAPI endpoint
 *   2. Handle success (crop_confidence, disease_confidence, fertilizer)
 *   3. Handle error_type (NOT_LEAF, LOW_IMAGE_QUALITY, MODEL_UNAVAILABLE, LOW_CROP_CONFIDENCE, LOW_DISEASE_CONFIDENCE)
 *
 * NO LLM PREDICTION FALLBACKS — ML models are used exclusively for disease classification.
 */

import type { PredictionResult } from '../types';
import { dataUrlToBlob } from '../utils/imageUtils';
import { API_BASE_URL, PREDICT_ENDPOINT, HEALTH_ENDPOINT } from '../config/apiConfig';

const TIMEOUT_MS = 45_000;

export class PredictionError extends Error {
  constructor(
    message: string,
    public status?: number,
    public errorType?: string,
  ) {
    super(message);
    this.name = 'PredictionError';
  }
}

/**
 * Send a compressed image dataURL to FastAPI and return the prediction.
 *
 * Success: returns PredictionResult with crop_confidence + disease_confidence directly from trained Keras models.
 * Error: throws PredictionError with status, errorType, and user-readable message.
 * No LLM fallback is used for predictions (per absolute rule).
 */
export async function predictDisease(imageDataUrl: string): Promise<PredictionResult> {
  console.log('[PredictionService] Sending request to:', PREDICT_ENDPOINT);

  const blob = dataUrlToBlob(imageDataUrl);
  const form  = new FormData();
  form.append('file', blob, 'leaf.jpg');

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(PREDICT_ENDPOINT, {
      method: 'POST',
      body:   form,
      signal: controller.signal,
    });

    clearTimeout(timer);

    let data: Record<string, unknown>;
    try {
      data = await response.json();
    } catch {
      throw new PredictionError(
        `Server returned non-JSON response (HTTP ${response.status})`,
        response.status,
        'SERVER_ERROR'
      );
    }

    // Handle error responses from backend
    if (!response.ok || data.success === false) {
      const errorType   = (data.error_type as string | undefined) ?? 'SERVER_ERROR';
      const serverMsg   = (data.message as string | undefined) ?? `Server error (${response.status})`;
      throw new PredictionError(serverMsg, response.status, errorType);
    }

    // Map fertilizer object or legacy string fields
    let fertName: string | undefined = undefined;
    let fertDosage: string | undefined = undefined;
    let fertApp: string | undefined = undefined;
    let fertFreq: string | undefined = undefined;

    if (data.fertilizer && typeof data.fertilizer === 'object') {
      const f = data.fertilizer as Record<string, string>;
      fertName   = f.name;
      fertDosage = f.dosage;
      fertApp    = f.application;
      fertFreq   = f.frequency;
    } else {
      fertName   = typeof data.fertilizer  === 'string' ? data.fertilizer  : undefined;
      fertDosage = typeof data.dosage      === 'string' ? data.dosage      : undefined;
      fertApp    = typeof data.application === 'string' ? data.application : undefined;
      fertFreq   = typeof data.frequency   === 'string' ? data.frequency   : undefined;
    }

    const parsedCrop = typeof data.crop === 'object' && data.crop !== null
      ? String((data.crop as any).name ?? '')
      : String(data.crop ?? '');

    const crop_confidence = typeof data.crop === 'object' && data.crop !== null
      ? Number((data.crop as any).confidence ?? 0) * 100
      : Number(data.crop_confidence ?? 0);

    const parsedDisease = typeof data.disease === 'object' && data.disease !== null
      ? String((data.disease as any).name ?? '')
      : String(data.disease ?? '');

    const disease_confidence = typeof data.disease === 'object' && data.disease !== null
      ? Number((data.disease as any).confidence ?? 0) * 100
      : Number(data.disease_confidence ?? 0);

    const result: PredictionResult = {
      crop:               parsedCrop,
      crop_confidence,
      disease:            parsedDisease,
      disease_confidence,
      severity:           (data.severity as PredictionResult['severity']) ?? 'Medium',
      prediction_time_ms: typeof data.prediction_time_ms === 'number' ? data.prediction_time_ms : 0,
      fertilizer:         fertName,
      dosage:             fertDosage,
      application:        fertApp,
      frequency:          fertFreq,
      mock:               false,
    };

    console.log('[PredictionService] Genuine ML prediction received from backend:', result);
    return result;

  } catch (err) {
    clearTimeout(timer);
    if (err instanceof PredictionError) throw err;

    if ((err as Error).name === 'AbortError') {
      throw new PredictionError(
        'Request timed out. The backend server took too long to analyze the image.',
        408,
        'TIMEOUT',
      );
    }

    throw new PredictionError(
      'Cannot connect to the detection backend. Please ensure the backend server is running on ' + API_BASE_URL,
      0,
      'NETWORK_ERROR',
    );
  }
}

/** Check if FastAPI backend is reachable */
export async function checkBackendHealth(): Promise<boolean> {
  try {
    const res = await fetch(HEALTH_ENDPOINT, {
      signal: AbortSignal.timeout(3000),
    });
    return res.ok;
  } catch {
    return false;
  }
}
