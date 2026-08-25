/**
 * fertilizerService.ts
 * Returns disease-based fertilizer recommendations.
 * No NPK/soil input required — recommendations are derived from the
 * detected disease only.
 *
 * To add new crops/diseases: add entries to the FERTILIZER_DB object.
 * The UI will render them automatically without any code changes.
 */

import type { FertilizerRecommendation } from '../types';

// ─── Database ─────────────────────────────────────────────────────────────────
// Keys: "Crop|Disease" (case-sensitive, match labels.json)

type FertilizerDB = Record<string, FertilizerRecommendation[]>;

const FERTILIZER_DB: FertilizerDB = {

  // ─── HEALTHY (all crops) ──────────────────────────────────────────────────
  'default|Healthy': [
    {
      name: 'Azospirillum + PSB Mix',
      type: 'Bio',
      dosage: '2 kg per acre',
      applicationMethod: 'Mix with compost; apply near root zone',
      frequency: 'Once before sowing, repeat after 30 days',
      benefits: ['Fixes atmospheric nitrogen', 'Improves phosphorus availability', 'Enhances root growth', 'Boosts plant immunity'],
      precautions: ['Do not mix with chemical fungicides', 'Apply in the evening or early morning', 'Keep away from direct sunlight'],
      icon: '🌿',
    },
    {
      name: 'Mycorrhizal Inoculant',
      type: 'Bio',
      dosage: '1 kg per acre',
      applicationMethod: 'Seed treatment or soil drench near roots',
      frequency: 'Once per crop season',
      benefits: ['Extends root system', 'Improves water absorption', 'Reduces transplant shock', 'Increases nutrient uptake'],
      precautions: ['Store in cool dry place', 'Use within 6 months of manufacture'],
      icon: '🍄',
    },
  ],

  // ─── TOMATO ───────────────────────────────────────────────────────────────
  'Tomato|Early Blight': [
    {
      name: 'Trichoderma viride',
      type: 'Bio',
      dosage: '4–5 g per kg seed / 2.5 kg per acre (soil drench)',
      applicationMethod: 'Dissolve in water; drench soil around base of plant',
      frequency: 'At transplanting and repeat every 21 days during humid weather',
      benefits: ['Controls Alternaria solani (early blight fungus)', 'Improves plant immunity', 'Promotes healthy root development', 'Safe for beneficial insects'],
      precautions: ['Avoid use within 48 hours of chemical fungicides', 'Apply in evening', 'Do not use in standing water'],
      icon: '🛡️',
    },
    {
      name: 'Mancozeb 75WP',
      type: 'Chemical',
      dosage: '2.5 g per litre of water',
      applicationMethod: 'Foliar spray; cover both sides of leaves thoroughly',
      frequency: 'Every 10–14 days; stop 7 days before harvest',
      benefits: ['Broad-spectrum fungicide', 'Rapid disease control', 'Prevents spore germination'],
      precautions: ['Wear gloves and mask during application', 'Do not spray near water bodies', 'Rotate with other fungicides to prevent resistance'],
      icon: '⚗️',
    },
  ],

  'Tomato|Late Blight': [
    {
      name: 'Pseudomonas fluorescens',
      type: 'Bio',
      dosage: '2.5 kg per acre in 200 L water',
      applicationMethod: 'Foliar spray every 10 days from early disease onset',
      frequency: 'Every 10 days for 3 applications',
      benefits: ['Induces systemic resistance', 'Suppresses Phytophthora infestans', 'Environment-friendly', 'Compatible with organic farming'],
      precautions: ['Store below 25°C', 'Apply in early morning or evening', 'Do not mix with bactericides'],
      icon: '🦠',
    },
    {
      name: 'Metalaxyl + Mancozeb (Ridomil Gold)',
      type: 'Chemical',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray covering entire plant canopy',
      frequency: 'Every 7–10 days during heavy rainfall or high humidity',
      benefits: ['Systemic + contact action', 'Highly effective against late blight', 'Quick curative action'],
      precautions: ['Do not exceed 3 applications per season', 'PHI: 14 days before harvest', 'Use protective clothing'],
      icon: '⚗️',
    },
  ],

  'Tomato|Bacterial Spot': [
    {
      name: 'Copper Oxychloride 50WP',
      type: 'Chemical',
      dosage: '3 g per litre of water',
      applicationMethod: 'Foliar spray at first sign of symptoms',
      frequency: 'Every 7–10 days for 3 consecutive sprays',
      benefits: ['Effective against bacterial diseases', 'Protective action', 'Economical'],
      precautions: ['Avoid spraying during rain', 'Do not use in high temperatures (above 35°C)', 'PHI: 7 days'],
      icon: '🔵',
    },
    {
      name: 'Streptomycin Sulphate',
      type: 'Chemical',
      dosage: '1 g per litre of water (combine with copper)',
      applicationMethod: 'Mix with copper oxychloride and spray foliarly',
      frequency: 'Every 10 days, max 2 applications',
      benefits: ['Antibiotic action against bacteria', 'Rapid knockdown', 'Effective in wet conditions'],
      precautions: ['Use only when bacterial spot is confirmed', 'Avoid resistance build-up by limiting use', 'Wear full protection'],
      icon: '💊',
    },
  ],

  'Tomato|Leaf Mold': [
    {
      name: 'Neem Oil (3%)',
      type: 'Organic',
      dosage: '5 ml neem oil + 2 ml soap per litre water',
      applicationMethod: 'Foliar spray targeting undersides of leaves',
      frequency: 'Every 7 days for 4 weeks',
      benefits: ['Controls fungal pathogens', 'Repels whitefly (secondary vector)', 'Biodegradable and safe'],
      precautions: ['Apply early morning or evening', 'Shake well before use', 'Do not spray on flowering plants in strong sunlight'],
      icon: '🌿',
    },
  ],

  'Tomato|Septoria Leaf Spot': [
    {
      name: 'Chlorothalonil 75WP',
      type: 'Chemical',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray, starting at first symptom appearance',
      frequency: 'Every 7–10 days; max 4 applications per season',
      benefits: ['Preventive and curative action', 'Protects healthy tissue', 'Broad-spectrum fungicide'],
      precautions: ['PHI: 7 days', 'Wear gloves and mask', 'Rotate chemistry class to prevent resistance'],
      icon: '⚗️',
    },
  ],

  'Tomato|Spider Mites': [
    {
      name: 'Verticillium lecanii (Biopesticide)',
      type: 'Bio',
      dosage: '2.5 kg per acre in 200 L water',
      applicationMethod: 'Foliar spray targeting mite colonies on leaf undersides',
      frequency: 'Every 7 days for 3 applications',
      benefits: ['Myco-insecticide targets mites and whitefly', 'Safe for bees', 'No resistance development'],
      precautions: ['Apply in high humidity conditions (>80%)', 'Do not mix with fungicides', 'Use fresh preparation'],
      icon: '🕷️',
    },
    {
      name: 'Abamectin 1.8% EC',
      type: 'Chemical',
      dosage: '1.5 ml per litre of water',
      applicationMethod: 'High-volume spray targeting leaf undersides',
      frequency: 'Twice with 7-day interval',
      benefits: ['Highly effective miticide', 'Acts on nervous system of mites', 'Long residual activity'],
      precautions: ['Highly toxic to fish and bees — keep away from water', 'PHI: 7 days', 'Rotate with different MOA'],
      icon: '⚗️',
    },
  ],

  'Tomato|Yellow Leaf Curl Virus': [
    {
      name: 'Imidacloprid 17.8% SL (Vector Control)',
      type: 'Chemical',
      dosage: '0.5 ml per litre of water',
      applicationMethod: 'Foliar spray to control whitefly vector; soil drench for seedlings',
      frequency: 'At transplanting + 21 days later; repeat if whitefly pressure high',
      benefits: ['Controls whitefly (TYLCV vector)', 'Systemic action', 'Reduces virus spread'],
      precautions: ['Do not use near pollinator activity', 'PHI: 14 days', 'Remove severely infected plants'],
      icon: '🚫',
    },
    {
      name: 'Neem Seed Kernel Extract (NSKE 5%)',
      type: 'Organic',
      dosage: '50 g NSKE in 1 L water; filter and spray',
      applicationMethod: 'Foliar spray targeting whitefly adults and nymphs',
      frequency: 'Every 5–7 days during vector peak activity',
      benefits: ['Repels whitefly naturally', 'No chemical residues', 'Safe for humans and environment'],
      precautions: ['Prepare fresh; use within 8 hours', 'Apply in evening', 'Combine with yellow sticky traps'],
      icon: '🌿',
    },
  ],

  'Tomato|Mosaic Virus': [
    {
      name: 'Potassium Silicate (Si)',
      type: 'Organic',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray to strengthen cell walls',
      frequency: 'Weekly for 4 weeks after detection',
      benefits: ['Strengthens plant defense', 'Reduces viral symptom severity', 'Improves stress tolerance'],
      precautions: ['No direct cure for virus — management only', 'Remove heavily infected plants', 'Disinfect tools with 1% bleach'],
      icon: '💎',
    },
  ],

  'Tomato|Target Spot': [
    {
      name: 'Azoxystrobin 23% SC',
      type: 'Chemical',
      dosage: '1 ml per litre of water',
      applicationMethod: 'Foliar spray at disease onset',
      frequency: 'Every 14 days; max 3 applications',
      benefits: ['Systemic strobilurin fungicide', 'Prevents and cures target spot', 'Long protection duration'],
      precautions: ['Limit to 3 sprays to avoid resistance', 'PHI: 7 days', 'Do not apply during heat of day'],
      icon: '🎯',
    },
  ],

  // ─── PADDY / RICE ─────────────────────────────────────────────────────────
  'Paddy|Leaf Blight': [
    {
      name: 'Pseudomonas fluorescens',
      type: 'Bio',
      dosage: '2.5 kg per acre in 500 L water',
      applicationMethod: 'Foliar spray; wet all plant surfaces',
      frequency: 'At tillering and panicle initiation stages',
      benefits: ['Controls Xanthomonas oryzae (BLB bacteria)', 'Boosts systemic resistance', 'Safe for aquatic ecosystem'],
      precautions: ['Apply in morning', 'Do not mix with copper-based fungicides', 'Use fresh culture'],
      icon: '🌾',
    },
    {
      name: 'Validamycin 3% L',
      type: 'Chemical',
      dosage: '2 ml per litre of water',
      applicationMethod: 'Foliar spray ensuring good coverage of leaves',
      frequency: 'Twice at 10-day intervals from early infection',
      benefits: ['Systemic action', 'Very effective against BLB and sheath blight', 'Low mammalian toxicity'],
      precautions: ['Avoid spraying during flowering', 'PHI: 14 days', 'Apply in calm weather'],
      icon: '⚗️',
    },
  ],

  'Paddy|Leaf Blast': [
    {
      name: 'Tricyclazole 75WP',
      type: 'Chemical',
      dosage: '0.6 g per litre of water',
      applicationMethod: 'Foliar spray at first sign of blast lesions',
      frequency: 'Preventive: at tillering; Curative: repeat after 10 days',
      benefits: ['Highly specific blast fungicide', 'Melanin biosynthesis inhibitor', 'Long lasting protection'],
      precautions: ['Do not exceed 2 applications', 'PHI: 14 days', 'Wear full protective equipment'],
      icon: '💊',
    },
    {
      name: 'Isoprothiolane 40% EC',
      type: 'Chemical',
      dosage: '1.5 ml per litre of water',
      applicationMethod: 'Foliar spray or granule application in flood water',
      frequency: 'At booting stage and panicle emergence',
      benefits: ['Also controls sheath blight', 'Systemic activity', 'Enhances grain filling'],
      precautions: ['Do not drain water after granule application for 7 days', 'PHI: 21 days'],
      icon: '⚗️',
    },
  ],

  'Paddy|Brown Spot': [
    {
      name: 'Edifenphos (Hinosan) 50% EC',
      type: 'Chemical',
      dosage: '1 ml per litre of water',
      applicationMethod: 'Foliar spray at tillering and heading',
      frequency: 'Two sprays: at tillering and heading stages',
      benefits: ['Effective against Helminthosporium', 'Systemic action', 'Also suppresses blast'],
      precautions: ['PHI: 14 days', 'Highly toxic to fish — avoid aquatic contamination', 'Wear full protection'],
      icon: '⚗️',
    },
    {
      name: 'Potassium Silicate',
      type: 'Organic',
      dosage: '2 g per litre, as foliar spray',
      applicationMethod: 'Apply preventively to build cell-wall resistance',
      frequency: 'Monthly from 30 DAT',
      benefits: ['Strengthens leaf tissues', 'Reduces brown spot severity', 'Improves grain quality'],
      precautions: ['Do not mix with acidic solutions', 'Use silicon-deficient soil analysis to confirm need'],
      icon: '💎',
    },
  ],

  'Paddy|Sheath Blight': [
    {
      name: 'Trichoderma harzianum',
      type: 'Bio',
      dosage: '2.5 kg per acre mixed with 50 kg FYM',
      applicationMethod: 'Soil application near root zone before transplanting',
      frequency: 'One basal application + one at 30 DAT',
      benefits: ['Suppresses Rhizoctonia solani', 'Improves soil health', 'Reduces chemical dependency'],
      precautions: ['Do not use with chemical fungicides for 7 days', 'Keep in cool, dry storage'],
      icon: '🛡️',
    },
    {
      name: 'Hexaconazole 5% EC',
      type: 'Chemical',
      dosage: '2 ml per litre of water',
      applicationMethod: 'Foliar spray targeting leaf sheath (basal region)',
      frequency: 'At tillering and at panicle initiation (2 sprays)',
      benefits: ['Triazole fungicide; systemic action', 'Effective against sheath blight', 'Also controls false smut'],
      precautions: ['PHI: 14 days', 'Phytotoxic at high doses', 'Rotate with different chemistry'],
      icon: '⚗️',
    },
  ],

  // ─── WHEAT ────────────────────────────────────────────────────────────────
  'Wheat|Leaf Rust': [
    {
      name: 'Propiconazole 25% EC',
      type: 'Chemical',
      dosage: '1 ml per litre of water',
      applicationMethod: 'Foliar spray at first pustule appearance',
      frequency: 'Two sprays: at flag leaf emergence and heading',
      benefits: ['Triazole; systemic action against rusts', 'Prevents uredospore germination', 'Long-lasting protection'],
      precautions: ['PHI: 14 days', 'Do not apply at grain filling', 'Wear gloves and mask'],
      icon: '⚗️',
    },
  ],

  'Wheat|Loose Smut': [
    {
      name: 'Carboxin + Thiram (Vitavax Power)',
      type: 'Chemical',
      dosage: '2.5 g per kg seed',
      applicationMethod: 'Seed treatment before sowing',
      frequency: 'Once — at sowing time only',
      benefits: ['Kills Ustilago tritici in seed embryo', 'Systemic + contact action', 'Cost-effective prevention'],
      precautions: ['Treat seeds in shade', 'Do not consume treated seeds', 'Wash hands after handling'],
      icon: '🌱',
    },
  ],

  'Wheat|Crown Root Rot': [
    {
      name: 'Trichoderma viride + FYM',
      type: 'Bio',
      dosage: '2.5 kg Trichoderma per acre + 50 kg FYM',
      applicationMethod: 'Mix and apply in soil before sowing',
      frequency: 'One application before sowing; repeat at 30 DAS',
      benefits: ['Suppresses Fusarium and Bipolaris', 'Improves root health', 'Long-term soil health benefit'],
      precautions: ['Do not mix with chemical fungicides', 'Store in cool location'],
      icon: '🛡️',
    },
  ],

  // ─── SUGARCANE ────────────────────────────────────────────────────────────
  'Sugarcane|Red Rot': [
    {
      name: 'Carbendazim 50WP',
      type: 'Chemical',
      dosage: '1 g per litre; soak setts for 1 hour',
      applicationMethod: 'Sett treatment by soaking before planting',
      frequency: 'Once before planting; remove infected stalks immediately',
      benefits: ['Controls Colletotrichum falcatum', 'Systemic seed treatment', 'Prevents field spread'],
      precautions: ['Destroy infected ratoons', 'Do not plant infected material', 'PHI: 30 days in soil'],
      icon: '🔴',
    },
  ],

  'Sugarcane|Red Rust': [
    {
      name: 'Hexaconazole 5% SC',
      type: 'Chemical',
      dosage: '2 ml per litre of water',
      applicationMethod: 'Foliar spray at first rust pustule appearance',
      frequency: 'Two sprays: 10 days apart',
      benefits: ['Effective against Puccinia erianthi', 'Curative and preventive action', 'Good rainfastness'],
      precautions: ['Do not harvest for 14 days after spray', 'Use in calm, dry weather'],
      icon: '🟠',
    },
  ],

  // ─── COTTON ───────────────────────────────────────────────────────────────
  'Cotton|Bacterial Blight': [
    {
      name: 'Streptomycin + Copper Oxychloride',
      type: 'Chemical',
      dosage: 'Streptomycin 0.01% + Copper 0.3%',
      applicationMethod: 'Foliar spray beginning at boll formation',
      frequency: 'Every 10 days, max 3 sprays',
      benefits: ['Combined antibacterial action', 'Protects lint quality', 'Reduces angular leaf spot spread'],
      precautions: ['Limit streptomycin use to prevent resistance', 'Wear PPE', 'PHI: 14 days'],
      icon: '🌿',
    },
  ],

  'Cotton|Aphids': [
    {
      name: 'Chrysoperla carnea (Bioagent)',
      type: 'Bio',
      dosage: '50,000 eggs per acre',
      applicationMethod: 'Release in field during evening; target aphid colonies',
      frequency: 'Release twice — 10 days apart at aphid peak',
      benefits: ['Natural predator; no residues', 'Safe for all beneficial insects', 'Reduces chemical use'],
      precautions: ['Do not spray insecticides 7 days before or after release', 'Release in evening or early morning'],
      icon: '🦗',
    },
    {
      name: 'Imidacloprid 17.8% SL',
      type: 'Chemical',
      dosage: '0.5 ml per litre of water',
      applicationMethod: 'Foliar spray targeting aphid colonies on underside of leaves',
      frequency: 'Once; repeat if population rebounds after 14 days',
      benefits: ['Systemic neonicotinoid', 'Rapid knockdown', 'Long residual protection'],
      precautions: ['Restrict to 1 spray per season', 'Highly toxic to bees — avoid during flowering', 'PHI: 7 days'],
      icon: '⚗️',
    },
  ],

  'Cotton|Army Worm': [
    {
      name: 'Bacillus thuringiensis (Bt) 5% WP',
      type: 'Bio',
      dosage: '1.5 g per litre of water',
      applicationMethod: 'Foliar spray targeting young larvae; target leaf surface where feeding occurs',
      frequency: 'Every 5–7 days while infestation is active',
      benefits: ['Species-specific biopesticide', 'No resistance build-up', 'Safe for natural enemies'],
      precautions: ['Use fresh batch; check viability', 'Apply in morning or evening', 'Ineffective against large larvae'],
      icon: '🦋',
    },
  ],

  'Cotton|Target Spot': [
    {
      name: 'Fluxapyroxad 250 SC',
      type: 'Chemical',
      dosage: '0.5 ml per litre of water',
      applicationMethod: 'Foliar spray at boll formation stage',
      frequency: 'Two sprays: 14 days apart',
      benefits: ['SDHI fungicide; broad spectrum', 'Long protection period', 'Preserves yield potential'],
      precautions: ['PHI: 14 days', 'Rotate with non-SDHI chemistry', 'Wear full PPE'],
      icon: '🎯',
    },
  ],

  // ─── GROUNDNUT ────────────────────────────────────────────────────────────
  'Groundnut|Leaf Spot': [
    {
      name: 'Carbendazim 50WP',
      type: 'Chemical',
      dosage: '1 g per litre of water',
      applicationMethod: 'Foliar spray at 30 DAS and at podding stage',
      frequency: 'Every 21 days from pod formation',
      benefits: ['Controls Cercospora arachidicola', 'Systemic protection', 'Improves pod quality'],
      precautions: ['PHI: 7 days', 'Do not exceed 3 sprays', 'Wear gloves'],
      icon: '🥜',
    },
  ],

  'Groundnut|Late Leaf Spot': [
    {
      name: 'Chlorothalonil 75WP',
      type: 'Chemical',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray with even coverage on leaves',
      frequency: 'Every 10–14 days from 40 DAS',
      benefits: ['Broad-spectrum protective fungicide', 'Controls both early and late leaf spot', 'Economical'],
      precautions: ['PHI: 7 days', 'Wear mask — may cause respiratory irritation', 'Do not exceed 4 applications'],
      icon: '⚗️',
    },
  ],

  'Groundnut|Rust': [
    {
      name: 'Propiconazole 25% EC',
      type: 'Chemical',
      dosage: '1 ml per litre of water',
      applicationMethod: 'Foliar spray at first pustule appearance',
      frequency: 'Two sprays: 10–14 days apart',
      benefits: ['Systemic triazole', 'Highly effective against Puccinia arachidis', 'Improves pod yield'],
      precautions: ['PHI: 14 days', 'Use during dry weather', 'Rotate with mancozeb'],
      icon: '⚗️',
    },
  ],

  'Groundnut|Nutrition Deficiency': [
    {
      name: 'Micronutrient Mix (Fe, Zn, B)',
      type: 'Organic',
      dosage: '5 g per litre of water',
      applicationMethod: 'Foliar spray during early vegetative stage; ensure thorough leaf coverage',
      frequency: 'Every 14 days for 2 applications; repeat if yellowing persists',
      benefits: [
        'Corrects iron, zinc, and boron deficiencies',
        'Restores healthy green leaf colour within 7–10 days',
        'Improves pod fill and oil content',
        'Boosts photosynthesis efficiency',
      ],
      precautions: [
        'Apply in early morning or late evening',
        'Do not mix with phosphate-based fertilizers',
        'Use chelated micronutrient forms for better absorption',
        'Get soil test to confirm deficiency before applying',
      ],
      icon: '🌿',
    },
    {
      name: 'Ferrous Sulphate (FeSO₄)',
      type: 'Chemical',
      dosage: '5 g per litre of water for foliar spray; 25 kg per acre soil application',
      applicationMethod: 'Foliar spray for quick uptake; soil application for season-long correction',
      frequency: 'Foliar: twice at 15-day intervals; Soil: once before sowing',
      benefits: ['Corrects iron-deficiency chlorosis', 'Economical and widely available', 'Quick visual response'],
      precautions: ['Acidic; avoid contact with skin and eyes', 'Do not spray on hot sunny days', 'Mix with equal amount of lime for soil application'],
      icon: '⚗️',
    },
  ],

  // ─── SUNFLOWER ────────────────────────────────────────────────────────────

  'Sunflower|Downy Mildew': [
    {
      name: 'Metalaxyl 35% SD (Seed Treatment)',
      type: 'Chemical',
      dosage: '6 g per kg seed',
      applicationMethod: 'Dry seed treatment before sowing',
      frequency: 'Once at seed treatment stage',
      benefits: ['Prevents systemic downy mildew infection', 'Long-lasting seed protection', 'Cost-effective'],
      precautions: ['Do not consume treated seed', 'Apply in well-ventilated area'],
      icon: '🌻',
    },
    {
      name: 'Fosetyl-Al 80WP',
      type: 'Chemical',
      dosage: '2.5 g per litre of water',
      applicationMethod: 'Foliar spray at cotyledon and 4-leaf stage',
      frequency: 'Two sprays: 7–10 days apart',
      benefits: ['Systemic phosphonate; moves upward and downward', 'Effective against downy mildew in field'],
      precautions: ['PHI: 14 days', 'Rotate with different chemistry'],
      icon: '⚗️',
    },
  ],

  'Sunflower|Alternaria Leaf Spot': [
    {
      name: 'Mancozeb 75WP',
      type: 'Chemical',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray covering both sides of leaves',
      frequency: 'At bud initiation and at head formation; every 10–14 days',
      benefits: ['Multi-site fungicide; low resistance risk', 'Broad-spectrum protection', 'Economical'],
      precautions: ['PHI: 7 days', 'Wear mask — manganese toxicity concern at high doses'],
      icon: '⚗️',
    },
  ],

  // ─── EGGPLANT ─────────────────────────────────────────────────────────────
  'Eggplant|Wilt Disease': [
    {
      name: 'Trichoderma viride + Pseudomonas fluorescens',
      type: 'Bio',
      dosage: '2.5 kg each per acre in 50 kg compost',
      applicationMethod: 'Mix and apply in soil; drench root zone at transplanting',
      frequency: 'At transplanting + 21 DAS',
      benefits: ['Suppresses Fusarium and Ralstonia wilt', 'Improves soil microbial balance', 'Long-lasting effect'],
      precautions: ['Avoid use with chemical fungicides for 7 days', 'Remove wilted plants before application'],
      icon: '🍆',
    },
  ],

  'Eggplant|Leaf Spot': [
    {
      name: 'Copper Hydroxide 77WP',
      type: 'Chemical',
      dosage: '2.5 g per litre of water',
      applicationMethod: 'Foliar spray with good canopy coverage',
      frequency: 'Every 10 days during wet/rainy season',
      benefits: ['Broad-spectrum bactericide/fungicide', 'Protects from Cercospora leaf spot', 'Good rainfastness'],
      precautions: ['Phytotoxic in cool wet weather — test on few plants first', 'PHI: 7 days'],
      icon: '🔵',
    },
  ],

  'Eggplant|Mosaic Virus': [
    {
      name: 'Imidacloprid (Vector Control)',
      type: 'Chemical',
      dosage: '0.5 ml per litre of water',
      applicationMethod: 'Foliar spray targeting aphid/thrips vectors',
      frequency: 'At first vector detection; repeat after 14 days',
      benefits: ['Controls virus-spreading insects', 'Systemic protection', 'Reduces virus spread in field'],
      precautions: ['No direct cure for virus — vector management only', 'PHI: 7 days', 'Remove infected plants'],
      icon: '🔴',
    },
  ],

  // ─── BLACKGRAM ────────────────────────────────────────────────────────────
  'Blackgram|Yellow Mosaic': [
    {
      name: 'Thiamethoxam 25WG',
      type: 'Chemical',
      dosage: '0.5 g per litre of water (for whitefly vector control)',
      applicationMethod: 'Foliar spray targeting whitefly adults',
      frequency: 'Every 10 days; max 2 applications',
      benefits: ['Controls whitefly (YMIV vector)', 'Systemic and rapid action', 'Reduces further spread'],
      precautions: ['Remove and destroy infected plants', 'Use resistant varieties for next crop', 'PHI: 7 days'],
      icon: '🟡',
    },
  ],

  'Blackgram|Powdery Mildew': [
    {
      name: 'Sulphur 80WP (Wettable Sulphur)',
      type: 'Organic',
      dosage: '3 g per litre of water',
      applicationMethod: 'Foliar spray covering all plant surfaces',
      frequency: 'Every 7–10 days during dry weather; max 4 applications',
      benefits: ['Effective against powdery mildew', 'Organic approved', 'Also controls mites'],
      precautions: ['Do not spray in temperatures above 35°C — risk of phytotoxicity', 'PHI: 7 days'],
      icon: '⚪',
    },
  ],

  'Blackgram|Anthracnose': [
    {
      name: 'Carbendazim 50WP',
      type: 'Chemical',
      dosage: '1 g per litre of water',
      applicationMethod: 'Foliar spray at first anthracnose lesion appearance',
      frequency: 'Two sprays: 7–10 days apart',
      benefits: ['Systemic control of Colletotrichum', 'Protects pods and seeds', 'Fast acting'],
      precautions: ['PHI: 7 days', 'Rotate with mancozeb', 'Use disease-free seed for next season'],
      icon: '🫘',
    },
  ],

  // ─── TURMERIC ─────────────────────────────────────────────────────────────
  'Turmeric|Leaf Blotch': [
    {
      name: 'Mancozeb 75WP',
      type: 'Chemical',
      dosage: '2 g per litre of water',
      applicationMethod: 'Foliar spray covering all leaf surfaces',
      frequency: 'Every 21 days during growing season',
      benefits: ['Controls Taphrina maculans', 'Broad-spectrum protection', 'Economical'],
      precautions: ['PHI: 7 days', 'Wear mask', 'Do not spray near harvest'],
      icon: '🟡',
    },
  ],

  'Turmeric|Rhizome Disease': [
    {
      name: 'Trichoderma viride (Rhizome Treatment)',
      type: 'Bio',
      dosage: '4 g per kg rhizome + 10 g per kg soil',
      applicationMethod: 'Treat rhizomes before planting; mix in soil application',
      frequency: 'Once at planting; repeat soil drench at 30 DAP',
      benefits: ['Suppresses Pythium and Fusarium wilt', 'Improves rhizome quality', 'Sustainable solution'],
      precautions: ['Use fresh Trichoderma culture', 'Do not mix with chemical fungicides'],
      icon: '🛡️',
    },
    {
      name: 'Metalaxyl 35% SD',
      type: 'Chemical',
      dosage: '6 g per kg rhizome (seed treatment)',
      applicationMethod: 'Dust rhizomes before planting',
      frequency: 'Once at planting',
      benefits: ['Systemic fungicide; controls Pythium aphanidermatum', 'High efficacy against root rot'],
      precautions: ['Use only as seed treatment', 'Wear gloves', 'Store treated rhizomes separately'],
      icon: '⚗️',
    },
  ],
};

// ─── Lookup Function ──────────────────────────────────────────────────────────

/**
 * Get fertilizer recommendations for a detected crop + disease.
 * Falls back to generic biofertilizer if no specific entry exists.
 */
export function getFertilizerRecommendations(
  crop: string,
  disease: string
): FertilizerRecommendation[] {
  // Check exact crop+disease match
  const key = `${crop}|${disease}`;
  if (FERTILIZER_DB[key]) return FERTILIZER_DB[key];

  // Healthy crop fallback
  if (disease.toLowerCase() === 'healthy') {
    return FERTILIZER_DB['default|Healthy'];
  }

  // Partial disease name match within same crop
  const cropKey = Object.keys(FERTILIZER_DB).find(
    (k) => k.startsWith(`${crop}|`) && disease.toLowerCase().includes(k.split('|')[1].toLowerCase())
  );
  if (cropKey) return FERTILIZER_DB[cropKey];

  // Generic biofertilizer fallback
  return [
    {
      name: 'Trichoderma viride + Pseudomonas fluorescens',
      type: 'Bio',
      dosage: '2.5 kg each per acre',
      applicationMethod: 'Soil drench near root zone + foliar spray',
      frequency: 'Every 21 days during crop season',
      benefits: [
        `Controls fungal and bacterial pathogens causing ${disease}`,
        'Improves plant systemic resistance',
        'Promotes healthy root development',
        'Safe for environment and beneficial organisms',
      ],
      precautions: [
        'Do not mix with chemical fungicides within 48 hours',
        'Apply in early morning or evening',
        'Use fresh culture within validity period',
        'Store in cool, dry location away from sunlight',
      ],
      icon: '🛡️',
    },
    {
      name: 'Azospirillum + PSB Mix',
      type: 'Bio',
      dosage: '2 kg per acre',
      applicationMethod: 'Mix with compost; apply to soil around crop base',
      frequency: 'Once at planting + once at 30 days',
      benefits: ['Fixes nitrogen', 'Solubilizes phosphorus', 'Improves overall plant vigor'],
      precautions: ['Keep away from direct sunlight', 'Use within shelf life'],
      icon: '🌿',
    },
  ];
}
