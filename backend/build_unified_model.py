"""
build_unified_model.py
-----------------------
Builds a unified 56-class model from individual per-crop Keras models.

Strategy (Ensemble Router):
  Each sub-model predicts probabilities for its own crop's classes.
  We scatter those outputs into a 56-dim global vector (by labels.json index),
  then apply a final Softmax to get a proper probability distribution.

  Missing crops (Blackgram, Sugarcane, Turmeric) get zero-logit branches.

Output:
  backend/model/model.keras  — ready to use by the FastAPI backend.

Usage:
  cd "trail 2/backend"
  python build_unified_model.py
"""

import json
import numpy as np
from pathlib import Path

# ─── Paths ────────────────────────────────────────────────────────────────────
BASE_DL = Path(r"C:\Users\gopal\Downloads\Leaf Disease Prediction (DL)")
BACKEND  = Path(__file__).parent
LABELS   = BACKEND / "model" / "labels.json"
OUT      = BACKEND / "model" / "model.keras"

IMAGE_SIZE = 224

# ─── Crop → individual model file + class order ────────────────────────────────
# Disease names MUST be in the same order as that model's output indices.
CROP_MODELS = {
    "Cotton": {
        "path": BASE_DL / "cotton" / "cotton_disease.keras",
        "classes": ["Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"],
    },
    "Eggplant": {
        "path": BASE_DL / "eggplant" / "eggplant_mobilenet.keras",
        "classes": ["Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"],
    },
    "Groundnut": {
        "path": BASE_DL / "groundnut" / "groundnut_disease_prediction.keras",
        "classes": ["Healthy", "Late Leaf Spot", "Leaf Spot", "Rust"],
    },
    "Paddy": {
        "path": BASE_DL / "rice" / "paddy_mobilenet.keras",
        "classes": ["Brown Spot", "Healthy", "Leaf Blast", "Leaf Blight", "Leaf Scald", "Sheath Blight"],
    },
    "Sunflower": {
        "path": BASE_DL / "sunflower" / "sunflower_wheat_mobilenet.keras",
        "classes": ["Alternaria Leaf Spot", "Downy Mildew", "Healthy", "Powdery Mildew",
                    "Rhizopus Head Rot", "Rust", "Sclerotinia"],
    },
    "Tomato": {
        "path": BASE_DL / "tomato" / "tomato_cnn_model.keras",
        "classes": ["Bacterial Spot", "Early Blight", "Healthy", "Late Blight", "Leaf Mold",
                    "Mosaic Virus", "Septoria Leaf Spot", "Spider Mites", "Target Spot",
                    "Yellow Leaf Curl Virus"],
    },
    "Wheat": {
        "path": BASE_DL / "wheat" / "wheat_cnn_model.keras",
        "classes": ["Crown Root Rot", "Healthy", "Leaf Rust", "Loose Smut"],
    },
}

# Crops without individual models — zero-logit branches
MISSING_CROPS = {
    "Blackgram":  ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"],
    "Sugarcane":  ["Healthy", "Red Rot", "Red Rust"],
    "Turmeric":   ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"],
}


def load_labels():
    with open(LABELS) as f:
        return json.load(f)["classes"]


def build_reorder_map(crop_name, model_classes, all_labels):
    pairs = []
    for entry in all_labels:
        if entry["crop"] != crop_name:
            continue
        disease = entry["disease"]
        global_idx = entry["index"]
        if disease in model_classes:
            local_idx = model_classes.index(disease)
            pairs.append((local_idx, global_idx))
        else:
            print(f"  WARNING: '{disease}' not in model classes for {crop_name}")
    return pairs


def make_layers_unique(model, prefix: str):
    try:
        model._name = f"{prefix}_model"
    except Exception:
        pass
    for layer in getattr(model, "layers", []):
        try:
            layer._name = f"{prefix}_{layer.name}"
        except Exception:
            pass
        if hasattr(layer, "layers"):
            make_layers_unique(layer, prefix)


def load_sub_model(crop_name: str, model_path: Path, num_classes: int):
    import tensorflow as tf
    import zipfile
    import tempfile
    import os

    path_str = str(model_path)
    c_lower = crop_name.lower()

    if "eggplant_mobilenet" in path_str or "paddy_mobilenet" in path_str:
        base_model = tf.keras.applications.MobileNetV2(
            input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3),
            include_top=False,
            weights=None,
            name=f"{c_lower}_base"
        )
        model = tf.keras.Sequential([
            tf.keras.layers.InputLayer(shape=(IMAGE_SIZE, IMAGE_SIZE, 3), name=f"{c_lower}_in"),
            base_model,
            tf.keras.layers.GlobalAveragePooling2D(name=f"{c_lower}_gap"),
            tf.keras.layers.Dense(256, activation="relu", name=f"{c_lower}_dense"),
            tf.keras.layers.Dropout(0.2, name=f"{c_lower}_dropout"),
            tf.keras.layers.Dense(num_classes, activation="softmax", name=f"{c_lower}_out")
        ], name=f"{c_lower}_submodel")

        with tempfile.TemporaryDirectory() as tmpdir:
            weights_path = os.path.join(tmpdir, "model.weights.h5")
            with zipfile.ZipFile(path_str, "r") as z:
                z.extract("model.weights.h5", tmpdir)
            model.load_weights(weights_path)
        make_layers_unique(model, c_lower)
        return model

    loaded = tf.keras.models.load_model(path_str, compile=False)
    make_layers_unique(loaded, c_lower)
    return loaded



def build_unified_model():
    import tensorflow as tf
    import zipfile
    import tempfile
    import os

    all_labels = load_labels()
    num_classes = len(all_labels)
    print(f"Building unified model for {num_classes} classes...\n")

    SUB_MODELS_DIR = BACKEND / "model" / "sub_models"
    SUB_MODELS_DIR.mkdir(parents=True, exist_ok=True)

    for crop_name, cfg in CROP_MODELS.items():
        model_path = cfg["path"]
        model_classes = cfg["classes"]
        c_lower = crop_name.lower()
        target_save = SUB_MODELS_DIR / f"{c_lower}.keras"
        print(f"[{crop_name}] Processing {model_path.name} -> {target_save.name}...")

        if not model_path.exists():
            print(f"  File not found at {model_path}! Skipping.")
            continue

        try:
            model = load_sub_model(crop_name, model_path, len(model_classes))
            model.save(str(target_save))
            print(f"  Successfully saved {target_save.name}")
        except Exception as e:
            print(f"  Failed to save {crop_name}: {e}")

    # Also touch/save backend/model/model.keras indicator file
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT, "w") as f:
        f.write(json.dumps({"status": "ready", "num_classes": num_classes, "sub_models": list(CROP_MODELS.keys())}, indent=2))

    print(f"\nSaved sub-models to: {SUB_MODELS_DIR}")
    print(f"Created model indicator file at: {OUT}")
    print("Done!")


if __name__ == "__main__":
    build_unified_model()



