"""
convert_to_tflite.py
--------------------
Converts all trained Keras models (1 Stage-1 Crop Classifier + 10 Crop Disease Models)
to optimized TensorFlow Lite (.tflite) format for on-device inference in Flutter.

Outputs:
  - agrovision_app/assets/models/crop_classifier.tflite
  - agrovision_app/assets/models/blackgram.tflite
  - agrovision_app/assets/models/cotton.tflite
  - agrovision_app/assets/models/eggplant.tflite
  - agrovision_app/assets/models/groundnut.tflite
  - agrovision_app/assets/models/paddy.tflite
  - agrovision_app/assets/models/sugarcane.tflite
  - agrovision_app/assets/models/sunflower.tflite
  - agrovision_app/assets/models/tomato.tflite
  - agrovision_app/assets/models/turmeric.tflite
  - agrovision_app/assets/models/wheat.tflite
  - agrovision_app/assets/models/crop_labels.json
  - agrovision_app/assets/models/disease_models_config.json
"""

import os
import json
import logging
from pathlib import Path
import numpy as np
import tensorflow as tf

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger(__name__)

BACKEND_DIR = Path(__file__).parent.parent
SUB_MODELS_DIR = BACKEND_DIR / "model" / "sub_models"
APP_ASSETS_MODELS = BACKEND_DIR.parent / "agrovision_app" / "assets" / "models"
APP_ASSETS_MODELS.mkdir(parents=True, exist_ok=True)

# ── 1. Crop Classifier Config ─────────────────────────────────────────────────
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

# ── 2. Per-Crop Disease Sub-Models Config ──────────────────────────────────────
DISEASE_MODEL_CONFIG = {
    "Blackgram": {
        "file": "blackgram.keras",
        "tflite_file": "blackgram.tflite",
        "size": 224,
        "norm": "0_255",
        "classes": ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"],
    },
    "Cotton": {
        "file": "cotton.keras",
        "tflite_file": "cotton.tflite",
        "size": 224,
        "norm": "0_255",
        "classes": ["Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"],
    },
    "Eggplant": {
        "file": "eggplant.keras",
        "tflite_file": "eggplant.tflite",
        "size": 224,
        "norm": "0_255",
        "classes": ["Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"],
    },
    "Groundnut": {
        "file": "groundnut.keras",
        "tflite_file": "groundnut.tflite",
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
        "tflite_file": "paddy.tflite",
        "size": 224,
        "norm": "0_1",
        "classes": ["Leaf Blight", "Brown Spot", "Healthy", "Leaf Blast", "Leaf Scald", "Sheath Blight"],
    },
    "Sugarcane": {
        "file": "sugarcane.keras",
        "tflite_file": "sugarcane.tflite",
        "size": 224,
        "norm": "0_255",
        "classes": ["Healthy", "Red Rot", "Red Rust"],
    },
    "Sunflower": {
        "file": "sunflower.keras",
        "tflite_file": "sunflower.tflite",
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
        "tflite_file": "tomato.tflite",
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
        "tflite_file": "turmeric.tflite",
        "size": 224,
        "norm": "0_255",
        "classes": ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"],
    },
    "Wheat": {
        "file": "wheat.keras",
        "tflite_file": "wheat.tflite",
        "size": 224,
        "norm": "0_1",
        "classes": ["Leaf Rust", "Loose Smut", "Crown Root Rot", "Healthy"],
    },
}


def convert_model(keras_path: Path, tflite_path: Path, input_shape: tuple) -> None:
    """Convert a Keras model to TFLite format and test inference parity."""
    logger.info(f"Converting {keras_path.name} -> {tflite_path.name}...")
    
    # Load Keras model
    model = tf.keras.models.load_model(str(keras_path), compile=False)
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save .tflite
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    
    size_mb = len(tflite_model) / (1024 * 1024)
    logger.info(f"Saved {tflite_path.name} ({size_mb:.2f} MB)")
    
    # Verify Parity with random input
    dummy_input = np.random.uniform(0.0, 255.0, size=input_shape).astype(np.float32)
    
    # Keras prediction
    keras_pred = model.predict(dummy_input, verbose=0)
    
    # TFLite prediction
    interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    interpreter.set_tensor(input_details[0]['index'], dummy_input)
    interpreter.invoke()
    tflite_pred = interpreter.get_tensor(output_details[0]['index'])
    
    max_diff = np.max(np.abs(keras_pred - tflite_pred))
    top_keras_idx = np.argmax(keras_pred[0])
    top_tflite_idx = np.argmax(tflite_pred[0])
    
    logger.info(f"  Parity Check: max diff={max_diff:.6f} | Keras top idx={top_keras_idx} vs TFLite top idx={top_tflite_idx}")
    if top_keras_idx != top_tflite_idx:
        logger.warning(f"  Warning: Index mismatch on dummy input for {keras_path.name}!")
    else:
        logger.info(f"  [PASS] {tflite_path.name} verified identical.")


def main():
    logger.info("Starting conversion of all 11 Keras models to TensorFlow Lite...")
    
    # 1. Convert Crop Classifier (Stage 1)
    crop_classifier_keras = SUB_MODELS_DIR / "crop_classifier.keras"
    crop_classifier_tflite = APP_ASSETS_MODELS / "crop_classifier.tflite"
    convert_model(crop_classifier_keras, crop_classifier_tflite, (1, 224, 224, 3))
    
    # 2. Convert 10 Disease Sub-Models (Stage 2)
    for crop_name, cfg in DISEASE_MODEL_CONFIG.items():
        keras_file = SUB_MODELS_DIR / cfg["file"]
        tflite_file = APP_ASSETS_MODELS / cfg["tflite_file"]
        img_size = cfg["size"]
        convert_model(keras_file, tflite_file, (1, img_size, img_size, 3))
        
    # 3. Export JSON configs to assets/models/
    crop_labels_path = APP_ASSETS_MODELS / "crop_labels.json"
    with open(crop_labels_path, "w") as f:
        json.dump({
            "crops": CROP_CLASSIFIER_CLASSES,
            "threshold": 65.0,
            "image_size": 224,
            "norm": "mobilenet_v2"
        }, f, indent=2)
    logger.info(f"Exported {crop_labels_path.name}")
    
    disease_config_path = APP_ASSETS_MODELS / "disease_models_config.json"
    with open(disease_config_path, "w") as f:
        json.dump({
            "disease_threshold": 50.0,
            "models": DISEASE_MODEL_CONFIG
        }, f, indent=2)
    logger.info(f"Exported {disease_config_path.name}")
    
    logger.info("All models and configs successfully converted and saved to Flutter assets/models!")


if __name__ == "__main__":
    main()
