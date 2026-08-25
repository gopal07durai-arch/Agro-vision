/**
 * diseaseUtils.ts
 * Helpers for severity, confidence formatting, and disease display.
 */

import type { SeverityLevel } from '../types';

/**
 * Determine severity from confidence + disease name.
 */
export function getSeverity(
  confidence: number,
  modelSeverity?: string
): SeverityLevel {
  if (modelSeverity && ['None', 'Low', 'Medium', 'High'].includes(modelSeverity)) {
    return modelSeverity as SeverityLevel;
  }
  if (confidence >= 90) return 'High';
  if (confidence >= 70) return 'Medium';
  if (confidence >= 50) return 'Low';
  return 'None';
}

/** Format confidence number to a clean percentage string */
export function formatConfidence(value: number): string {
  return `${value.toFixed(2)}%`;
}

/** Severity → Tailwind color classes */
export const SEVERITY_COLORS: Record<SeverityLevel, string> = {
  None:   'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/60 dark:text-emerald-200 border border-emerald-200 dark:border-emerald-700',
  Low:    'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/60 dark:text-yellow-200 border border-yellow-200 dark:border-yellow-700',
  Medium: 'bg-orange-100 text-orange-800 dark:bg-orange-900/60 dark:text-orange-200 border border-orange-200 dark:border-orange-700',
  High:   'bg-red-100 text-red-800 dark:bg-red-900/60 dark:text-red-200 border border-red-200 dark:border-red-700',
};

/** Severity → dot indicator color */
export const SEVERITY_DOT: Record<SeverityLevel, string> = {
  None:   'bg-emerald-500',
  Low:    'bg-yellow-500',
  Medium: 'bg-orange-500',
  High:   'bg-red-500',
};

/** Severity → glow color */
export const SEVERITY_GLOW: Record<SeverityLevel, string> = {
  None:   'shadow-emerald-200 dark:shadow-emerald-900',
  Low:    'shadow-yellow-200 dark:shadow-yellow-900',
  Medium: 'shadow-orange-200 dark:shadow-orange-900',
  High:   'shadow-red-200 dark:shadow-red-900',
};

/** Format ms to human-readable */
export function formatPredictionTime(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

/** Crop name → emoji icon */
export const CROP_ICONS: Record<string, string> = {
  Tomato:    '🍅',
  Paddy:     '🌾',
  Rice:      '🌾',
  Wheat:     '🌾',
  Cotton:    '🌿',
  Sugarcane: '🎋',
  Groundnut: '🥜',
  Sunflower: '🌻',
  Turmeric:  '🟡',
  Blackgram: '🫘',
  Eggplant:  '🍆',
  Default:   '🌱',
};

export function getCropIcon(crop: string): string {
  return CROP_ICONS[crop] ?? CROP_ICONS.Default;
}

/** Crop → theme color classes */
export const CROP_COLORS: Record<string, { bg: string; text: string; border: string }> = {
  Tomato:    { bg: 'from-red-600 to-rose-600',     text: 'text-red-600',    border: 'border-red-200' },
  Paddy:     { bg: 'from-yellow-600 to-amber-600', text: 'text-yellow-600', border: 'border-yellow-200' },
  Wheat:     { bg: 'from-amber-600 to-orange-600', text: 'text-amber-600',  border: 'border-amber-200' },
  Cotton:    { bg: 'from-blue-600 to-indigo-600',  text: 'text-blue-600',   border: 'border-blue-200' },
  Sugarcane: { bg: 'from-green-600 to-teal-600',   text: 'text-green-600',  border: 'border-green-200' },
  Groundnut: { bg: 'from-orange-600 to-red-600',   text: 'text-orange-600', border: 'border-orange-200' },
  Sunflower: { bg: 'from-yellow-500 to-orange-500',text: 'text-yellow-600', border: 'border-yellow-200' },
  Turmeric:  { bg: 'from-yellow-600 to-amber-700', text: 'text-yellow-700', border: 'border-yellow-200' },
  Blackgram: { bg: 'from-purple-600 to-indigo-600',text: 'text-purple-600', border: 'border-purple-200' },
  Eggplant:  { bg: 'from-purple-700 to-violet-600',text: 'text-purple-700', border: 'border-purple-200' },
  Default:   { bg: 'from-green-600 to-emerald-600',text: 'text-green-600',  border: 'border-green-200' },
};

export function getCropColors(crop: string) {
  return CROP_COLORS[crop] ?? CROP_COLORS.Default;
}

/** Disease → category icon */
export function getDiseaseIcon(disease: string): string {
  const lower = disease.toLowerCase();
  if (lower.includes('healthy'))                                     return '✅';
  if (lower.includes('blight'))                                      return '🔴';
  if (lower.includes('rust'))                                        return '🟠';
  if (lower.includes('mildew'))                                      return '🔵';
  if (lower.includes('wilt'))                                        return '🟤';
  if (lower.includes('virus') || lower.includes('mosaic'))           return '🟣';
  if (lower.includes('spot'))                                        return '🟡';
  if (lower.includes('rot'))                                         return '⚫';
  if (lower.includes('aphid') || lower.includes('mite') || lower.includes('pest')) return '🐛';
  if (lower.includes('smut') || lower.includes('scald'))             return '🔸';
  if (lower.includes('blast'))                                       return '💥';
  if (lower.includes('sclerotinia') || lower.includes('mold'))       return '🍄';
  if (lower.includes('anthracnose'))                                 return '🔺';
  return '⚠️';
}

/** Disease severity → estimated recovery time */
export function getEstimatedRecoveryTime(severity: SeverityLevel, disease: string): string {
  if (disease.toLowerCase().includes('healthy')) return 'No treatment needed';
  switch (severity) {
    case 'None':   return '1–2 weeks of care';
    case 'Low':    return '2–3 weeks with treatment';
    case 'Medium': return '3–5 weeks with consistent treatment';
    case 'High':   return '6–8 weeks; severe cases may not recover';
    default:       return '3–4 weeks';
  }
}

/** Suggested follow-up questions based on disease */
export function getSuggestedQuestions(crop: string, disease: string): string[] {
  const isHealthy = disease.toLowerCase().includes('healthy');
  if (isHealthy) {
    return [
      `How do I keep my ${crop} healthy?`,
      `What are the best fertilizers for ${crop}?`,
      `How often should I water ${crop}?`,
      `How do I prevent diseases in ${crop}?`,
    ];
  }
  return [
    `How do I treat ${disease} in ${crop}?`,
    `How long does recovery from ${disease} take?`,
    `Can I use organic methods to control ${disease}?`,
    `How does ${disease} spread to other plants?`,
    `What are the best preventive measures for ${disease}?`,
    `How often should I spray for ${disease}?`,
  ];
}
