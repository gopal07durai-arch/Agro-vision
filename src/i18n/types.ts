export type LanguageCode = 'en' | 'ta' | 'hi' | 'te' | 'ml';

export interface LanguageInfo {
  code: LanguageCode;
  name: string;
  nativeName: string;
  flag: string;
}

export const SUPPORTED_LANGUAGES: LanguageInfo[] = [
  { code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧' },
  { code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳' },
  { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳' },
  { code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳' },
  { code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳' },
];

export type TranslationKey = keyof TranslationDictionary;

export type TranslationDictionary = {
  // Common & Header
  app_title: string;
  app_subtitle: string;
  online: string;
  offline: string;
  back: string;
  history: string;
  dark_mode: string;
  light_mode: string;
  select_language: string;
  close: string;
  retry: string;
  cancel: string;
  save: string;
  loading: string;
  error: string;
  success: string;

  // Splash
  splash_title: string;
  splash_title_accent: string;
  splash_subtitle: string;
  feature_camera: string;
  feature_ai: string;
  feature_treatment: string;

  // Upload
  upload_title: string;
  upload_subtitle: string;
  drag_drop_title: string;
  drag_drop_subtitle: string;
  browse_files: string;
  take_photo: string;
  take_photo_sub: string;
  supports_formats: string;
  max_size: string;
  quality_tips_title: string;
  tip_good_lighting: string;
  tip_single_leaf: string;
  tip_hold_steady: string;
  analysis_failed: string;

  // Camera
  camera_title: string;
  camera_permission_title: string;
  camera_permission_desc: string;
  allow_camera: string;
  switch_camera: string;
  capture: string;
  retake: string;
  use_photo: string;
  position_leaf: string;
  good_lighting_guide: string;

  // Validation Error
  validation_error_title: string;
  unsupported_crop: string;
  unsupported_crop_desc: string;
  err_quality_title: string;
  low_confidence_title: string;
  low_crop_conf_desc: string;
  low_disease_conf_desc: string;
  not_leaf_desc: string;
  blurry_desc: string;
  dark_desc: string;
  multiple_desc: string;
  cropped_desc: string;
  low_res_desc: string;
  try_again_leaf: string;

  // Analyzing Loader
  analyzing_title: string;
  elapsed: string;
  progress: string;
  first_load_note: string;
  step_compressing: string;
  step_compressing_desc: string;
  step_quality: string;
  step_quality_desc: string;
  step_validating: string;
  step_validating_desc: string;
  step_predicting: string;
  step_predicting_desc: string;
  step_explaining: string;
  step_explaining_desc: string;
  identified_status: string;

  // Prediction & Report
  analysis_complete: string;
  crop_detected: string;
  crop_confidence: string;
  disease_identified: string;
  disease_confidence: string;
  confidence_score: string;
  severity_level: string;
  treatment_recommendations: string;
  options_count: string;
  disease_overview: string;
  symptoms: string;
  cause: string;
  spread_method: string;
  biofertilizer: string;
  dosage: string;
  application_method: string;
  frequency: string;
  benefits: string;
  precautions: string;
  organic_control: string;
  chemical_control: string;
  recovery_time: string;
  preventive_measures: string;
  farmer_explanation: string;
  download_pdf: string;
  start_chat: string;
  scan_another: string;
  rate_recommendation: string;
  rating_thank_you: string;
  rate_prompt: string;

  // Severity
  severity_high: string;
  severity_medium: string;
  severity_low: string;
  severity_none: string;

  // Crops
  crop_Tomato: string;
  crop_Paddy: string;
  crop_Wheat: string;
  crop_Cotton: string;
  crop_Sugarcane: string;
  crop_Groundnut: string;
  crop_Sunflower: string;
  crop_Blackgram: string;
  crop_Eggplant: string;
  crop_Turmeric: string;

  // Common Diseases
  disease_Healthy: string;
  disease_EarlyBlight: string;
  disease_LateBlight: string;
  disease_BacterialSpot: string;
  disease_LeafMold: string;
  disease_SeptoriaLeafSpot: string;
  disease_SpiderMites: string;
  disease_TargetSpot: string;
  disease_MosaicVirus: string;
  disease_YellowLeafCurlVirus: string;
  disease_BrownSpot: string;
  disease_LeafBlast: string;
  disease_LeafBlight: string;
  disease_LeafScald: string;
  disease_SheathBlight: string;
  disease_CrownRootRot: string;
  disease_LeafRust: string;
  disease_LooseSmut: string;
  disease_Aphids: string;
  disease_ArmyWorm: string;
  disease_BacterialBlight: string;
  disease_PowderyMildew: string;
  disease_RedRot: string;
  disease_RedRust: string;
  disease_LateLeafSpot: string;
  disease_LeafSpot: string;
  disease_Rust: string;
  disease_AlternariaLeafSpot: string;
  disease_DownyMildew: string;
  disease_RhizopusHeadRot: string;
  disease_Sclerotinia: string;
  disease_Anthracnose: string;
  disease_LeafCrinkle: string;
  disease_YellowMosaic: string;
  disease_InsectPest: string;
  disease_SmallLeaf: string;
  disease_WhiteMold: string;
  disease_WiltDisease: string;
  disease_DryLeaf: string;
  disease_LeafBlotch: string;
  disease_RhizomeDisease: string;

  // Fertilizer Types
  type_bio: string;
  type_chemical: string;
  type_organic: string;

  // Chat
  chat_assistant: string;
  chat_subtitle: string;
  chat_welcome_title: string;
  chat_welcome_msg: string;
  chat_ask_placeholder: string;
  chat_send: string;
  chat_thinking: string;
  chat_disclaimer: string;
  chat_suggested_title: string;
  chat_q1: string;
  chat_q2: string;
  chat_q3: string;

  // History
  history_title: string;
  history_subtitle: string;
  history_scans: string;
  history_avg_confidence: string;
  history_diseases_found: string;
  history_empty_title: string;
  history_empty_desc: string;
  history_scan_now: string;
  history_showing_last: string;
  history_failed_load: string;

  // Quality & Prediction Errors
  err_dark: string;
  err_low_res: string;
  err_blurry: string;
  err_unsupported_type: string;
  err_too_large: string;
  err_backend: string;
  err_timeout: string;
  err_unexpected: string;
  err_low_confidence: string;
  err_unsupported_crop: string;
  err_timeout_title: string;
  err_backend_title: string;
  err_model_unavailable_title: string;

  // PDF
  pdf_report_title: string;
  pdf_generated_on: string;
  pdf_disclaimer: string;

  // Master UI/UX Enhancement Keys
  hero_badge: string;
  hero_main_heading: string;
  hero_subtitle_master: string;
  upload_card_title: string;
  upload_card_subtitle: string;
  upload_card_secondary: string;
  btn_upload_image: string;
  btn_take_photo: string;
  btn_replace_image: string;
  btn_analyze_leaf: string;
  camera_guide_text: string;
  scan_step_scanning: string;
  scan_step_crop_chars: string;
  scan_step_disease_patterns: string;
  scan_step_diagnosis: string;
  confidence_unavailable: string;
  download_report: string;
  supported_crops_label: string;
  tips_accurate_diagnosis_title: string;
  tip_natural_lighting: string;
  tip_single_crop_leaf: string;
  tip_camera_steady: string;
  tip_complete_leaf_visible: string;
  btn_upload_another: string;
  btn_try_again: string;

  // Additional Navigation & Modal Keys
  nav_home: string;
  nav_scan: string;
  nav_history: string;
  nav_about: string;
  about_agrovision: string;
  preview_captured_photo: string;
  preview_uploaded_file: string;
  preview_leaf_ready: string;
  preview_confirm_desc: string;
  about_mission_title: string;
  about_mission_desc: string;
  about_arch_title: string;
  about_stage1_title: string;
  about_stage1_desc: string;
  about_stage2_title: string;
  about_stage2_desc: string;
  about_crops_title: string;
  about_features_title: string;
  about_feat_quality: string;
  about_feat_lang: string;
  about_feat_pdf: string;
  about_feat_chat: string;
  disease_status_healthy: string;
  disease_status_detected: string;
  farmer_action_guide_title: string;
  farmer_action_guide_subtitle: string;
  camera_position_leaf: string;
  fertilizer_section_subtitle: string;
};



