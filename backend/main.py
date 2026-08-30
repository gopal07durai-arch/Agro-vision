"""
main.py
-------
FastAPI application entry point.

Run with:
    python main.py
Or:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

import logging
import os
import time
import uvicorn
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Load .env from same directory as this file
load_dotenv()

from api.predict import router as predict_router
from api.chat import router as chat_router
from model.model_loader import load_model

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "info").upper(),
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
# Startup state — shared with predict router
# ─────────────────────────────────────────────
startup_state = {
    "ready": False,
    "startup_start_ms": 0,
    "startup_duration_ms": 0,
}


# ─────────────────────────────────────────────
# Lifespan (startup / shutdown)
# ─────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    t0 = time.time()
    startup_state["startup_start_ms"] = int(t0 * 1000)

    logger.info("🌱 AgroVision AI Backend starting up...")
    logger.info("⏳ Loading ML models — this takes 20-30 seconds on first start...")
    load_model()  # Load crop classifier + all disease sub-models at startup (ONCE)

    elapsed_ms = int((time.time() - t0) * 1000)
    startup_state["startup_duration_ms"] = elapsed_ms
    startup_state["ready"] = True

    logger.info(f"✅ All models loaded. Server ready in {elapsed_ms/1000:.1f}s.")
    logger.info("🌐 Backend accessible at: http://0.0.0.0:8000")
    logger.info("📖 API docs: http://localhost:8000/docs")
    logger.info("❤️  Health: GET /api/v1/health")
    logger.info("🔬 Predict: POST /api/v1/predict")
    yield
    logger.info("🛑 AgroVision AI Backend shutting down.")


# ─────────────────────────────────────────────
# App
# ─────────────────────────────────────────────
app = FastAPI(
    title="AgroVision AI — Crop Disease Detection API",
    description=(
        "Upload a crop leaf image to detect the crop name, disease, "
        "and confidence score using a trained two-stage Keras model pipeline. "
        "Supported crops: Blackgram, Cotton, Eggplant, Groundnut, Paddy, "
        "Sugarcane, Sunflower, Tomato, Turmeric, Wheat."
    ),
    version="3.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────
# Inject startup_state into predict router
# ─────────────────────────────────────────────
app.state.startup_state = startup_state

# ─────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────
app.include_router(predict_router, prefix="/api/v1", tags=["prediction"])
app.include_router(chat_router, prefix="/api", tags=["chat"])


@app.get("/health", tags=["health"])
async def health_check():
    """Standard cloud health probe for Render, Railway, AWS, and GCP."""
    return {
        "status": "ok",
        "service": "AgroVision AI",
        "version": "3.0.0",
        "ready": startup_state["ready"],
    }


@app.get("/", tags=["root"])
async def root():
    return {
        "service": "AgroVision AI — Crop Disease Detection",
        "version": "3.0.0",
        "docs": "/docs",
        "health": "/health",
        "api_health": "/api/v1/health",
        "predict": "POST /api/v1/predict",
        "startup_ready": startup_state["ready"],
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    host = os.getenv("HOST", "0.0.0.0")
    logger.info(f"Starting on {host}:{port}")

    # Show LAN IPs for easy mobile configuration
    try:
        import socket
        hostname = socket.gethostname()
        lan_ip = socket.gethostbyname(hostname)
        logger.info(f"💡 For physical mobile device, use: http://{lan_ip}:{port}")
        logger.info(f"💡 For Android Emulator, use: http://10.0.2.2:{port}")
    except Exception:
        pass

    uvicorn.run("main:app", host=host, port=port, reload=False)
