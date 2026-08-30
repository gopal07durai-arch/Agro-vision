import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/crop_disease_service.dart';
import 'chat_screen.dart';

class CropDiseaseScreen extends StatefulWidget {
  final String? initialCrop;
  final String? initialDisease;

  const CropDiseaseScreen({
    super.key,
    this.initialCrop,
    this.initialDisease,
  });

  @override
  State<CropDiseaseScreen> createState() => _CropDiseaseScreenState();
}

class _CropDiseaseScreenState extends State<CropDiseaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _diseaseController = TextEditingController();

  String? _selectedCrop;
  bool _isLoading = false;
  CropDiseaseResult? _result;
  String? _errorMessage;

  static const List<Map<String, String>> _predefinedCrops = [
    {'name': 'Blackgram', 'emoji': '🫘'},
    {'name': 'Cotton', 'emoji': '☁️'},
    {'name': 'Eggplant', 'emoji': '🍆'},
    {'name': 'Groundnut', 'emoji': '🥜'},
    {'name': 'Paddy', 'emoji': '🌾'},
    {'name': 'Sugarcane', 'emoji': '🎋'},
    {'name': 'Sunflower', 'emoji': '🌻'},
    {'name': 'Tomato', 'emoji': '🍅'},
    {'name': 'Turmeric', 'emoji': '🌿'},
    {'name': 'Wheat', 'emoji': '🌾'},
  ];

  static const Map<String, List<String>> _cropDiseasesMap = {
    'Blackgram': ['Anthracnose', 'Leaf Crinkle', 'Powdery Mildew', 'Yellow Mosaic'],
    'Cotton': ['Aphids', 'Army Worm', 'Bacterial Blight', 'Powdery Mildew', 'Target Spot'],
    'Eggplant': ['Insect Pest', 'Leaf Spot', 'Mosaic Virus', 'Small Leaf', 'White Mold', 'Wilt Disease'],
    'Groundnut': ['Late Leaf Spot', 'Leaf Spot', 'Nutrition Deficiency', 'Rust'],
    'Paddy': ['Brown Spot', 'Leaf Blast', 'Leaf Blight', 'Leaf Scald', 'Sheath Blight'],
    'Sugarcane': ['Red Rot', 'Red Rust'],
    'Sunflower': ['Alternaria Leaf Spot', 'Downy Mildew', 'Powdery Mildew', 'Rhizopus Head Rot', 'Rust', 'Sclerotinia'],
    'Tomato': ['Bacterial Spot', 'Early Blight', 'Late Blight', 'Leaf Mold', 'Mosaic Virus', 'Septoria Leaf Spot', 'Spider Mites', 'Target Spot', 'Yellow Leaf Curl Virus'],
    'Turmeric': ['Dry Leaf', 'Leaf Blotch', 'Rhizome Disease'],
    'Wheat': ['Crown Root Rot', 'Leaf Rust', 'Loose Smut'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialCrop != null) {
      _selectedCrop = widget.initialCrop;
      _cropController.text = widget.initialCrop!;
    }
    if (widget.initialDisease != null) {
      _diseaseController.text = widget.initialDisease!;
    }
    if (widget.initialCrop != null && widget.initialDisease != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecommendation());
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendation() async {
    final cropName = _selectedCrop ?? _cropController.text.trim();
    final diseaseName = _diseaseController.text.trim();

    if (cropName.isEmpty || diseaseName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cropName.isEmpty
              ? AppLocalizations.of(context).cropRequiredErr
              : AppLocalizations.of(context).diseaseRequiredErr),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context);
    final service = CropDiseaseService();

    final res = await service.getRecommendation(
      crop: cropName,
      disease: diseaseName,
      language: l10n.locale,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (res.success) {
        _result = res;
      } else {
        _errorMessage = res.errorMessage ?? 'Unable to load recommendation.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.cropDiseaseCareTitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: Container(
        decoration: AppTheme.homeGradient(isDark),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description card
              _buildHeaderCard(context, isDark, l10n),
              const SizedBox(height: 20),

              // Input Form Card
              _buildFormCard(context, isDark, l10n),
              const SizedBox(height: 24),

              // Loading indicator
              if (_isLoading) _buildLoadingView(isDark, l10n),

              // Error view
              if (_errorMessage != null && !_isLoading)
                _buildErrorView(isDark, l10n),

              // Result View
              if (_result != null && !_isLoading)
                _buildResultView(context, isDark, l10n),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.emeraldGreen.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cropDiseaseCareTitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cropDiseaseCareSubtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildFormCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    final availableDiseases = _selectedCrop != null
        ? (_cropDiseasesMap[_selectedCrop] ?? [])
        : <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop selection label
            Text(
              l10n.cropNameInputLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            // Crop Dropdown Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCrop,
                  hint: Text(
                    l10n.selectCropHint,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.emeraldGreen),
                  items: _predefinedCrops.map((c) {
                    final cropName = c['name']!;
                    final emoji = c['emoji']!;
                    final localizedName = l10n.cropName(cropName);
                    return DropdownMenuItem<String>(
                      value: cropName,
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            localizedName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCrop = val;
                      _cropController.text = val ?? '';
                      _diseaseController.clear();
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Disease Selection / Input
            Text(
              l10n.diseaseNameInputLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),

            // Quick suggestion chips for selected crop's diseases
            if (availableDiseases.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableDiseases.map((d) {
                  final isSelected = _diseaseController.text == d;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _diseaseController.text = d;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.emeraldGreen
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.emeraldGreen
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Disease Text Field
            TextField(
              controller: _diseaseController,
              decoration: InputDecoration(
                hintText: l10n.enterDiseaseHint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.coronavirus_outlined, color: AppTheme.emeraldGreen, size: 20),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchRecommendation,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  l10n.getRecommendationBtn,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: AppTheme.emeraldGreen.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildLoadingView(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: AppTheme.emeraldGreen,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.generatingRecommendation,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorView(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _fetchRecommendation,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
              style: TextButton.styleFrom(foregroundColor: AppTheme.emeraldGreen),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildResultView(BuildContext context, bool isDark, AppLocalizations l10n) {
    final r = _result!;
    final cropLocalized = l10n.cropName(r.crop);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Badge Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.emeraldGreen, AppTheme.emeraldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emeraldGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      cropLocalized,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      r.disease,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$cropLocalized: ${r.disease}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

        const SizedBox(height: 16),

        // Overview Card
        if (r.overview.isNotEmpty)
          _buildInfoCard(
            title: l10n.diseaseOverviewLabel,
            content: r.overview,
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),

        // Symptoms Card
        if (r.symptoms.isNotEmpty)
          _buildInfoCard(
            title: l10n.symptomsTitle,
            content: r.symptoms,
            icon: Icons.search_rounded,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),

        // Recommended Fertilizer Card
        if (r.fertilizer.isNotEmpty)
          _buildInfoCard(
            title: l10n.recommendedFertilizerTitle,
            content: r.fertilizer,
            icon: Icons.grass_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),

        // Treatment Plan Card
        if (r.treatment.isNotEmpty)
          _buildInfoCard(
            title: l10n.treatmentTitleLabel,
            content: r.treatment,
            icon: Icons.medication_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),

        // Dosage Card
        if (r.dosage.isNotEmpty)
          _buildInfoCard(
            title: l10n.dosageTitle,
            content: r.dosage,
            icon: Icons.straighten_rounded,
            color: const Color(0xFF06B6D4),
            isDark: isDark,
          ),

        // Timing Card
        if (r.timing.isNotEmpty)
          _buildInfoCard(
            title: l10n.applicationTimingTitle,
            content: r.timing,
            icon: Icons.schedule_rounded,
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),

        // Prevention Card
        if (r.prevention.isNotEmpty)
          _buildInfoCard(
            title: l10n.preventionTitle,
            content: r.prevention,
            icon: Icons.shield_outlined,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),

        // Precautions Card
        if (r.precautions.isNotEmpty)
          _buildInfoCard(
            title: l10n.precautionsTitle,
            content: r.precautions,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),

        const SizedBox(height: 16),

        // Ask Follow-up in Chat Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    initialMessage:
                        'I need more details about treating ${r.disease} in ${r.crop}.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(
              l10n.askFollowUpChat,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppTheme.emeraldGreen,
              side: const BorderSide(color: AppTheme.emeraldGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}
