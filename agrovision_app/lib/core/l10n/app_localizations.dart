// app_localizations.dart
// ─────────────────────────────────────────────────────────────────────────────
// Complete Multi-Language Localizations for AgroVision AI
// English (en), Tamil (ta), Hindi (hi), Telugu (te), Malayalam (ml)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/recommendation_result.dart';
import 'agricultural_localizations.dart';

class AppLocalizations {
  final String locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('en');
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<String> supportedLocales = ['en', 'ta', 'hi', 'ml'];

  // ── Translation lookup ──────────────────────────────────────────────────────
  String tr(String key) {
    final dict = _translations[locale] ?? _translations['en']!;
    return dict[key] ?? _translations['en']![key] ?? key;
  }

  // ── Common Getters ─────────────────────────────────────────────────────────
  String get appTitle => tr('app_title');
  String get appSubtitle => tr('app_subtitle');
  String get loading => tr('loading');
  String get retry => tr('retry');
  String get back => tr('back');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get openSettings => tr('open_settings');
  String get goBack => tr('go_back');
  String get refresh => tr('refresh');

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome => tr('nav_home');
  String get navScan => tr('nav_scan');
  String get navHistory => tr('nav_history');
  String get history => tr('nav_history');
  String get navAbout => tr('nav_about');
  String get about => tr('nav_about');
  String get settings => tr('settings');
  String get noScansYet => tr('no_scans_yet');
  String get noScansSubtitle => tr('no_scans_subtitle');

  // ── Home Screen ────────────────────────────────────────────────────────────
  String get heroTitle => tr('hero_title');
  String get heroSubtitle => tr('hero_subtitle');
  String get scanWithCamera => tr('scan_with_camera');
  String get uploadFromGallery => tr('upload_from_gallery');
  String get supportedCrops => tr('supported_crops');
  String get howItWorks => tr('how_it_works');
  String get quickTip => tr('quick_tip');
  String get quickTipDesc => tr('quick_tip_desc');
  String get recentScans => tr('recent_scans');
  String get viewAll => tr('view_all');
  String get aiPoweredAgriculture => tr('ai_powered_agriculture');
  String get cropDiseaseDetection => tr('crop_disease_detection');
  String get whatWeDetect => tr('what_we_detect');
  String get cropId => tr('crop_id');
  String get cropIdDesc => tr('crop_id_desc');
  String get diseaseTitle => tr('disease_title');
  String get diseaseDesc => tr('disease_desc');
  String get treatmentTitle => tr('treatment_title');
  String get treatmentDesc => tr('treatment_desc');

  // ── Scan Screen ────────────────────────────────────────────────────────────
  String get scanLeaf => tr('scan_leaf');
  String get takePhoto => tr('take_photo');
  String get selectPhoto => tr('select_photo');
  String get analyzeLeaf => tr('analyze_leaf');
  String get retake => tr('retake');
  String get preparingImage => tr('preparing_image');
  String get connectingServer => tr('connecting_server');
  String get sendingImage => tr('sending_image');
  String get identifyingCrop => tr('identifying_crop');
  String get savingResult => tr('saving_result');
  String get analysisComplete => tr('analysis_complete');
  String get tipsForBestResults => tr('tips_for_best_results');
  String get backendNotReachable => tr('backend_not_reachable');
  String get backendConnecting => tr('backend_connecting');
  String get backendOnline => tr('backend_online');
  String get backendOffline => tr('backend_offline');
  String get configuredUrl => tr('configured_url');
  String get readyToAnalyze => tr('ready_to_analyze');
  String get analyzingLeafDesc => tr('analyzing_leaf_desc');
  String get supportsFormats => tr('supports_formats');
  String get tipNaturalLighting => tr('tip_natural_lighting');
  String get tipSingleLeaf => tr('tip_single_leaf');
  String get tipHoldSteady => tr('tip_hold_steady');
  String get tipSupportedCrops => tr('tip_supported_crops');
  String get tipFillFrame => tr('tip_fill_frame');

  // ── Result & Recommendation Screen ─────────────────────────────────────────
  String get cropDetected => tr('crop_detected');
  String get problem => tr('problem');
  String get status => tr('status');
  String get healthyCropDetected => tr('healthy_crop_detected');
  String get diseasePestDetected => tr('disease_pest_detected');
  String get confidenceScores => tr('confidence_scores');
  String get cropConfidence => tr('crop_confidence');
  String get diseaseConfidence => tr('disease_confidence');
  String get recommendedTreatment => tr('recommended_treatment');
  String get whyThisRecommendation => tr('why_this_recommendation');
  String get treatmentRecommendation => tr('treatment_recommendation');
  String get activeIngredient => tr('active_ingredient');
  String get applicationDetails => tr('application_details');
  String get dosage => tr('dosage');
  String get application => tr('application');
  String get timing => tr('timing');
  String get frequency => tr('frequency');
  String get duration => tr('duration');
  String get howToApply => tr('how_to_apply');
  String get safetyPrecautions => tr('safety_precautions');
  String get tapToViewSafety => tr('tap_to_view_safety');
  String get preHarvestInterval => tr('pre_harvest_interval');
  String get fertilizerRecommendation => tr('fertilizer_recommendation');
  String get organicAlternative => tr('organic_alternative');
  String get prevention => tr('prevention');
  String get sourceVerification => tr('source_verification');
  String get rateAnalysis => tr('rate_analysis');
  String get rateSubtitle => tr('rate_subtitle');
  String get thankYouRating => tr('thank_you_rating');
  String get scanAgain => tr('scan_again');
  String get noRecommendationTitle => tr('no_recommendation_title');
  String get aiDisclaimer => tr('ai_disclaimer');
  String get precautionsLabel => tr('precautions_label');
  String get safetyNotesLabel => tr('safety_notes_label');
  String get organicDisclaimer => tr('organic_disclaimer');
  String get tapToViewOrganic => tr('tap_to_view_organic');
  String get tapToViewPrevention => tr('tap_to_view_prevention');
  String get sourceVerifiedNote => tr('source_verified_note');
  String get noRecDetail => tr('no_rec_detail');
  String get forManagement => tr('for_management');
  String get typeLabel => tr('type_label');
  String get whyCropIdentified => tr('why_crop_identified');
  String get whyProblemIdentified => tr('why_problem_identified');
  String get whyRecMatched => tr('why_rec_matched');
  String get whyVerifiedDb => tr('why_verified_db');

  // How to apply steps
  String get howToApplyStep1Title => tr('how_to_apply_step1_title');
  String get howToApplyStep1Desc => tr('how_to_apply_step1_desc');
  String get howToApplyStep2Title => tr('how_to_apply_step2_title');
  String get howToApplyStep2Desc => tr('how_to_apply_step2_desc');
  String get howToApplyStep3Title => tr('how_to_apply_step3_title');
  String get howToApplyStep3Desc => tr('how_to_apply_step3_desc');
  String get howToApplyStep4Title => tr('how_to_apply_step4_title');
  String get howToApplyStep4Desc => tr('how_to_apply_step4_desc');
  String get howToApplyStep5Title => tr('how_to_apply_step5_title');
  String get howToApplyStep5Desc => tr('how_to_apply_step5_desc');

  // Settings
  String get language => tr('language');
  String get appearance => tr('appearance');
  String get darkMode => tr('dark_mode');
  String get backendConnection => tr('backend_connection');
  String get serverUrl => tr('server_url');
  String get fastApiServerUrl => tr('fastapi_server_url');
  String get testConnection => tr('test_connection');
  String get testing => tr('testing');
  String get quickPresets => tr('quick_presets');
  String get enterValidUrl => tr('enter_valid_url');
  String get connectionSuccess => tr('connection_success');
  String get connectionFailure => tr('connection_failure');
  String get darkThemeEnabled => tr('dark_theme_enabled');
  String get lightThemeEnabled => tr('light_theme_enabled');
  String get appVersionFooter => tr('app_version_footer');

  // History & Errors
  String get confidenceTag => tr('confidence_tag');
  String get failedToLoadHistory => tr('failed_to_load_history');
  String get errInvalidImageTitle => tr('err_invalid_image_title');
  String get errLowQualityTitle => tr('err_low_quality_title');
  String get errLowCropTitle => tr('err_low_crop_title');
  String get errLowDiseaseTitle => tr('err_low_disease_title');
  String get errUnsupportedCropTitle => tr('err_unsupported_crop_title');
  String get errModelUnavailableTitle => tr('err_model_unavailable_title');
  String get errBackendStartingTitle => tr('err_backend_starting_title');
  String get errTimeoutTitle => tr('err_timeout_title');
  String get errAnalysisFailedTitle => tr('err_analysis_failed_title');

  // Splash & About
  String get featureCamera => tr('feature_camera');
  String get featureAiDetection => tr('feature_ai_detection');
  String get featureTreatment => tr('feature_treatment');
  String get versionLabel => tr('version_label');
  String get aboutCaptureTitle => tr('about_capture_title');
  String get aboutCaptureDesc => tr('about_capture_desc');
  String get aboutAiTitle => tr('about_ai_title');
  String get aboutAiDesc => tr('about_ai_desc');
  String get aboutPlanTitle => tr('about_plan_title');
  String get aboutPlanDesc => tr('about_plan_desc');
  String get mlModelSection => tr('ml_model_section');
  String get architectureLabel => tr('architecture_label');
  String get cropDetectionLabel => tr('crop_detection_label');
  String get diseaseDetectionLabel => tr('disease_detection_label');
  String get cropThresholdLabel => tr('crop_threshold_label');
  String get diseaseThresholdLabel => tr('disease_threshold_label');
  String get expertDisclaimer => tr('expert_disclaimer');

  // ── Agricultural Localization Delegation ───────────────────────────────────
  String cropName(String crop) => AgriculturalLocalizations.cropName(crop, locale);
  String diseaseName(String disease, [String? crop]) => AgriculturalLocalizations.diseaseName(disease, locale);
  String severityLabel(String severity) => AgriculturalLocalizations.severityLabel(severity, locale);
  String problemTypeLabel(String? type) => AgriculturalLocalizations.problemTypeLabel(type, locale);
  String productCategoryLabel(String? category) => AgriculturalLocalizations.productCategoryLabel(category, locale);
  String fertilizerName(String name) => AgriculturalLocalizations.fertilizerName(name, locale);

  RecommendationResult? getLocalizedRecommendation(String crop, String disease, RecommendationResult? original) {
    return AgriculturalLocalizations.getLocalizedRecommendation(crop, disease, original, locale);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Master Translations Dictionary
  // ───────────────────────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _translations = {
    // ── English ──────────────────────────────────────────────────────────────
    'en': {
      'app_title': 'AgroVision AI',
      'app_subtitle': 'Smart Crop Disease Detection Platform',
      'loading': 'Loading...',
      'retry': 'Retry',
      'back': 'Back',
      'cancel': 'Cancel',
      'save': 'Save',
      'open_settings': 'Open Settings',
      'go_back': 'Go Back',
      'refresh': 'Refresh',
      'nav_home': 'Home',
      'nav_scan': 'Scan',
      'nav_history': 'History',
      'nav_about': 'About',
      'settings': 'Settings',
      'hero_title': 'Protect Your Crops\nwith AI Detection',
      'hero_subtitle': 'Instant crop & disease identification with verified agricultural treatment recommendations.',
      'scan_with_camera': 'Scan Leaf with Camera',
      'upload_from_gallery': 'Upload from Gallery',
      'supported_crops': 'Supported Crops (10 Crops)',
      'how_it_works': 'How It Works',
      'quick_tip': 'Photo Quality Tip',
      'quick_tip_desc': 'Capture a clear, well-lit photo of a single leaf with the affected area in focus.',
      'recent_scans': 'Recent Scans',
      'view_all': 'View All',
      'ai_powered_agriculture': 'AI-Powered Agriculture',
      'crop_disease_detection': 'Crop Disease Detection',
      'what_we_detect': 'What We Detect',
      'crop_id': 'Crop ID',
      'crop_id_desc': '10 supported crops',
      'disease_title': 'Disease',
      'disease_desc': 'AI-powered detection',
      'treatment_title': 'Treatment',
      'treatment_desc': 'Targeted solutions',
      'scan_leaf': 'Scan Leaf',
      'take_photo': 'Take Photo',
      'select_photo': 'Select Photo',
      'analyze_leaf': 'Analyze Leaf',
      'retake': 'Retake',
      'preparing_image': 'Preparing image...',
      'connecting_server': 'Connecting to detection server...',
      'sending_image': 'Sending image for analysis...',
      'identifying_crop': 'Identifying crop and disease...',
      'saving_result': 'Saving result...',
      'analysis_complete': 'Analysis Complete',
      'tips_for_best_results': 'Tips for Best Results',
      'backend_not_reachable': 'Backend Not Reachable',
      'backend_connecting': 'Checking backend connection...',
      'backend_online': 'Backend Connected',
      'backend_offline': 'Backend Offline',
      'configured_url': 'Configured backend URL:',
      'ready_to_analyze': 'Ready to analyze',
      'analyzing_leaf_desc': 'Please wait while the AI analyzes your leaf',
      'supports_formats': 'Supports: JPG, PNG, WebP · Max size: 10 MB',
      'tip_natural_lighting': 'Use natural light or bright indoor lighting',
      'tip_single_leaf': 'Focus on a single leaf, close up',
      'tip_hold_steady': 'Hold steady to avoid blur',
      'tip_supported_crops': 'Only supported crop leaves are accepted',
      'tip_fill_frame': 'Fill the frame with the leaf — avoid background clutter',
      'crop_detected': 'CROP DETECTED',
      'problem': 'PROBLEM',
      'status': 'STATUS',
      'healthy_crop_detected': 'Healthy Crop Detected',
      'disease_pest_detected': 'Disease/Pest Detected',
      'confidence_scores': 'Confidence Scores',
      'crop_confidence': 'Crop Confidence',
      'disease_confidence': 'Disease Confidence',
      'recommended_treatment': 'Recommended Treatment',
      'why_this_recommendation': 'Why this recommendation?',
      'treatment_recommendation': 'Treatment Recommendation',
      'active_ingredient': 'Active Ingredient',
      'application_details': 'Application Details',
      'dosage': 'Dosage',
      'application': 'Application',
      'timing': 'Timing',
      'frequency': 'Frequency',
      'duration': 'Duration',
      'how_to_apply': 'How to Apply',
      'safety_precautions': 'Safety & Precautions',
      'tap_to_view_safety': 'Tap to view safety information and precautions.',
      'pre_harvest_interval': 'Pre-Harvest Interval',
      'fertilizer_recommendation': 'Fertilizer & Nutrient Recommendation',
      'organic_alternative': 'Organic / Biological Alternative',
      'prevention': 'Prevention',
      'source_verification': 'Source & Verification',
      'rate_analysis': 'Rate this analysis',
      'rate_subtitle': 'Your feedback helps improve AgroVision AI',
      'thank_you_rating': 'Thank you for your rating!',
      'scan_again': 'Scan Again',
      'no_recommendation_title': 'No Verified Recommendation Available',
      'ai_disclaimer': 'This is an AI-based identification. Recommendations are suggested treatments from verified agricultural sources (TNAU/ICAR). Always verify with local agricultural officers before application.',
      'precautions_label': 'Precautions',
      'safety_notes_label': 'Safety Notes',
      'organic_disclaimer': 'Organic options may require more frequent applications. Verify suitability with your local agricultural officer.',
      'tap_to_view_organic': 'Tap to view organic or biological alternative option.',
      'tap_to_view_prevention': 'Tap to view crop-specific prevention measures.',
      'source_verified_note': 'Recommendations are sourced from verified agricultural databases (TNAU, ICAR). Always verify with your local agricultural extension officer and the product label before application.',
      'no_rec_detail': 'No verified treatment recommendation is available in our current database. Please consult your local agricultural extension officer or Tamil Nadu Agricultural University (TNAU) for guidance.',
      'for_management': 'For: {0} management',
      'type_label': 'Type',
      'why_crop_identified': '✓ Crop identified as {0}',
      'why_problem_identified': '✓ Problem identified as {0}',
      'why_rec_matched': '✓ Recommendation matched to {0} + {1}',
      'why_verified_db': '✓ Selected from verified agricultural database',
      'how_to_apply_step1_title': 'Prepare',
      'how_to_apply_step1_desc': 'Put on protective gloves, goggles, and mask before handling any product.',
      'how_to_apply_step2_title': 'Measure',
      'how_to_apply_step2_desc': 'Measure the exact verified dosage. Never exceed the recommended concentration.',
      'how_to_apply_step3_title': 'Apply',
      'how_to_apply_step3_desc': 'Apply as directed — foliar spray, soil drench, or seed treatment per the instructions.',
      'how_to_apply_step4_title': 'Monitor',
      'how_to_apply_step4_desc': 'Observe plants 3–5 days after application for response and re-check pest/disease levels.',
      'how_to_apply_step5_title': 'Repeat',
      'how_to_apply_step5_desc': 'Repeat only according to the verified frequency. Do not apply more frequently than recommended.',
      'language': 'Language',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'backend_connection': 'Backend Connection',
      'server_url': 'Server URL',
      'fastapi_server_url': 'FastAPI Server URL',
      'test_connection': 'Test Connection',
      'testing': 'Testing...',
      'quick_presets': 'Quick Presets:',
      'enter_valid_url': 'Please enter a valid URL',
      'connection_success': 'Connected! Cloud backend is online & ready.',
      'connection_failure': 'Cannot reach server. Please check your internet connection and try again.',
      'dark_theme_enabled': 'Dark theme enabled',
      'light_theme_enabled': 'Light theme enabled',
      'app_version_footer': 'AgroVision AI v1.0.0\nPowered by Two-Stage ML Pipeline',
      'no_scans_yet': 'No scans yet',
      'no_scans_subtitle': 'Your scan history will appear here after you analyze your first leaf.',
      'confidence_tag': '% confidence',
      'failed_to_load_history': 'Failed to load history',
      'err_invalid_image_title': 'Invalid Image',
      'err_low_quality_title': 'Image Quality Too Low',
      'err_low_crop_title': 'Cannot Identify Crop',
      'err_low_disease_title': 'Cannot Identify Disease',
      'err_unsupported_crop_title': 'Unsupported Crop',
      'err_model_unavailable_title': 'Service Unavailable',
      'err_backend_starting_title': 'Server Starting Up',
      'err_timeout_title': 'Server Slow to Respond',
      'err_analysis_failed_title': 'Analysis Failed',
      'feature_camera': 'Camera',
      'feature_ai_detection': 'AI Detection',
      'feature_treatment': 'Treatment',
      'version_label': 'Version 1.0.0',
      'about_capture_title': 'Capture or Upload',
      'about_capture_desc': 'Take a photo with your camera or upload from gallery',
      'about_ai_title': 'AI Analysis',
      'about_ai_desc': 'Two-stage ML pipeline identifies crop and disease',
      'about_plan_title': 'Get Treatment Plan',
      'about_plan_desc': 'Receive targeted fertilizer recommendations instantly',
      'ml_model_section': 'ML Model',
      'architecture_label': 'Two-Stage Keras CNN',
      'crop_detection_label': 'Stage 1 (Crop Classifier)',
      'disease_detection_label': 'Stage 2 (Disease Sub-models)',
      'crop_threshold_label': '65% confidence',
      'disease_threshold_label': '50% confidence',
      'expert_disclaimer': 'This AI tool provides guidance only. Always consult a certified agricultural expert before applying any treatment.',
    },

    // ── Tamil தமிழ் ────────────────────────────────────────────────────────
    'ta': {
      'app_title': 'அக்ரோவிஷன் AI',
      'app_subtitle': 'ஸ்மார்ட் பயிர் நோய் கண்டறிதல் தளம்',
      'loading': 'ஏற்றுகிறது...',
      'retry': 'மீண்டும் முயற்சி',
      'back': 'பின்னால்',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'open_settings': 'அமைப்புகளைத் திற',
      'go_back': 'திரும்பிச் செல்',
      'refresh': 'புதுப்பி',
      'nav_home': 'முகப்பு',
      'nav_scan': 'ஸ்கேன்',
      'nav_history': 'வரலாறு',
      'nav_about': 'பற்றி',
      'settings': 'அமைப்புகள்',
      'hero_title': 'AI தொழில்நுட்பத்தால்\nபயிர்களைப் பாதுகாப்போம்',
      'hero_subtitle': 'உடனடி பயிர் நோய் கண்டறிதல் மற்றும் சரிபார்க்கப்பட்ட விவசாய சிகிச்சை பரிந்துரைகள்.',
      'scan_with_camera': 'கேமரா மூலம் இலை ஸ்கேன்',
      'upload_from_gallery': 'கேலரியிலிருந்து பதிவேற்று',
      'supported_crops': 'ஆதரிக்கப்படும் பயிர்கள் (10 பயிர்கள்)',
      'how_it_works': 'எவ்வாறு செயல்படுகிறது',
      'quick_tip': 'புகைப்பட உதவிக்குறிப்பு',
      'quick_tip_desc': 'நல்ல வெளிச்சத்தில் பாதிக்கப்பட்ட இலையைத் தெளிவாகப் படம் எடுக்கவும்.',
      'recent_scans': 'சமீபத்திய ஸ்கேன்கள்',
      'view_all': 'அனைத்தையும் பார்',
      'ai_powered_agriculture': 'AI விவசாய நுண்ணறிவு',
      'crop_disease_detection': 'பயிர் நோய் கண்டறிதல் தளம்',
      'what_we_detect': 'நாங்கள் கண்டறிவது',
      'crop_id': 'பயிர் அடையாளம்',
      'crop_id_desc': '10 ஆதரிக்கப்படும் பயிர்கள்',
      'disease_title': 'நோய் கண்டறிதல்',
      'disease_desc': 'AI மாதிரி பகுப்பாய்வு',
      'treatment_title': 'சிகிச்சை & உரம்',
      'treatment_desc': 'இலக்கு வைக்கப்பட்ட தீர்வுகள்',
      'scan_leaf': 'இலையை ஸ்கேன் செய்',
      'take_photo': 'புகைப்படம் எடு',
      'select_photo': 'புகைப்படம் தேர்ந்தெடு',
      'analyze_leaf': 'பகுப்பாய்வு செய்',
      'retake': 'மீண்டும் எடு',
      'preparing_image': 'படம் தயாராகிறது...',
      'connecting_server': 'சேவையகத்துடன் இணைகிறது...',
      'sending_image': 'பகுப்பாய்வுக்கு அனுப்புகிறது...',
      'identifying_crop': 'பயிர் மற்றும் நோயை அடையாளம் காண்கிறது...',
      'saving_result': 'முடிவுகளைச் சேமிக்கிறது...',
      'analysis_complete': 'பகுப்பாய்வு முடிந்தது',
      'tips_for_best_results': 'சிறந்த முடிவுகளுக்கான குறிப்புகள்',
      'backend_not_reachable': 'சேவையகம் இணைக்கப்படவில்லை',
      'backend_connecting': 'இணைப்பைச் சரிபார்க்கிறது...',
      'backend_online': 'சேவையகம் இணைக்கப்பட்டது',
      'backend_offline': 'சேவையகம் ஆஃப்லைன்',
      'configured_url': 'அமைக்கப்பட்ட சர்வர் முகவரி:',
      'ready_to_analyze': 'பகுப்பாய்வுக்குத் தயார்',
      'analyzing_leaf_desc': 'AI உங்கள் இலையை பகுப்பாய்வு செய்யும் வரை காத்திருக்கவும்',
      'supports_formats': 'ஆதரிக்கப்படும் வடிவங்கள்: JPG, PNG, WebP · அதிகபட்சம் 10 MB',
      'tip_natural_lighting': 'நல்ல இயற்கை வெளிச்சம் அல்லது பிரகாசமான வெளிச்சத்தைப் பயன்படுத்தவும்',
      'tip_single_leaf': 'ஒரே ஒரு இலையை அருகில் கவனம் செலுத்தவும்',
      'tip_hold_steady': 'மங்கலாகாமல் இருக்க கேமராவை நிலையாகப் பிடிக்கவும்',
      'tip_supported_crops': 'ஆதரிக்கப்படும் பயிர் இலைகள் மட்டுமே ஏற்கப்படும்',
      'tip_fill_frame': 'இலையை சட்டகத்திற்குள் முழுமையாக வைக்கவும் — பின்புலக் குழப்பங்களைத் தவிர்க்கவும்',
      'crop_detected': 'கண்டறியப்பட்ட பயிர்',
      'problem': 'பிரச்சனை / நோய்',
      'status': 'நிலை',
      'healthy_crop_detected': 'ஆரோக்கியமான பயிர்',
      'disease_pest_detected': 'நோய் / பூச்சி கண்டறியப்பட்டது',
      'confidence_scores': 'நம்பகத்தன்மை மதிப்பெண்கள்',
      'crop_confidence': 'பயிர் நம்பகத்தன்மை',
      'disease_confidence': 'நோய் நம்பகத்தன்மை',
      'recommended_treatment': 'பரிந்துரைக்கப்பட்ட சிகிச்சை',
      'why_this_recommendation': 'ஏன் இந்த பரிந்துரை?',
      'treatment_recommendation': 'சிகிச்சை பரிந்துரை',
      'active_ingredient': 'செயலில் உள்ள மூலப்பொருள்',
      'application_details': 'பயன்பாட்டு விவரங்கள்',
      'dosage': 'மருந்தின் அளவு',
      'application': 'பயன்பாட்டு முறை',
      'timing': 'பயன்படுத்தும் நேரம்',
      'frequency': 'பயன்பாட்டு இடைவெளி',
      'duration': 'கால அளவு',
      'how_to_apply': 'பயன்படுத்துவது எப்படி',
      'safety_precautions': 'பாதுகாப்பு & முன்னெச்சரிக்கைகள்',
      'tap_to_view_safety': 'பாதுகாப்புத் தகவல்களைப் பார்க்க தட்டவும்.',
      'pre_harvest_interval': 'அறுவடைக்கு முந்தைய இடைவெளி',
      'fertilizer_recommendation': 'உர மற்றும் ஊட்டச்சத்து பரிந்துரை',
      'organic_alternative': 'இயற்கை / உயிரியல் மாற்று',
      'prevention': 'தடுப்பு முறைகள்',
      'source_verification': 'மூலம் & சரிபார்ப்பு',
      'rate_analysis': 'இந்த பகுப்பாய்வை மதிப்பிடுங்கள்',
      'rate_subtitle': 'உங்கள் கருத்து அக்ரோவிஷன் AI-ஐ மேம்படுத்த உதவுகிறது',
      'thank_you_rating': 'உங்கள் மதிப்பீட்டிற்கு நன்றி!',
      'scan_again': 'மீண்டும் ஸ்கேன் செய்',
      'no_recommendation_title': 'சரிபார்க்கப்பட்ட பரிந்துரை கிடைக்கவில்லை',
      'ai_disclaimer': 'இது AI அடிப்படையிலான கண்டறிதல். TNAU/ICAR சரிபார்க்கப்பட்ட விவசாய பரிந்துரைகள். பயன்பாட்டிற்கு முன் வேளாண் அதிகாரியிடம் உறுதிப்படுத்தவும்.',
      'precautions_label': 'முன்னெச்சரிக்கைகள்',
      'safety_notes_label': 'பாதுகாப்பு குறிப்புகள்',
      'organic_disclaimer': 'இயற்கை முறைகளுக்கு அடிக்கடி தெளிக்க வேண்டியிருக்கலாம். உங்கள் உள்ளூர் வேளாண் அதிகாரியிடம் உறுதிப்படுத்தவும்.',
      'tap_to_view_organic': 'இயற்கை அல்லது உயிரியல் மாற்று விருப்பத்தைப் பார்க்க தட்டவும்.',
      'tap_to_view_prevention': 'பயிர் சார்ந்த தடுப்பு நடவடிக்கைகளைப் பார்க்க தட்டவும்.',
      'source_verified_note': 'பரிந்துரைகள் சரிபார்க்கப்பட்ட வேளாண் தரவுத்தளங்களிலிருந்து (TNAU, ICAR) பெறப்பட்டவை. பயன்பாட்டிற்கு முன் உள்ளூர் வேளாண் அலுவலரிடம் உறுதிப்படுத்தவும்.',
      'no_rec_detail': 'தற்போதைய தரவுத்தளத்தில் இந்த பயிர் மற்றும் நோய்க்கான பரிந்துரை கிடைக்கவில்லை. வழிகாட்டுதலுக்கு உள்ளூர் வேளாண் அதிகாரி அல்லது தமிழ்நாடு வேளாண்மைப் பல்கலைக்கழகத்தை (TNAU) அணுகவும்.',
      'for_management': 'நோக்கம்: {0} மேலாண்மை',
      'type_label': 'வகை',
      'why_crop_identified': '✓ பயிர் அடையாளம்: {0}',
      'why_problem_identified': '✓ பிரச்சனை அடையாளம்: {0}',
      'why_rec_matched': '✓ பரிந்துரை பொருத்தம்: {0} + {1}',
      'why_verified_db': '✓ சரிபார்க்கப்பட்ட வேளாண் தரவுத்தளத்திலிருந்து தேர்வு செய்யப்பட்டது',
      'how_to_apply_step1_title': 'தயார் செய்தல்',
      'how_to_apply_step1_desc': 'எந்தவொரு தயாரிப்பையும் கையாளும் முன் பாதுகாப்பு கையுறைகள், முகக்கவசம் அணியவும்.',
      'how_to_apply_step2_title': 'அளவிடுதல்',
      'how_to_apply_step2_desc': 'பரிந்துரைக்கப்பட்ட சரியான அளவை அளவிடவும். பரிந்துரைக்கப்பட்ட செறிவை விட அதிகமாக பயன்படுத்த வேண்டாம்.',
      'how_to_apply_step3_title': 'பயன்படுத்துதல்',
      'how_to_apply_step3_desc': 'வழிகாட்டலின்படி இலைவழித் தெளிப்பு, மண் நனைத்தல் அல்லது விதை நேர்த்தி செய்யவும்.',
      'how_to_apply_step4_title': 'கண்காணித்தல்',
      'how_to_apply_step4_desc': 'பயன்படுத்திய 3–5 நாட்களுக்குப் பிறகு பயிரின் வளர்ச்சியை கவனித்து நோய் நிலையைக் கண்காணிக்கவும்.',
      'how_to_apply_step5_title': 'மீண்டும் செய்தல்',
      'how_to_apply_step5_desc': 'பரிந்துரைக்கப்பட்ட கால இடைவெளியில் மட்டுமே மீண்டும் பயன்படுத்தவும்.',
      'language': 'மொழி (Language)',
      'appearance': 'தோற்றம்',
      'dark_mode': 'டார்க் பயன்முறை',
      'backend_connection': 'சேவையக இணைப்பு',
      'server_url': 'சர்வர் URL',
      'fastapi_server_url': 'FastAPI சர்வர் URL',
      'test_connection': 'இணைப்பைச் சோதிக்கவும்',
      'testing': 'சோதிக்கிறது...',
      'quick_presets': 'விரைவு முன்னமைவுகள்:',
      'enter_valid_url': 'சரியான URL ஐ உள்ளிடவும்',
      'connection_success': 'இணைக்கப்பட்டது! கிளவுட் சேவையகம் இயங்குகிறது & தயார்.',
      'connection_failure': 'சேவையகத்தை அணுக முடியவில்லை. உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
      'dark_theme_enabled': 'டார்க் பயன்முறை இயக்கப்பட்டது',
      'light_theme_enabled': 'லைட் பயன்முறை இயக்கப்பட்டது',
      'app_version_footer': 'அக்ரோவிஷன் AI v1.0.0\nஇரு-நிலை ML மாதிரி மூலம் இயக்கப்படுகிறது',
      'no_scans_yet': 'இன்னும் ஸ்கேன்கள் இல்லை',
      'no_scans_subtitle': 'உங்கள் முதல் இலையை ஆய்வு செய்த பிறகு ஸ்கேன் வரலாறு இங்கே தோன்றும்.',
      'confidence_tag': '% நம்பகத்தன்மை',
      'failed_to_load_history': 'வரலாற்றை ஏற்ற முடியவில்லை',
      'err_invalid_image_title': 'தவறான படம்',
      'err_low_quality_title': 'படத்தின் தரம் மிகவும் குறைவு',
      'err_low_crop_title': 'பயிரை அடையாளம் காண முடியவில்லை',
      'err_low_disease_title': 'நோயை அடையாளம் காண முடியவில்லை',
      'err_unsupported_crop_title': 'ஆதரிக்கப்படாத பயிர்',
      'err_model_unavailable_title': 'சேவை கிடைக்கவில்லை',
      'err_backend_starting_title': 'சேவையகம் தொடங்குகிறது',
      'err_timeout_title': 'சேவையகம் பதிலளிக்க தாமதமாகிறது',
      'err_analysis_failed_title': 'பகுப்பாய்வு தோல்வியடைந்தது',
      'feature_camera': 'கேமரா',
      'feature_ai_detection': 'AI கண்டறிதல்',
      'feature_treatment': 'சிகிச்சை',
      'version_label': 'பதிப்பு 1.0.0',
      'about_capture_title': 'படம் எடு அல்லது பதிவேற்று',
      'about_capture_desc': 'கேமராவில் படம் எடுக்கவும் அல்லது கேலரியிலிருந்து பதிவேற்றவும்',
      'about_ai_title': 'AI பகுப்பாய்வு',
      'about_ai_desc': 'இரு-நிலை ML மாதிரி பயிர் மற்றும் நோயை அடையாளம் காண்கிறது',
      'about_plan_title': 'சிகிச்சை திட்டம் பெறுங்கள்',
      'about_plan_desc': 'துல்லியமான உர மற்றும் சிகிச்சை பரிந்துரைகளை உடனடியாகப் பெறுங்கள்',
      'ml_model_section': 'ML மாதிரி தகவல்',
      'architecture_label': 'இரு-நிலை Keras CNN',
      'crop_detection_label': 'நிலை 1 (பயிர் வகைப்படுத்தி)',
      'disease_detection_label': 'நிலை 2 (நோய் மாதிரி)',
      'crop_threshold_label': '65% நம்பகத்தன்மை வரம்பு',
      'disease_threshold_label': '50% நம்பகத்தன்மை வரம்பு',
      'expert_disclaimer': 'இந்த AI கருவி வழிகாட்டுதலை மட்டுமே வழங்குகிறது. எந்தவொரு சிகிச்சையையும் பயன்படுத்துவதற்கு முன்பு சான்றளிக்கப்பட்ட வேளாண் நிபுணரை அணுகவும்.',
    },

    // ── Hindi हिन्दी ───────────────────────────────────────────────────────
    'hi': {
      'app_title': 'एग्रोविजन AI',
      'app_subtitle': 'स्मार्ट फसल रोग पहचान मंच',
      'loading': 'लोड हो रहा है...',
      'retry': 'पुनः प्रयास करें',
      'back': 'वापस',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'open_settings': 'सेटिंग्स खोलें',
      'go_back': 'वापस जाएं',
      'refresh': 'रिफ्रेश करें',
      'nav_home': 'होम',
      'nav_scan': 'स्कैन',
      'nav_history': 'इतिहास',
      'nav_about': 'के बारे में',
      'settings': 'सेटिंग्स',
      'hero_title': 'AI से करें अपनी फसलों की सुरक्षा',
      'hero_subtitle': 'सटीक फसल रोग पहचान और प्रमाणित कृषि उपचार सिफारिशें।',
      'scan_with_camera': 'कैमरे से पत्ती स्कैन करें',
      'upload_from_gallery': 'गैलरी से अपलोड करें',
      'supported_crops': 'समर्थित फसलें (10 फसलें)',
      'how_it_works': 'यह कैसे काम करता है',
      'quick_tip': 'फोटो गुणवत्ता टिप',
      'quick_tip_desc': 'अच्छी रोशनी में संक्रमित पत्ती की स्पष्ट फोटो लें।',
      'recent_scans': 'हालिया स्कैन',
      'view_all': 'सभी देखें',
      'ai_powered_agriculture': 'AI-संचालित कृषि',
      'crop_disease_detection': 'फसल रोग पहचान मंच',
      'what_we_detect': 'हम क्या पहचानते हैं',
      'crop_id': 'फसल पहचान',
      'crop_id_desc': '10 समर्थित फसलें',
      'disease_title': 'रोग पहचान',
      'disease_desc': 'AI-संचालित जांच',
      'treatment_title': 'उपचार एवं पोषण',
      'treatment_desc': 'सटीक समाधान',
      'scan_leaf': 'पत्ती स्कैन करें',
      'take_photo': 'फोटो लें',
      'select_photo': 'फोटो चुनें',
      'analyze_leaf': 'विश्लेषण करें',
      'retake': 'दोबारा लें',
      'preparing_image': 'छवि तैयार हो रही है...',
      'connecting_server': 'सर्वर से कनेक्ट हो रहा है...',
      'sending_image': 'विश्लेषण के लिए भेज रहे हैं...',
      'identifying_crop': 'फसल और रोग की पहचान हो रही है...',
      'saving_result': 'परिणाम सहेजा जा रहा है...',
      'analysis_complete': 'विश्लेषण पूर्ण',
      'tips_for_best_results': 'सर्वोत्तम परिणामों के लिए सुझाव',
      'backend_not_reachable': 'सर्वर से कनेक्ट नहीं हो सका',
      'backend_connecting': 'कनेक्शन जाँचा जा रहा है...',
      'backend_online': 'सर्वर कनेक्टेड',
      'backend_offline': 'सर्वर ऑफ़लाइन',
      'configured_url': 'कॉन्फ़िगर किया गया URL:',
      'ready_to_analyze': 'विश्लेषण के लिए तैयार',
      'analyzing_leaf_desc': 'कृपया प्रतीक्षा करें जब तक AI आपकी पत्ती का विश्लेषण करता है',
      'supports_formats': 'समर्थित: JPG, PNG, WebP · अधिकतम आकार: 10 MB',
      'tip_natural_lighting': 'प्राकृतिक रोशनी या उज्ज्वल इनडोर प्रकाश का उपयोग करें',
      'tip_single_leaf': 'एकल पत्ती पर करीब से ध्यान केंद्रित करें',
      'tip_hold_steady': 'धुंधलापन से बचने के लिए कैमरे को स्थिर रखें',
      'tip_supported_crops': 'केवल समर्थित फसल की पत्तियां ही स्वीकार की जाती हैं',
      'tip_fill_frame': 'पत्ती से फ्रेम को भरें — पृष्ठभूमि की अव्यवस्था से बचें',
      'crop_detected': 'पहचानी गई फसल',
      'problem': 'समस्या / रोग',
      'status': 'स्थिति',
      'healthy_crop_detected': 'स्वस्थ फसल पाई गई',
      'disease_pest_detected': 'रोग या कीट की पहचान',
      'confidence_scores': 'सटीकता स्कोर',
      'crop_confidence': 'फसल सटीकता',
      'disease_confidence': 'रोग सटीकता',
      'recommended_treatment': 'अनुशंसित उपचार',
      'why_this_recommendation': 'यह सिफारिश क्यों?',
      'treatment_recommendation': 'उपचार सिफारिश',
      'active_ingredient': 'सक्रिय घटक',
      'application_details': 'उपयोग का विवरण',
      'dosage': 'मात्रा / खुराक',
      'application': 'प्रयोग विधि',
      'timing': 'समय',
      'frequency': 'आवृत्ति',
      'duration': 'अवधि',
      'how_to_apply': 'कैसे उपयोग करें',
      'safety_precautions': 'सुरक्षा और सावधानियां',
      'tap_to_view_safety': 'सुरक्षा जानकारी देखने के लिए टैप करें।',
      'pre_harvest_interval': 'कटाई पूर्व प्रतीक्षा अवधि',
      'fertilizer_recommendation': 'उर्वरक एवं पोषक तत्व सिफारिश',
      'organic_alternative': 'जैविक / प्राकृतिक विकल्प',
      'prevention': 'रोकथाम के उपाय',
      'source_verification': 'स्रोत और सत्यापन',
      'rate_analysis': 'इस विश्लेषण को रेट करें',
      'rate_subtitle': 'आपकी प्रतिक्रिया एग्रोविजन AI को बेहतर बनाती है',
      'thank_you_rating': 'आपकी रेटिंग के लिए धन्यवाद!',
      'scan_again': 'फिर से स्कैन करें',
      'no_recommendation_title': 'प्रमाणित सिफारिश उपलब्ध नहीं है',
      'ai_disclaimer': 'यह AI आधारित पहचान है। ICAR/कृषि विश्वविद्यालय प्रमाणित सुझाव। उपयोग से पहले स्थानीय कृषि अधिकारी से सलाह लें।',
      'precautions_label': 'सावधानियां',
      'safety_notes_label': 'सुरक्षा नोट्स',
      'organic_disclaimer': 'जैविक विकल्पों को अधिक बार छिड़कने की आवश्यकता हो सकती है। अपने स्थानीय कृषि अधिकारी से पुष्टि करें।',
      'tap_to_view_organic': 'जैविक या प्राकृतिक विकल्प देखने के लिए टैप करें।',
      'tap_to_view_prevention': 'फसल विशिष्ट रोकथाम के उपाय देखने के लिए टैप करें।',
      'source_verified_note': 'सिफारिशें प्रमाणित कृषि डेटाबेस (TNAU, ICAR) से प्राप्त की गई हैं। उपयोग से पहले अपने स्थानीय कृषि विस्तार अधिकारी से परामर्श लें।',
      'no_rec_detail': 'हमारे वर्तमान डेटाबेस में कोई सत्यापित उपचार सिफारिश उपलब्ध नहीं है। मार्गदर्शन के लिए कृपया अपने स्थानीय कृषि अधिकारी से संपर्क करें।',
      'for_management': 'उद्देश्य: {0} प्रबंधन',
      'type_label': 'प्रकार',
      'why_crop_identified': '✓ फसल पहचान: {0}',
      'why_problem_identified': '✓ समस्या पहचान: {0}',
      'why_rec_matched': '✓ सिफारिश मिलान: {0} + {1}',
      'why_verified_db': '✓ प्रमाणित कृषि डेटाबेस से चयनित',
      'how_to_apply_step1_title': 'तैयारी',
      'how_to_apply_step1_desc': 'किसी भी उत्पाद को संभालने से पहले सुरक्षा दस्ताने, चश्मा और मास्क पहनें।',
      'how_to_apply_step2_title': 'मापन',
      'how_to_apply_step2_desc': 'सटीक सत्यापित खुराक मापें। अनुशंसित सांद्रता से अधिक का उपयोग कभी न करें।',
      'how_to_apply_step3_title': 'छिड़काव / प्रयोग',
      'how_to_apply_step3_desc': 'निर्देशानुसार पर्ण स्प्रे, मिट्टी भिगोना या बीज उपचार के रूप में लागू करें।',
      'how_to_apply_step4_title': 'निगरानी',
      'how_to_apply_step4_desc': 'प्रयोग के 3-5 दिन बाद पौधों की प्रतिक्रिया देखें और कीट/रोग के स्तर की पुनः जांच करें।',
      'how_to_apply_step5_title': 'दोहराना',
      'how_to_apply_step5_desc': 'केवल सत्यापित आवृत्ति के अनुसार दोहराएं। अनुशंसित से अधिक बार प्रयोग न करें।',
      'language': 'भाषा (Language)',
      'appearance': 'दिखावट',
      'dark_mode': 'डार्क मोड',
      'backend_connection': 'सर्वर कनेक्शन',
      'server_url': 'सर्वर URL',
      'fastapi_server_url': 'FastAPI सर्वर URL',
      'test_connection': 'कनेक्शन जांचें',
      'testing': 'जांच जारी है...',
      'quick_presets': 'त्वरित प्रीसेट:',
      'enter_valid_url': 'कृपया एक मान्य URL दर्ज करें',
      'connection_success': 'कनेक्टेड! क्लाउड बैकएंड ऑनलाइन और तैयार है।',
      'connection_failure': 'सर्वर तक पहुंच संभव नहीं है। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।',
      'dark_theme_enabled': 'डार्क थीम सक्षम',
      'light_theme_enabled': 'लाइट थीम सक्षम',
      'app_version_footer': 'एग्रोविजन AI v1.0.0 — द्वि-स्तरीय ML मॉडल द्वारा संचालित',
      'no_scans_yet': 'अभी कोई स्कैन नहीं',
      'no_scans_subtitle': 'पहली पत्ती का विश्लेषण करने के बाद आपका स्कैन इतिहास यहाँ दिखाई देगा।',
      'confidence_tag': '% सटीकता',
      'failed_to_load_history': 'इतिहास लोड करने में विफल',
      'err_invalid_image_title': 'अमान्य छवि',
      'err_low_quality_title': 'छवि की गुणवत्ता बहुत कम है',
      'err_low_crop_title': 'फसल की पहचान नहीं हो सकी',
      'err_low_disease_title': 'रोग की पहचान नहीं हो सकी',
      'err_unsupported_crop_title': 'असमर्थित फसल',
      'err_model_unavailable_title': 'सेवा अनुपलब्ध है',
      'err_backend_starting_title': 'सर्वर शुरू हो रहा है',
      'err_timeout_title': 'सर्वर ने जवाब देने में बहुत अधिक समय लिया',
      'err_analysis_failed_title': 'विश्लेषण विफल रहा',
      'feature_camera': 'कैमरा',
      'feature_ai_detection': 'AI पहचान',
      'feature_treatment': 'उपचार',
      'version_label': 'संस्करण 1.0.0',
      'about_capture_title': 'फोटो लें या अपलोड करें',
      'about_capture_desc': 'अपने कैमरे से फोटो लें या गैलरी से अपलोड करें',
      'about_ai_title': 'AI विश्लेषण',
      'about_ai_desc': 'द्वि-स्तरीय ML मॉडल फसल और रोग की पहचान करता है',
      'about_plan_title': 'उपचार योजना प्राप्त करें',
      'about_plan_desc': 'सटीक उर्वरक और उपचार सिफारिशें तुरंत प्राप्त करें',
      'ml_model_section': 'ML मॉडल जानकारी',
      'architecture_label': 'द्वि-स्तरीय Keras CNN',
      'crop_detection_label': 'चरण 1 (फसल क्लासिफायर)',
      'disease_detection_label': 'चरण 2 (रोग सब-मॉडल)',
      'crop_threshold_label': '65% सटीकता सीमा',
      'disease_threshold_label': '50% सटीकता सीमा',
      'expert_disclaimer': 'यह AI उपकरण केवल मार्गदर्शन प्रदान करता है। किसी भी उपचार को लागू करने से पहले हमेशा एक प्रमाणित कृषि विशेषज्ञ से परामर्श करें।',
    },

    // ── Malayalam മലയാളം ───────────────────────────────────────────────────
    'ml': {
      'app_title': 'അഗ്രോവിഷൻ AI',
      'app_subtitle': 'സ്മാർട്ട് വിള രോഗ നിർണയ പ്ലാറ്റ്‌ഫോം',
      'loading': 'ലോഡ് ചെയ്യുന്നു...',
      'retry': 'വീണ്ടും ശ്രമിക്കുക',
      'back': 'തിരികെ',
      'cancel': 'റദ്ദാക്കുക',
      'save': 'സംരക്ഷിക്കുക',
      'open_settings': 'ക്രമീകരണങ്ങൾ തുറക്കുക',
      'go_back': 'പിന്നോട്ട് പോകുക',
      'refresh': 'റിഫ്രഷ് ചെയ്യുക',
      'nav_home': 'ഹോം',
      'nav_scan': 'സ്കാൻ',
      'nav_history': 'ചരിത്രം',
      'nav_about': 'കുറിച്ച്',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'hero_title': 'AI ഉപയോഗിച്ച് വിളകളെ സംരക്ഷിക്കാം',
      'hero_subtitle': 'തൽക്ഷണ വിള രോഗ കണ്ടെത്തലും പരിശോധിച്ച കാർഷിക ചികിത്സാ ശുപാർശകളും.',
      'scan_with_camera': 'ക്യാമറയിൽ ഇല സ്കാൻ ചെയ്യുക',
      'upload_from_gallery': 'ഗ്യാലറിയിൽ നിന്ന് അപ്‌ലോഡ് ചെയ്യുക',
      'supported_crops': 'പിന്തുണയ്ക്കുന്ന വിളകൾ (10 വിളകൾ)',
      'how_it_works': 'ഇത് എങ്ങനെ പ്രവർത്തിക്കുന്നു',
      'quick_tip': 'ഫോട്ടോ എടുക്കുന്നതിനുള്ള ടിപ്പ്',
      'quick_tip_desc': 'നല്ല വെളിച്ചത്തിൽ രോഗം ബാധിച്ച ഇലയുടെ വ്യക്തമായ ഫോട്ടോ എടുക്കുക.',
      'recent_scans': 'സമീപകാല സ്കാനുകൾ',
      'view_all': 'എല്ലാം കാണുക',
      'ai_powered_agriculture': 'AI-അധിഷ്ഠിത കൃഷി',
      'crop_disease_detection': 'വിള രോഗ നിർണയ പ്ലാറ്റ്‌ഫോം',
      'what_we_detect': 'ഞങ്ങൾ കണ്ടെത്തുന്നത്',
      'crop_id': 'വിള തിരിച്ചറിയൽ',
      'crop_id_desc': '10 പിന്തുണയ്ക്കുന്ന വിളകൾ',
      'disease_title': 'രോഗ നിർണയം',
      'disease_desc': 'AI പരിശോധന',
      'treatment_title': 'ചികിത്സ & വളം',
      'treatment_desc': 'ലക്ഷ്യബോധമുള്ള പരിഹാരങ്ങൾ',
      'scan_leaf': 'ഇല സ്കാൻ ചെയ്യുക',
      'take_photo': 'ഫോട്ടോ എടുക്കുക',
      'select_photo': 'ഫോട്ടോ തിരഞ്ഞെടുക്കുക',
      'analyze_leaf': 'വിശകലനം ചെയ്യുക',
      'retake': 'വീണ്ടും എടുക്കുക',
      'preparing_image': 'ചിത്രം തയ്യാറാക്കുന്നു...',
      'connecting_server': 'സെർവറുമായി ബന്ധിപ്പിക്കുന്നു...',
      'sending_image': 'വിശകലനത്തിനായി അയക്കുന്നു...',
      'identifying_crop': 'വിളയും രോഗവും തിരിച്ചറിയുന്നു...',
      'saving_result': 'ഫലങ്ങൾ സംരക്ഷിക്കുന്നു...',
      'analysis_complete': 'വിശകലനം പൂർത്തിയായി',
      'tips_for_best_results': 'മികച്ച ഫലങ്ങൾക്കുള്ള നുറുങ്ങുകൾ',
      'backend_not_reachable': 'സെർവറുമായി ബന്ധപ്പെടാൻ കഴിഞ്ഞില്ല',
      'backend_connecting': 'കണക്ഷൻ പരിശോധിക്കുന്നു...',
      'backend_online': 'സെർവർ കണക്റ്റ് ചെയ്തു',
      'backend_offline': 'സെർവർ ഓഫ്‌ലൈൻ',
      'configured_url': 'ക്രമീകരിച്ച URL:',
      'ready_to_analyze': 'വിശകലനത്തിന് തയ്യാറാണ്',
      'analyzing_leaf_desc': 'AI നിങ്ങളുടെ ഇല വിശകലനം ചെയ്യുന്നതുവരെ ദയവായി കാത്തിരിക്കുക',
      'supports_formats': 'പിന്തുണയ്ക്കുന്നത്: JPG, PNG, WebP · പരമാവധി വലിപ്പം: 10 MB',
      'tip_natural_lighting': 'നല്ല പ്രകൃതിദത്ത വെളിച്ചം അല്ലെങ്കിൽ തെളിഞ്ഞ വെളിച്ചം ഉപയോഗിക്കുക',
      'tip_single_leaf': 'ഒരു ഇലയിൽ മാത്രം ശ്രദ്ധ കേന്ദ്രീകരിക്കുക',
      'tip_hold_steady': 'വ്യക്തതയ്ക്കായി ക്യാമറ ഇളകാതെ പിടിക്കുക',
      'tip_supported_crops': 'പിന്തുണയ്ക്കുന്ന വിളകളുടെ ഇലകൾ മാത്രമേ സ്വീകരിക്കുകയുള്ളൂ',
      'tip_fill_frame': 'ഫ്രെയിമിൽ ഇല പൂർണ്ണമായി ഉൾക്കൊള്ളിക്കുക',
      'crop_detected': 'കണ്ടെത്തിയ വിള',
      'problem': 'പ്രശ്നം / രോഗം',
      'status': 'സ്ഥിതി',
      'healthy_crop_detected': 'ആരോഗ്യമുള്ള വിള',
      'disease_pest_detected': 'രോഗം / കീടബാധ കണ്ടെത്തി',
      'confidence_scores': 'കൃത്യതാ സ്കോർ',
      'crop_confidence': 'വിള കൃത്യത',
      'disease_confidence': 'രോഗ കൃത്യത',
      'recommended_treatment': 'ശുപാർശ ചെയ്ത ചികിത്സ',
      'why_this_recommendation': 'എന്തുകൊണ്ട് ഈ ശുപാർശ?',
      'treatment_recommendation': 'ചികിത്സാ ശുപാർശ',
      'active_ingredient': 'സജീവ ഘടകം',
      'application_details': 'ഉപയോഗ വിവരങ്ങൾ',
      'dosage': 'അളവ് / ഡോസ്',
      'application': 'പ്രയോഗ രീതി',
      'timing': 'സമയം',
      'frequency': 'ആവൃത്തി',
      'duration': 'കാലാവധി',
      'how_to_apply': 'എങ്ങനെ പ്രയോഗിക്കാം',
      'safety_precautions': 'സുരക്ഷാ മുൻകരുതലുകൾ',
      'tap_to_view_safety': 'സുരക്ഷാ വിവരങ്ങൾ കാണാൻ ടാപ്പ് ചെയ്യുക.',
      'pre_harvest_interval': 'വിളവെടുപ്പിന് മുമ്പുള്ള കാത്തിരിപ്പ് സമയം',
      'fertilizer_recommendation': 'വളവും പോഷകങ്ങളും ശുപാർശ',
      'organic_alternative': 'ജൈവ / പ്രകൃതിദത്ത ബദൽ',
      'prevention': 'പ്രതിരോധ മാർഗ്ഗങ്ങൾ',
      'source_verification': 'ഉറവിടവും പരിശോധനയും',
      'rate_analysis': 'ഈ വിശകലനം വിലയിരുത്തുക',
      'rate_subtitle': 'നിങ്ങളുടെ അഭിപ്രായം അഗ്രോവിഷൻ AI മെച്ചപ്പെടുത്താൻ സഹായിക്കുന്നു',
      'thank_you_rating': 'നിങ്ങളുടെ റേറ്റിംഗിന് നന്ദി!',
      'scan_again': 'വീണ്ടും സ്കാൻ ചെയ്യുക',
      'no_recommendation_title': 'പരിശോധിച്ച ശുപാർശ ലഭ്യമല്ല',
      'ai_disclaimer': 'ഇത് AI അടിസ്ഥാനമാക്കിയുള്ള കണ്ടെത്തലാണ്. കാർഷിക സർവകലാശാല അംഗീകരിച്ച ശുപാർശകൾ. ഉപയോഗിക്കുന്നതിന് മുൻപ് കൃഷി ഓഫീസറുമായി ബന്ധപ്പെടുക.',
      'precautions_label': 'മുൻകരുതലുകൾ',
      'safety_notes_label': 'സുരക്ഷാ കുറിപ്പുകൾ',
      'organic_disclaimer': 'ജൈവ രീതികൾ കൂടുതൽ തവണ പ്രയോഗിക്കേണ്ടി വന്നേക്കാം. നിങ്ങളുടെ പ്രാദേശിക കൃഷി ഓഫീസറുമായി ബന്ധപ്പെടുക.',
      'tap_to_view_organic': 'ജൈവ അല്ലെങ്കിൽ പ്രകൃതിദത്ത ബദൽ ഓപ്ഷൻ കാണാൻ ടാപ്പ് ചെയ്യുക.',
      'tap_to_view_prevention': 'വിളയ്ക്ക് അനുയോജ്യമായ പ്രതിരോധ നടപടികൾ കാണാൻ ടാപ്പ് ചെയ്യുക.',
      'source_verified_note': 'ശുപാർശകൾ പരിശോധിച്ച കാർഷിക ഡാറ്റാബേസുകളിൽ (TNAU, ICAR) നിന്നുള്ളതാണ്. ഉപയോഗിക്കുന്നതിന് മുൻപ് പ്രാദേശിക കൃഷി ഓഫീസറുമായി സ്ഥിരീകരിക്കുക.',
      'no_rec_detail': 'നിലവിലെ ഡാറ്റാബേസിൽ പരിശോധിച്ച ചികിത്സാ ശുപാർശ ലഭ്യമല്ല. മാർഗ്ഗനിർദ്ദേശത്തിനായി പ്രാദേശിക കൃഷി ഓഫീസറെ സമീപിക്കുക.',
      'for_management': 'ലക്ഷ്യം: {0} പരിപാലനം',
      'type_label': 'തരം',
      'why_crop_identified': '✓ വിള തിരിച്ചറിഞ്ഞു: {0}',
      'why_problem_identified': '✓ പ്രശ്നം തിരിച്ചറിഞ്ഞു: {0}',
      'why_rec_matched': '✓ ശുപാർശ യോജിച്ചത്: {0} + {1}',
      'why_verified_db': '✓ പരിശോധിച്ച കാർഷിക ഡാറ്റാബേസിൽ നിന്ന് തിരഞ്ഞെടുത്തു',
      'how_to_apply_step1_title': 'തയ്യാറാക്കുക',
      'how_to_apply_step1_desc': 'ഉൽപ്പന്നങ്ങൾ കൈകാര്യം ചെയ്യുന്നതിന് മുൻപ് സുരക്ഷാ കയ്യുറകൾ, കണ്ണട, മാസ്ക് എന്നിവ ധരിക്കുക.',
      'how_to_apply_step2_title': 'അളക്കുക',
      'how_to_apply_step2_desc': 'കൃത്യമായ ഡോസ് അളക്കുക. നിർദ്ദേശിച്ച അളവിൽ കൂടുതൽ ഒരിക്കലും ഉപയോഗിക്കരുത്.',
      'how_to_apply_step3_title': 'പ്രയോഗിക്കുക',
      'how_to_apply_step3_desc': 'നിർദ്ദേശിച്ചതുപോലെ ഇലകളിൽ തളിക്കുകയോ മണ്ണിൽ ഒഴിക്കുകയോ വിത്ത് പരിചരണം നടത്തുകയോ ചെയ്യുക.',
      'how_to_apply_step4_title': 'നിരീക്ഷിക്കുക',
      'how_to_apply_step4_desc': 'പ്രയോഗിച്ച് 3-5 ദിവസങ്ങൾക്ക് ശേഷം ചെടികളുടെ പ്രതികരണം നിരീക്ഷിച്ച് രോഗാവസ്ഥ വിലയിരുത്തുക.',
      'how_to_apply_step5_title': 'ആവർത്തിക്കുക',
      'how_to_apply_step5_desc': 'ശുപാർശ ചെയ്ത ഇടവേളകളിൽ മാത്രം ആവർത്തിക്കുക.',
      'language': 'ഭാഷ (Language)',
      'appearance': 'രൂപഭാവം',
      'dark_mode': 'ഡാർക്ക് മോഡ്',
      'backend_connection': 'സെർവർ കണക്ഷൻ',
      'server_url': 'സെർവർ URL',
      'fastapi_server_url': 'FastAPI സെർവർ URL',
      'test_connection': 'കണക്ഷൻ പരിശോധിക്കുക',
      'testing': 'പരിശോധിക്കുന്നു...',
      'quick_presets': 'ദ്രുത പ്രീസെറ്റുകൾ:',
      'enter_valid_url': 'സാധുവായ ഒരു URL നൽകുക',
      'connection_success': 'കണക്റ്റ് ചെയ്തു! ക്ലൗഡ് ബാക്കെൻഡ് ഓൺലൈനും തയ്യാറുമാണ്.',
      'connection_failure': 'സെർവറിൽ എത്താൻ കഴിഞ്ഞില്ല. ദയവായി നിങ്ങളുടെ ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.',
      'dark_theme_enabled': 'ഡാർക്ക് തീം പ്രവർത്തനക്ഷമമാക്കി',
      'light_theme_enabled': 'ലൈറ്റ് തീം പ്രവർത്തനക്ഷമമാക്കി',
      'app_version_footer': 'അഗ്രോവിഷൻ AI v1.0.0 — ടു-സ്റ്റേജ് ML മോഡൽ നൽകുന്ന കരുത്ത്',
      'no_scans_yet': 'ഇതുവരെ സ്കാനുകൾ ഇല്ല',
      'no_scans_subtitle': 'നിങ്ങളുടെ ആദ്യത്തെ ഇല വിശകലനം ചെയ്ത ശേഷം നിങ്ങളുടെ സ്കാൻ ചരിത്രം ഇവിടെ കാണാം.',
      'confidence_tag': '% കൃത്യത',
      'failed_to_load_history': 'ചരിത്രം ലോഡ് ചെയ്യാൻ കഴിഞ്ഞില്ല',
      'err_invalid_image_title': 'അസാധുവായ ചിത്രം',
      'err_low_quality_title': 'ചിത്രത്തിന്റെ ഗുണനിലവാരം വളരെ കുറവാണ്',
      'err_low_crop_title': 'വിള തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല',
      'err_low_disease_title': 'രോഗം തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല',
      'err_unsupported_crop_title': 'പിന്തുണയ്ക്കാത്ത വിള',
      'err_model_unavailable_title': 'സേവനം ലഭ്യമല്ല',
      'err_backend_starting_title': 'സെർവർ ആരംഭിക്കുന്നു',
      'err_timeout_title': 'സെർവർ പ്രതികരിക്കാൻ കൂടുതൽ സമയമെടുത്തു',
      'err_analysis_failed_title': 'വിശകലനം പരാജയപ്പെട്ടു',
      'feature_camera': 'ക്യാമറ',
      'feature_ai_detection': 'AI കണ്ടെത്തൽ',
      'feature_treatment': 'ചികിത്സ',
      'version_label': 'പതിപ്പ് 1.0.0',
      'about_capture_title': 'ഫോട്ടോ എടുക്കുക അല്ലെങ്കിൽ അപ്‌ലോഡ് ചെയ്യുക',
      'about_capture_desc': 'ക്യാമറയിൽ ഫോട്ടോ എടുക്കുക അല്ലെങ്കിൽ ഗ്യാലറിയിൽ നിന്ന് അപ്‌ലോഡ് ചെയ്യുക',
      'about_ai_title': 'AI വിശകലനം',
      'about_ai_desc': 'ടു-സ്റ്റേജ് ML മോഡൽ വിളയും രോഗവും തിരിച്ചറിയുന്നു',
      'about_plan_title': 'ചികിത്സാ പദ്ധതി നേടുക',
      'about_plan_desc': 'കൃത്യമായ വളവും ചികിത്സാ ശുപാർശകളും ഉടനടി നേടുക',
      'ml_model_section': 'ML മോഡൽ വിവരങ്ങൾ',
      'architecture_label': 'ടു-സ്റ്റേജ് Keras CNN',
      'crop_detection_label': 'ഘട്ടം 1 (വിള തിരിച്ചറിയൽ)',
      'disease_detection_label': 'ഘട്ടം 2 (രോഗ മോഡലുകൾ)',
      'crop_threshold_label': '65% കൃത്യതാ പരിധി',
      'disease_threshold_label': '50% കൃത്യതാ പരിധി',
      'expert_disclaimer': 'ഈ AI ടൂൾ ഒരു വഴികാട്ടി മാത്രമാണ്. ഏതെങ്കിലും ചികിത്സ പ്രയോഗിക്കുന്നതിന് മുൻപ് സാക്ഷ്യപ്പെടുത്തിയ കാർഷിക വിദഗ്ദ്ധനെ സമീപിക്കുക.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      true;
}
