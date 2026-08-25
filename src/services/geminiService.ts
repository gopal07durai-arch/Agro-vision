/**
 * geminiService.ts
 * Gemini API integration:
 *   1. validateLeafImage     — Vision check: is this a crop leaf?
 *   2. getDiseaseExplanation — Full 17-field structured disease info
 *   3. getChatResponse       — Disease-scoped follow-up chatbot
 *
 * Fully localized to user's selected language.
 */

import type { DiseaseInfo, ChatMessage, ValidationResult } from '../types';

const GEMINI_KEY   = (import.meta.env.VITE_GEMINI_API_KEY ?? '').trim();
const GEMINI_MODEL = 'gemini-2.0-flash';
const BASE_URL     = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// ─── Low-level text call ──────────────────────────────────────────────────────

async function callGemini(prompt: string): Promise<string> {
  if (!GEMINI_KEY) throw new Error('VITE_GEMINI_API_KEY is not set.');

  const body = {
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.2, maxOutputTokens: 2048 },
  };

  const res = await fetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-goog-api-key': GEMINI_KEY },
    body: JSON.stringify(body),
  });

  if (res.status === 429) throw new Error('Rate limit reached. Please try again in a moment.');
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message ?? `API error (${res.status})`);
  }

  const data = await res.json();
  return (
    data?.candidates?.[0]?.content?.parts
      ?.map((p: { text?: string }) => p.text)
      .filter(Boolean)
      .join('\n') ?? ''
  );
}

// ─── Vision call (image + text) ───────────────────────────────────────────────

async function callGeminiVision(base64Image: string, prompt: string): Promise<string> {
  if (!GEMINI_KEY) throw new Error('VITE_GEMINI_API_KEY is not set.');

  const imageData = base64Image.includes(',') ? base64Image.split(',')[1] : base64Image;

  const body = {
    contents: [{
      role: 'user',
      parts: [
        { inlineData: { mimeType: 'image/jpeg', data: imageData } },
        { text: prompt },
      ],
    }],
    generationConfig: { temperature: 0.1, maxOutputTokens: 512 },
  };

  const res = await fetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-goog-api-key': GEMINI_KEY },
    body: JSON.stringify(body),
  });

  if (res.status === 429) throw new Error('Rate limit reached. Please try again.');
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message ?? `API error (${res.status})`);
  }

  const data = await res.json();
  return (
    data?.candidates?.[0]?.content?.parts
      ?.map((p: { text?: string }) => p.text)
      .filter(Boolean)
      .join('\n') ?? ''
  );
}

// ─── Multi-turn chat call ─────────────────────────────────────────────────────

async function callGeminiChat(
  messages: Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }>,
  systemInstruction?: string
): Promise<string> {
  if (!GEMINI_KEY) throw new Error('VITE_GEMINI_API_KEY is not set.');

  const body: Record<string, unknown> = {
    contents: messages,
    generationConfig: { temperature: 0.5, maxOutputTokens: 1024 },
  };
  if (systemInstruction) {
    body.systemInstruction = { parts: [{ text: systemInstruction }] };
  }

  const res = await fetch(BASE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-goog-api-key': GEMINI_KEY },
    body: JSON.stringify(body),
  });

  if (res.status === 429) throw new Error('Rate limit reached.');
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err?.error?.message ?? `API error (${res.status})`);
  }

  const data = await res.json();
  return (
    data?.candidates?.[0]?.content?.parts
      ?.map((p: { text?: string }) => p.text)
      .filter(Boolean)
      .join('\n') ?? ''
  );
}

// ─── 1. Leaf Validator ────────────────────────────────────────────────────────

const LEAF_VALIDATION_PROMPT = (targetLangName = 'English') => `
You are an agricultural image validation system.

Examine this image and determine if it contains ANY crop, plant, leaf, foliage, stem, crop field, or agricultural plant material (even if held in hand, diseased, yellowed/browned, in a pot, or in a field).

CRITICAL INSTRUCTIONS:
1. Set "isLeaf": true if the image contains any crop leaf, plant foliage, stem, or agricultural crop material.
2. Set "isLeaf": false ONLY if the image is completely unrelated to plants (e.g. human face/person without plant, vehicle, building, document text, or non-plant object).
3. Write the "reason" field in valid ${targetLangName} language only.

Return ONLY a valid JSON object with no markdown:
{
  "isLeaf": true or false,
  "quality": "good" | "blurry" | "dark" | "multiple" | "invalid" | "cropped" | "low_res",
  "reason": "One sentence explanation in ${targetLangName}"
}
`.trim();

export async function validateLeafImage(
  dataUrl: string,
  targetLangName = 'English'
): Promise<ValidationResult> {
  if (!GEMINI_KEY) {
    return { isLeaf: true, quality: 'good', reason: 'Validation skipped (no API key)' };
  }

  try {
    const raw = await callGeminiVision(dataUrl, LEAF_VALIDATION_PROMPT(targetLangName));
    const cleaned = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim();
    const parsed = JSON.parse(cleaned) as ValidationResult;
    return parsed;
  } catch (err) {
    console.warn('Leaf validation failed, proceeding without validation:', err);
    return { isLeaf: true, quality: 'good', reason: 'Validation service unavailable' };
  }
}

// ─── 2. Disease Explanation (17 fields) ──────────────────────────────────────

const DISEASE_PROMPT = (crop: string, disease: string, targetLangName = 'English') => `
You are an expert agricultural scientist and plant pathologist. The AI system has identified "${disease}" in a "${crop}" plant.

CRITICAL LANGUAGE REQUIREMENT:
You MUST write ALL text values in the JSON strictly in the ${targetLangName} language.
Do NOT mix languages or use English unless technical chemical names require it.
The farmer will read this report in ${targetLangName}.

Return ONLY a valid JSON object with no markdown fences or extra text:

{
  "overview": "2-3 sentence overview of this disease in ${targetLangName}",
  "symptoms": ["symptom 1 in ${targetLangName}", "symptom 2", "symptom 3", "symptom 4"],
  "cause": "Single sentence describing primary cause in ${targetLangName}",
  "spreadMethod": "Single sentence describing spread in ${targetLangName}",
  "biofertilizer": "Name of effective biofertilizer",
  "dosage": "Specific dosage in ${targetLangName}",
  "applicationMethod": "Application instructions in ${targetLangName}",
  "precautions": ["precaution 1 in ${targetLangName}", "precaution 2", "precaution 3"],
  "organicControl": ["organic method 1 in ${targetLangName}", "organic method 2"],
  "chemicalControl": ["chemical treatment 1 in ${targetLangName}", "chemical treatment 2"],
  "recoveryTime": "Estimated recovery time in ${targetLangName}",
  "preventiveMeasures": ["preventive measure 1 in ${targetLangName}", "preventive measure 2", "preventive measure 3"],
  "farmerFriendlyExplanation": "Simple 2-3 sentence guide for village farmers in ${targetLangName}"
}

If the disease is "Healthy", describe it as a healthy crop in ${targetLangName}.
`.trim();

export async function getDiseaseExplanation(
  crop: string,
  disease: string,
  targetLangName = 'English'
): Promise<DiseaseInfo> {
  const isHealthy = disease.toLowerCase() === 'healthy';

  const fallback: DiseaseInfo = {
    overview: isHealthy
      ? `Your ${crop} plant is in excellent health.`
      : `${disease} detected in ${crop}.`,
    symptoms: isHealthy
      ? ['Vibrant leaves', 'Normal growth']
      : ['Visible lesions', 'Yellowing of leaves', 'Wilting'],
    cause: isHealthy ? 'Healthy crop.' : 'Pathogen infection under favourable conditions.',
    spreadMethod: isHealthy ? 'N/A' : 'Spreads via wind, water splash, infected tools.',
    biofertilizer: isHealthy ? 'Azospirillum + PSB Mix' : 'Pseudomonas fluorescens',
    dosage: '2.5 kg per acre',
    applicationMethod: 'Foliar spray or soil drench',
    precautions: ['Apply in early morning or evening', 'Avoid spraying during rain'],
    organicControl: ['Neem oil spray (5 ml/L)', 'Trichoderma viride drench'],
    chemicalControl: ['Mancozeb 75WP @ 2.5g/L', 'Copper oxychloride 50WP @ 3g/L'],
    recoveryTime: isHealthy ? 'N/A' : '3–4 weeks with treatment',
    preventiveMeasures: ['Crop rotation', 'Field sanitation', 'Good drainage'],
    farmerFriendlyExplanation: isHealthy
      ? `Your ${crop} is healthy. Maintain regular care.`
      : `Treat your ${crop} for ${disease} promptly. Apply recommended spray in morning/evening.`,
  };

  try {
    const raw = await callGemini(DISEASE_PROMPT(crop, disease, targetLangName));
    const cleaned = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim();
    const parsed = JSON.parse(cleaned) as DiseaseInfo;

    const required: Array<keyof DiseaseInfo> = [
      'overview', 'symptoms', 'cause', 'spreadMethod',
      'biofertilizer', 'dosage', 'applicationMethod', 'precautions',
      'organicControl', 'chemicalControl', 'recoveryTime',
      'preventiveMeasures', 'farmerFriendlyExplanation',
    ];
    for (const key of required) {
      if (!parsed[key]) throw new Error(`Missing key: ${key}`);
    }
    return parsed;
  } catch (err) {
    console.warn('getDiseaseExplanation failed, using fallback:', err);
    return fallback;
  }
}

// ─── 3. Follow-up chatbot ─────────────────────────────────────────────────────

const CHAT_SYSTEM = (crop: string, disease: string, targetLangName = 'English') =>
  `You are a knowledgeable agricultural assistant specializing in crop health for ${crop} plants.
${disease.toLowerCase() === 'healthy'
  ? `The farmer's ${crop} is currently healthy.`
  : `The farmer's ${crop} has been diagnosed with "${disease}".`
}

CRITICAL LANGUAGE MANDATE:
You MUST respond STRICTLY in ${targetLangName} language only.
Do NOT reply in English or mix multiple languages.
Use simple, practical, farmer-friendly terms in ${targetLangName}.

Guidelines:
- Answer ONLY questions about crop health, treatment, and care
- Maximum 3 short paragraphs per reply
- Do NOT mention AI, Gemini, or language models`;

export async function getChatResponse(
  crop: string,
  disease: string,
  history: ChatMessage[],
  targetLangName = 'English'
): Promise<string> {
  const messages = history.map((m) => ({
    role: m.role === 'user' ? ('user' as const) : ('model' as const),
    parts: [{ text: m.content }],
  }));

  try {
    return await callGeminiChat(messages, CHAT_SYSTEM(crop, disease, targetLangName));
  } catch (err) {
    console.error('Chat response error:', err);
    return 'Error generating response. Please try again.';
  }
}

// ─── 4. Vision Crop & Disease Predictor (NOT used in main pipeline) ────────────────────
// This function is kept for development/testing only.
// The production prediction pipeline uses FastAPI /predict (ML models), NOT this function.
// Do NOT call this from usePrediction.ts or any production code path.

const CROP_DISEASE_PREDICT_PROMPT = `
You are an expert plant pathologist and AI crop disease classifier.
Examine this crop leaf image closely and predict the crop name, disease name, confidence scores, and severity.

Select crop ONLY from this list of supported crops and their valid diseases:
1. Tomato: "Bacterial Spot", "Early Blight", "Healthy", "Late Blight", "Leaf Mold", "Mosaic Virus", "Septoria Leaf Spot", "Spider Mites", "Target Spot", "Yellow Leaf Curl Virus"
2. Paddy: "Brown Spot", "Healthy", "Leaf Blast", "Leaf Blight", "Leaf Scald", "Sheath Blight"
3. Wheat: "Crown Root Rot", "Healthy", "Leaf Rust", "Loose Smut"
4. Cotton: "Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"
5. Sugarcane: "Healthy", "Red Rot", "Red Rust"
6. Groundnut: "Healthy", "Late Leaf Spot", "Leaf Spot", "Nutrition Deficiency", "Rust"
7. Sunflower: "Alternaria Leaf Spot", "Downy Mildew", "Healthy", "Powdery Mildew", "Rhizopus Head Rot", "Rust", "Sclerotinia"
8. Blackgram: "Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"
9. Eggplant: "Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"
10. Turmeric: "Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"

Return ONLY a valid JSON object with no markdown formatting:
{
  "crop": "Exact crop name from list",
  "crop_confidence": number between 60 and 99,
  "disease": "Exact disease name from list",
  "disease_confidence": number between 55 and 99,
  "severity": "Low" | "Medium" | "High"
}
`.trim();

export async function predictWithGeminiVision(
  imageDataUrl: string
): Promise<{
  crop: string;
  crop_confidence: number;
  disease: string;
  disease_confidence: number;
  severity: 'Low' | 'Medium' | 'High';
}> {
  if (!GEMINI_KEY) throw new Error('VITE_GEMINI_API_KEY is not set.');

  const raw = await callGeminiVision(imageDataUrl, CROP_DISEASE_PREDICT_PROMPT);
  const cleaned = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim();
  const parsed = JSON.parse(cleaned);

  // Strict validation — reject fake/missing fields instead of using hardcoded defaults
  if (!parsed.crop || typeof parsed.crop !== 'string') {
    throw new Error('Gemini did not return a valid crop name.');
  }
  if (!parsed.disease || typeof parsed.disease !== 'string') {
    throw new Error('Gemini did not return a valid disease name.');
  }
  if (typeof parsed.crop_confidence !== 'number' || parsed.crop_confidence <= 0) {
    throw new Error('Gemini did not return a valid crop confidence score.');
  }
  if (typeof parsed.disease_confidence !== 'number' || parsed.disease_confidence <= 0) {
    throw new Error('Gemini did not return a valid disease confidence score.');
  }

  return {
    crop:               parsed.crop,
    crop_confidence:    parsed.crop_confidence,
    disease:            parsed.disease,
    disease_confidence: parsed.disease_confidence,
    severity:           (parsed.severity as 'Low' | 'Medium' | 'High') ?? 'Medium',
  };
}

