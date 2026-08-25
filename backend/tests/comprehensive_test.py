import os
import sys
import tensorflow as tf
from pathlib import Path
from PIL import Image
import numpy as np

# Suppress TF logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

BASE_DL = Path(r'C:\Users\gopal\Downloads\Leaf Disease Prediction (DL)')
sub_models_dir = Path(r'c:\Users\gopal\OneDrive\Desktop\trail 2\backend\model\sub_models')

print("=" * 60)
print("COMPREHENSIVE TEST OF ALL 10 CROPS & MODELS")
print("=" * 60)

crop_classifier = tf.keras.models.load_model(str(sub_models_dir / 'crop_classifier.keras'), compile=False)
crops = ["Blackgram", "Cotton", "Eggplant", "Groundnut", "Paddy", "Sugarcane", "Sunflower", "Tomato", "Turmeric", "Wheat"]

disease_configs = {
    "Blackgram": {"file": "blackgram.keras", "size": 224, "classes": ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"], "folder": BASE_DL / "Blackgram"},
    "Cotton": {"file": "cotton.keras", "size": 224, "classes": ["Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"], "folder": BASE_DL / "cotton"},
    "Eggplant": {"file": "eggplant.keras", "size": 224, "classes": ["Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"], "folder": BASE_DL / "eggplant"},
    "Groundnut": {"file": "groundnut.keras", "size": 150, "classes": ["early_leaf_spot_1", "early_rust_1", "healthy_leaf_1", "late_leaf_spot_1", "nutrition_deficiency_1", "rust_1"], "folder": BASE_DL / "groundnut"},
    "Paddy": {"file": "paddy.keras", "size": 224, "classes": ["Brown Spot", "Healthy", "Leaf Blast", "Leaf Blight", "Leaf Scald", "Sheath Blight"], "folder": BASE_DL / "rice"},
    "Sugarcane": {"file": "sugarcane.keras", "size": 224, "classes": ["Healthy", "Red Rot", "Red Rust"], "folder": BASE_DL / "sugarcane"},
    "Sunflower": {"file": "sunflower.keras", "size": 224, "classes": ["alternaria sunflower", "downy mildew sunflower", "healthy sunflower", "healthy wheat", "mosaic wheat", "powdery mildew sunflower", "powdery mildew wheat", "rhizopus sunflower", "rust sunflower", "rust wheat", "sclerotinia sunflower", "septoria wheat", "smuts wheat"], "folder": BASE_DL / "sunflower"},
    "Tomato": {"file": "tomato.keras", "size": 150, "classes": ["Bacterial Spot", "Early Blight", "Healthy", "Late Blight", "Leaf Mold", "Mosaic Virus", "Septoria Leaf Spot", "Spider Mites", "Target Spot", "Yellow Leaf Curl Virus"], "folder": BASE_DL / "tomato"},
    "Turmeric": {"file": "turmeric.keras", "size": 224, "classes": ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"], "folder": BASE_DL / "Turmeric"},
    "Wheat": {"file": "wheat.keras", "size": 224, "classes": ["Crown Root Rot", "Healthy", "Leaf Rust", "Loose Smut"], "folder": BASE_DL / "wheat"},
}

for crop_name in crops:
    cfg = disease_configs[crop_name]
    folder = cfg["folder"]
    img_files = list(folder.rglob("*.jpg")) + list(folder.rglob("*.png")) + list(folder.rglob("*.jpeg")) + list(folder.rglob("*.JPG"))
    
    if not img_files:
        print(f"[{crop_name}] NO IMAGES FOUND in {folder}")
        continue
    
    # Test up to 3 random sample images
    np.random.seed(42)
    selected = [img_files[i] for i in np.random.choice(len(img_files), min(3, len(img_files)), replace=False)]
    
    d_model = tf.keras.models.load_model(str(sub_models_dir / cfg["file"]), compile=False)
    
    print(f"\n[{crop_name.upper()}] Testing {len(selected)} samples:")
    for img_p in selected:
        img = Image.open(img_p).convert("RGB")
        
        # Stage 1: Crop Classifier (expects [0, 255] float32 because it has built-in mobilenet_v2 preprocess_input)
        img_crop = img.resize((224, 224), Image.LANCZOS)
        arr_crop_255 = np.expand_dims(np.array(img_crop, dtype=np.float32), 0)
        crop_preds = crop_classifier.predict(arr_crop_255, verbose=0)[0]
        pred_crop_idx = int(np.argmax(crop_preds))
        pred_crop = crops[pred_crop_idx]
        crop_conf = float(crop_preds[pred_crop_idx]) * 100
        
        # Stage 2: Disease Model
        d_size = cfg["size"]
        img_d = img.resize((d_size, d_size), Image.LANCZOS)
        arr_d_1 = np.expand_dims(np.array(img_d, dtype=np.float32) / 255.0, 0)
        d_preds = d_model.predict(arr_d_1, verbose=0)[0]
        pred_d_idx = int(np.argmax(d_preds))
        pred_d = cfg["classes"][pred_d_idx]
        d_conf = float(d_preds[pred_d_idx]) * 100
        
        print(f"  Img: {img_p.parent.name}/{img_p.name[:25]} -> Pred Crop: {pred_crop} ({crop_conf:.1f}%) | Disease: {pred_d} ({d_conf:.1f}%)")
