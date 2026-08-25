/**
 * apiConfig.ts
 * Centralized API configuration for AgroVision / Farmer AI Chatbot.
 */

export const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL ??
  import.meta.env.VITE_FASTAPI_URL ??
  'http://localhost:8000'
).replace(/\/$/, '');

export const PREDICT_ENDPOINT = `${API_BASE_URL}/api/v1/predict`;
export const HEALTH_ENDPOINT  = `${API_BASE_URL}/api/v1/health`;
