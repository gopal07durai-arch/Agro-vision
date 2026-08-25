"""
predict.py
----------
FastAPI router: POST /api/v1/predict  |  GET /api/v1/recommendation

Standardized Request / Response Pipeline:
  Stage 0: Startup Readiness Check (503 if still loading models)
  Stage 1: Image File Integrity & MIME Validation
  Stage 2: Leaf / Non-Leaf & Out-of-Distribution Rejection (leaf_validator)
  Stage 3: Two-Stage Keras ML Pipeline (Crop Classifier -> Disease Classifier)
  Stage 4: Supported Crop & Margin Validation
  Stage 5: Confidence Threshold Verification (Crop >= 65%, Disease >= 50%)
  Stage 6: Enriched Recommendation Lookup

Error Types:
  - BACKEND_STARTING       (models not yet ready — retry in a few seconds)
  - INVALID_IMAGE          (unsupported file type, corrupted, > 10MB)
  - LOW_IMAGE_QUALITY      (blurry, dark, overexposed, resolution < 60x60)
  - NOT_LEAF               (road, person, face, hand, vehicle, building, animal, laptop, furniture, random object)
  - UNSUPPORTED_CROP       (unrecognized or unsupported crop)
  - LOW_CROP_CONFIDENCE    (crop confidence below 65% or ambiguous margin)
  - LOW_DISEASE_CONFIDENCE (disease confidence below 50%)
  - MODEL_UNAVAILABLE      (model files missing or unreadable)
  - SERVER_ERROR           (unexpected internal error)
"""

import io
import logging
import time
from fastapi import APIRouter, Request, UploadFile, File, Query
from fastapi.responses import JSONResponse
from PIL import Image

from model.leaf_validator import validate_image_for_prediction
from model.crop_config import CROP_MODEL_CONFIG, SUPPORTED_CROPS
from model.model_loader import (
    predict,
    is_model_loaded,
    CROP_CONFIDENCE_THRESHOLD,
    DISEASE_CONFIDENCE_THRESHOLD,
    _WHEAT_CONTAMINATED_CLASS,
)

logger = logging.getLogger(__name__)

router = APIRouter()


# ─── Enriched Recommendation Database ────────────────────────────────────────
#
# Key: "Crop|Disease" — strictly mapped to trained crop and disease class names.
#
# Fields:
#   problem_type         : "Pest" | "Disease" | "Nutrient Deficiency" | "Healthy"
#   product_name         : Exact commercial/generic product name
#   product_category     : "Insecticide"|"Fungicide"|"Bactericide"|"Biological Control"|
#                          "Organic Treatment"|"Fertilizer"|"Nutrient Supplement"|"Preventive Treatment"
#   active_ingredient    : Chemical or biological active ingredient
#   formulation          : e.g. "17.8 SL", "75 WP", "50 WP"
#   purpose              : One-line plain-language purpose
#   dosage               : Exact verified dosage value
#   dosage_unit          : "ml/L" | "g/L" | "kg/acre" | "g/kg seed" | etc.
#   application_method   : How to apply
#   application_timing   : When to apply
#   frequency            : How often
#   duration             : Total treatment duration / number of sprays
#   precautions          : Usage precautions (list joined as string)
#   safety_notes         : Protective equipment and safety info
#   harvest_waiting_period: Days before harvest (or null)
#   organic_alternative  : Organic/biological alternative product or method (or null)
#   prevention           : Crop/problem-specific prevention advice
#   source               : Verified source name
#   last_verified        : Verification date string
#   region               : Applicable region
#   fertilizer           : Optional separate fertilizer/nutrient section (or null)
#
# IMPORTANT: Never invent dosage. All values are sourced from verified agricultural
# guidelines (Tamil Nadu Agricultural University, ICAR, product label data).
# If a value is unknown, use null — never guess.

RECOMMENDATION_DB: dict[str, dict] = {

    # ═══════════════════════════════════════════════════════════════════════════
    # TOMATO
    # ═══════════════════════════════════════════════════════════════════════════

    "Tomato|Early Blight": {
        "problem_type": "Disease",
        "product_name": "Trichoderma viride",
        "product_category": "Biological Control",
        "active_ingredient": "Trichoderma viride (1×10⁸ CFU/g)",
        "formulation": "WP (Wettable Powder)",
        "purpose": "Biological control of Early Blight (Alternaria solani) by antagonistic action",
        "dosage": "2.5 kg/acre",
        "dosage_unit": "kg/acre",
        "application_method": "Dissolve in 200L water; drench soil around base of plant or foliar spray",
        "application_timing": "Apply at first symptom appearance or preventively at transplanting",
        "frequency": "Every 21 days during humid weather",
        "duration": "3 applications per season",
        "precautions": "Do not mix with chemical fungicides. Apply in cool part of the day.",
        "safety_notes": "Generally safe — wear gloves and mask. Wash hands after handling.",
        "harvest_waiting_period": None,
        "organic_alternative": "Neem oil 5ml/L foliar spray every 10 days",
        "prevention": "Maintain proper plant spacing. Remove infected leaves. Avoid overhead irrigation. Practice crop rotation.",
        "source": "Tamil Nadu Agricultural University (TNAU) Crop Protection Guide",
        "last_verified": "2024-01",
        "region": "South India",
        "fertilizer": None,
    },

    "Tomato|Late Blight": {
        "problem_type": "Disease",
        "product_name": "Pseudomonas fluorescens",
        "product_category": "Biological Control",
        "active_ingredient": "Pseudomonas fluorescens (1×10⁸ CFU/ml)",
        "formulation": "Liquid",
        "purpose": "Biological suppression of Late Blight (Phytophthora infestans) through ISR induction",
        "dosage": "2.5 kg/acre in 200L water",
        "dosage_unit": "kg/acre",
        "application_method": "Foliar spray; cover both upper and lower leaf surfaces",
        "application_timing": "Begin at first appearance; preventive use from early vegetative stage in high-risk periods",
        "frequency": "Every 10 days — 3 applications",
        "duration": "30 days treatment cycle",
        "precautions": "Do not mix with chemical pesticides. Use within 24h of preparation.",
        "safety_notes": "Biological product — wear gloves. Avoid contact with eyes.",
        "harvest_waiting_period": None,
        "organic_alternative": "Copper oxychloride 50WP at 3g/L as a chemical backup",
        "prevention": "Use certified disease-free seeds. Ensure good air circulation. Avoid overhead irrigation. Remove and destroy infected plants immediately.",
        "source": "ICAR-IIHR Tomato Disease Management Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Bacterial Spot": {
        "problem_type": "Disease",
        "product_name": "Copper oxychloride 50WP",
        "product_category": "Bactericide",
        "active_ingredient": "Copper oxychloride (50% w/w)",
        "formulation": "50 WP (Wettable Powder)",
        "purpose": "Control of Bacterial Spot (Xanthomonas vesicatoria) on tomato leaves and fruit",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces thoroughly",
        "application_timing": "Apply at first symptom appearance; preventive spray before rainy periods",
        "frequency": "Every 10–14 days",
        "duration": "3–4 applications",
        "precautions": "Do not apply in hot sun. Avoid mixing with alkaline pesticides. Follow label directions.",
        "safety_notes": "Wear gloves, goggles, and face mask. Avoid inhalation. Wash hands after use. Keep away from water bodies.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Bacillus subtilis 2 kg/acre foliar spray every 10 days",
        "prevention": "Use certified disease-free transplants. Avoid working in wet fields. Remove crop debris.",
        "source": "TNAU Crop Protection Compendium",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Leaf Mold": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Leaf Mold (Fulvia fulva) in tomato under humid greenhouse/field conditions",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of both leaf surfaces, especially undersides",
        "application_timing": "Apply at first sign of yellow patches on upper leaf surfaces",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Do not exceed 4 applications per season. Do not apply within 7 days of harvest.",
        "safety_notes": "Wear gloves, goggles, and respiratory mask. Avoid skin contact. Wash hands thoroughly after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Improve greenhouse ventilation; use neem oil 5ml/L as preventive spray",
        "prevention": "Maintain good greenhouse ventilation. Avoid excessive humidity. Use disease-resistant varieties.",
        "source": "TNAU Tomato Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Septoria Leaf Spot": {
        "problem_type": "Disease",
        "product_name": "Copper oxychloride 50WP",
        "product_category": "Fungicide",
        "active_ingredient": "Copper oxychloride (50% w/w)",
        "formulation": "50 WP",
        "purpose": "Control of Septoria Leaf Spot (Septoria lycopersici)",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "Begin at first symptom appearance after fruit set",
        "frequency": "Every 10–14 days",
        "duration": "3–4 applications",
        "precautions": "Do not exceed 6 applications/season. Observe 7-day PHI.",
        "safety_notes": "Wear full PPE. Keep away from children and animals during application.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Trichoderma viride 2.5 kg/acre soil drench + foliar spray",
        "prevention": "Remove lower infected leaves. Stake plants for air circulation. Avoid wetting foliage.",
        "source": "ICAR-IIHR Disease Management Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Spider Mites": {
        "problem_type": "Pest",
        "product_name": "Abamectin 1.9EC",
        "product_category": "Insecticide",
        "active_ingredient": "Abamectin (1.9% EC)",
        "formulation": "1.9 EC (Emulsifiable Concentrate)",
        "purpose": "Control of Two-Spotted Spider Mite (Tetranychus urticae) on tomato",
        "dosage": "0.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting undersides of leaves where mites congregate",
        "application_timing": "Apply when mite population first detected; avoid flowering stage if possible",
        "frequency": "Every 7–10 days — maximum 2 consecutive sprays",
        "duration": "2 applications, then switch to alternative",
        "precautions": "Highly toxic to bees — do not apply during flowering. Do not apply in high temperatures. Rotate with different MoA.",
        "safety_notes": "Wear full PPE including gloves, goggles, and respirator. Do not eat/drink during use. Keep away from water bodies.",
        "harvest_waiting_period": "3 days",
        "organic_alternative": "Neem oil 5ml/L + soap solution 2ml/L foliar spray every 7 days",
        "prevention": "Monitor regularly with hand lens. Maintain adequate soil moisture. Remove heavily infested leaves.",
        "source": "TNAU Tomato Pest Management Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Target Spot": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Target Spot (Corynespora cassiicola) on tomato",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of both leaf surfaces",
        "application_timing": "Apply at first lesion appearance; do not wait for severe infection",
        "frequency": "Every 10–14 days",
        "duration": "3–4 applications",
        "precautions": "Follow 7-day PHI. Do not mix with alkaline products.",
        "safety_notes": "Wear gloves, goggles, and mask. Wash thoroughly after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Trichoderma harzianum 2 kg/acre foliar spray",
        "prevention": "Remove infected plant debris. Improve air circulation. Avoid dense planting.",
        "source": "TNAU Crop Protection Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Mosaic Virus": {
        "problem_type": "Disease",
        "product_name": "Imidacloprid 17.8 SL",
        "product_category": "Insecticide",
        "active_ingredient": "Imidacloprid (17.8% w/v)",
        "formulation": "17.8 SL (Soluble Liquid)",
        "purpose": "Control of aphid vectors that transmit Tomato Mosaic Virus (ToMV)",
        "dosage": "0.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting aphid colonies on undersides of leaves and shoot tips",
        "application_timing": "Apply at first aphid detection; early intervention reduces virus spread",
        "frequency": "Once; repeat after 15 days only if aphids persist",
        "duration": "1–2 applications",
        "precautions": "Highly toxic to bees — do not apply during flowering. Observe 21-day PHI. Rotate with different MoA to prevent resistance.",
        "safety_notes": "Wear gloves, goggles, and respirator. Do not touch eyes or mouth. Wash hands after use. Keep away from water bodies.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Neem oil 5ml/L + yellow sticky traps for aphid monitoring",
        "prevention": "Use virus-free certified seed. Control aphid populations early. Remove and destroy infected plants. Use reflective mulch.",
        "source": "ICAR-IIHR Tomato Virus Management Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Yellow Leaf Curl Virus": {
        "problem_type": "Disease",
        "product_name": "Thiamethoxam 25WG",
        "product_category": "Insecticide",
        "active_ingredient": "Thiamethoxam (25% w/w)",
        "formulation": "25 WG (Water-Dispersible Granule)",
        "purpose": "Control of whitefly (Bemisia tabaci) vectors that transmit Tomato Yellow Leaf Curl Virus (TYLCV)",
        "dosage": "0.3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray targeting whitefly adults and nymphs on leaf undersides",
        "application_timing": "Apply at first whitefly detection; early intervention is critical for virus prevention",
        "frequency": "Every 15 days",
        "duration": "2–3 applications",
        "precautions": "Do not apply during flowering — highly toxic to bees. Observe PHI. Rotate MoA to prevent resistance.",
        "safety_notes": "Wear full PPE. Wash hands after use. Store in cool, dry place. Keep away from water bodies.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Yellow sticky traps + neem oil 5ml/L spray every 7 days",
        "prevention": "Use TYLCV-resistant varieties. Install insect-proof nets in nurseries. Remove and destroy infected plants. Use reflective mulch.",
        "source": "TNAU Tomato Production Technology Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Tomato|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Preventive biostimulant application to maintain crop health",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Maintain proper plant spacing. Ensure adequate nutrition. Monitor for early pest/disease signs. Practice crop rotation.",
        "source": "TNAU General Crop Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "NPK 19:19:19 (Water-Soluble Fertilizer)",
            "product_category": "Fertilizer",
            "npk": "19-19-19",
            "primary_nutrient": "Balanced NPK",
            "dosage": "5 g/L foliar spray",
            "dosage_unit": "g/L",
            "application_method": "Foliar spray in cool morning hours",
            "growth_stage": "Vegetative to early fruiting stage",
            "frequency": "Every 15 days",
            "expected_benefit": "Promotes balanced vegetative growth, flowering, and fruit development",
            "source": "TNAU Tomato Nutrition Management",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # PADDY / RICE
    # ═══════════════════════════════════════════════════════════════════════════

    "Paddy|Brown Spot": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Brown Spot (Helminthosporium oryzae) in paddy",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "Apply at first brown spots visible; repeat if necessary",
        "frequency": "Every 14 days — maximum 2 applications",
        "duration": "2 applications",
        "precautions": "Do not apply near water bodies. Observe 21-day PHI.",
        "safety_notes": "Wear gloves, goggles, and mask. Do not eat/drink/smoke during use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre soil drench 10 days before transplanting",
        "prevention": "Balanced fertilization — avoid excess nitrogen. Ensure proper potassium nutrition. Use certified disease-free seed.",
        "source": "TNAU Paddy Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Muriate of Potash (MOP)",
            "product_category": "Fertilizer",
            "npk": "0-0-60",
            "primary_nutrient": "Potassium",
            "dosage": "40 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Soil broadcast and incorporate",
            "growth_stage": "Basal application at transplanting",
            "frequency": "Once at transplanting",
            "expected_benefit": "Adequate potassium reduces susceptibility to Brown Spot disease",
            "source": "TNAU Paddy Nutrition Guide",
        },
    },

    "Paddy|Leaf Blast": {
        "problem_type": "Disease",
        "product_name": "Tricyclazole 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Tricyclazole (75% WP)",
        "formulation": "75 WP",
        "purpose": "Control of Leaf Blast (Pyricularia oryzae) — the most destructive paddy disease",
        "dosage": "0.6 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of all leaf surfaces",
        "application_timing": "Apply at first spindle-shaped lesion appearance; at tillering stage",
        "frequency": "Every 10 days — 3 applications",
        "duration": "30-day treatment cycle",
        "precautions": "Do not exceed 3 applications. Observe 21-day PHI. Rotate with different fungicide MoA.",
        "safety_notes": "Wear gloves, goggles, and respiratory protection. Avoid contact with skin and eyes. Wash thoroughly after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Pseudomonas fluorescens 2.5 kg/acre foliar spray every 10 days",
        "prevention": "Use blast-resistant varieties. Avoid excess nitrogen. Ensure proper plant spacing. Drain fields periodically.",
        "source": "ICAR-NRRI Paddy Blast Management Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Paddy|Leaf Blight": {
        "problem_type": "Disease",
        "product_name": "Copper oxychloride 50WP",
        "product_category": "Bactericide",
        "active_ingredient": "Copper oxychloride (50% w/w)",
        "formulation": "50 WP",
        "purpose": "Control of Bacterial Leaf Blight (Xanthomonas oryzae pv. oryzae)",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray targeting leaf sheaths and leaf blades",
        "application_timing": "Apply at first water-soaked lesion appearance near leaf tip",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Do not apply in heavy wind. Avoid run-off into irrigation water.",
        "safety_notes": "Wear gloves and eye protection. Wash hands after handling.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Pseudomonas fluorescens 2.5 kg/acre spray",
        "prevention": "Use certified disease-free seeds. Drain flooded fields. Maintain good soil drainage. Remove ratoon crop.",
        "source": "TNAU Paddy Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Paddy|Leaf Scald": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Leaf Scald (Monographella albescens) in paddy",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray at early disease onset",
        "application_timing": "Apply at first lesion appearance on leaf tips or margins",
        "frequency": "Every 14 days",
        "duration": "2 applications",
        "precautions": "Observe 21-day PHI. Do not use near water bodies.",
        "safety_notes": "Wear protective gloves and mask. Avoid inhalation of spray mist.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre soil drench",
        "prevention": "Use certified seed. Maintain balanced nutrition — avoid excess nitrogen. Improve field drainage.",
        "source": "TNAU Paddy Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Paddy|Sheath Blight": {
        "problem_type": "Disease",
        "product_name": "Hexaconazole 5EC",
        "product_category": "Fungicide",
        "active_ingredient": "Hexaconazole (5% EC)",
        "formulation": "5 EC",
        "purpose": "Control of Sheath Blight (Rhizoctonia solani) in paddy",
        "dosage": "2 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting plant base and leaf sheaths at waterline level",
        "application_timing": "Apply at maximum tillering stage when disease first appears",
        "frequency": "Every 21 days — 2 applications",
        "duration": "2 applications",
        "precautions": "Observe 14-day PHI. Avoid excessive nitrogen application.",
        "safety_notes": "Wear full PPE. Do not eat or drink during application.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Trichoderma harzianum 2 kg/acre soil drench at tillering",
        "prevention": "Avoid dense planting. Maintain balanced fertilization. Use sheath-blight resistant varieties.",
        "source": "ICAR-NRRI Sheath Blight Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Paddy|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Preventive biofertilizer application for yield enhancement",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for early pest/disease signs. Maintain proper water management. Apply balanced fertilization.",
        "source": "TNAU Paddy Production Manual",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azospirillum biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Seed treatment or soil drench near roots",
            "growth_stage": "At transplanting or seed treatment",
            "frequency": "Once per crop season",
            "expected_benefit": "Biological nitrogen fixation improves crop yield and reduces chemical N requirement by 25%",
            "source": "TNAU Biofertilizer Recommendation",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # WHEAT
    # ═══════════════════════════════════════════════════════════════════════════

    "Wheat|Crown Root Rot": {
        "problem_type": "Disease",
        "product_name": "Trichoderma viride",
        "product_category": "Biological Control",
        "active_ingredient": "Trichoderma viride (1×10⁸ CFU/g)",
        "formulation": "WP",
        "purpose": "Biological control of Crown and Root Rot (Fusarium spp., Helminthosporium sativum)",
        "dosage": "4 g/kg seed",
        "dosage_unit": "g/kg seed",
        "application_method": "Seed treatment — coat seed evenly before sowing",
        "application_timing": "24–48 hours before sowing",
        "frequency": "Once per season (seed treatment)",
        "duration": "One-time seed treatment",
        "precautions": "Do not mix with chemical seed treatments. Shade-dry after treatment. Do not expose treated seed to direct sunlight.",
        "safety_notes": "Wear gloves. Biological product — generally safe. Wash hands after use.",
        "harvest_waiting_period": None,
        "organic_alternative": "Soil amendment with well-decomposed FYM to improve soil microbiology",
        "prevention": "Ensure good soil drainage. Rotate crops with non-host crops. Avoid waterlogging.",
        "source": "ICAR-IIWBR Wheat Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Wheat|Leaf Rust": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Leaf Rust (Puccinia triticina) — most widespread wheat disease in India",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray; thorough coverage of flag leaf and upper leaves",
        "application_timing": "Apply at first rust pustule appearance; critical window is flag-leaf emergence",
        "frequency": "Every 14 days — maximum 2 applications",
        "duration": "2 applications",
        "precautions": "Observe 21-day PHI. Do not apply in excessive wind. Rotate fungicide MoA.",
        "safety_notes": "Wear gloves, goggles, and respirator. Wash thoroughly after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Sulphur 80WP at 3g/L as partial suppression",
        "prevention": "Use rust-resistant certified varieties. Monitor flag leaf stage carefully. Avoid late sowing.",
        "source": "ICAR-IIWBR Wheat Rust Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Wheat|Loose Smut": {
        "problem_type": "Disease",
        "product_name": "Carboxin 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Carboxin (75% WP)",
        "formulation": "75 WP",
        "purpose": "Seed treatment for control of Loose Smut (Ustilago tritici) — seed-borne disease",
        "dosage": "2.5 g/kg seed",
        "dosage_unit": "g/kg seed",
        "application_method": "Seed treatment — dry powder dressing on seed before sowing",
        "application_timing": "48 hours before sowing",
        "frequency": "Once per season (seed treatment)",
        "duration": "One-time seed treatment",
        "precautions": "Wear gloves and mask. Do not sow treated seed near food crops without PHI compliance.",
        "safety_notes": "Moderately hazardous — wear full PPE for seed treatment. Store treated seed separately.",
        "harvest_waiting_period": None,
        "organic_alternative": "Hot-water treatment of seed at 54°C for 10 minutes, then cool and dry (certified protocol only)",
        "prevention": "Use certified disease-free seed. Remove and destroy smutted heads before spore release. Practice crop rotation.",
        "source": "ICAR-IIWBR Wheat Seed Treatment Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Wheat|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer application for optimal wheat yield",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for rust at flag-leaf stage. Ensure balanced NPK fertilization. Use certified disease-free seed.",
        "source": "ICAR-IIWBR Wheat Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azotobacter biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Seed treatment or soil drench before sowing",
            "growth_stage": "Before sowing",
            "frequency": "Once before sowing",
            "expected_benefit": "Biological nitrogen fixation supplements chemical N requirement; improves grain filling",
            "source": "ICAR-IIWBR Biofertilizer Recommendation",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # SUGARCANE
    # ═══════════════════════════════════════════════════════════════════════════

    "Sugarcane|Red Rot": {
        "problem_type": "Disease",
        "product_name": "Trichoderma viride",
        "product_category": "Biological Control",
        "active_ingredient": "Trichoderma viride (1×10⁸ CFU/g)",
        "formulation": "WP",
        "purpose": "Biological control and prevention of Red Rot (Colletotrichum falcatum)",
        "dosage": "2 kg/acre in 200L water",
        "dosage_unit": "kg/acre",
        "application_method": "Sett treatment before planting; soil drench at planting furrows",
        "application_timing": "At sett planting stage",
        "frequency": "Once at planting; repeat soil drench after 45 days",
        "duration": "2 applications",
        "precautions": "Do not mix with chemical fungicides. Apply in shade or evening hours.",
        "safety_notes": "Biological product — wear gloves. Wash hands after use.",
        "harvest_waiting_period": None,
        "organic_alternative": "Healthy sett selection + hot-water treatment at 50°C for 2 hours",
        "prevention": "Use disease-free setts from certified sources. Rogue out infected clumps immediately. Avoid waterlogging. Practice crop rotation.",
        "source": "TNAU Sugarcane Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sugarcane|Red Rust": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Red Rust / Pineapple Disease on sugarcane",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray at first rust appearance",
        "application_timing": "Apply at early rust pustule stage",
        "frequency": "Every 14 days — 2 applications",
        "duration": "2 applications",
        "precautions": "Observe local PHI. Rotate MoA between applications.",
        "safety_notes": "Wear gloves and eye protection. Wash hands after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Sulphur dust application as partial suppression",
        "prevention": "Plant resistant varieties. Ensure proper plant spacing. Maintain balanced fertilization.",
        "source": "TNAU Sugarcane Crop Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sugarcane|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer for nitrogen supply in sugarcane",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for red rot early. Ensure good field drainage. Use certified healthy setts.",
        "source": "TNAU Sugarcane Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azospirillum biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Mix with FYM; apply in furrows at planting",
            "growth_stage": "At planting",
            "frequency": "Once per season",
            "expected_benefit": "Biological nitrogen fixation reduces chemical N requirement; improves cane yield and sugar recovery",
            "source": "TNAU Sugarcane Biofertilizer Guide",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # GROUNDNUT
    # ═══════════════════════════════════════════════════════════════════════════

    "Groundnut|Late Leaf Spot": {
        "problem_type": "Disease",
        "product_name": "Chlorothalonil 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Chlorothalonil (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Late Leaf Spot (Phaeoisariopsis personata) — most damaging groundnut foliar disease",
        "dosage": "2 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of both leaf surfaces",
        "application_timing": "Begin spray at 30 DAS; repeat at 45, 60, 75 DAS",
        "frequency": "Every 10–14 days — 4 applications",
        "duration": "4 applications through the season",
        "precautions": "Observe 14-day PHI. Do not apply near water bodies. Rotate MoA.",
        "safety_notes": "Wear gloves, goggles, and mask. Avoid inhalation. Wash thoroughly after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Mancozeb 75WP at 2.5g/L as alternative",
        "prevention": "Use tolerant varieties. Maintain proper plant spacing. Avoid late-season planting. Remove infected plant debris.",
        "source": "ICAR-ICRISAT Groundnut Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Groundnut|Leaf Spot": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Early Leaf Spot (Cercospora arachidicola) on groundnut",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray at first disease appearance",
        "application_timing": "Begin at first circular lesion appearance (25–30 DAS)",
        "frequency": "Every 10–14 days",
        "duration": "3–4 applications",
        "precautions": "Observe 7-day PHI. Wear protective equipment.",
        "safety_notes": "Wear gloves and mask. Wash after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Neem oil 5ml/L + copper oxychloride combination",
        "prevention": "Use disease-tolerant varieties. Crop rotation. Remove infected plant debris.",
        "source": "TNAU Groundnut Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Groundnut|Nutrition Deficiency": {
        "problem_type": "Nutrient Deficiency",
        "product_name": None,
        "product_category": "Nutrient Supplement",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Correction of micronutrient deficiency in groundnut",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": "Soil test before application is strongly recommended.",
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": "FYM 5 tonnes/acre + vermicompost 1 tonne/acre",
        "prevention": "Conduct soil tests regularly. Maintain soil pH between 6.0–7.0. Ensure balanced fertilization.",
        "source": "ICAR-ICRISAT Groundnut Nutrition Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Micronutrient Mix (Fe, Zn, B)",
            "product_category": "Nutrient Supplement",
            "npk": None,
            "primary_nutrient": "Iron (Fe), Zinc (Zn), Boron (B)",
            "dosage": "5 g/L",
            "dosage_unit": "g/L",
            "application_method": "Foliar spray in early morning hours",
            "growth_stage": "Early vegetative stage (20–30 DAS)",
            "frequency": "Every 14 days — 2 applications",
            "expected_benefit": "Corrects micronutrient deficiency; improves pod filling and yield",
            "source": "TNAU Groundnut Nutrition Guide",
        },
    },

    "Groundnut|Rust": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Groundnut Rust (Puccinia arachidis)",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray at early rust pustule appearance",
        "application_timing": "Apply at first rust pustule stage; continue until crop maturity",
        "frequency": "Every 14 days",
        "duration": "2–3 applications",
        "precautions": "Observe 21-day PHI. Rotate MoA between sprays.",
        "safety_notes": "Wear gloves and goggles. Wash hands after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Sulphur 80WP at 3g/L foliar spray",
        "prevention": "Use rust-resistant varieties. Maintain adequate plant spacing. Avoid late-season planting.",
        "source": "TNAU Groundnut Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Groundnut|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer application for nitrogen supply in groundnut",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for early leaf spot from 25 DAS. Ensure adequate calcium nutrition at pegging stage.",
        "source": "TNAU Groundnut Production Manual",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Rhizobium biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "200 g per 10 kg seed",
            "dosage_unit": "g per 10 kg seed",
            "application_method": "Seed treatment — coat seed evenly; do not expose to direct sunlight",
            "growth_stage": "Before sowing",
            "frequency": "Once per season",
            "expected_benefit": "Biological nitrogen fixation through root nodulation; reduces chemical N need by up to 50%",
            "source": "TNAU Groundnut Biofertilizer Recommendation",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # SUNFLOWER
    # ═══════════════════════════════════════════════════════════════════════════

    "Sunflower|Alternaria Leaf Spot": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Alternaria Leaf Spot (Alternaria helianthi) on sunflower",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray at first lesion appearance",
        "application_timing": "Begin spray at first circular lesion with yellow halo",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Observe 7-day PHI. Wear protective equipment.",
        "safety_notes": "Wear gloves and mask. Wash thoroughly after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre foliar spray",
        "prevention": "Use tolerant varieties. Maintain adequate plant spacing. Remove infected leaves.",
        "source": "TNAU Sunflower Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Downy Mildew": {
        "problem_type": "Disease",
        "product_name": "Metalaxyl 8% + Mancozeb 64% WP",
        "product_category": "Fungicide",
        "active_ingredient": "Metalaxyl + Mancozeb",
        "formulation": "WP (8+64%)",
        "purpose": "Control of Downy Mildew (Plasmopara halstedii) — systemic + contact fungicide",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray at seedling stage; soil drench for severe infection",
        "application_timing": "Apply at first symptom; critical preventive spray at 2–3 leaf stage",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Observe 21-day PHI. Rotate MoA to prevent metalaxyl resistance.",
        "safety_notes": "Wear gloves, goggles, and mask. Wash thoroughly after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Seed treatment with Trichoderma viride 4g/kg seed",
        "prevention": "Use downy-mildew resistant varieties. Avoid waterlogging. Use certified disease-free seed.",
        "source": "TNAU Sunflower Production Technology",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Powdery Mildew": {
        "problem_type": "Disease",
        "product_name": "Sulphur 80WP",
        "product_category": "Fungicide",
        "active_ingredient": "Sulphur (80% w/w)",
        "formulation": "80 WP",
        "purpose": "Control of Powdery Mildew (Erysiphe cichoracearum) on sunflower",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces thoroughly",
        "application_timing": "At first whitish powdery patch appearance on upper leaf surface",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Do not apply in temperature above 35°C — risk of phytotoxicity. Observe 7-day PHI.",
        "safety_notes": "Wear mask and gloves. Avoid inhalation. Keep away from water bodies.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Potassium bicarbonate 5g/L spray as eco-friendly option",
        "prevention": "Ensure good air circulation. Avoid overhead irrigation. Use powdery-mildew tolerant varieties.",
        "source": "TNAU Sunflower Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Rust": {
        "problem_type": "Disease",
        "product_name": "Propiconazole 25EC",
        "product_category": "Fungicide",
        "active_ingredient": "Propiconazole (25% EC)",
        "formulation": "25 EC",
        "purpose": "Control of Sunflower Rust (Puccinia helianthi)",
        "dosage": "1 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray at early rust pustule appearance",
        "application_timing": "Apply at first rust pustule on lower leaf surface",
        "frequency": "Every 14 days",
        "duration": "2 applications",
        "precautions": "Observe 21-day PHI.",
        "safety_notes": "Wear gloves and goggles. Wash hands after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Sulphur 80WP 3g/L as alternative",
        "prevention": "Use rust-resistant varieties. Maintain adequate spacing. Remove infected crop debris.",
        "source": "TNAU Sunflower Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Rhizopus Head Rot": {
        "problem_type": "Disease",
        "product_name": "Carbendazim 50WP",
        "product_category": "Fungicide",
        "active_ingredient": "Carbendazim (50% WP)",
        "formulation": "50 WP",
        "purpose": "Control of Rhizopus Head Rot (Rhizopus stolonifer) on sunflower heads",
        "dosage": "1 g/L",
        "dosage_unit": "g/L",
        "application_method": "Directed spray at flower head formation stage",
        "application_timing": "Spray when heads begin forming; critical at R4–R5 stage",
        "frequency": "Every 10 days",
        "duration": "2–3 applications",
        "precautions": "Do not spray during full bloom to protect pollinators.",
        "safety_notes": "Wear gloves and mask. Wash hands after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre foliar spray",
        "prevention": "Avoid insect and physical damage to heads. Ensure good air circulation. Avoid overhead irrigation near flowering.",
        "source": "TNAU Sunflower Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Sclerotinia": {
        "problem_type": "Disease",
        "product_name": "Carbendazim 50WP",
        "product_category": "Fungicide",
        "active_ingredient": "Carbendazim (50% WP)",
        "formulation": "50 WP",
        "purpose": "Control of Sclerotinia Stem Rot and Head Rot (Sclerotinia sclerotiorum)",
        "dosage": "1 g/L",
        "dosage_unit": "g/L",
        "application_method": "Directed spray at stem base and flower head",
        "application_timing": "Spray preventively at stem elongation stage",
        "frequency": "Every 10 days",
        "duration": "2 applications",
        "precautions": "Observe 14-day PHI. Rotate MoA between applications.",
        "safety_notes": "Wear PPE. Wash hands after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Trichoderma viride soil drench at 2 kg/acre",
        "prevention": "Remove and destroy infected plants and sclerotia. Ensure good drainage. Long crop rotation (4+ years) to deplete sclerotia.",
        "source": "ICAR Sunflower Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Sunflower|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer for nitrogen supply in sunflower",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for alternaria leaf spot from flowering stage. Maintain balanced NPK nutrition.",
        "source": "TNAU Sunflower Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azospirillum biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Seed treatment or soil drench before sowing",
            "growth_stage": "Before sowing",
            "frequency": "Once per season",
            "expected_benefit": "Biological nitrogen fixation; improves head diameter and seed weight",
            "source": "TNAU Sunflower Biofertilizer Guide",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # COTTON
    # ═══════════════════════════════════════════════════════════════════════════

    "Cotton|Aphids": {
        "problem_type": "Pest",
        "product_name": "Imidacloprid 17.8 SL",
        "product_category": "Insecticide",
        "active_ingredient": "Imidacloprid (17.8% SL)",
        "formulation": "17.8 SL (Soluble Liquid)",
        "purpose": "Control of cotton aphid (Aphis gossypii) — a key sucking pest of cotton",
        "dosage": "0.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting undersides of leaves where aphid colonies form",
        "application_timing": "Apply at first aphid colony detection; early morning or late evening",
        "frequency": "Once; repeat after 15 days only if aphids persist",
        "duration": "1–2 applications per outbreak",
        "precautions": "Highly toxic to bees and pollinators — do not apply during flowering. Observe 21-day PHI. Do not mix with alkaline pesticides. Rotate MoA to prevent resistance.",
        "safety_notes": "Wear gloves, goggles, and respirator mask. Do not eat/drink/smoke during use. Wash hands and face after use. Keep away from water bodies. Store in original container away from children.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Neem oil 5ml/L + soap solution 2ml/L; spray every 7 days on aphid colonies",
        "prevention": "Monitor weekly with sticky yellow traps. Encourage natural enemies (ladybird beetles). Avoid excessive nitrogen fertilization that promotes aphid-preferred succulent growth.",
        "source": "TNAU Cotton Pest Management Guide",
        "last_verified": "2024-01",
        "region": "South India",
        "fertilizer": None,
    },

    "Cotton|Army Worm": {
        "problem_type": "Pest",
        "product_name": "Chlorpyrifos 20EC",
        "product_category": "Insecticide",
        "active_ingredient": "Chlorpyrifos (20% EC)",
        "formulation": "20 EC",
        "purpose": "Control of Cotton Army Worm (Spodoptera litura / S. exigua) — destructive defoliating pest",
        "dosage": "2.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray in the evening when larvae are active; direct spray to soil surface for pupae",
        "application_timing": "Apply at early larval stage (1st–3rd instar); most effective before large larvae appear",
        "frequency": "Every 10–14 days",
        "duration": "2 applications",
        "precautions": "Highly toxic — do not apply near water bodies. Observe 30-day PHI. Do not apply in high temperature. Rotate MoA.",
        "safety_notes": "Wear full PPE including gloves, goggles, respirator, and boots. Do not eat/drink/smoke during use. Wash all clothing after use. Keep away from children.",
        "harvest_waiting_period": "30 days",
        "organic_alternative": "Bacillus thuringiensis (Bt) 1 kg/acre spray — effective against young larvae",
        "prevention": "Set pheromone traps for adult monitoring. Remove egg masses manually. Practice summer ploughing to expose pupae.",
        "source": "TNAU Cotton Pest Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Cotton|Bacterial Blight": {
        "problem_type": "Disease",
        "product_name": "Copper hydroxide 53.8 DF",
        "product_category": "Bactericide",
        "active_ingredient": "Copper hydroxide (53.8% DF)",
        "formulation": "53.8 DF (Dry Flowable)",
        "purpose": "Control of Cotton Bacterial Blight (Xanthomonas citri pv. malvacearum)",
        "dosage": "2 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of both leaf surfaces",
        "application_timing": "Apply at first angular water-soaked lesion appearance",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Do not apply in rain. Do not mix with alkaline products. Observe 7-day PHI.",
        "safety_notes": "Wear gloves and eye protection. Avoid inhalation. Wash hands after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Pseudomonas fluorescens 2.5 kg/acre spray every 10 days",
        "prevention": "Use certified disease-free seed. Practice crop rotation. Remove infected plant debris at season end.",
        "source": "TNAU Cotton Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Cotton|Powdery Mildew": {
        "problem_type": "Disease",
        "product_name": "Sulphur 80WP",
        "product_category": "Fungicide",
        "active_ingredient": "Sulphur (80% w/w)",
        "formulation": "80 WP",
        "purpose": "Control of Cotton Powdery Mildew (Leveillula taurica)",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "At first whitish powdery patch appearance; cool and dry weather favors disease",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Do not apply in temperature above 35°C. Observe 7-day PHI.",
        "safety_notes": "Wear mask and gloves. Avoid inhalation. Keep away from water bodies.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Potassium bicarbonate 5g/L spray",
        "prevention": "Maintain adequate plant spacing. Ensure good ventilation. Avoid late sowing.",
        "source": "TNAU Cotton Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Cotton|Target Spot": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Cotton Target Spot (Corynespora cassiicola)",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "At first target-spot lesion appearance",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Observe 7-day PHI. Wear protective equipment.",
        "safety_notes": "Wear gloves and mask. Wash after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre foliar spray",
        "prevention": "Remove infected leaves. Improve air circulation. Avoid dense planting.",
        "source": "TNAU Cotton Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Cotton|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer for phosphorus solubilization in cotton",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor weekly for sucking pests (aphids, jassids, whiteflies). Set pheromone traps. Practice IPM.",
        "source": "TNAU Cotton Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "PSB (Phosphate Solubilizing Bacteria)",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Phosphorus (biological solubilization)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Mix with compost; apply in furrows before sowing",
            "growth_stage": "Before sowing",
            "frequency": "Once before sowing",
            "expected_benefit": "Solubilizes bound soil phosphorus, making it available to the crop; reduces phosphatic fertilizer requirement",
            "source": "TNAU Cotton Biofertilizer Recommendation",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # BLACKGRAM
    # ═══════════════════════════════════════════════════════════════════════════

    "Blackgram|Anthracnose": {
        "problem_type": "Disease",
        "product_name": "Carbendazim 50WP",
        "product_category": "Fungicide",
        "active_ingredient": "Carbendazim (50% WP)",
        "formulation": "50 WP",
        "purpose": "Control of Blackgram Anthracnose (Colletotrichum lindemuthianum)",
        "dosage": "2 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray at first lesion appearance",
        "application_timing": "Begin spray at first dark irregular spots on leaves and pods",
        "frequency": "Every 10 days",
        "duration": "2–3 applications",
        "precautions": "Observe 14-day PHI. Do not mix with alkaline products.",
        "safety_notes": "Wear gloves and mask. Wash hands after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre foliar spray",
        "prevention": "Use certified disease-free seed. Seed treatment with Carbendazim 2g/kg. Practice crop rotation.",
        "source": "TNAU Blackgram Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Blackgram|Leaf Crinkle": {
        "problem_type": "Disease",
        "product_name": "Imidacloprid 17.8 SL",
        "product_category": "Insecticide",
        "active_ingredient": "Imidacloprid (17.8% SL)",
        "formulation": "17.8 SL",
        "purpose": "Control of aphid vectors (Aphis craccivora) that transmit Blackgram Leaf Crinkle Virus (BLCV)",
        "dosage": "0.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting aphid colonies on shoot tips and undersides of leaves",
        "application_timing": "Apply at first aphid detection; early intervention reduces virus spread",
        "frequency": "Once; repeat after 15 days if aphids persist",
        "duration": "1–2 applications",
        "precautions": "Toxic to bees — avoid during flowering. Observe 21-day PHI.",
        "safety_notes": "Wear gloves, goggles, and respirator. Wash hands after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Neem oil 5ml/L spray every 7 days + yellow sticky traps",
        "prevention": "Use virus-free certified seed. Control aphid populations early. Remove infected plants immediately.",
        "source": "TNAU Blackgram Crop Protection",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Blackgram|Powdery Mildew": {
        "problem_type": "Disease",
        "product_name": "Sulphur 80WP",
        "product_category": "Fungicide",
        "active_ingredient": "Sulphur (80% w/w)",
        "formulation": "80 WP",
        "purpose": "Control of Blackgram Powdery Mildew (Erysiphe polygoni)",
        "dosage": "3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "At first powdery white patches on upper leaf surface",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Do not apply above 35°C. Observe 7-day PHI.",
        "safety_notes": "Wear mask and gloves. Avoid inhalation.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Potassium bicarbonate 5g/L spray",
        "prevention": "Avoid dense planting. Maintain good air circulation. Use resistant varieties.",
        "source": "TNAU Blackgram Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Blackgram|Yellow Mosaic": {
        "problem_type": "Disease",
        "product_name": "Thiamethoxam 25WG",
        "product_category": "Insecticide",
        "active_ingredient": "Thiamethoxam (25% WG)",
        "formulation": "25 WG",
        "purpose": "Control of whitefly (Bemisia tabaci) vectors transmitting Yellow Mosaic Virus (YMV)",
        "dosage": "0.3 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray targeting whitefly on leaf undersides",
        "application_timing": "Apply at first whitefly detection; early intervention critical for virus prevention",
        "frequency": "Every 15 days",
        "duration": "2–3 applications",
        "precautions": "Toxic to bees — avoid during flowering. Observe 14-day PHI.",
        "safety_notes": "Wear full PPE. Wash hands after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Yellow sticky traps + Neem oil 5ml/L every 7 days",
        "prevention": "Use YMV-resistant varieties. Install silver/yellow reflective mulch. Remove infected plants immediately.",
        "source": "TNAU Blackgram Yellow Mosaic Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Blackgram|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer for nitrogen fixation in blackgram",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for whiteflies and yellow mosaic symptoms from 2 weeks after sowing. Use reflective mulch.",
        "source": "TNAU Blackgram Production Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Rhizobium biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation via root nodules)",
            "dosage": "200 g per 10 kg seed",
            "dosage_unit": "g per 10 kg seed",
            "application_method": "Seed treatment — coat seed evenly; do not expose to direct sunlight",
            "growth_stage": "Before sowing",
            "frequency": "Once per season",
            "expected_benefit": "Biological nitrogen fixation through root nodulation; provides up to 30–50 kg N/ha",
            "source": "TNAU Blackgram Biofertilizer Recommendation",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # EGGPLANT
    # ═══════════════════════════════════════════════════════════════════════════

    "Eggplant|Insect Pest": {
        "problem_type": "Pest",
        "product_name": "Spinosad 45 SC",
        "product_category": "Insecticide",
        "active_ingredient": "Spinosad (45% SC)",
        "formulation": "45 SC (Suspension Concentrate)",
        "purpose": "Control of eggplant shoot and fruit borer (Leucinodes orbonalis) — key eggplant pest",
        "dosage": "0.3 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray in the evening when larvae are active; target shoot tips and fruit",
        "application_timing": "Apply at first borer damage detection (wilting shoot tips or entry holes on fruit)",
        "frequency": "Every 10–14 days",
        "duration": "2–3 applications; then rotate MoA",
        "precautions": "Moderately toxic to bees — avoid spray during flowering. Rotate with different insecticide class. Observe 7-day PHI.",
        "safety_notes": "Wear gloves, goggles, and mask. Wash hands and face after use. Keep away from children and water bodies.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Bacillus thuringiensis (Bt) 1 kg/acre spray against early instar larvae",
        "prevention": "Remove and destroy affected shoots. Use pheromone traps for adult moth monitoring. Practice crop rotation.",
        "source": "TNAU Eggplant Pest Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|Leaf Spot": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Eggplant Leaf Spot (Phomopsis vexans / Alternaria spp.)",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; thorough coverage of both leaf surfaces",
        "application_timing": "At first lesion appearance",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Observe 7-day PHI. Wear protective equipment.",
        "safety_notes": "Wear gloves and mask. Wash after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Copper oxychloride 3g/L as alternative",
        "prevention": "Remove infected leaves. Improve air circulation. Avoid overhead irrigation.",
        "source": "TNAU Eggplant Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|Mosaic Virus": {
        "problem_type": "Disease",
        "product_name": "Imidacloprid 17.8 SL",
        "product_category": "Insecticide",
        "active_ingredient": "Imidacloprid (17.8% SL)",
        "formulation": "17.8 SL",
        "purpose": "Control of aphid vectors transmitting Eggplant Mosaic Virus",
        "dosage": "0.5 ml/L",
        "dosage_unit": "ml/L",
        "application_method": "Foliar spray targeting aphid colonies on shoot tips and undersides of leaves",
        "application_timing": "Apply at first aphid detection",
        "frequency": "Once; repeat after 15 days if aphids persist",
        "duration": "1–2 applications",
        "precautions": "Toxic to bees — avoid during flowering. Observe 21-day PHI.",
        "safety_notes": "Wear full PPE. Wash hands after use.",
        "harvest_waiting_period": "21 days",
        "organic_alternative": "Neem oil 5ml/L spray every 7 days",
        "prevention": "Remove infected plants immediately. Control aphid vectors. Use reflective mulch.",
        "source": "TNAU Eggplant Crop Protection",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|Small Leaf": {
        "problem_type": "Disease",
        "product_name": "Oxytetracycline 3.4% L",
        "product_category": "Bactericide",
        "active_ingredient": "Oxytetracycline",
        "formulation": "3.4% Liquid",
        "purpose": "Suppression of phytoplasma causing Little Leaf Disease in eggplant",
        "dosage": "0.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray at first symptom appearance",
        "application_timing": "At first small leaf / phyllody symptom",
        "frequency": "Every 10 days",
        "duration": "3 applications",
        "precautions": "Remove infected plants where possible. Control leafhopper vectors.",
        "safety_notes": "Wear gloves and mask. Wash after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Control leafhopper vectors with neem oil 5ml/L spray",
        "prevention": "Use certified disease-free transplants. Control leafhopper vectors. Remove and destroy infected plants.",
        "source": "TNAU Eggplant Disease Guide",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|White Mold": {
        "problem_type": "Disease",
        "product_name": "Carbendazim 50WP",
        "product_category": "Fungicide",
        "active_ingredient": "Carbendazim (50% WP)",
        "formulation": "50 WP",
        "purpose": "Control of White Mold / Stem Rot (Sclerotinia sclerotiorum) in eggplant",
        "dosage": "1 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray and soil drench at plant base",
        "application_timing": "At first cottony white mycelial growth appearance",
        "frequency": "Every 10 days",
        "duration": "2–3 applications",
        "precautions": "Observe 14-day PHI. Rotate MoA.",
        "safety_notes": "Wear gloves and mask. Wash hands after use.",
        "harvest_waiting_period": "14 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre soil drench",
        "prevention": "Ensure good drainage. Remove infected plants. Long crop rotation.",
        "source": "TNAU Eggplant Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|Wilt Disease": {
        "problem_type": "Disease",
        "product_name": "Trichoderma viride",
        "product_category": "Biological Control",
        "active_ingredient": "Trichoderma viride (1×10⁸ CFU/g)",
        "formulation": "WP",
        "purpose": "Biological control of Fusarium/Bacterial Wilt in eggplant",
        "dosage": "2 kg/acre in 200L water",
        "dosage_unit": "kg/acre",
        "application_method": "Soil drench around plant base at transplanting and 30 days later",
        "application_timing": "At transplanting; repeat at first wilt symptom",
        "frequency": "Every 21 days",
        "duration": "3 applications",
        "precautions": "Do not mix with chemical fungicides. Apply in cool hours.",
        "safety_notes": "Biological product — wear gloves. Wash hands after use.",
        "harvest_waiting_period": None,
        "organic_alternative": "Pseudomonas fluorescens 2.5 kg/acre soil drench",
        "prevention": "Use grafted seedlings on resistant rootstock. Avoid waterlogging. Practice 3-year crop rotation.",
        "source": "TNAU Eggplant Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Eggplant|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer and preventive biostimulant for healthy eggplant",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor weekly for shoot borer. Set pheromone traps. Practice IPM. Avoid excess nitrogen.",
        "source": "TNAU Eggplant Production Technology",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azospirillum + PSB Mix",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen + Phosphorus (biological)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Mix with compost; apply near root zone at transplanting",
            "growth_stage": "At transplanting",
            "frequency": "Once before transplanting",
            "expected_benefit": "Dual biofertilizer action — biological N fixation + P solubilization improves early establishment",
            "source": "TNAU Eggplant Biofertilizer Guide",
        },
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # TURMERIC
    # ═══════════════════════════════════════════════════════════════════════════

    "Turmeric|Dry Leaf": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Dry Leaf / Leaf Blight (Taphrina maculans) in turmeric",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "At first tip-burn or yellowing symptom",
        "frequency": "Every 15 days",
        "duration": "3 applications",
        "precautions": "Avoid excess spray run-off. Observe 7-day PHI.",
        "safety_notes": "Wear gloves and mask. Wash hands after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Potassium silicate 2ml/L foliar spray for strengthening leaf cuticle",
        "prevention": "Maintain adequate soil moisture. Avoid water stress. Improve drainage.",
        "source": "TNAU Turmeric Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Turmeric|Leaf Blotch": {
        "problem_type": "Disease",
        "product_name": "Mancozeb 75WP",
        "product_category": "Fungicide",
        "active_ingredient": "Mancozeb (75% w/w)",
        "formulation": "75 WP",
        "purpose": "Control of Turmeric Leaf Blotch (Taphrina maculans)",
        "dosage": "2.5 g/L",
        "dosage_unit": "g/L",
        "application_method": "Foliar spray; cover both leaf surfaces",
        "application_timing": "At first blotch symptom",
        "frequency": "Every 10–14 days",
        "duration": "3 applications",
        "precautions": "Observe 7-day PHI. Wear protective equipment.",
        "safety_notes": "Wear gloves and mask. Wash after use.",
        "harvest_waiting_period": "7 days",
        "organic_alternative": "Trichoderma viride 2 kg/acre spray",
        "prevention": "Improve air circulation. Remove infected leaves. Avoid overwatering.",
        "source": "TNAU Turmeric Disease Management",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Turmeric|Rhizome Disease": {
        "problem_type": "Disease",
        "product_name": "Trichoderma viride",
        "product_category": "Biological Control",
        "active_ingredient": "Trichoderma viride (1×10⁸ CFU/g)",
        "formulation": "WP",
        "purpose": "Biological control of Rhizome Rot (Pythium sp. / Fusarium sp.) in turmeric",
        "dosage": "2 kg/acre in 200L water",
        "dosage_unit": "kg/acre",
        "application_method": "Drench soil around rhizome planting area at planting and 30 days later",
        "application_timing": "At planting; repeat at 30 DAS",
        "frequency": "Every 21 days",
        "duration": "3 applications",
        "precautions": "Do not mix with chemical fungicides. Apply in cool hours.",
        "safety_notes": "Biological product — wear gloves. Wash hands after use.",
        "harvest_waiting_period": None,
        "organic_alternative": "Pseudomonas fluorescens 2.5 kg/acre soil drench",
        "prevention": "Use disease-free certified rhizomes. Ensure good drainage. Treat rhizomes with Trichoderma before planting.",
        "source": "TNAU Turmeric Production Technology",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": None,
    },

    "Turmeric|Healthy": {
        "problem_type": "Healthy",
        "product_name": None,
        "product_category": "Preventive Treatment",
        "active_ingredient": None,
        "formulation": None,
        "purpose": "Biofertilizer application for healthy turmeric rhizome development",
        "dosage": None,
        "dosage_unit": None,
        "application_method": None,
        "application_timing": None,
        "frequency": None,
        "duration": None,
        "precautions": None,
        "safety_notes": None,
        "harvest_waiting_period": None,
        "organic_alternative": None,
        "prevention": "Monitor for early rhizome rot symptoms. Ensure proper drainage. Use certified healthy rhizomes.",
        "source": "TNAU Turmeric Production Manual",
        "last_verified": "2024-01",
        "region": "India",
        "fertilizer": {
            "name": "Azospirillum biofertilizer",
            "product_category": "Fertilizer",
            "npk": None,
            "primary_nutrient": "Nitrogen (biological fixation)",
            "dosage": "2 kg/acre",
            "dosage_unit": "kg/acre",
            "application_method": "Mix with FYM; apply in furrows at planting",
            "growth_stage": "At planting",
            "frequency": "Once per season",
            "expected_benefit": "Biological N supply; promotes rhizome development and curcumin content",
            "source": "TNAU Turmeric Biofertilizer Guide",
        },
    },
}


def _build_fertilizer_compat(rec: dict) -> dict:
    """
    Build backward-compatible 'fertilizer' dict from the recommendation data.
    This keeps existing Flutter PredictionResult parsing working unchanged.
    """
    if rec is None:
        return {}
    # Use fertilizer section if available, else product details
    fert = rec.get("fertilizer")
    if fert:
        return {
            "name": fert.get("name", ""),
            "dosage": fert.get("dosage", ""),
            "application": fert.get("application_method", ""),
            "frequency": fert.get("frequency", ""),
        }
    # For non-healthy disease/pest entries, include the product as the "recommendation"
    product = rec.get("product_name")
    if product:
        return {
            "name": product,
            "dosage": f"{rec.get('dosage', '')} {rec.get('dosage_unit', '')}".strip(),
            "application": rec.get("application_method", ""),
            "frequency": rec.get("frequency", ""),
        }
    return {}


@router.get("/health")
async def health_check(request: Request):
    """
    GET /api/v1/health

    Returns backend health and startup readiness.
    """
    startup_state = getattr(request.app.state, "startup_state", {})
    startup_ready = startup_state.get("ready", False)
    startup_duration_ms = startup_state.get("startup_duration_ms", 0)

    return {
        "status": "ok",
        "service": "AgroVision AI — Crop Disease Detection API",
        "version": "3.0.0",
        "model_loaded": is_model_loaded(),
        "startup_ready": startup_ready,
        "startup_duration_ms": startup_duration_ms,
        "supported_crops": [
            "Blackgram", "Cotton", "Eggplant", "Groundnut", "Paddy",
            "Sugarcane", "Sunflower", "Tomato", "Turmeric", "Wheat"
        ],
        "confidence_thresholds": {
            "crop": CROP_CONFIDENCE_THRESHOLD,
            "disease": DISEASE_CONFIDENCE_THRESHOLD,
        }
    }


@router.get("/recommendation")
async def get_recommendation(
    crop: str = Query(..., description="Crop name (e.g. Cotton)"),
    problem: str = Query(..., description="Disease or pest name (e.g. Aphids)"),
):
    """
    GET /api/v1/recommendation?crop=Cotton&problem=Aphids

    Returns the verified recommendation for a specific crop + disease/pest combination.
    Returns 404 with a clear message if no verified recommendation exists.
    Never fabricates or falls back to a generic recommendation.
    """
    # Normalize
    crop = crop.strip().title()
    problem = problem.strip()

    # Validate crop
    if crop not in SUPPORTED_CROPS and crop not in CROP_MODEL_CONFIG:
        return JSONResponse(
            status_code=400,
            content={
                "success": False,
                "message": f"'{crop}' is not a supported crop. Supported crops: {', '.join(sorted(SUPPORTED_CROPS))}",
            }
        )

    key = f"{crop}|{problem}"
    rec = RECOMMENDATION_DB.get(key)

    if rec is None:
        return JSONResponse(
            status_code=404,
            content={
                "success": False,
                "crop": crop,
                "problem": problem,
                "message": (
                    f"No verified recommendation is available for {crop} + {problem}. "
                    "Please consult your local agricultural extension officer or "
                    "Tamil Nadu Agricultural University (TNAU) guidance."
                ),
            }
        )

    return JSONResponse(content={
        "success": True,
        "crop": crop,
        "problem": problem,
        "problem_type": rec.get("problem_type"),
        "recommendation": rec,
    })


@router.post("/predict")
async def predict_disease(request: Request, file: UploadFile = File(...)):
    """
    POST /api/v1/predict

    Multi-stage inference pipeline:
      Stage 0: Startup readiness check (503 BACKEND_STARTING if models still loading)
      Stage 1: Validate image format & size
      Stage 2: Leaf & OOD Validation (quality, human/skin/face, vegetation, OOD)
      Stage 3: Keras Model Inference (two-stage crop -> disease)
      Stage 4: Supported Crop & Margin Validation
      Stage 5: Confidence Threshold Verification (Crop >= 65%, Disease >= 50%)
      Stage 6: Enriched Recommendation Lookup
    """
    request_start = time.time()
    logger.info(
        f"[Predict] Request received — filename={file.filename}, "
        f"content_type={file.content_type}"
    )

    # ── Stage 0: Check Startup Readiness ──────────────────────────────────────
    startup_state = getattr(request.app.state, "startup_state", {})
    if not startup_state.get("ready", True):
        logger.warning("[Predict] Request received while models still loading.")
        return JSONResponse(
            status_code=503,
            content={
                "success":        False,
                "valid_leaf":     False,
                "supported_crop": False,
                "error_type":     "BACKEND_STARTING",
                "message":        (
                    "The detection service is still loading models. "
                    "Please wait a few seconds and try again."
                ),
            }
        )

    # ── Stage 1: Validate Content Type ────────────────────────────────────────
    allowed_types = {
        "image/jpeg", "image/jpg", "image/png", "image/webp",
        "application/octet-stream",
    }
    ct = (file.content_type or "").lower().split(";")[0].strip()
    if ct not in allowed_types:
        return JSONResponse(
            status_code=415,
            content={
                "success":        False,
                "valid_leaf":     False,
                "supported_crop": False,
                "error_type":     "INVALID_IMAGE",
                "message":        (
                    f"Unsupported file type: {file.content_type}. "
                    "Please upload a JPEG, PNG, or WebP crop leaf photo."
                ),
            }
        )

    # ── Stage 1b: Read & Parse Image Bytes ────────────────────────────────────
    try:
        contents = await file.read()
        if len(contents) > 10 * 1024 * 1024:  # 10MB max limit
            return JSONResponse(
                status_code=413,
                content={
                    "success":        False,
                    "valid_leaf":     False,
                    "supported_crop": False,
                    "error_type":     "INVALID_IMAGE",
                    "message":        "Image size is too large. Maximum allowed size is 10MB.",
                }
            )
        if len(contents) < 100:  # Suspiciously small — likely corrupt
            return JSONResponse(
                status_code=400,
                content={
                    "success":        False,
                    "valid_leaf":     False,
                    "supported_crop": False,
                    "error_type":     "INVALID_IMAGE",
                    "message":        "Image file is empty or corrupt. Please upload a valid leaf photo.",
                }
            )
        image = Image.open(io.BytesIO(contents))
        # Fix EXIF orientation (important for camera photos taken on mobile)
        image = _fix_image_orientation(image)
    except Exception as e:
        logger.error(f"Failed to decode uploaded image: {e}")
        return JSONResponse(
            status_code=400,
            content={
                "success":        False,
                "valid_leaf":     False,
                "supported_crop": False,
                "error_type":     "INVALID_IMAGE",
                "message":        "Invalid image file. Please upload a clear photo of a crop leaf.",
            }
        )

    # ── Stage 2: Input Quality & Leaf / Non-Leaf Validation ───────────────────
    is_valid, err_type, err_msg = validate_image_for_prediction(image)
    if not is_valid:
        logger.warning(
            f"[Predict] Image rejected by validator — error_type={err_type}, message={err_msg}"
        )
        return JSONResponse(
            status_code=422,
            content={
                "success":        False,
                "valid_leaf":     False,
                "supported_crop": False,
                "error_type":     err_type,
                "message":        err_msg,
            }
        )

    # ── Stage 3: Check Keras Model Availability ───────────────────────────────
    if not is_model_loaded():
        logger.error("[Predict] Model pipeline not loaded.")
        return JSONResponse(
            status_code=503,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": False,
                "error_type":     "MODEL_UNAVAILABLE",
                "message":        "The crop detection service is currently unavailable. Please try again shortly.",
            }
        )

    # ── Stage 4: Run Real TensorFlow Two-Stage Inference ─────────────────────
    result = predict(image)
    if result is None:
        return JSONResponse(
            status_code=500,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": False,
                "error_type":     "SERVER_ERROR",
                "message":        "Model inference failed unexpectedly. Please try again.",
            }
        )

    crop         = result.get("crop", "")
    disease      = result.get("disease", "")
    crop_conf    = result.get("crop_confidence", 0.0)
    disease_conf = result.get("disease_confidence", 0.0)

    # ── Stage 5: Supported Crop Validation ───────────────────────────────────
    if crop not in CROP_MODEL_CONFIG and crop not in SUPPORTED_CROPS:
        logger.warning(
            f"[Predict] Detected crop '{crop}' not in supported crop config."
        )
        return JSONResponse(
            status_code=422,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": False,
                "error_type":     "UNSUPPORTED_CROP",
                "message":        "This crop is not currently supported by AgroVision AI. Please upload a leaf from one of the supported crops.",
            }
        )

    # ── Stage 6: Crop Confidence Threshold ───────────────────────────────────
    if crop_conf < CROP_CONFIDENCE_THRESHOLD:
        logger.warning(
            f"[Predict] Low crop confidence: {crop} = {crop_conf:.1f}% "
            f"(threshold {CROP_CONFIDENCE_THRESHOLD}%)"
        )
        return JSONResponse(
            status_code=422,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": False,
                "error_type":     "LOW_CROP_CONFIDENCE",
                "message":        (
                    "Unable to identify the crop leaf confidently. "
                    "Please upload a clearer, closer photo of a single crop leaf."
                ),
            }
        )

    # ── Stage 6b: Sunflower Wheat-contamination Guard ─────────────────────────
    if crop == "Sunflower" and disease_conf == 0.0:
        logger.warning(
            "[WHEAT GUARD] Sunflower model predicted a Wheat-contaminated class."
        )
        return JSONResponse(
            status_code=422,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": True,
                "error_type":     "LOW_DISEASE_CONFIDENCE",
                "message":        (
                    "Unable to identify the Sunflower disease confidently. "
                    "Please upload a clearer Sunflower leaf image."
                ),
            }
        )

    # ── Stage 7: Disease Confidence Threshold ────────────────────────────────
    if disease_conf < DISEASE_CONFIDENCE_THRESHOLD:
        logger.warning(
            f"[Predict] Low disease confidence: {crop}->{disease} = "
            f"{disease_conf:.1f}% (threshold {DISEASE_CONFIDENCE_THRESHOLD}%)"
        )
        return JSONResponse(
            status_code=422,
            content={
                "success":        False,
                "valid_leaf":     True,
                "supported_crop": True,
                "error_type":     "LOW_DISEASE_CONFIDENCE",
                "message":        (
                    "Unable to identify the crop disease confidently. "
                    "Please upload a clearer, well-lit photo of a single leaf."
                ),
            }
        )

    # ── Stage 8: Enriched Recommendation Lookup ──────────────────────────────
    # IMPORTANT: No default fallback. If no recommendation exists, return null.
    # Never fabricate or substitute a different crop's recommendation.
    is_healthy = disease.lower() == "healthy"
    key = f"{crop}|{disease}"
    rec = RECOMMENDATION_DB.get(key)  # Returns None if no verified recommendation

    # Build backward-compatible fertilizer dict for existing Flutter parsing
    fertilizer_compat = _build_fertilizer_compat(rec) if rec else {}

    request_total_ms = int((time.time() - request_start) * 1000)
    logger.info(
        f"[Predict] [SUCCESS] crop={crop} ({crop_conf:.1f}%) | "
        f"disease={disease} ({disease_conf:.1f}%) | "
        f"healthy={is_healthy} | "
        f"recommendation={'found' if rec else 'not_found'} | "
        f"total_ms={request_total_ms}"
    )

    return JSONResponse(content={
        "success":            True,
        "status":             "success",
        "valid_leaf":         True,
        "supported_crop":     True,
        "healthy":            is_healthy,
        "crop":               {"name": crop,    "confidence": round(crop_conf    / 100.0, 4)},
        "disease":            {"name": disease, "confidence": round(disease_conf / 100.0, 4)},
        # Flat fields for full backward compatibility
        "crop_name":          crop,
        "crop_confidence":    crop_conf,
        "disease_name":       disease,
        "disease_confidence": disease_conf,
        "severity":           result.get("severity", "Medium" if not is_healthy else "None"),
        # Enriched recommendation object (new — used by new ResultScreen)
        "recommendation":     rec,
        # Backward-compatible fertilizer key (preserved for existing parsing)
        "fertilizer":         fertilizer_compat,
        "image_valid":        True,
        "model_version":      result.get("model_version", "v3.0 (Two-Stage ML Pipeline)"),
        "prediction_time_ms": result.get("prediction_time_ms", 0),
        "request_time_ms":    request_total_ms,
    })


def _fix_image_orientation(image: Image.Image) -> Image.Image:
    """
    Fix image EXIF orientation metadata.
    Mobile cameras often save rotated images with EXIF orientation tags.
    This corrects the rotation so inference receives the right-side-up image.
    """
    try:
        from PIL import ImageOps
        return ImageOps.exif_transpose(image)
    except Exception:
        return image
