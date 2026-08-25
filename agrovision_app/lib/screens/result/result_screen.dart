import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../models/prediction_result.dart';
import '../../models/recommendation_result.dart';
import '../../services/supabase_service.dart';
import '../scan/scan_screen.dart';
import '../../widgets/confidence_gauge.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/leaf_image_view.dart';
import '../../core/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResultScreen
// ─────────────────────────────────────────────────────────────────────────────
class ResultScreen extends StatefulWidget {
  final PredictionResult result;
  final File? imageFile;

  const ResultScreen({
    super.key,
    required this.result,
    this.imageFile,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  int _userRating = 0;
  bool _safetyExpanded = false;
  bool _preventionExpanded = false;
  bool _organicExpanded = false;
  final _supabase = SupabaseService();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final r = widget.result;
    // Localize the recommendation dynamically according to selected language
    final rec = l10n.getLocalizedRecommendation(r.crop, r.disease, r.recommendation);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image app bar ──────────────────────────────────────────────
          _buildHeroAppBar(context, r, isDark, l10n),

          // ── Content ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Detection cards
                _buildDetectionCards(context, r, isDark, l10n),
                const SizedBox(height: 16),

                // 2. Confidence section
                _buildConfidenceSection(context, r, isDark, l10n),
                const SizedBox(height: 16),

                // 3. Recommendation header (only if recommendation data available)
                if (rec != null) ...[
                  _buildRecommendationHeader(context, r, rec, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 4. Treatment card (pest/disease)
                if (rec != null && rec.hasTreatment) ...[
                  _buildTreatmentCard(context, r, rec, isDark, l10n),
                  const SizedBox(height: 16),

                  // 5. How to apply
                  _buildHowToApply(context, isDark, l10n),
                  const SizedBox(height: 16),

                  // 6. Safety & Precautions (expandable)
                  if (rec.hasSafetyInfo)
                    _buildSafetyCard(context, rec, isDark, l10n),
                  if (rec.hasSafetyInfo) const SizedBox(height: 16),

                  // 7. Harvest interval
                  _buildHarvestCard(context, rec, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 8. Fertilizer section
                if (rec != null && rec.hasFertilizer) ...[
                  _buildFertilizerCard(context, rec.fertilizerSection!, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 9. Organic alternative (expandable)
                if (rec != null && rec.hasOrganicAlternative) ...[
                  _buildOrganicCard(context, rec, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 10. Prevention (expandable)
                if (rec != null && rec.hasPrevention) ...[
                  _buildPreventionCard(context, rec, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 11. Source & verification
                if (rec != null && rec.isFromVerifiedSource) ...[
                  _buildSourceCard(context, rec, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 12. No recommendation notice
                if (rec == null) ...[
                  _buildNoRecommendationCard(context, r, isDark, l10n),
                  const SizedBox(height: 16),
                ],

                // 13. AI disclaimer
                _buildDisclaimerCard(context, isDark, l10n),
                const SizedBox(height: 16),

                // 14. Star rating
                _buildRatingCard(context, r, isDark, l10n),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _buildActionBar(context, isDark, l10n),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HERO APP BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHeroAppBar(
      BuildContext context, PredictionResult r, bool isDark, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        l10n.analysisComplete,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            LeafImageView(file: widget.imageFile, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: r.isHealthy
                      ? AppTheme.emeraldGreen
                      : const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      r.isHealthy
                          ? Icons.check_circle_rounded
                          : Icons.warning_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      r.isHealthy ? l10n.healthyCropDetected : l10n.diseasePestDetected,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DETECTION CARDS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDetectionCards(
      BuildContext context, PredictionResult r, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Row(
      children: [
        // Crop card
        Expanded(
          child: _card(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            borderColor: AppTheme.emeraldGreen.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _iconBox(Icons.eco_rounded, AppTheme.emeraldGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.cropDetected,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emeraldGreen,
                          letterSpacing: 0.8,
                        )),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(r.cropEmoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(l10n.cropName(r.crop),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ).animate().slideX(begin: -0.2, duration: 500.ms).fadeIn(),
        ),
        const SizedBox(width: 12),
        // Disease/Pest card
        Expanded(
          child: _card(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            borderColor: r.isHealthy
                ? AppTheme.emeraldGreen.withOpacity(0.3)
                : const Color(0xFF7C3AED).withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _iconBox(
                    r.isHealthy
                        ? Icons.check_circle_rounded
                        : Icons.biotech_rounded,
                    r.isHealthy
                        ? AppTheme.emeraldGreen
                        : const Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.isHealthy ? l10n.status : l10n.problem,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: r.isHealthy
                            ? AppTheme.emeraldGreen
                            : const Color(0xFF7C3AED),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                _severityBadge(r, l10n),
                const SizedBox(height: 6),
                Text(l10n.diseaseName(r.disease, r.crop),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ).animate().slideX(begin: 0.2, duration: 500.ms).fadeIn(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CONFIDENCE SECTION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildConfidenceSection(
      BuildContext context, PredictionResult r, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.confidenceScores,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ConfidenceGauge(
                label: l10n.cropConfidence,
                value: r.cropConfidence,
                color: AppTheme.emeraldGreen,
              ),
              Container(
                  width: 1,
                  height: 80,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              ConfidenceGauge(
                label: l10n.diseaseConfidence,
                value: r.diseaseConfidence,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 150.ms).slideY(begin: 0.15).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RECOMMENDATION HEADER CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendationHeader(BuildContext context, PredictionResult r,
      RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final localizedCrop = l10n.cropName(r.crop);
    final localizedDisease = l10n.diseaseName(r.disease, r.crop);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF1E293B)]
              : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.emeraldGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: AppTheme.emeraldGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_pharmacy_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.recommendedTreatment,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                _categoryBadge(
                  l10n.problemTypeLabel(rec.problemType),
                  _problemTypeColor(rec.problemType),
                ),
              ],
            ),
          ),

          // Info grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _infoTile(
                            '🌿 ${l10n.cropDetected}',
                            localizedCrop,
                            AppTheme.emeraldGreen,
                            isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoTile(
                            '⚠ ${l10n.problem}',
                            localizedDisease,
                            _problemTypeColor(rec.problemType),
                            isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _infoTile(
                            '🔬 ${l10n.typeLabel}',
                            l10n.problemTypeLabel(rec.problemType),
                            _problemTypeColor(rec.problemType),
                            isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoTile(
                            '📊 ${l10n.diseaseConfidence}',
                            '${r.diseaseConfidence.toStringAsFixed(0)}%',
                            AppTheme.emeraldGreen,
                            isDark)),
                  ],
                ),
                const SizedBox(height: 14),
                // Explainer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.emeraldGreen.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whyThisRecommendation,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.emeraldGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _whyItem(l10n.whyCropIdentified.replaceAll('{0}', localizedCrop)),
                      _whyItem(l10n.whyProblemIdentified.replaceAll('{0}', localizedDisease)),
                      _whyItem(l10n.whyRecMatched.replaceAll('{0}', localizedCrop).replaceAll('{1}', localizedDisease)),
                      _whyItem(l10n.whyVerifiedDb),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).slideY(begin: 0.2).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TREATMENT CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTreatmentCard(BuildContext context, PredictionResult r,
      RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final catColor = _categoryColor(rec.productCategory);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(
                  bottom: BorderSide(color: catColor.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_categoryIcon(rec.productCategory), color: catColor, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.treatmentRecommendation,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        l10n.forManagement.replaceAll('{0}', l10n.problemTypeLabel(rec.problemType)),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                _categoryBadge(
                  l10n.productCategoryLabel(rec.productCategory),
                  catColor,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  rec.productName ?? 'Product information unavailable',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: catColor,
                  ),
                ),

                if (rec.activeIngredient != null && rec.activeIngredient!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.activeIngredient}: ${rec.activeIngredient}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],

                if (rec.purpose != null && rec.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: catColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.purpose!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _SectionDivider(label: l10n.applicationDetails),
                const SizedBox(height: 12),

                _detailRow(
                  Icons.science_rounded,
                  l10n.dosage,
                  rec.dosageFormatted ?? 'Dosage information unavailable.',
                  catColor,
                  isDark,
                ),
                const SizedBox(height: 10),
                _detailRow(
                  Icons.water_drop_outlined,
                  l10n.application,
                  rec.applicationMethod ?? 'Information unavailable.',
                  catColor,
                  isDark,
                ),
                const SizedBox(height: 10),
                _detailRow(
                  Icons.schedule_rounded,
                  l10n.timing,
                  rec.applicationTiming ?? 'Information unavailable.',
                  catColor,
                  isDark,
                ),
                const SizedBox(height: 10),
                _detailRow(
                  Icons.repeat_rounded,
                  l10n.frequency,
                  rec.frequency ?? 'Information unavailable.',
                  catColor,
                  isDark,
                ),
                if (rec.duration != null && rec.duration!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.timer_outlined,
                    l10n.duration,
                    rec.duration!,
                    catColor,
                    isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HOW TO APPLY
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHowToApply(BuildContext context, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final steps = [
      ('01', l10n.howToApplyStep1Title, l10n.howToApplyStep1Desc, Icons.security_rounded),
      ('02', l10n.howToApplyStep2Title, l10n.howToApplyStep2Desc, Icons.straighten_rounded),
      ('03', l10n.howToApplyStep3Title, l10n.howToApplyStep3Desc, Icons.water_drop_rounded),
      ('04', l10n.howToApplyStep4Title, l10n.howToApplyStep4Desc, Icons.visibility_rounded),
      ('05', l10n.howToApplyStep5Title, l10n.howToApplyStep5Desc, Icons.refresh_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.format_list_numbered_rounded, AppTheme.emeraldGreen),
            const SizedBox(width: 10),
            Text(l10n.howToApply,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
          ]),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            s.$1,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                            width: 2,
                            height: 20,
                            color: AppTheme.emeraldGreen.withOpacity(0.2)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(s.$4,
                              size: 14, color: AppTheme.emeraldGreen),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(s.$2,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                )),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(s.$3,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black54,
                              height: 1.4,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 400.ms).slideY(begin: 0.15).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SAFETY CARD (expandable)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSafetyCard(
      BuildContext context, RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _safetyExpanded = !_safetyExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n.safetyPrecautions,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      )),
                ),
                Icon(
                  _safetyExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ],
            ),
            if (_safetyExpanded) ...[
              const SizedBox(height: 14),
              if (rec.precautions != null && rec.precautions!.isNotEmpty)
                _safetyItem(Icons.block_rounded,
                    l10n.precautionsLabel, rec.precautions!, isDark),
              if (rec.precautions != null && rec.safetyNotes != null)
                const SizedBox(height: 10),
              if (rec.safetyNotes != null && rec.safetyNotes!.isNotEmpty)
                _safetyItem(Icons.shield_rounded,
                    l10n.safetyNotesLabel, rec.safetyNotes!, isDark),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                l10n.tapToViewSafety,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate(delay: 450.ms).slideY(begin: 0.15).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HARVEST WAITING PERIOD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildHarvestCard(
      BuildContext context, RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final hasInterval = rec.harvestWaitingPeriod != null &&
        rec.harvestWaitingPeriod!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer_rounded,
                color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.preHarvestInterval,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                const SizedBox(height: 3),
                Text(
                  hasInterval
                      ? (l10n.locale == 'ta'
                          ? 'பயன்பாட்டிற்குப் பின் அறுவடை செய்ய ${rec.harvestWaitingPeriod} வரை காத்திருக்கவும்.'
                          : 'Wait ${rec.harvestWaitingPeriod} before harvesting after application.')
                      : (l10n.locale == 'ta'
                          ? 'இந்த தயாரிப்பிற்கு அறுவடைக்கு முந்தைய காத்திருப்பு நேரம் பற்றிய தகவல் கிடைக்கவில்லை.'
                          : 'Pre-harvest interval information is not available for this product.'),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FERTILIZER CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFertilizerCard(BuildContext context,
      FertilizerRecommendation fert, bool isDark, AppLocalizations l10n) {
    const color = Color(0xFF059669);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(
                  bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.spa_rounded, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.fertilizerRecommendation,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: color,
                        )),
                    Text(l10n.productCategoryLabel(fert.productCategory),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark ? Colors.white70 : color,
                        )),
                  ],
                ),
              ),
              _categoryBadge(l10n.productCategoryLabel('Fertilizer'), color),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fertilizerName(fert.name),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: color,
                    )),
                if (fert.primaryNutrient != null && fert.primaryNutrient!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${l10n.locale == 'ta' ? 'முதன்மை ஊட்டச்சத்து' : 'Primary Nutrient'}: ${fert.primaryNutrient}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      )),
                ],
                if (fert.npk != null && fert.npk!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('NPK: ${fert.npk}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ),
                ],
                const SizedBox(height: 14),
                if (fert.dosage != null && fert.dosage!.isNotEmpty)
                  _detailRow(
                    Icons.science_rounded,
                    l10n.dosage,
                    '${fert.dosage ?? ''} ${fert.dosageUnit ?? ''}'.trim(),
                    color,
                    isDark,
                  ),
                if (fert.applicationMethod != null && fert.applicationMethod!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.water_drop_outlined,
                    l10n.application,
                    fert.applicationMethod!,
                    color,
                    isDark,
                  ),
                ],
                if (fert.growthStage != null && fert.growthStage!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.eco_rounded,
                    l10n.locale == 'ta' ? 'பயிர் வளர்ச்சி நிலை' : 'Growth Stage',
                    fert.growthStage!,
                    color,
                    isDark,
                  ),
                ],
                if (fert.frequency != null && fert.frequency!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    Icons.repeat_rounded,
                    l10n.frequency,
                    fert.frequency!,
                    color,
                    isDark,
                  ),
                ],
                if (fert.expectedBenefit != null && fert.expectedBenefit!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 14, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fert.expectedBenefit!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 350.ms).slideY(begin: 0.15).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ORGANIC ALTERNATIVE (expandable)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOrganicCard(
      BuildContext context, RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    const color = Color(0xFF16A34A);

    return GestureDetector(
      onTap: () => setState(() => _organicExpanded = !_organicExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _iconBox(Icons.nature_rounded, color),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(l10n.organicAlternative,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ))),
              Icon(
                _organicExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
            ]),
            if (_organicExpanded) ...[
              const SizedBox(height: 12),
              Text(
                rec.organicAlternative!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                      l10n.organicDisclaimer,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    )),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(l10n.tapToViewOrganic,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  )),
            ],
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PREVENTION (expandable)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPreventionCard(
      BuildContext context, RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    const color = Color(0xFF0284C7);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: () =>
          setState(() => _preventionExpanded = !_preventionExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _iconBox(Icons.shield_rounded, color),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(l10n.prevention,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ))),
              Icon(
                _preventionExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
            ]),
            if (_preventionExpanded) ...[
              const SizedBox(height: 12),
              ...rec.prevention!.split('.').where((s) => s.trim().isNotEmpty).map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 5, right: 8),
                            decoration: const BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              step.trim(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ] else ...[
              const SizedBox(height: 6),
              Text(l10n.tapToViewPrevention,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  )),
            ],
          ],
        ),
      ),
    ).animate(delay: 550.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SOURCE & VERIFICATION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSourceCard(
      BuildContext context, RecommendationResult rec, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.verified_rounded, const Color(0xFF6366F1)),
            const SizedBox(width: 10),
            Text(l10n.sourceVerification,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ]),
          const SizedBox(height: 12),
          _sourceRow(Icons.library_books_outlined, l10n.locale == 'ta' ? 'மூலம்' : 'Source',
              rec.source ?? 'Information not available', isDark),
          if (rec.lastVerified != null) ...[
            const SizedBox(height: 8),
            _sourceRow(Icons.calendar_today_outlined, l10n.locale == 'ta' ? 'சரிபார்க்கப்பட்ட தேதி' : 'Last Verified',
                rec.lastVerified!, isDark),
          ],
          if (rec.region != null) ...[
            const SizedBox(height: 8),
            _sourceRow(Icons.location_on_outlined, l10n.locale == 'ta' ? 'பொருந்தும் பகுதி' : 'Applicable Region',
                rec.region!, isDark),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.sourceVerifiedNote,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NO RECOMMENDATION CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildNoRecommendationCard(
      BuildContext context, PredictionResult r, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 32),
          const SizedBox(height: 12),
          Text(
            l10n.noRecommendationTitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noRecDetail,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AI DISCLAIMER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDisclaimerCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiDisclaimer,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 650.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RATING CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRatingCard(
      BuildContext context, PredictionResult r, bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(l10n.rateAnalysis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
          const SizedBox(height: 6),
          Text(
            l10n.rateSubtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 12),
          StarRating(
            rating: _userRating,
            onRate: (rating) {
              if (!mounted) return;
              setState(() => _userRating = rating);
              _supabase.saveRating(
                sessionId: context.read<AppProvider>().sessionId,
                crop: r.crop,
                disease: r.disease,
                fertilizerName: r.fertilizer.name,
                rating: rating,
              );
            },
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 8),
            Text(
              '✓ ${l10n.thankYouRating}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.emeraldGreen,
              ),
            ),
          ],
        ],
      ),
    ).animate(delay: 700.ms).fadeIn();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActionBar(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: Text(l10n.scanAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _card({
    required bool isDark,
    required Color cardBg,
    required Color border,
    Color? borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? border),
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _severityBadge(PredictionResult r, AppLocalizations l10n) {
    if (r.isHealthy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.emeraldGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(l10n.severityLabel('None'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.emeraldGreen,
            )),
      );
    }
    final c = _severityColor(r.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(l10n.severityLabel(r.severity),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: c,
          )),
    );
  }

  Widget _infoTile(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _whyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppTheme.emeraldGreen.withOpacity(0.85),
          )),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color,
      bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _safetyItem(
      IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: const Color(0xFFDC2626)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                )),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.4,
              )),
        ],
      ),
    );
  }

  Widget _sourceRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _categoryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return const Color(0xFF10B981);
    }
  }

  Color _problemTypeColor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'pest': return const Color(0xFFDC2626);
      case 'disease': return const Color(0xFF7C3AED);
      case 'nutrient deficiency': return const Color(0xFFF59E0B);
      case 'healthy': return AppTheme.emeraldGreen;
      default: return const Color(0xFF64748B);
    }
  }

  Color _categoryColor(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'insecticide': return const Color(0xFFDC2626);
      case 'fungicide': return const Color(0xFF7C3AED);
      case 'bactericide': return const Color(0xFF2563EB);
      case 'biological control': return const Color(0xFF059669);
      case 'organic treatment': return const Color(0xFF16A34A);
      case 'fertilizer': return const Color(0xFF059669);
      case 'nutrient supplement': return const Color(0xFFF59E0B);
      case 'preventive treatment': return const Color(0xFF0284C7);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _categoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'insecticide': return Icons.bug_report_rounded;
      case 'fungicide': return Icons.coronavirus_rounded;
      case 'bactericide': return Icons.science_rounded;
      case 'biological control': return Icons.eco_rounded;
      case 'organic treatment': return Icons.nature_rounded;
      case 'fertilizer': return Icons.spa_rounded;
      case 'nutrient supplement': return Icons.water_drop_rounded;
      case 'preventive treatment': return Icons.shield_rounded;
      default: return Icons.local_pharmacy_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section divider widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
            child: Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0))),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.5,
            )),
        const SizedBox(width: 8),
        Expanded(
            child: Container(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0))),
      ],
    );
  }
}
