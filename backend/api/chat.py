"""
chat.py
-------
FastAPI router for AgroVision AI Assistant:
  - POST /api/chat & /api/ai/chat: Natural-language conversational agricultural AI (Gemini)
  - POST /api/crop-disease & /api/ai/crop-disease: Structured Crop + Disease recommendation (DB + Gemini)
  - GET  /api/chat/health & /api/ai/health: AI health check
"""

import json
import logging
import os
import re
import uuid
from typing import Optional
from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator

logger = logging.getLogger(__name__)
router = APIRouter()

# ── Language map ──────────────────────────────────────────────────────────────
_LANG = {
    "en": "English",
    "ta": "Tamil (தமிழ்)",
    "hi": "Hindi (हिन्दी)",
    "ml": "Malayalam (മലയാളം)",
}

_LANG_SHORT = {
    "en": "English",
    "ta": "Tamil",
    "hi": "Hindi",
    "ml": "Malayalam",
}

# ── Comprehensive Agriculture System Prompt for Chat ─────────────────────────
_SYS_TEMPLATE = """You are AgroVision AI, an intelligent agricultural assistant designed specifically to help farmers, agronomists, and agricultural workers.

Your role is to provide practical, clear, accurate, and farmer-friendly guidance on all farming topics:
- Crop identification and cultivation practices
- Crop diseases, symptoms, diagnosis, and management
- Pest identification and integrated pest management (IPM)
- Fertilizer recommendations (nutrients, organic alternatives, application timing)
- Soil preparation, health, and irrigation scheduling
- Prevention methods and safety precautions

GUIDELINES:
1. Provide simple, clear, practical, and well-structured answers with bullet points.
2. For fertilizers and pesticides: do NOT invent exact unsupported chemical dosages. Recommend trusted methods and advise following local agricultural extension guidelines (TNAU / ICAR).
3. Do NOT provide medical, legal, or unrelated financial advice.
4. Keep answers practical, farmer-friendly, and actionable.
5. If the user asks a greeting or general agricultural question, respond warmly and helpfully.

CRITICAL LANGUAGE RULE:
You MUST respond EXCLUSIVELY in {lang_name}. Do NOT mix other languages. Every word must be in {lang_name}.
"""

_SCAN_CONTEXT = """
=== VERIFIED ML SCAN RESULT (AgroVision AI) ===
Crop: {crop}
Disease/Condition: {disease}
Severity: {severity}
Detection Method: AgroVision AI Two-Stage ML Pipeline (verified)

IMPORTANT: Base your advice on this confirmed diagnosis.
================================================
"""

# ── Pydantic models ───────────────────────────────────────────────────────────

class HistoryMessage(BaseModel):
    role: str
    content: str


class ScanContextModel(BaseModel):
    crop: str
    disease: str
    severity: str = "Unknown"


class ChatRequest(BaseModel):
    message: str
    language: str = "en"
    conversation_id: Optional[str] = None
    history: Optional[list[HistoryMessage]] = None
    scan_context: Optional[ScanContextModel] = None

    @field_validator("message")
    @classmethod
    def _msg_check(cls, v):
        if not v or not v.strip():
            raise ValueError("Message cannot be empty")
        return v.strip()

    @field_validator("language")
    @classmethod
    def _lang_check(cls, v):
        v = (v or "en").lower().strip()
        return v if v in {"en", "ta", "hi", "ml"} else "en"


class CropDiseaseRequest(BaseModel):
    crop: str
    disease: str
    language: str = "en"

    @field_validator("crop")
    @classmethod
    def _crop_check(cls, v):
        if not v or not v.strip():
            raise ValueError("Crop name cannot be empty")
        return v.strip()

    @field_validator("disease")
    @classmethod
    def _disease_check(cls, v):
        if not v or not v.strip():
            raise ValueError("Disease name cannot be empty")
        return v.strip()

    @field_validator("language")
    @classmethod
    def _lang_check(cls, v):
        v = (v or "en").lower().strip()
        return v if v in {"en", "ta", "hi", "ml"} else "en"


# ── Max conversation history to send to Gemini ───────────────────────────────
_MAX_HISTORY = 20


def _build_system_prompt(lang: str, ctx: Optional[ScanContextModel]) -> str:
    lang_name = _LANG.get(lang, "English")
    sys_prompt = _SYS_TEMPLATE.format(lang_name=lang_name)
    if ctx:
        sys_prompt += _SCAN_CONTEXT.format(
            crop=ctx.crop,
            disease=ctx.disease,
            severity=ctx.severity,
        )
    return sys_prompt.strip()


def _resp(status: int, data: dict) -> JSONResponse:
    return JSONResponse(content=data, status_code=status)


# ── Gemini SDK initializer ────────────────────────────────────────────────────
_gemini_client = None
_gemini_sdk_type = None  # "genai_new" or "genai_old"


def _get_gemini():
    """Return (sdk_type, client_or_model). Lazy-initialized."""
    global _gemini_client, _gemini_sdk_type
    if _gemini_client is not None:
        return _gemini_sdk_type, _gemini_client

    key = os.getenv("GEMINI_API_KEY", "").strip()
    if not key:
        raise RuntimeError(
            "GEMINI_API_KEY environment variable is not set. "
            "Add it to backend/.env and restart the server."
        )

    # Prefer google-genai (new SDK)
    try:
        from google import genai  # type: ignore
        client = genai.Client(api_key=key)
        _gemini_client = client
        _gemini_sdk_type = "genai_new"
        logger.info("[AI] Initialized google-genai (new SDK)")
        return _gemini_sdk_type, _gemini_client
    except ImportError:
        pass

    # Fall back to google-generativeai (legacy SDK)
    try:
        import google.generativeai as g  # type: ignore
        g.configure(api_key=key)
        model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        model_obj = g.GenerativeModel(model_name)
        _gemini_client = model_obj
        _gemini_sdk_type = "genai_old"
        logger.info(f"[AI] Initialized google-generativeai (legacy SDK) — model: {model_name}")
        return _gemini_sdk_type, _gemini_client
    except ImportError:
        raise RuntimeError(
            "No Gemini SDK found. Install with: pip install google-genai"
        )


def _get_model_name() -> str:
    return os.getenv("GEMINI_MODEL", "gemini-3.6-flash")


# ── Handler for AI Chat ───────────────────────────────────────────────────────
async def _handle_chat(req: ChatRequest):
    cid = req.conversation_id or str(uuid.uuid4())

    try:
        sdk_type, client_or_model = _get_gemini()
    except RuntimeError as e:
        logger.error(f"[Chat] Gemini init failed: {e}")
        return _resp(503, {
            "success": False,
            "error_code": "AI_SERVICE_UNAVAILABLE",
            "message": "AI Assistant is not configured. Contact support.",
        })

    sys_prompt = _build_system_prompt(req.language, req.scan_context)
    hist = (req.history or [])[-_MAX_HISTORY:]
    model_name = _get_model_name()

    try:
        if sdk_type == "genai_new":
            from google.genai import types  # type: ignore

            history_contents = []
            for msg in hist:
                role = "model" if msg.role == "assistant" else "user"
                history_contents.append(
                    types.Content(role=role, parts=[types.Part(text=msg.content)])
                )

            chat_session = client_or_model.chats.create(
                model=model_name,
                config=types.GenerateContentConfig(
                    system_instruction=sys_prompt,
                    temperature=0.7,
                    top_p=0.9,
                    max_output_tokens=1500,
                ),
                history=history_contents,
            )
            response = chat_session.send_message(req.message)
            answer = (response.text or "").strip()

        else:
            ghist = []
            for msg in hist:
                role = "model" if msg.role == "assistant" else "user"
                ghist.append({"role": role, "parts": [msg.content]})

            chat_session = client_or_model.start_chat(history=ghist)
            full_message = f"{sys_prompt}\n\nFarmer's question: {req.message}"
            response = chat_session.send_message(full_message)
            answer = response.text.strip()

        if not answer:
            raise ValueError("Gemini returned an empty response")

        logger.info(f"[Chat] OK cid={cid} lang={req.language} chars={len(answer)}")
        return _resp(200, {
            "success": True,
            "conversation_id": cid,
            "answer": answer,
            "response": answer,
            "language": req.language,
        })

    except Exception as e:
        err_str = str(e).lower()
        logger.error(f"[Chat] Error: {e}", exc_info=True)

        if "quota" in err_str or "rate" in err_str or "429" in err_str:
            return _resp(429, {
                "success": False,
                "error_code": "RATE_LIMIT_EXCEEDED",
                "message": "AI is busy. Please wait a moment and try again.",
            })
        if "api_key" in err_str or ("invalid" in err_str and "key" in err_str):
            return _resp(503, {
                "success": False,
                "error_code": "AI_SERVICE_UNAVAILABLE",
                "message": "AI configuration error. Please contact support.",
            })
        if "timeout" in err_str or "deadline" in err_str:
            return _resp(504, {
                "success": False,
                "error_code": "AI_TIMEOUT",
                "message": "AI response timed out. Please try again.",
            })
        return _resp(500, {
            "success": False,
            "error_code": "SERVER_ERROR",
            "message": "AI Assistant encountered an error. Please try again.",
        })


# ── Handler for Crop & Disease Recommendation ─────────────────────────────────
async def _handle_crop_disease(req: CropDiseaseRequest):
    crop_in = req.crop.strip()
    disease_in = req.disease.strip()
    lang = req.language
    lang_name = _LANG.get(lang, "English")

    # 1. Lookup verified database in predict.py
    matched_rec = None
    try:
        from api.predict import RECOMMENDATION_DB
        # Try direct key
        key1 = f"{crop_in}|{disease_in}"
        matched_rec = RECOMMENDATION_DB.get(key1)

        # Try case-insensitive / alias match
        if not matched_rec:
            for k, val in RECOMMENDATION_DB.items():
                c_part, d_part = k.split("|", 1) if "|" in k else (k, "")
                if c_part.lower() == crop_in.lower() and d_part.lower() == disease_in.lower():
                    matched_rec = val
                    break
    except Exception as e:
        logger.warning(f"[CropDisease] RECOMMENDATION_DB lookup error: {e}")

    # 2. Build structured prompt for Gemini
    if matched_rec:
        rec_context = f"""
VERIFIED AGRICULTURAL DATA (TNAU / ICAR):
- Product Name: {matched_rec.get('product_name', 'N/A')}
- Category: {matched_rec.get('product_category', 'N/A')}
- Active Ingredient: {matched_rec.get('active_ingredient', 'N/A')}
- Purpose: {matched_rec.get('purpose', 'N/A')}
- Dosage: {matched_rec.get('dosage', 'Consult local officer')} ({matched_rec.get('dosage_unit', '')})
- Application Method: {matched_rec.get('application_method', 'N/A')}
- Application Timing: {matched_rec.get('application_timing', 'N/A')}
- Frequency: {matched_rec.get('frequency', 'N/A')}
- Precautions: {matched_rec.get('precautions', 'N/A')}
- Organic Alternative: {matched_rec.get('organic_alternative', 'N/A')}
- Prevention: {matched_rec.get('prevention', 'N/A')}
- Source: {matched_rec.get('source', 'TNAU/ICAR')}
"""
    else:
        rec_context = "No specific pre-calculated database entry found. Use authoritative agricultural science. If chemical dosage is not 100% verified, state clearly that exact dosage must follow the manufacturer product label and local agricultural extension guidance."

    structured_prompt = f"""You are AgroVision AI, an expert agricultural scientist.
Provide a complete, structured care and treatment guide for:
Crop: {crop_in}
Disease/Problem: {disease_in}

{rec_context}

Respond in the following JSON format:
```json
{{
  "crop": "{crop_in}",
  "disease": "{disease_in}",
  "overview": "Clear 2-3 sentence overview of this condition in {crop_in}.",
  "symptoms": "Key symptoms visible on leaves/stems/fruits.",
  "fertilizer": "Recommended fertilizer and nutrient management (NPK, micronutrients, organic options).",
  "treatment": "Recommended chemical and biological treatments with active ingredients.",
  "dosage": "Verified dosage if known, or safe application rate with label verification note.",
  "timing": "Best time of day and crop growth stage for application.",
  "prevention": "Cultural and preventive practices (spacing, seed treatment, crop rotation, irrigation).",
  "precautions": "Safety measures, PPE, pre-harvest interval, and when to consult an agronomist.",
  "formatted_text": "A complete, beautifully formatted farmer-friendly guide with emojis and clear sections."
}}
```

CRITICAL RULES:
1. Every string value inside the JSON MUST be translated into {lang_name}.
2. Provide practical, accurate, farmer-friendly guidance.
3. Return ONLY valid JSON wrapped in ```json ... ```.
"""

    try:
        sdk_type, client_or_model = _get_gemini()
        model_name = _get_model_name()

        raw_text = ""
        if sdk_type == "genai_new":
            from google.genai import types  # type: ignore
            res = client_or_model.models.generate_content(
                model=model_name,
                contents=structured_prompt,
                config=types.GenerateContentConfig(
                    temperature=0.4,
                    max_output_tokens=2000,
                ),
            )
            raw_text = (res.text or "").strip()
        else:
            res = client_or_model.generate_content(structured_prompt)
            raw_text = (res.text or "").strip()

        # Parse JSON from markdown codeblock
        json_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw_text, re.DOTALL)
        if json_match:
            parsed = json.loads(json_match.group(1))
        else:
            parsed = json.loads(raw_text)

        logger.info(f"[CropDisease] OK crop={crop_in} disease={disease_in} lang={lang}")
        return _resp(200, {
            "success": True,
            "crop": parsed.get("crop", crop_in),
            "disease": parsed.get("disease", disease_in),
            "overview": parsed.get("overview", ""),
            "symptoms": parsed.get("symptoms", ""),
            "fertilizer": parsed.get("fertilizer", ""),
            "treatment": parsed.get("treatment", ""),
            "dosage": parsed.get("dosage", ""),
            "timing": parsed.get("timing", ""),
            "prevention": parsed.get("prevention", ""),
            "precautions": parsed.get("precautions", ""),
            "response": parsed.get("formatted_text", raw_text),
            "language": lang,
        })

    except Exception as e:
        logger.error(f"[CropDisease] Error: {e}", exc_info=True)
        # Fallback if JSON parse or AI fails but DB has info
        if matched_rec:
                dosage_val = str(matched_rec.get('dosage', '')).strip()
                unit_val = str(matched_rec.get('dosage_unit', '')).strip()
                clean_dosage = dosage_val if (unit_val.lower() in dosage_val.lower() or not unit_val) else f"{dosage_val} {unit_val}"
                return _resp(200, {
                    "success": True,
                    "crop": crop_in,
                    "disease": disease_in,
                    "overview": matched_rec.get("purpose", ""),
                    "symptoms": f"Common symptoms of {disease_in} in {crop_in}.",
                    "fertilizer": matched_rec.get("organic_alternative", "Balanced NPK fertilizer per soil test."),
                    "treatment": f"{matched_rec.get('product_name', '')} ({matched_rec.get('active_ingredient', '')})",
                    "dosage": clean_dosage,
                    "timing": matched_rec.get("application_timing", ""),
                    "prevention": matched_rec.get("prevention", ""),
                    "precautions": matched_rec.get("precautions", ""),
                    "response": f"**{crop_in} — {disease_in}**\n\nTreatment: {matched_rec.get('product_name', '')}\nDosage: {clean_dosage}\nApplication: {matched_rec.get('application_method', '')}\nPrevention: {matched_rec.get('prevention', '')}",
                    "language": lang,
                })

        return _resp(500, {
            "success": False,
            "error_code": "AI_ERROR",
            "message": "Unable to generate recommendation at this moment. Please try again.",
        })


# ── Route definitions (supporting both /chat and /ai/chat) ───────────────────
@router.post("/chat", tags=["chat"])
@router.post("/ai/chat", tags=["chat"])
async def chat_endpoint(req: ChatRequest):
    return await _handle_chat(req)


@router.post("/crop-disease", tags=["crop-disease"])
@router.post("/ai/crop-disease", tags=["crop-disease"])
async def crop_disease_endpoint(req: CropDiseaseRequest):
    return await _handle_crop_disease(req)


@router.get("/chat/health", tags=["health"])
@router.get("/ai/health", tags=["health"])
async def chat_health():
    key = os.getenv("GEMINI_API_KEY", "").strip()
    configured = bool(key)
    model_name = _get_model_name()

    gemini_reachable = False
    if configured:
        try:
            from google import genai  # type: ignore
            client = genai.Client(api_key=key)
            _ = list(client.models.list())
            gemini_reachable = True
        except Exception as e:
            logger.warning(f"[Chat/health] Gemini probe warning: {e}")

    return _resp(200, {
        "success": True,
        "chat_configured": configured,
        "gemini_reachable": gemini_reachable,
        "model": model_name,
        "languages": ["en", "ta", "hi", "ml"],
        "endpoints": [
            "POST /api/chat",
            "POST /api/ai/chat",
            "POST /api/crop-disease",
            "POST /api/ai/crop-disease",
        ],
    })
