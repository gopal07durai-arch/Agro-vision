"""
crop_config.py
--------------
Centralized Configuration for AgroVision AI Model Pipeline.

Defines:
  - SUPPORTED_CROPS: Verified list of supported crop names.
  - CROP_MODEL_CONFIG: Centralized specification per crop.
  - MODEL_SETTINGS: Global settings for image dimensions, color space, and normalization.
"""

from typing import Dict, List, Any

# Global Model Architecture & Preprocessing Parameters
MODEL_SETTINGS = {
    "image_size": 224,           # 224 x 224 input
    "color_mode": "RGB",         # Red, Green, Blue
    "normalization": "0_to_1",   # / 255.0 float32
    "num_total_classes": 57,
}

SUPPORTED_CROPS: List[str] = [
    "Blackgram",
    "Cotton",
    "Eggplant",
    "Groundnut",
    "Paddy",
    "Sugarcane",
    "Sunflower",
    "Tomato",
    "Turmeric",
    "Wheat",
]

CROP_MODEL_CONFIG: Dict[str, Dict[str, Any]] = {
    "Blackgram": {
        "displayName": "Blackgram",
        "aliases": ["blackgram", "urad", "minumulu", "uzhunnu"],
        "class_indices": [0, 1, 2, 3, 4],
        "diseases": ["Anthracnose", "Healthy", "Leaf Crinkle", "Powdery Mildew", "Yellow Mosaic"],
    },
    "Cotton": {
        "displayName": "Cotton",
        "aliases": ["cotton", "kapas", "patti"],
        "class_indices": [5, 6, 7, 8, 9, 10],
        "diseases": ["Aphids", "Army Worm", "Bacterial Blight", "Healthy", "Powdery Mildew", "Target Spot"],
    },
    "Eggplant": {
        "displayName": "Eggplant (Brinjal)",
        "aliases": ["eggplant", "brinjal", "baingan", "vankaya", "kathirikai"],
        "class_indices": [11, 12, 13, 14, 15, 16, 17],
        "diseases": ["Healthy", "Insect Pest", "Leaf Spot", "Mosaic Virus", "Small Leaf", "White Mold", "Wilt Disease"],
    },
    "Groundnut": {
        "displayName": "Groundnut",
        "aliases": ["groundnut", "peanut", "moongphali", "verukadalai"],
        "class_indices": [18, 19, 20, 21, 22],
        "diseases": ["Healthy", "Late Leaf Spot", "Leaf Spot", "Nutrition Deficiency", "Rust"],
        # Note: "Nutrition Deficiency" maps from "nutrition_deficiency_1" in the sub-model class list.
    },
    "Paddy": {
        "displayName": "Paddy (Rice)",
        "aliases": ["paddy", "rice", "chawal", "dhan", "arisi"],
        "class_indices": [23, 24, 25, 26, 27, 28],
        "diseases": ["Brown Spot", "Healthy", "Leaf Blast", "Leaf Blight", "Leaf Scald", "Sheath Blight"],
    },
    "Sugarcane": {
        "displayName": "Sugarcane",
        "aliases": ["sugarcane", "ganna", "karumbu"],
        "class_indices": [29, 30, 31],
        "diseases": ["Healthy", "Red Rot", "Red Rust"],
    },
    "Sunflower": {
        "displayName": "Sunflower",
        "aliases": ["sunflower", "surajmukhi"],
        "class_indices": [32, 33, 34, 35, 36, 37, 38],
        "diseases": ["Alternaria Leaf Spot", "Downy Mildew", "Healthy", "Powdery Mildew", "Rhizopus Head Rot", "Rust", "Sclerotinia"],
    },
    "Tomato": {
        "displayName": "Tomato",
        "aliases": ["tomato", "tamatar", "thakkali"],
        "class_indices": [39, 40, 41, 42, 43, 44, 45, 46, 47, 48],
        "diseases": ["Bacterial Spot", "Early Blight", "Healthy", "Late Blight", "Leaf Mold", "Mosaic Virus", "Septoria Leaf Spot", "Spider Mites", "Target Spot", "Yellow Leaf Curl Virus"],
    },
    "Turmeric": {
        "displayName": "Turmeric",
        "aliases": ["turmeric", "haldi", "manjal"],
        "class_indices": [49, 50, 51, 52],
        "diseases": ["Dry Leaf", "Healthy", "Leaf Blotch", "Rhizome Disease"],
    },
    "Wheat": {
        "displayName": "Wheat",
        "aliases": ["wheat", "gehun", "gothumai"],
        "class_indices": [53, 54, 55, 56],
        "diseases": ["Crown Root Rot", "Healthy", "Leaf Rust", "Loose Smut"],
    },
}
