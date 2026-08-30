import logging
import os
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
    "ta": "Tamil",
    "hi": "Hindi",
    "ml": "Malayalam",
}

# ── Comprehensive Agriculture System Prompt ───────────────────────────────────
_SYS_TEMPLATE = """You are AgroVision AI, an expert agricultural assistant designed specifically to help farmers and agricultural workers.

Your role is to provide practical, clear, and accurate guidance on all farming-related topics.

TOPICS YOU CAN HELP WITH:
- Crop identification and growth stages
- Crop diseases, symptoms, diagnosis, and management
- Pest identification and integrated pest management
- Fertilizer recommendations (type, dosage, timing, application methods)
- Soil preparation, health, and nutrient management
- Irrigation techniques, scheduling, and water management
- Seed selection and crop variety recommendations
- Organic farming and biological controls
- Weather-related crop management
- Post-harvest handling and storage
- General farming best practices

GUIDELINES:
1. Ask useful follow-up questions if the crop name, symptoms, location, growth stage, or duration of symptoms is missing and would improve your advice.
2. Do NOT invent a diagnosis when there is insufficient information — ask clarifying questions first.
3. When a verified AgroVision AI ML scan result is provided, use it as the authoritative starting point. Do NOT contradict the ML result without clearly explaining your alternative reasoning.
4. For fertilizers and pesticides: avoid claiming guaranteed results. Always advise to follow product labels, dosage instructions, and local agricultural extension guidance.
5. For serious crop losses, chemical exposure, or unfamiliar symptoms, recommend consulting a local agricultural officer or expert.
6. Keep answers practical, farmer-friendly, and actionable.
7. Suggest AgroVision AI's Crop Leaf Scan feature when image-based identification would help.
8. Do NOT provide medical advice, legal advice, or financial advice.
9. Be concise but thorough — farmers need actionable information, not lengthy academic essays.

LANGUAGE RULE:
Respond ONLY in {lang_name}. Do not mix languages in your response. Even if the user writes in a different language, always respond in {lang_name}.
"""

_SCAN_CONTEXT = """
=== VERIFIED ML SCAN RESULT (AgroVision AI) ===
Crop: {crop}
Disease/Condition: {disease}
Severity: {severity}
Detection Method: AgroVision AI Two-Stage ML Pipeline (verified)

IMPORTANT: This is a machine-learning verified result from the AgroVision AI system. Base your advice on this information. Do not ask the user to re-identify the crop or disease — these are already confirmed.
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
        v = v.lower().strip()
        return v if v in {"en", "ta", "hi", "ml"} else "en"


# ── Max conversation history to send to Gemini ───────────────────────────────
_MAX_HISTORY = 20


def _build_system_prompt(lang: str, ctx: Optional[ScanContextModel]) -> str:
    """Build the full system instruction with language and optional scan context."""
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
        logger.info("[Chat] Initialized google-genai (new SDK) — model: gemini-3.6-flash")
        return _gemini_sdk_type, _gemini_client
    except ImportError:
        pass

    # Fall back to google-generativeai (legacy SDK)
    try:
        import google.generativeai as g  # type: ignore
        g.configure(api_key=key)
        model_obj = g.GenerativeModel(
            "gemini-2.0-flash",
            system_instruction="You are AgroVision AI agricultural assistant.",
            generation_config={"temperature": 0.7, "top_p": 0.9, "max_output_tokens": 1500},
        )
        _gemini_client = model_obj
        _gemini_sdk_type = "genai_old"
        logger.info("[Chat] Initialized google-generativeai (legacy SDK) — model: gemini-2.0-flash")
        return _gemini_sdk_type, _gemini_client
    except ImportError:
        raise RuntimeError(
            "No Gemini SDK found. Install with: pip install google-genai"
        )


# ── POST /api/chat ────────────────────────────────────────────────────────────
@router.post("/chat", tags=["chat"])
async def chat(req: ChatRequest):
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

    try:
        if sdk_type == "genai_new":
            from google import genai  # type: ignore
            from google.genai import types  # type: ignore

            # Build conversation history for chat session
            history_contents = []
            for msg in hist:
                role = "model" if msg.role == "assistant" else "user"
                history_contents.append(
                    types.Content(role=role, parts=[types.Part(text=msg.content)])
                )

            # Use Chat.send_message (recommended by SDK over Models.generate_content)
            chat_session = client_or_model.chats.create(
                model="gemini-3.6-flash",
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
            # Legacy google-generativeai SDK
            ghist = []
            for msg in hist:
                role = "model" if msg.role == "assistant" else "user"
                ghist.append({"role": role, "parts": [msg.content]})

            chat_session = client_or_model.start_chat(history=ghist)
            # Prepend system context to first user message
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
        if "api_key" in err_str or ("invalid" in err_str and "key" in err_str) or "api key not valid" in err_str:
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
        if "model" in err_str and ("not found" in err_str or "404" in err_str):
            return _resp(503, {
                "success": False,
                "error_code": "AI_SERVICE_UNAVAILABLE",
                "message": "AI model unavailable. Please try again later.",
            })
        return _resp(500, {
            "success": False,
            "error_code": "SERVER_ERROR",
            "message": "AI Assistant encountered an error. Please try again.",
        })


# ── GET /api/chat/health ──────────────────────────────────────────────────────
@router.get("/chat/health", tags=["chat"])
async def chat_health():
    key = os.getenv("GEMINI_API_KEY", "").strip()
    configured = bool(key)

    # Quick connectivity probe
    gemini_reachable = False
    if configured:
        try:
            from google import genai  # type: ignore
            client = genai.Client(api_key=key)
            # Just list models to check connectivity — lightweight
            _ = list(client.models.list())
            gemini_reachable = True
        except Exception as e:
            logger.warning(f"[Chat/health] Gemini probe failed: {e}")

    return _resp(200, {
        "success": True,
        "chat_configured": configured,
        "gemini_reachable": gemini_reachable,
        "model": "gemini-3.6-flash",
        "languages": ["en", "ta", "hi", "ml"],
        "features": [
            "multi-turn-conversation",
            "scan-context-integration",
            "multilingual-responses",
            "conversation-history",
        ],
    })
