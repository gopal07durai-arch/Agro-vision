"""
model_loader.py
---------------
Loads the trained Keras crop classifier (crop_classifier.keras) and per-crop disease models.

NO FAKE PREDICTIONS, NO MOCK DATA, NO RANDOM FALLBACKS, NO HARDCODED CROP DEFAULTS.

Inference Pipeline (Strict Two-Stage):
  Stage 1 (Crop Classification):
    Run crop_classifier.keras (10 classes: Blackgram, Cotton, Eggplant, Groundnut, Paddy, Sugarcane, Sunflower, Tomato, Turmeric, Wheat).
    Input: [0.0, 255.0] float32 image tensor (model has built-in mobilenet_v2.preprocess_input layer).
    Returns predicted crop + genuine model crop_confidence.

  Stage 2 (Disease Classification):
    Conditioned strictly on the predicted crop, run ONLY that crop's disease sub-model with that model's exact expected preprocessing:
      - Blackgram, Cotton, Eggplant, Sugarcane, Turmeric: [0.0, 255.0] float32
      - Groundnut, Paddy, Sunflower, Tomato, Wheat: [0.0, 1.0] float32
    Returns predicted disease + genuine model disease_confidence.

  If crop_confidence < CROP_CONFIDENCE_THRESHOLD or disease_confidence < DISEASE_CONFIDENCE_THRESHOLD,
  the prediction API rejects with LOW_CROP_CONFIDENCE or LOW_DISEASE_CONFIDENCE.

  If the Sunflower disease sub-model predicts a Wheat-contaminated class (the Sunflower model
  was trained on a Sunflower+Wheat combined dataset), disease_confidence is set to 0.0 so the
  API rejects it as LOW_DISEASE_CONFIDENCE.

  CROP_CONFIDENCE_THRESHOLD is set to 65% (was 55%) to reduce false Wheat predictions
  from the crop classifier on ambiguous or low-quality leaf images.
"""

import os
import json
import logging
import time
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

from model.crop_config import MODEL_SETTINGS

logger = logging.getLogger(__name__)

# Model Version
MODEL_VERSION = "v3.1 (Two-Stage ML Pipeline — Entropy-Guarded Inference)"

# Paths
_BACKEND_DIR  = Path(__file__).parent.parent          # backend/
_LABELS_PATH  = _BACKEND_DIR / os.getenv("LABELS_PATH", "model/labels.json")
_IMAGE_SIZE   = int(os.getenv("IMAGE_SIZE", str(MODEL_SETTINGS["image_size"])))

# Configurable thresholds (0-100 scale).
# CROP_CONFIDENCE_THRESHOLD raised to 65% (was 55%) to reduce false Wheat predictions.
# Change via .env: CROP_CONFIDENCE_THRESHOLD=65.0
CROP_CONFIDENCE_THRESHOLD    = float(os.getenv("CROP_CONFIDENCE_THRESHOLD",    "65.0"))
DISEASE_CONFIDENCE_THRESHOLD = float(os.getenv("DISEASE_CONFIDENCE_THRESHOLD", "50.0"))

# Globals
_model                      = None
_crop_classifier_model      = None
_sub_models: dict[str, Any] = {}
_labels: list[dict]         = []
_startup_ready: bool        = False  # True only after all models + warmup complete

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Crop Classifier Class Order (10 classes)
# MUST match training class order from train_crop_classifier.py
# ─────────────────────────────────────────────────────────────────────────────
CROP_CLASSIFIER_CLASSES = [
    "Blackgram",
    "Cotton",
    "Eggplant",
    "Groundnut",
    "Paddy",
    "Sugarcane",
    "Sunflower",
    "Tomato",
    "Turmeric",
    "Wheat"
]

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Per-Crop Disease Sub-Models (Exact Training Output Orders & Scaling)
# ─────────────────────────────────────────────────────────────────────────────
_DISEASE_MODEL_CONFIG = {
    "Blackgram": {
        "file": "blackgram.keras",
        "size": 224,
        "norm": "0_255",
        "classes": ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"],
    },
    "Cotton": {
        "file": "cotton.keras",
        "size": 224,
        "norm": "0_255",
        "classes": ["Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"],
    },
    "Eggplant": {
        "file": "eggplant.keras",
        "size": 224,
        "norm": "0_255",
        "classes": ["Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"],
    },
    "Groundnut": {
        "file": "groundnut.keras",
        "size": 150,
        "norm": "0_1",
        "classes": [
            "early_leaf_spot_1",
            "early_rust_1",
            "healthy_leaf_1",
            "late_leaf_spot_1",
            "nutrition_deficiency_1",
            "rust_1",
        ],
        "class_map": {
            "early_leaf_spot_1":      "Leaf Spot",
            "early_rust_1":           "Rust",
            "healthy_leaf_1":         "Healthy",
            "late_leaf_spot_1":       "Late Leaf Spot",
            "nutrition_deficiency_1": "Nutrition Deficiency",
            "rust_1":                 "Rust",
        },
    },
    "Paddy": {
        "file": "paddy.keras",
        "size": 224,
        "norm": "0_1",
        "classes": ["Leaf Blight", "Brown Spot", "Healthy", "Leaf Blast", "Leaf Scald", "Sheath Blight"],
    },
    "Sugarcane": {
        "file": "sugarcane.keras",
        "size": 224,
        "norm": "0_255",
        "classes": ["Healthy", "Red Rot", "Red Rust"],
    },
    "Sunflower": {
        "file": "sunflower.keras",
        "size": 224,
        "norm": "0_1",
        "classes": [
            "alternaria sunflower",
            "downy mildew sunflower",
            "healthy sunflower",
            "healthy wheat",
            "mosaic wheat",
            "powdery mildew sunflower",
            "powdery mildew wheat",
            "rhizopus sunflower",
            "rust sunflower",
            "rust wheat",
            "sclerotinia sunflower",
            "septoria wheat",
            "smuts wheat",
        ],
        "class_map": {
            "alternaria sunflower":     "Alternaria Leaf Spot",
            "downy mildew sunflower":   "Downy Mildew",
            "healthy sunflower":        "Healthy",
            "powdery mildew sunflower": "Powdery Mildew",
            "rhizopus sunflower":       "Rhizopus Head Rot",
            "rust sunflower":           "Rust",
            "sclerotinia sunflower":    "Sclerotinia",
            "healthy wheat":            "__WHEAT_CLASS__",
            "mosaic wheat":             "__WHEAT_CLASS__",
            "powdery mildew wheat":     "__WHEAT_CLASS__",
            "rust wheat":               "__WHEAT_CLASS__",
            "septoria wheat":           "__WHEAT_CLASS__",
            "smuts wheat":              "__WHEAT_CLASS__",
        },
    },
    "Tomato": {
        "file": "tomato.keras",
        "size": 150,
        "norm": "0_1",
        "classes": [
            "Bacterial Spot",
            "Early Blight",
            "Late Blight",
            "Leaf Mold",
            "Septoria Leaf Spot",
            "Spider Mites",
            "Target Spot",
            "Yellow Leaf Curl Virus",
            "Mosaic Virus",
            "Healthy"
        ],
    },
    "Turmeric": {
        "file": "turmeric.keras",
        "size": 224,
        "norm": "0_255",
        "classes": ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"],
    },
    "Wheat": {
        "file": "wheat.keras",
        "size": 224,
        "norm": "0_1",
        "classes": ["Leaf Rust", "Loose Smut", "Crown Root Rot", "Healthy"],
    },
}

# Sentinel value for Sunflower wheat-contaminated disease predictions
_WHEAT_CONTAMINATED_CLASS = "__WHEAT_CLASS__"


def load_labels() -> list[dict]:
    """Load labels.json from disk."""
    if not _LABELS_PATH.exists():
        logger.error(f"Labels file not found at {_LABELS_PATH}")
        return []
    with open(_LABELS_PATH, "r") as f:
        data = json.load(f)
    return data.get("classes", [])


def _validate_model_shapes():
    """
    Startup health check: verify model input/output shapes match expectations.
    """
    if _crop_classifier_model is not None:
        try:
            out_shape = _crop_classifier_model.output_shape
            expected_classes = len(CROP_CLASSIFIER_CLASSES)
            actual_classes = out_shape[-1]
            if actual_classes != expected_classes:
                logger.error(
                    f"[MODEL HEALTH] Crop classifier output mismatch: "
                    f"expected {expected_classes} classes, got {actual_classes}."
                )
            else:
                logger.info(
                    f"[MODEL HEALTH] Crop classifier: output shape {out_shape} ✓ "
                    f"({actual_classes} classes)"
                )
        except Exception as e:
            logger.warning(f"[MODEL HEALTH] Could not inspect crop classifier output shape: {e}")

    for crop_name, model in _sub_models.items():
        cfg = _DISEASE_MODEL_CONFIG.get(crop_name)
        if cfg is None:
            continue
        try:
            out_shape = model.output_shape
            expected_classes = len(cfg["classes"])
            actual_classes = out_shape[-1]
            if actual_classes != expected_classes:
                logger.error(
                    f"[MODEL HEALTH] Disease model '{crop_name}': output mismatch: "
                    f"expected {expected_classes} classes, got {actual_classes}."
                )
            else:
                logger.info(
                    f"[MODEL HEALTH] Disease model '{crop_name}': output shape {out_shape} ✓ "
                    f"({actual_classes} classes)"
                )
        except Exception as e:
            logger.warning(f"[MODEL HEALTH] Could not inspect disease model '{crop_name}' output shape: {e}")


class TFLiteRunner:
    """Wrapper around tf.lite.Interpreter providing a Keras-like .predict() API."""
    def __init__(self, model_path: str):
        import tensorflow as tf
        self.interpreter = tf.lite.Interpreter(model_path=str(model_path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        self.output_shape = tuple(self.output_details[0]['shape'])

    def predict(self, input_tensor: np.ndarray, verbose: int = 0) -> np.ndarray:
        self.interpreter.set_tensor(
            self.input_details[0]['index'],
            input_tensor.astype(np.float32)
        )
        self.interpreter.invoke()
        return self.interpreter.get_tensor(self.output_details[0]['index'])


def load_model():
    """Load trained crop classifier and per-crop disease models at startup (TFLite or Keras)."""
    global _model, _crop_classifier_model, _sub_models, _labels

    _labels = load_labels()
    sub_dir = _BACKEND_DIR / "model" / "sub_models"

    if not sub_dir.exists():
        logger.error(f"Sub-models directory not found at {sub_dir}")
        _model = None
        return

    try:
        import tensorflow as tf

        # 1. Load Stage 1 Crop Classifier (Prefer TFLite for fast boot and low RAM)
        crop_cls_tflite = sub_dir / "crop_classifier.tflite"
        crop_cls_keras = sub_dir / "crop_classifier.keras"

        if crop_cls_tflite.exists():
            _crop_classifier_model = TFLiteRunner(str(crop_cls_tflite))
            logger.info(f"[MODEL] Stage 1 Crop Classifier loaded from {crop_cls_tflite.name} (TFLite)")
        elif crop_cls_keras.exists():
            _crop_classifier_model = tf.keras.models.load_model(str(crop_cls_keras), compile=False)
            logger.info(f"[MODEL] Stage 1 Crop Classifier loaded from {crop_cls_keras.name} (Keras)")
        else:
            logger.error(
                f"[MODEL] Stage 1 Crop Classifier file MISSING at {sub_dir}. "
                "Crop identification is UNAVAILABLE. Server will reject all prediction requests."
            )
            _crop_classifier_model = None
            _model = None
            return

        # 2. Load Stage 2 Disease Models (Prefer TFLite)
        _sub_models.clear()
        for crop_name, cfg in _DISEASE_MODEL_CONFIG.items():
            base_name = cfg["file"].replace(".keras", "")
            tflite_path = sub_dir / f"{base_name}.tflite"
            keras_path = sub_dir / cfg["file"]

            if tflite_path.exists():
                try:
                    _sub_models[crop_name] = TFLiteRunner(str(tflite_path))
                    logger.info(f"[MODEL] Stage 2 Disease Model loaded for '{crop_name}' from {tflite_path.name} (TFLite)")
                except Exception as ex:
                    logger.warning(f"Failed to load TFLite disease model for {crop_name}: {ex}")
            elif keras_path.exists():
                try:
                    _sub_models[crop_name] = tf.keras.models.load_model(str(keras_path), compile=False)
                    logger.info(f"[MODEL] Stage 2 Disease Model loaded for '{crop_name}' from {keras_path.name} (Keras)")
                except Exception as ex:
                    logger.warning(f"Failed to load Keras disease model for {crop_name}: {ex}")

        if _sub_models:
            _model = "READY"
            logger.info(
                f"[MODEL] Two-stage ML pipeline ready "
                f"({len(_sub_models)} crop disease models loaded)."
            )
        else:
            logger.error("[MODEL] No disease models loaded. Server will reject prediction requests.")
            _model = None

        # 3. Startup shape validation
        _validate_model_shapes()

        if _model is not None:
            warmup_models()

    except Exception as e:
        logger.error(f"Failed to load model pipeline: {e}")
        _model = None


def warmup_models():
    """
    Pre-compile TensorFlow predict graphs at startup so the first real request is fast.
    Uses a synthetic green dummy image. The warmup prediction result is DISCARDED —
    it is NOT shown to users. The warmup image is not a real crop leaf.
    """
    global _startup_ready
    try:
        from model.leaf_validator import warmup_leaf_validator
        warmup_leaf_validator()

        # Use a synthetic green image for warmup — result is discarded
        dummy_img = Image.new("RGB", (224, 224), color=(30, 160, 40))
        predict(dummy_img)
        logger.info("[MODEL] TensorFlow predict graphs warmed up successfully.")
        logger.info(
            f"[MODEL] Crop confidence threshold: {CROP_CONFIDENCE_THRESHOLD}% | "
            f"Disease confidence threshold: {DISEASE_CONFIDENCE_THRESHOLD}%"
        )
    except Exception as e:
        logger.warning(f"Model warmup warning: {e}")
    finally:
        # Mark startup complete regardless — warmup failure is non-fatal
        _startup_ready = True
        logger.info("[MODEL] ✅ Startup complete. Ready to serve requests.")


def is_model_loaded() -> bool:
    """Return True if Keras model pipeline is loaded and ready."""
    return _model is not None


def is_startup_ready() -> bool:
    """Return True if all models are loaded AND warmup inference is complete."""
    return _startup_ready and _model is not None


def preprocess_image(image: Image.Image, target_size: int = _IMAGE_SIZE, norm: str = "0_255") -> np.ndarray:
    """
    Resize and format image for model inference.
    - norm='0_255': [0.0, 255.0] float32 tensor (for models with internal preprocess_input like MobileNetV2)
    - norm='0_1': [0.0, 1.0] float32 tensor (for models trained with rescale=1./255)
    """
    image = image.convert("RGB")
    image = image.resize((target_size, target_size), Image.LANCZOS)
    arr = np.array(image, dtype=np.float32)
    if norm == "0_1":
        arr = arr / 255.0
    return np.expand_dims(arr, axis=0)  # shape: (1, H, W, 3)


def _get_severity(crop_name: str, disease_name: str) -> str:
    """Find severity string from labels.json for a given crop + disease."""
    for entry in _labels:
        if entry["crop"] == crop_name and entry["disease"] == disease_name:
            return entry.get("severity", "Medium")
    return "Medium"


def predict(image: Image.Image) -> dict | None:
    """
    Run real Two-Stage TensorFlow inference on a PIL Image.

    Stage 1: Crop Classifier model predicts the crop from pixel visual features.
    Stage 2: Selected crop's disease model predicts the disease.

    Confidences come directly from the models' genuine softmax probabilities.

    NO FAKE PREDICTIONS, NO DEFAULT CROPS, NO HARDCODED FALLBACKS.
    """
    global _model, _crop_classifier_model, _sub_models

    if _model is None:
        logger.error("Predict called but model pipeline is unavailable.")
        return None

    if _crop_classifier_model is None:
        logger.error("Crop classifier is not loaded. Cannot identify crop from image.")
        return None

    start = time.time()
    try:
        # ─────────────────────────────────────────────────────────────────────
        # Stage 1: Crop Classification (real model only — no fallbacks)
        # crop_classifier.keras has built-in mobilenet_v2.preprocess_input,
        # so it requires [0.0, 255.0] float32 input.
        # ─────────────────────────────────────────────────────────────────────
        arr_crop = preprocess_image(image, target_size=_IMAGE_SIZE, norm="0_255")
        crop_preds = _crop_classifier_model.predict(arr_crop, verbose=0)[0]
        crop_idx = int(np.argmax(crop_preds))
        detected_crop = CROP_CLASSIFIER_CLASSES[crop_idx]
        crop_confidence = round(float(crop_preds[crop_idx]) * 100, 2)

        # Log top 5 crop predictions for debugging (server-side only)
        crop_probs_sorted = sorted(
            zip(CROP_CLASSIFIER_CLASSES, crop_preds),
            key=lambda x: x[1],
            reverse=True
        )
        logger.info("=== TOP 5 CROP PREDICTIONS ===")
        for i, (c_name, c_prob) in enumerate(crop_probs_sorted[:5]):
            logger.info(f"  {i+1}. {c_name}: {c_prob * 100:.2f}%")

        # Compute softmax entropy of crop output for OOD analysis
        # NOTE: Genuine crop leaf photos tend to be highly peaked (one dominant class).
        # Posters/non-plant images also produce peaked outputs (the model always picks something).
        # We use the top-2 margin as an additional signal logged for debugging.
        sorted_probs = np.sort(crop_preds)[::-1]
        top1_prob = float(sorted_probs[0])
        top2_prob = float(sorted_probs[1]) if len(sorted_probs) > 1 else 0.0
        crop_margin = round((top1_prob - top2_prob) * 100.0, 2)  # margin in percentage points

        # Softmax entropy (bits) — low entropy = model is very sure
        crop_entropy_bits = float(-np.sum(crop_preds[crop_preds > 0] * np.log2(crop_preds[crop_preds > 0] + 1e-12)))
        logger.info(f"[OOD] Crop softmax entropy={crop_entropy_bits:.3f} bits | top1-top2 margin={crop_margin:.1f}%")

        # ─────────────────────────────────────────────────────────────────────
        # Stage 2: Disease Classification for Detected Crop
        # ─────────────────────────────────────────────────────────────────────
        crop_model = _sub_models.get(detected_crop)
        cfg = _DISEASE_MODEL_CONFIG.get(detected_crop)

        if crop_model is None or cfg is None:
            logger.error(f"No disease model loaded for detected crop '{detected_crop}'.")
            return None

        target_size = cfg.get("size", 224)
        norm_mode = cfg.get("norm", "0_1")
        arr_disease = preprocess_image(image, target_size=target_size, norm=norm_mode)
        disease_preds = crop_model.predict(arr_disease, verbose=0)[0]

        disease_idx = int(np.argmax(disease_preds))
        raw_disease_name = cfg["classes"][disease_idx]

        # Map class name if mapping exists
        class_map = cfg.get("class_map", {})
        disease_name = class_map.get(raw_disease_name, raw_disease_name)
        disease_confidence = round(float(disease_preds[disease_idx]) * 100, 2)

        # ─────────────────────────────────────────────────────────────────────
        # Wheat-contamination guard for Sunflower sub-model
        # ─────────────────────────────────────────────────────────────────────
        if disease_name == _WHEAT_CONTAMINATED_CLASS:
            logger.warning(
                f"[WHEAT GUARD] Sunflower disease model predicted Wheat-contaminated class "
                f"'{raw_disease_name}' (prob: {disease_confidence:.1f}%). "
                "Setting disease_confidence=0.0 to force LOW_DISEASE_CONFIDENCE rejection."
            )
            disease_name = raw_disease_name
            disease_confidence = 0.0

        # Log top 5 disease predictions for debugging (server-side only)
        disease_probs_sorted = sorted(
            zip(cfg["classes"], disease_preds),
            key=lambda x: x[1],
            reverse=True
        )
        logger.info(f"=== TOP 5 DISEASE PREDICTIONS FOR {detected_crop.upper()} ===")
        for i, (d_name, d_prob) in enumerate(disease_probs_sorted[:5]):
            mapped_d_name = class_map.get(d_name, d_name)
            logger.info(f"  {i+1}. {mapped_d_name}: {d_prob * 100:.2f}%")

        severity = _get_severity(detected_crop, disease_name)

        result = {
            "crop":               detected_crop,
            "crop_confidence":    crop_confidence,
            "crop_margin":        crop_margin,        # top1 - top2 margin in %
            "crop_entropy_bits": crop_entropy_bits,  # softmax entropy for OOD logging
            "disease":            disease_name,
            "disease_confidence": disease_confidence,
            "severity":           severity,
            "model_version":      MODEL_VERSION,
            "prediction_time_ms": int((time.time() - start) * 1000),
        }
        return result

    except Exception as e:
        logger.error(f"TensorFlow inference error: {e}")
        return None
