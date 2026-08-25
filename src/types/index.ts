// ─────────────────────────────────────────────────────────────
// Shared TypeScript interfaces — AI Agriculture Platform
// ─────────────────────────────────────────────────────────────

/** Result returned by FastAPI /predict endpoint (two-stage confidence) */
export interface PredictionResult {
  crop: string;
  /** Stage 1 confidence: sum of probabilities across all disease classes of the detected crop */
  crop_confidence: number;        // 0–100
  disease: string;
  /** Stage 2 confidence: probability of the specific winning disease class */
  disease_confidence: number;     // 0–100
  severity: 'None' | 'Low' | 'Medium' | 'High';
  prediction_time_ms: number;
  fertilizer?: string;            // primary fertilizer name from backend
  dosage?: string;                // dosage string from backend
  application?: string;           // application method from backend
  frequency?: string;             // application frequency from backend
  mock?: boolean;
}

/** Error response from FastAPI /predict endpoint */
export interface PredictionErrorResponse {
  success: false;
  error_type: 'NOT_LEAF' | 'UNSUPPORTED_CROP' | 'LOW_CONFIDENCE' | 'INVALID_IMAGE' | 'SERVER_ERROR';
  message: string;
}

/** One fertilizer recommendation entry */
export interface FertilizerRecommendation {
  name: string;
  type: 'Bio' | 'Chemical' | 'Organic';
  dosage: string;
  applicationMethod: string;
  frequency: string;
  benefits: string[];
  precautions: string[];
  icon: string;             // emoji icon
}

/** Full structured disease info from Gemini — 17 fields */
export interface DiseaseInfo {
  // Core
  overview: string;
  symptoms: string[];
  cause: string;
  spreadMethod: string;
  // Treatment
  biofertilizer: string;
  dosage: string;
  applicationMethod: string;
  precautions: string[];
  organicControl: string[];
  chemicalControl: string[];
  // Recovery & Prevention
  recoveryTime: string;
  preventiveMeasures: string[];
  // Farmer-facing
  farmerFriendlyExplanation: string;
  // Legacy fields (kept for backward compat)
  symptoms_list?: string[];
  causes?: string[];
  prevention?: string[];
  organicTreatment?: string[];
  chemicalTreatment?: string[];
  recoveryTips?: string[];
}

/** Image validation result */
export interface ValidationResult {
  isLeaf: boolean;
  reason: string;
  quality: 'good' | 'blurry' | 'dark' | 'low_res' | 'multiple' | 'invalid' | 'cropped';
}

/** Image quality assessment (client-side) */
export interface ImageQuality {
  isBlurry: boolean;
  isDark: boolean;
  isLowRes: boolean;
  score: number;  // 0–100
}

/** Chat message */
export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

/** Prediction history entry from Supabase */
export interface PredictionHistoryEntry {
  id: string;
  session_id: string;
  crop_name: string;
  disease_name: string;
  crop_confidence: number;
  disease_confidence: number;
  severity: string;
  fertilizer_name: string;
  created_at: string;
  user_rating?: number;
}

/** Full app state passed between views */
export interface AppState {
  view: 'splash' | 'upload' | 'analyzing' | 'prediction' | 'chat' | 'history';
  imageDataUrl: string | null;
  prediction: PredictionResult | null;
  fertilizers: FertilizerRecommendation[];
  diseaseInfo: DiseaseInfo | null;
  sessionId: string;
}

/** Severity color mapping */
export type SeverityLevel = 'None' | 'Low' | 'Medium' | 'High';
