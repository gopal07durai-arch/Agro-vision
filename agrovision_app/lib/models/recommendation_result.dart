// recommendation_result.dart
// ──────────────────────────
// Dart model for the enriched crop+disease recommendation returned by the backend.
// All fields are nullable — if a field is not in the verified database, it is null
// and the UI must display "Information not available" or hide the field entirely.
//
// IMPORTANT: The backend never fabricates dosage, safety notes, or product details.
// This model faithfully reflects that — null means "not in verified database".


// ─────────────────────────────────────────────────────────────────────────────
// FertilizerRecommendation — shown only when nutritional support is applicable
// ─────────────────────────────────────────────────────────────────────────────
class FertilizerRecommendation {
  final String name;
  final String productCategory;
  final String? npk;
  final String? primaryNutrient;
  final String? dosage;
  final String? dosageUnit;
  final String? applicationMethod;
  final String? growthStage;
  final String? frequency;
  final String? expectedBenefit;
  final String? source;

  const FertilizerRecommendation({
    required this.name,
    required this.productCategory,
    this.npk,
    this.primaryNutrient,
    this.dosage,
    this.dosageUnit,
    this.applicationMethod,
    this.growthStage,
    this.frequency,
    this.expectedBenefit,
    this.source,
  });

  factory FertilizerRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendation(
      name: json['name'] as String? ?? '',
      productCategory: json['product_category'] as String? ?? 'Fertilizer',
      npk: json['npk'] as String?,
      primaryNutrient: json['primary_nutrient'] as String?,
      dosage: json['dosage'] as String?,
      dosageUnit: json['dosage_unit'] as String?,
      applicationMethod: json['application_method'] as String?,
      growthStage: json['growth_stage'] as String?,
      frequency: json['frequency'] as String?,
      expectedBenefit: json['expected_benefit'] as String?,
      source: json['source'] as String?,
    );
  }

  bool get isAvailable => name.isNotEmpty;
}


// ─────────────────────────────────────────────────────────────────────────────
// RecommendationResult — the main enriched recommendation model
// ─────────────────────────────────────────────────────────────────────────────
class RecommendationResult {
  /// "Pest" | "Disease" | "Nutrient Deficiency" | "Healthy"
  final String? problemType;

  // ── Treatment product details ───────────────────────────────────────────────
  /// e.g. "Imidacloprid 17.8 SL"
  final String? productName;

  /// "Insecticide" | "Fungicide" | "Bactericide" | "Biological Control" |
  /// "Organic Treatment" | "Fertilizer" | "Nutrient Supplement" | "Preventive Treatment"
  final String? productCategory;

  /// Chemical or biological active ingredient
  final String? activeIngredient;

  /// Formulation code, e.g. "17.8 SL"
  final String? formulation;

  /// Plain-language purpose of the product
  final String? purpose;

  // ── Dosage ─────────────────────────────────────────────────────────────────
  /// Verified dosage value (numeric)
  final String? dosage;

  /// Unit for the dosage, e.g. "ml/L" or "kg/acre"
  final String? dosageUnit;

  // ── Application ────────────────────────────────────────────────────────────
  final String? applicationMethod;
  final String? applicationTiming;
  final String? frequency;
  final String? duration;

  // ── Safety ─────────────────────────────────────────────────────────────────
  final String? precautions;
  final String? safetyNotes;

  /// Days before harvest (or null if not applicable / not available)
  final String? harvestWaitingPeriod;

  // ── Alternatives & prevention ─────────────────────────────────────────────
  final String? organicAlternative;
  final String? prevention;

  // ── Source & verification ─────────────────────────────────────────────────
  final String? source;
  final String? lastVerified;
  final String? region;

  // ── Fertilizer section (optional — only when nutritional support applies) ──
  final FertilizerRecommendation? fertilizerSection;

  const RecommendationResult({
    this.problemType,
    this.productName,
    this.productCategory,
    this.activeIngredient,
    this.formulation,
    this.purpose,
    this.dosage,
    this.dosageUnit,
    this.applicationMethod,
    this.applicationTiming,
    this.frequency,
    this.duration,
    this.precautions,
    this.safetyNotes,
    this.harvestWaitingPeriod,
    this.organicAlternative,
    this.prevention,
    this.source,
    this.lastVerified,
    this.region,
    this.fertilizerSection,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    FertilizerRecommendation? fertSection;
    final rawFert = json['fertilizer'];
    if (rawFert != null && rawFert is Map<String, dynamic>) {
      fertSection = FertilizerRecommendation.fromJson(rawFert);
    }

    return RecommendationResult(
      problemType: json['problem_type'] as String?,
      productName: json['product_name'] as String?,
      productCategory: json['product_category'] as String?,
      activeIngredient: json['active_ingredient'] as String?,
      formulation: json['formulation'] as String?,
      purpose: json['purpose'] as String?,
      dosage: json['dosage'] as String?,
      dosageUnit: json['dosage_unit'] as String?,
      applicationMethod: json['application_method'] as String?,
      applicationTiming: json['application_timing'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      precautions: json['precautions'] as String?,
      safetyNotes: json['safety_notes'] as String?,
      harvestWaitingPeriod: json['harvest_waiting_period'] as String?,
      organicAlternative: json['organic_alternative'] as String?,
      prevention: json['prevention'] as String?,
      source: json['source'] as String?,
      lastVerified: json['last_verified'] as String?,
      region: json['region'] as String?,
      fertilizerSection: fertSection,
    );
  }

  /// True if there is a treatment product to show
  bool get hasTreatment =>
      productName != null && productName!.isNotEmpty && problemType != 'Healthy';

  /// True if a fertilizer/nutrient section should be shown
  bool get hasFertilizer =>
      fertilizerSection != null && fertilizerSection!.isAvailable;

  /// True if an organic alternative is available
  bool get hasOrganicAlternative =>
      organicAlternative != null && organicAlternative!.isNotEmpty;

  /// True if prevention advice is available
  bool get hasPrevention =>
      prevention != null && prevention!.isNotEmpty;

  /// True if safety notes are available
  bool get hasSafetyInfo =>
      (precautions != null && precautions!.isNotEmpty) ||
      (safetyNotes != null && safetyNotes!.isNotEmpty);

  /// Convenience: dosage with unit combined, or null
  String? get dosageFormatted {
    if (dosage == null) return null;
    if (dosageUnit != null && dosageUnit!.isNotEmpty) {
      return '$dosage $dosageUnit';
    }
    return dosage;
  }

  /// Display label for the product category badge
  String get categoryBadgeLabel => productCategory ?? 'Treatment';

  /// True if this recommendation came from verified DB
  bool get isFromVerifiedSource =>
      source != null && source!.isNotEmpty;

  /// True if this is a healthy crop (no disease treatment needed)
  bool get isHealthy => problemType == 'Healthy';
}
