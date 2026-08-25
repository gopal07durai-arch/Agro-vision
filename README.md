# 🌿 AgroVision AI — Smart Crop Disease Detection Platform

> Upload a crop leaf photo → get instant AI-powered disease diagnosis, fertilizer recommendations, and a Gemini-generated treatment plan.

---

## Architecture

```
React Frontend
│
├── Upload / Camera Capture
│       │
│       ▼
├── Image Quality Check        (client-side: blur, brightness, resolution)
│       │
│       ▼
├── Leaf Validator             (Gemini Vision API — is this a crop leaf?)
│       │
│       ▼
├── FastAPI Backend            (POST /api/v1/predict)
│       │
│       ▼
├── TensorFlow / Keras Model   (crop classifier + disease classifier, single pass)
│       │ returns: crop, disease, confidence, severity
│       ▼
├── Fertilizer Engine          (local DB lookup → 3+ ranked recommendations)
│       │
│       ▼
├── Gemini Explanation         (gemini-2.0-flash → 17-field structured disease info)
│       │
│       ▼
├── Prediction Page            (CropDiseaseCard, DiseaseInfoCard, FertilizerCard, RecoveryCard)
│       │
│       ├── PDF Export
│       ├── Star Rating
│       └── Chat (Follow-up Assistant)
│               │
│               ▼
└── Supabase                   (prediction_history, fertilizer_ratings tables)
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + TypeScript + Vite |
| Styling | Tailwind CSS v3 + custom CSS |
| Backend | FastAPI (Python) |
| ML Model | TensorFlow / Keras (`.keras` format) |
| AI APIs | Google Gemini 2.0 Flash |
| Database | Supabase (PostgreSQL) |
| Translation | Google Translate (via cookie / Translate widget) |

---

## Quickstart

### Prerequisites
- Node.js 18+
- Python 3.10+
- A trained Keras model file (`model.keras`) — see **Model Setup** below

### 1. Clone & Install Frontend

```bash
npm install
```

### 2. Configure Frontend Environment

Copy `.env.example` to `.env` and fill in your keys:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_GEMINI_API_KEY=your-gemini-api-key
VITE_FASTAPI_URL=http://localhost:8000
```

### 3. Install Backend

```bash
cd backend
pip install -r requirements.txt
```

### 4. Configure Backend Environment

Create `backend/.env`:

```env
MODEL_PATH=model/model.keras
LABELS_PATH=model/labels.json
IMAGE_SIZE=224
LOG_LEVEL=info
CORS_ORIGINS=http://localhost:5173,http://localhost:4173
```

### 5. Place Your Model

Drop your trained Keras model into `backend/model/model.keras`.

> **No model?** The backend automatically falls back to **mock mode** — cycling through label classes deterministically. Great for frontend development.

### 6. Start the Backend

```bash
cd backend
uvicorn main:app --reload --port 8000
```

API docs available at: [http://localhost:8000/docs](http://localhost:8000/docs)

### 7. Start the Frontend

```bash
npm run dev
```

App runs at: [http://localhost:5173](http://localhost:5173)

---

## Supabase Setup

Create the following tables in your Supabase project:

### `prediction_history`

```sql
create table prediction_history (
  id              uuid primary key default gen_random_uuid(),
  session_id      text not null,
  image_url       text,
  crop_name       text not null,
  disease_name    text not null,
  confidence      float not null,
  severity        text,
  fertilizer_name text,
  recommendation  jsonb,
  prediction_time_ms integer,
  user_rating     integer,
  created_at      timestamptz default now()
);
```

### `fertilizer_ratings`

```sql
create table fertilizer_ratings (
  id              uuid primary key default gen_random_uuid(),
  session_id      text not null,
  fertilizer_name text not null,
  crop_type       text not null,
  disease_type    text not null,
  rating          integer not null,
  created_at      timestamptz default now()
);
```

---

## Model Format

The model should accept **224×224 RGB images** (normalized `[0,1]`) and output a softmax distribution over all disease classes defined in `backend/model/labels.json`.

### `labels.json` format

```json
{
  "classes": [
    { "crop": "Tomato", "disease": "Early Blight", "severity": "Medium" },
    { "crop": "Tomato", "disease": "Healthy",      "severity": "None"   },
    ...
  ]
}
```

The class index in the softmax output must correspond 1:1 with the array index in `classes`.

---

## Supported Crops & Diseases

| Crop | Diseases |
|------|----------|
| Tomato | Early Blight, Late Blight, Bacterial Spot, Leaf Mold, Septoria, Spider Mites, Mosaic Virus, Yellow Leaf Curl, Healthy |
| Paddy | Brown Spot, Leaf Blast, Leaf Blight, Leaf Scald, Sheath Blight, Healthy |
| Wheat | Crown Root Rot, Leaf Rust, Loose Smut, Healthy |
| Cotton | Aphids, Army Worm, Bacterial Blight, Powdery Mildew, Target Spot, Healthy |
| Sugarcane | Red Rot, Red Rust, Healthy |
| Groundnut | Late Leaf Spot, Leaf Spot, Rust, Healthy |
| Sunflower | Alternaria Leaf Spot, Downy Mildew, Powdery Mildew, Rust, Rhizopus Head Rot, Sclerotinia, Healthy |
| Blackgram | Anthracnose, Leaf Crinkle, Powdery Mildew, Yellow Mosaic, Healthy |
| Eggplant | Insect Pest, Leaf Spot, Mosaic Virus, Small Leaf, White Mold, Wilt Disease, Healthy |
| Turmeric | Dry Leaf, Leaf Blotch, Rhizome Disease, Healthy |

---

## API Reference

### `POST /api/v1/predict`

| Field | Type | Description |
|-------|------|-------------|
| `file` | `UploadFile` | JPEG / PNG / WebP image (max 10 MB) |

**Response:**

```json
{
  "crop": "Tomato",
  "disease": "Early Blight",
  "confidence": 96.42,
  "severity": "Medium",
  "fertilizer": "Trichoderma viride",
  "dosage": "2.5 kg/acre soil drench",
  "prediction_time_ms": 142,
  "mock": false
}
```

### `GET /api/v1/health`

Returns `{ "status": "ok" }` when the backend is running.

---

## Scripts

```bash
npm run dev          # Start development server
npm run build        # Production build
npm run typecheck    # TypeScript type check (no emit)
npm run lint         # ESLint
npm run deploy       # Deploy to GitHub Pages (gh-pages)
```

---

## Project Structure

```
trail 2/
├── src/
│   ├── components/
│   │   ├── layout/        Header.tsx
│   │   ├── upload/        ImageUploader.tsx, CameraCapture.tsx, LeafValidationError.tsx
│   │   ├── prediction/    PredictionPage, CropDiseaseCard, DiseaseInfoCard, FertilizerCard,
│   │   │                  RecoveryCard, AnalyzingLoader, ActionBar, ConfidenceIndicator
│   │   ├── history/       HistoryPage.tsx, HistoryCard.tsx
│   │   └── Chat.tsx, ChatMessage.tsx, ChatInput.tsx, Translator.tsx
│   ├── hooks/             usePrediction.ts, useGeminiChat.ts
│   ├── services/          predictionService.ts, geminiService.ts,
│   │                      fertilizerService.ts, supabaseService.ts
│   ├── types/             index.ts
│   ├── utils/             imageUtils.ts
│   └── App.tsx
├── backend/
│   ├── api/               predict.py
│   ├── model/             model_loader.py, labels.json
│   ├── main.py
│   └── requirements.txt
└── supabase/
```

---

## License

MIT — Built for the agricultural AI community 🌱
