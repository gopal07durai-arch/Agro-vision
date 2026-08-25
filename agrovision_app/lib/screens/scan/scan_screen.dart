import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/image_service.dart';
import '../../services/detection_service.dart';
import '../../services/on_device_ml_service.dart';
import '../../models/api_error.dart';
import '../result/result_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/leaf_image_view.dart';

class ScanScreen extends StatefulWidget {
  final bool openCamera;

  const ScanScreen({super.key, this.openCamera = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _selectedImage;
  bool _isAnalyzing = false;
  String _analysisStep = '';
  double _analysisProgress = 0.0;
  final _imageService = ImageService();
  final _detection    = DetectionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkBackend();
    if (widget.openCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureFromCamera());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    OnDeviceMLService.instance.initialize().catchError((_) {});
  }

  Future<void> _captureFromCamera() async {
    final file = await _imageService.captureFromCamera();
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
      _checkBackend();
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _imageService.pickFromGallery();
    if (file != null && mounted) {
      setState(() => _selectedImage = file);
      _checkBackend();
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null || _isAnalyzing) return;

    final sessionId = context.read<AppProvider>().sessionId;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isAnalyzing = true;
      _analysisStep = l10n.preparingImage;
      _analysisProgress = 0.0;
    });

    _detection.addListener(_onDetectionProgress);

    try {
      final result = await _detection.analyze(_selectedImage!, sessionId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            imageFile: _selectedImage!,
          ),
        ),
      );
    } on ApiError catch (e) {
      _detection.removeListener(_onDetectionProgress);
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showError(e);
        if (e.isNetworkError) {
          _checkBackend();
        }
      }
      return;
    } finally {
      _detection.removeListener(_onDetectionProgress);
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _onDetectionProgress() {
    if (mounted) {
      setState(() {
        _analysisStep = _detection.statusMessage;
        _analysisProgress = _detection.progress;
      });
    }
  }

  void _showError(ApiError error) {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backendUrl = AppConfig.apiBaseUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => _ErrorSheet(
        error: error,
        backendUrl: backendUrl,
        onRetry: () {
          Navigator.of(sheetCtx).pop();
          if (mounted) _analyze();
        },
        onOpenSettings: () {
          Navigator.of(sheetCtx).pop();
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(l10n.scanLeaf),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          if (_selectedImage != null)
            TextButton.icon(
              onPressed: () => setState(() => _selectedImage = null),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retake),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.emeraldGreen,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildBackendBanner(isDark, l10n),
              Expanded(
                child: _selectedImage == null
                    ? _buildPickerSection(isDark, l10n)
                    : _buildPreviewSection(isDark, l10n),
              ),
            ],
          ),
          if (_isAnalyzing) _buildAnalyzingOverlay(isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildBackendBanner(bool isDark, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.emeraldGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '🌱 On-Device TFLite Engine (100% Offline)',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.greenAccent : const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSection(bool isDark, AppLocalizations l10n) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.camera_alt_rounded,
                  title: l10n.takePhoto,
                  subtitle: l10n.scanWithCamera,
                  color: AppTheme.emeraldGreen,
                  bg: cardBg,
                  border: border,
                  onTap: _captureFromCamera,
                ).animate().slideX(begin: -0.3, duration: 500.ms).fadeIn(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.photo_library_rounded,
                  title: l10n.selectPhoto,
                  subtitle: l10n.uploadFromGallery,
                  color: const Color(0xFF3B82F6),
                  bg: cardBg,
                  border: border,
                  onTap: _pickFromGallery,
                ).animate().slideX(begin: 0.3, duration: 500.ms).fadeIn(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tips_and_updates_rounded,
                          color: AppTheme.emeraldGreen, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.tipsForBestResults,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTip(Icons.wb_sunny_outlined, l10n.tipNaturalLighting),
                _buildTip(Icons.center_focus_strong_rounded, l10n.tipSingleLeaf),
                _buildTip(Icons.motion_photos_off_rounded, l10n.tipHoldSteady),
                _buildTip(Icons.image_not_supported_outlined, l10n.tipSupportedCrops),
                _buildTip(Icons.crop_free_rounded, l10n.tipFillFrame),
              ],
            ),
          ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn(),

          const SizedBox(height: 24),

          Text(
            l10n.supportsFormats,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ).animate(delay: 400.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.emeraldGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LeafImageView(
                          file: _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16, left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco_rounded,
                                    size: 14, color: AppTheme.emeraldGreen),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.readyToAnalyze,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                        begin: const Offset(0.95, 0.95),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => setState(() => _selectedImage = null),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.retake),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyze,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search_rounded, size: 18),
                        label: Text(
                          _isAnalyzing ? l10n.loading : l10n.analyzeLeaf,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).slideY(begin: 0.2).fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingOverlay(bool isDark, AppLocalizations l10n) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 36,
                  color: AppTheme.emeraldGreen,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.1, 1.1),
                  duration: 1000.ms),

              const SizedBox(height: 20),
              Text(
                _analysisStep,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.analyzingLeafDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: _analysisProgress,
                  minHeight: 6,
                  backgroundColor: AppTheme.emeraldGreen.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.emeraldGreen),
                ),
              ),
              if (_analysisStep.toLowerCase().contains('connect') ||
                  _analysisStep.toLowerCase().contains('server')) ...[
                const SizedBox(height: 12),
                Text(
                  AppConfig.apiBaseUrl,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSheet extends StatelessWidget {
  const _ErrorSheet({
    required this.error,
    required this.backendUrl,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final ApiError error;
  final String backendUrl;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = _iconForError(error.type);
    final color = _colorForError(error.type);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _titleForError(error.type, l10n),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizedErrorMessage(error, l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.goBack),
            ),
          ),
          const SizedBox(height: 4),
          const SafeArea(top: false, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  String _titleForError(ApiErrorType type, AppLocalizations l10n) {
    switch (type) {
      case ApiErrorType.notLeaf:
      case ApiErrorType.invalidImage:
        return l10n.errInvalidImageTitle;
      case ApiErrorType.lowImageQuality:
        return l10n.errLowQualityTitle;
      case ApiErrorType.lowCropConfidence:
        return l10n.errLowCropTitle;
      case ApiErrorType.lowDiseaseConfidence:
        return l10n.errLowDiseaseTitle;
      case ApiErrorType.unsupportedCrop:
        return l10n.errUnsupportedCropTitle;
      case ApiErrorType.modelUnavailable:
        return l10n.errModelUnavailableTitle;
      case ApiErrorType.backendStarting:
        return l10n.errBackendStartingTitle;
      case ApiErrorType.noInternet:
      case ApiErrorType.networkError:
        return l10n.backendNotReachable;
      case ApiErrorType.timeout:
        return l10n.errTimeoutTitle;
      default:
        return l10n.errAnalysisFailedTitle;
    }
  }

  IconData _iconForError(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.notLeaf:
      case ApiErrorType.invalidImage:
        return Icons.image_not_supported_rounded;
      case ApiErrorType.lowImageQuality:
        return Icons.blur_on_rounded;
      case ApiErrorType.lowCropConfidence:
      case ApiErrorType.lowDiseaseConfidence:
        return Icons.help_outline_rounded;
      case ApiErrorType.noInternet:
      case ApiErrorType.networkError:
        return Icons.wifi_off_rounded;
      case ApiErrorType.timeout:
        return Icons.timer_off_rounded;
      case ApiErrorType.backendStarting:
        return Icons.hourglass_top_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _colorForError(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.noInternet:
      case ApiErrorType.networkError:
      case ApiErrorType.timeout:
      case ApiErrorType.backendStarting:
        return Colors.orange;
      case ApiErrorType.lowCropConfidence:
      case ApiErrorType.lowDiseaseConfidence:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  String _localizedErrorMessage(ApiError error, AppLocalizations l10n) {
    final lang = l10n.locale;
    if (lang == 'ta') {
      switch (error.type) {
        case ApiErrorType.notLeaf:
          return 'ஆதரிக்கப்படாத படம். தயவுசெய்து ஆதரிக்கப்பட்ட பயிர் இலையின் தெளிவான புகைப்படத்தைப் பதிவேற்றவும்.';
        case ApiErrorType.invalidImage:
          return 'செல்லுபடியாகாத படம். JPG, PNG அல்லது WebP வடிவ படத்தைப் பதிவேற்றவும்.';
        case ApiErrorType.lowImageQuality:
          return 'படத்தின் தரம் மிகவும் குறைவாக உள்ளது. நல்ல வெளிச்சத்தில் கேமராவை நிலையாகப் பிடித்து தெளிவான படம் எடுக்கவும்.';
        case ApiErrorType.lowCropConfidence:
          return 'பயிரை நம்பிக்கையுடன் அடையாளம் காண முடியவில்லை. தயவுசெய்து தெளிவான இலை படத்தை பதிவேற்றவும்.';
        case ApiErrorType.lowDiseaseConfidence:
          return 'நோயை நம்பிக்கையுடன் அடையாளம் காண முடியவில்லை. தயவுசெய்து தெளிவான இலை படத்தை பதிவேற்றவும்.';
        case ApiErrorType.unsupportedCrop:
          return 'இந்த பயிர் வகை தற்போது ஆதரிக்கப்படவில்லை. ஆதரிக்கப்படும் 10 பயிர்களில் ஒன்றைப் பயன்படுத்தவும்.';
        case ApiErrorType.modelUnavailable:
          return 'AI சேவை தற்போது கிடைக்கவில்லை. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';
        case ApiErrorType.backendStarting:
          return 'AI சேவையகம் தயாராகிறது. தயவுசெய்து சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';
        case ApiErrorType.noInternet:
        case ApiErrorType.networkError:
          return 'இணைய இணைப்பு இல்லை. உங்கள் மொபைல் டேட்டா அல்லது Wi-Fi இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';
        case ApiErrorType.timeout:
          return 'சேவையகம் பதிலளிக்க அதிக நேரம் எடுத்தது. உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';
        default:
          return error.message;
      }
    } else if (lang == 'hi') {
      switch (error.type) {
        case ApiErrorType.notLeaf:
          return 'असमर्थित छवि। कृपया समर्थित फसल की पत्ती की स्पष्ट फोटो लें।';
        case ApiErrorType.invalidImage:
          return 'अमान्य छवि। कृपया JPG, PNG या WebP प्रारूप में फोटो अपलोड करें।';
        case ApiErrorType.lowImageQuality:
          return 'छवि की गुणवत्ता बहुत कम है। कृपया अच्छी रोशनी में स्पष्ट फोटो लें।';
        case ApiErrorType.lowCropConfidence:
          return 'फसल की पहचान नहीं हो सकी। कृपया स्पष्ट पत्ती की फोटो लें।';
        case ApiErrorType.lowDiseaseConfidence:
          return 'रोग की पहचान नहीं हो सकी। कृपया स्पष्ट पत्ती की फोटो लें।';
        case ApiErrorType.unsupportedCrop:
          return 'यह फसल वर्तमान में समर्थित नहीं है। कृपया 10 समर्थित फसलों में से एक चुनें।';
        case ApiErrorType.modelUnavailable:
          return 'AI सेवा वर्तमान में उपलब्ध नहीं है। कृपया थोड़ी देर बाद प्रयास करें।';
        case ApiErrorType.backendStarting:
          return 'AI सर्वर लोड हो रहा है। कृपया कुछ क्षण प्रतीक्षा करें।';
        case ApiErrorType.noInternet:
        case ApiErrorType.networkError:
          return 'कोई इंटरनेट कनेक्शन नहीं है। कृपया अपना मोबाइल डेटा या वाई-फाई जांचें।';
        case ApiErrorType.timeout:
          return 'सर्वर से उत्तर मिलने में समय लगा। कृपया पुनः प्रयास करें।';
        default:
          return error.message;
      }
    } else if (lang == 'ml') {
      switch (error.type) {
        case ApiErrorType.notLeaf:
          return 'പിന്തുണയ്ക്കാത്ത ചിത്രം. ദയവായി പിന്തുണയ്ക്കുന്ന വിളയുടെ ഇലയുടെ വ്യക്തമായ ഫോട്ടോ അപ്‌ലോഡ് ചെയ്യുക.';
        case ApiErrorType.invalidImage:
          return 'അസാധുവായ ചിത്രം. ദയവായി JPG, PNG അല്ലെങ്കിൽ WebP ചിത്രം നൽകുക.';
        case ApiErrorType.lowImageQuality:
          return 'ചിത്രത്തിന്റെ ഗുണനിലവാരം കുറവാണ്. നല്ല വെളിച്ചത്തിൽ വ്യക്തമായ ചിത്രം പകർത്തുക.';
        case ApiErrorType.lowCropConfidence:
          return 'വിള തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല. ദയവായി വ്യക്തമായ ഇലയുടെ ചിത്രം നൽകുക.';
        case ApiErrorType.lowDiseaseConfidence:
          return 'രോഗം തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല. ദയവായി വ്യക്തമായ ഇലയുടെ ചിത്രം നൽകുക.';
        case ApiErrorType.unsupportedCrop:
          return 'ഈ വിള നിലവിൽ പിന്തുണയ്ക്കുന്നില്ല. 10 പിന്തുണയ്ക്കുന്ന വിളകളിൽ ഒന്ന് തിരഞ്ഞെടുക്കുക.';
        case ApiErrorType.modelUnavailable:
          return 'AI സേവനം താൽക്കാലികമായി ലഭ്യമല്ല. ദയവായി അല്പം കഴിഞ്ഞ് ശ്രമിക്കുക.';
        case ApiErrorType.backendStarting:
          return 'AI സെർവർ ആരംഭിക്കുന്നു. ദയവായി കാത്തിരിക്കുക.';
        case ApiErrorType.noInternet:
        case ApiErrorType.networkError:
          return 'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല. ദയവായി മൊബൈൽ ഡാറ്റ അല്ലെങ്കിൽ വൈ-ഫൈ പരിശോധിക്കുക.';
        case ApiErrorType.timeout:
          return 'സെർവർ പ്രതികരിക്കാൻ സമയം എടുത്തു. ദയവായി വീണ്ടും ശ്രമിക്കുക.';
        default:
          return error.message;
      }
    }
    return error.message;
  }
}
