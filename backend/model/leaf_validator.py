"""
leaf_validator.py
-----------------
Robust Image Quality Assessment and Out-of-Distribution (OOD) Validation Pipeline.

Multi-Stage Validation Pipeline:
  Stage 1: Minimum Dimensions & Resolution Check (>= 60x60)
  Stage 2: Brightness & Blur Assessment (Laplacian variance, luminosity extremes)
  Stage 3: ImageNet Out-of-Distribution (OOD) Classifier via MobileNetV2
           (Detects vehicles, buildings, technology, animals, furniture, human apparel, etc.)
  Stage 4: Chlorophyll & Plant Tissue vs Human Skin / Grey-Surface Color Space Analysis
           (Evaluates green foliage dominance, diseased yellow/brown tissue, YCbCr human skin, low-saturation asphalt/metal)
  Stage 5: Color Diversity / Shannon Entropy Guard
           (Posters and documents have highly diverse color histograms; crop leaves have concentrated hue ranges)

Error Types:
  - LOW_IMAGE_QUALITY: resolution < 60x60, pitch dark, overexposed, blurry
  - NOT_LEAF: human, face, hand, vehicle, road, building, animal, laptop, furniture,
              poster, document, screenshot, random object, non-leaf image
"""

import logging
from typing import Tuple, Optional
from PIL import Image
import numpy as np
import cv2

logger = logging.getLogger(__name__)

# Global MobileNetV2 for ImageNet OOD classification
_ood_model = None
_decode_predictions = None

# Comprehensive Non-Plant ImageNet Class Keywords
_NON_PLANT_KEYWORDS = {
    # People & Anatomy
    'person', 'man', 'woman', 'child', 'boy', 'girl', 'groom', 'bride', 'face',
    'suit', 'jersey', 't-shirt', 'jean', 'shoe', 'sunglasses', 'hat', 'coat',
    'dress', 'mask', 'wig', 'sock', 'glove', 'brassiere', 'bikini', 'swimming_trunks',

    # Vehicles & Transportation
    'sports_car', 'van', 'truck', 'motorcycle', 'bicycle', 'bus', 'train', 'airplane',
    'airliner', 'warplane', 'helicopter', 'speedboat', 'canoe', 'sailboat', 'tank',
    'trailer', 'limousine', 'jeep', 'minivan', 'cab', 'taxi', 'convertible', 'racer',
    'scooter', 'moped', 'forklift', 'golfcart', 'snowmobile', 'tow_truck', 'fire_engine',

    # Architecture & Infrastructure
    'building', 'house', 'palace', 'monument', 'castle', 'church', 'bridge',
    'pier', 'dock', 'dam', 'beacon', 'lighthouse', 'traffic_light', 'street_sign',
    'tile_roof', 'cinema', 'restaurant', 'bakery', 'barbershop', 'bookshop', 'butcher_shop',
    'cliff_dwelling', 'patio', 'swimming_pool', 'fountain', 'tombstone',

    # Electronics & Office
    'laptop', 'desktop_computer', 'monitor', 'keyboard', 'cellular_telephone',
    'mouse', 'printer', 'screen', 'television', 'ipod', 'radio', 'speaker',
    'cassette', 'cd_player', 'modem', 'hard_disc', 'joystick', 'remote_control',
    'camera', 'digital_clock', 'analog_clock', 'stopwatch', 'calculator',

    # Household, Furniture & Tools
    'chair', 'table', 'desk', 'sofa', 'bed', 'lamp', 'coffee_mug', 'cup', 'water_bottle',
    'wine_bottle', 'beer_bottle', 'plate', 'bowl', 'fork', 'spoon', 'knife', 'pot',
    'pan', 'frying_pan', 'refrigerator', 'microwave', 'toaster', 'oven', 'dishwasher',
    'vacuum', 'iron', 'hammer', 'screwdriver', 'wrench', 'scissors', 'bucket', 'barrel',
    'box', 'crate', 'pillow', 'quilt', 'doormat', 'washbasin', 'toilet_seat', 'bathtub',

    # Animals
    'golden_retriever', 'persian_cat', 'tiger', 'lion', 'elephant', 'dog', 'cat',
    'bird', 'parrot', 'eagle', 'owl', 'snake', 'lizard', 'frog', 'horse', 'cow',
    'sheep', 'pig', 'goat', 'bear', 'wolf', 'fox', 'monkey', 'rabbit', 'hamster',
    'fish', 'shark', 'whale', 'dolphin', 'spider', 'bee', 'wasp', 'fly', 'cockroach',

    # Processed Food & Goods
    'pizza', 'hamburger', 'cheeseburger', 'hotdog', 'sandwich', 'ice_cream',
    'bagel', 'pretzel', 'loaf', 'bread', 'cake', 'cookie', 'french_fries', 'burrito'
}


def _get_ood_model():
    """Lazily load MobileNetV2 with ImageNet weights for OOD non-plant classification."""
    global _ood_model, _decode_predictions
    if _ood_model is None:
        try:
            import tensorflow as tf
            _ood_model = tf.keras.applications.MobileNetV2(weights='imagenet', include_top=True)
            _decode_predictions = tf.keras.applications.mobilenet_v2.decode_predictions
            logger.info("ImageNet OOD validation model (MobileNetV2) loaded successfully.")
        except Exception as e:
            logger.warning(f"Failed to load MobileNetV2 OOD model: {e}")
            _ood_model = None
    return _ood_model, _decode_predictions


def warmup_leaf_validator():
    """Warm up the OOD validation model graph."""
    try:
        model, _ = _get_ood_model()
        if model is not None:
            import tensorflow as tf
            dummy = np.zeros((1, 224, 224, 3), dtype=np.float32)
            dummy = tf.keras.applications.mobilenet_v2.preprocess_input(dummy)
            model.predict(dummy, verbose=0)
            logger.info("Leaf validator OOD model warmed up successfully.")
    except Exception as e:
        logger.warning(f"Leaf validator warmup warning: {e}")


def _check_plant_tissue_metrics(img_bgr: np.ndarray) -> dict:
    """
    Analyze pixel distribution to compute:
      - green_ratio: Strictly green-dominant plant foliage pixels (G > R and G > B)
      - diseased_ratio: Yellow/brown diseased plant tissue (excluding human skin)
      - skin_ratio: Human skin tone pixels (YCbCr color space)
      - low_sat_ratio: Neutral grey / asphalt / road / concrete / metal / paper pixels
      - non_plant_color_ratio: Artificial non-botanical colors (Blue, Cyan, Magenta, Purple)
      - total_plant_ratio: Total valid plant tissue area (green + coupled diseased tissue)
    """
    total_pixels = float(img_bgr.shape[0] * img_bgr.shape[1])
    b, g, r = cv2.split(img_bgr.astype(np.float32))

    # 1. Strictly Green-Dominant Plant Foliage (G must exceed both R and B with minimal brightness)
    green_dominant = (g > r * 1.04) & (g > b * 1.04) & (g >= 28.0)
    green_ratio = float(np.sum(green_dominant)) / total_pixels

    # 2. Human Skin Detection in YCbCr color space (Cr in [133, 173], Cb in [77, 127])
    ycrcb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2YCrCb)
    skin_mask = cv2.inRange(
        ycrcb,
        np.array([0, 133, 77], dtype=np.uint8),
        np.array([255, 173, 127], dtype=np.uint8)
    )
    skin_ratio = float(np.sum(skin_mask > 0)) / total_pixels

    # 3. Yellow/Brown Diseased Plant Tissue (Hue in [10, 26], Saturation in [35, 255], Value in [30, 245])
    # Exclude any pixels that match human skin tones
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    diseased_raw = cv2.inRange(
        hsv,
        np.array([10, 35, 30], dtype=np.uint8),
        np.array([26, 255, 245], dtype=np.uint8)
    )
    diseased_mask = cv2.bitwise_and(diseased_raw, cv2.bitwise_not(skin_mask))
    diseased_ratio = float(np.sum(diseased_mask > 0)) / total_pixels

    # 4. Low-Saturation Grey / Asphalt / Road / Metal / Paper pixels (Saturation < 22)
    low_sat_mask = (hsv[:, :, 1] < 22).astype(np.uint8) * 255
    low_sat_ratio = float(np.sum(low_sat_mask > 0)) / total_pixels

    # 5. Non-Botanical Colors (Blue, Cyan, Magenta, Purple: Hue 80-170 with Sat > 40 and Val > 30)
    non_plant_colors_mask = (
        (hsv[:, :, 0] >= 80) & (hsv[:, :, 0] <= 170) &
        (hsv[:, :, 1] > 40) & (hsv[:, :, 2] > 30)
    ).astype(np.uint8) * 255
    non_plant_color_ratio = float(np.sum(non_plant_colors_mask > 0)) / total_pixels

    # 6. Total combined plant tissue
    # Note: Diseased yellow/brown is ONLY credited toward plant tissue if some green leaf foliage is present (>= 4%)
    if green_ratio >= 0.04:
        plant_mask = green_dominant | (diseased_mask > 0)
        total_plant_ratio = float(np.sum(plant_mask)) / total_pixels
    else:
        # Without green foliage, isolated yellow/orange regions are synthetic/cardboard/posters
        total_plant_ratio = green_ratio

    return {
        "green_ratio": green_ratio,
        "diseased_ratio": diseased_ratio,
        "skin_ratio": skin_ratio,
        "low_sat_ratio": low_sat_ratio,
        "non_plant_color_ratio": non_plant_color_ratio,
        "total_plant_ratio": total_plant_ratio,
    }


def _check_imagenet_ood(pil_image: Image.Image) -> Tuple[bool, Optional[str]]:
    """
    Run MobileNetV2 ImageNet classifier to check if top predictions represent non-plant subjects with high confidence.
    Returns (is_non_plant: bool, detected_class_name: str | None).
    """
    model, decode_fn = _get_ood_model()
    if model is None or decode_fn is None:
        return False, None

    try:
        import tensorflow as tf
        resized = pil_image.convert('RGB').resize((224, 224), Image.LANCZOS)
        arr = np.array(resized, dtype=np.float32)
        arr = tf.keras.applications.mobilenet_v2.preprocess_input(arr)
        arr = np.expand_dims(arr, axis=0)

        preds = model.predict(arr, verbose=0)
        decoded = decode_fn(preds, top=5)[0]  # [(class_id, class_name, prob), ...]

        for _, class_name, prob in decoded[:3]:
            name_lower = class_name.lower().replace('_', ' ')
            if any(kw in name_lower for kw in _NON_PLANT_KEYWORDS) and prob > 0.35:
                logger.info(f"[OOD Filter] Rejected by MobileNetV2: {class_name} (prob: {prob:.2f})")
                return True, class_name.replace('_', ' ').title()

    except Exception as e:
        logger.warning(f"OOD check error: {e}")

    return False, None


def validate_image_for_prediction(pil_image: Image.Image) -> Tuple[bool, Optional[str], Optional[str]]:
    """
    Comprehensive multi-stage validation function executed before crop/disease inference.

    Returns:
        (is_valid: bool, error_type: str | None, message: str | None)

    Error Types:
        - LOW_IMAGE_QUALITY: resolution < 60x60, pitch dark, overexposed, blurry
        - NOT_LEAF: human, face, hand, vehicle, road, building, animal, laptop, furniture, poster, document, screenshot
    """
    # ── Stage 1: Resolution & Dimensions ──────────────────────────────────────
    w, h = pil_image.size
    if w < 60 or h < 60:
        return False, "LOW_IMAGE_QUALITY", "Image resolution is too low. Please upload a clearer photo."

    # Convert PIL Image to OpenCV BGR numpy array
    img_rgb = np.array(pil_image.convert('RGB'))
    img_bgr = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)

    # ── Stage 2: Image Quality Checks (Brightness & Blur) ─────────────────────
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

    avg_brightness = float(np.mean(gray))
    if avg_brightness < 8.0:
        return False, "LOW_IMAGE_QUALITY", "The image is too dark. Please upload a photo taken under bright natural lighting."
    if avg_brightness > 253.0:
        return False, "LOW_IMAGE_QUALITY", "The image is overexposed/blank. Please capture a clear leaf image."

    lap_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if lap_var < 3.0:
        logger.info(f"[Quality Filter] Rejected for blur: Laplacian var = {lap_var:.2f}")
        return False, "LOW_IMAGE_QUALITY", "The photo is too blurry for diagnosis. Please hold your camera steady and capture a sharp image."

    # ── Stage 3: Plant Tissue vs Human Skin vs Non-Plant Grey/Road Surface ───
    metrics = _check_plant_tissue_metrics(img_bgr)
    green_r = metrics["green_ratio"]
    skin_r  = metrics["skin_ratio"]
    lowsat_r = metrics["low_sat_ratio"]
    non_plant_r = metrics["non_plant_color_ratio"]
    plant_r = metrics["total_plant_ratio"]

    # Rule 3a: Non-botanical artificial colors (Blue, Cyan, Magenta, Purple posters/vehicles/screens)
    if non_plant_r > 0.05 and green_r < 0.35:
        logger.info(f"[Validation Filter] Rejected as artificial/poster/vehicle: non_plant_color_ratio={non_plant_r:.3f}, green_ratio={green_r:.3f}")
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf, not a poster, vehicle, or artificial object."

    # Rule 3b: Human skin / hand / person dominance
    if skin_r > 0.10 and green_r < 0.15:
        logger.info(f"[Validation Filter] Rejected as human skin/person: skin_ratio={skin_r:.2f}, green_ratio={green_r:.2f}")
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf, not a person or object."

    # Rule 3c: Asphalt / Road / Concrete / Neutral Grey / Paper Document dominance
    if lowsat_r > 0.55 and green_r < 0.10:
        logger.info(f"[Validation Filter] Rejected as neutral/road/grey/document: low_sat_ratio={lowsat_r:.2f}, green_ratio={green_r:.2f}")
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf, not a road, wall, or document."

    # Rule 3d: Minimum green plant tissue requirement
    if green_r < 0.04:
        logger.info(f"[Validation Filter] Rejected: Insufficient green plant tissue = {green_r:.3f} < 0.04")
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf."

    # Rule 3e: Minimum total plant tissue area requirement (at least 12% total plant coverage)
    if plant_r < 0.12:
        logger.info(f"[Validation Filter] Rejected: Total plant tissue ratio = {plant_r:.3f} < 0.12")
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf."

    # ── Stage 4: Color Diversity / Shannon Entropy Guard ─────────────────────
    entropy, hue_peak_ratio = _compute_hue_entropy(img_bgr)
    if entropy > 2.8 and green_r < 0.25:
        logger.info(
            f"[Entropy Filter] Rejected: hue_entropy={entropy:.2f}, green_ratio={green_r:.3f} — likely poster/document/screenshot."
        )
        return False, "NOT_LEAF", "Please upload a clear image of a supported crop leaf, not a poster, document, or screenshot."

    # ── Stage 5: MobileNetV2 ImageNet Classifier Check ───────────────────────
    # Only run OOD classifier if plant dominance is moderate (< 55%) to catch green non-plant items
    if green_r < 0.55:
        is_non_plant, detected_class = _check_imagenet_ood(pil_image)
        if is_non_plant:
            return False, "NOT_LEAF", f"Please upload a clear image of a supported crop leaf, not a {detected_class.lower()}."

    # All validation stages successfully passed!
    return True, None, None


def _compute_hue_entropy(img_bgr: np.ndarray) -> tuple[float, float]:
    """
    Compute Shannon entropy of the hue histogram and the ratio of peak-hue pixels.
    Crop leaves are dominated by green/yellow-brown hues → low entropy.
    Posters, documents, screenshots have many diverse hues → high entropy.

    Returns:
        (entropy_bits: float, hue_peak_ratio: float)
    """
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)
    hue_channel = hsv[:, :, 0]          # 0–179 in OpenCV
    sat_channel = hsv[:, :, 1]          # 0–255

    # Only analyse pixels with meaningful saturation (not near-grey / background)
    mask = sat_channel > 25
    hue_values = hue_channel[mask]

    if hue_values.size < 500:           # Too few coloured pixels → probably grey/dark image
        return 0.0, 1.0

    # Compute histogram with 36 bins (each bin = 5° of hue)
    hist, _ = np.histogram(hue_values, bins=36, range=(0, 180))
    hist = hist.astype(np.float64)
    hist /= hist.sum() + 1e-8

    # Shannon entropy
    nonzero = hist[hist > 0]
    entropy = float(-np.sum(nonzero * np.log2(nonzero)))

    # Peak-hue dominance: fraction of coloured pixels in the largest bin
    hue_peak_ratio = float(hist.max())

    return entropy, hue_peak_ratio


def compute_image_color_entropy(pil_image: Image.Image) -> float:
    """
    Public wrapper — returns hue Shannon entropy (bits) for use by the predict pipeline.
    Higher entropy = more diverse colours = more likely a poster/document/non-leaf.
    """
    img_rgb = np.array(pil_image.convert('RGB'))
    img_bgr = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)
    entropy, _ = _compute_hue_entropy(img_bgr)
    return entropy
