import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../scan/scan_screen.dart';
import '../history/history_screen.dart';
import '../about/about_screen.dart';
import '../settings/settings_screen.dart';
import '../assistant/assistant_home_screen.dart';
import '../../widgets/floating_leaf.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Nav indices: 0=Home, 1=Scan(push), 2=Assistant(push), 3=History, 4=About
  int? _stackIndex(int navIndex) {
    switch (navIndex) {
      case 0: return 0; // Home
      case 1: return null; // Scan — full screen push
      case 2: return null; // Assistant — full screen push
      case 3: return 1; // History
      case 4: return 2; // About
      default: return 0;
    }
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
      return;
    }
    if (navIndex == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AssistantHomeScreen()),
      );
      return;
    }
    setState(() => _selectedIndex = navIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stackIdx = _stackIndex(_selectedIndex) ?? 0;

    final screens = [
      const _HomeTab(),
      const HistoryScreen(),
      const AboutScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: stackIdx,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    // selectedIndex excludes the push-only tabs (1=Scan, 2=Assistant)
    final displayIndex = (_selectedIndex == 1 || _selectedIndex == 2) ? 0 : _selectedIndex;
    return NavigationBar(
      selectedIndex: displayIndex,
      onDestinationSelected: _onNavTap,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 0,
      indicatorColor: AppTheme.emeraldGreen.withOpacity(0.12),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded, color: AppTheme.emeraldGreen),
          label: l10n.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.camera_alt_outlined),
          selectedIcon: const Icon(Icons.camera_alt_rounded, color: AppTheme.emeraldGreen),
          label: l10n.navScan,
        ),
        NavigationDestination(
          icon: const Icon(Icons.smart_toy_outlined),
          selectedIcon: const Icon(Icons.smart_toy_rounded, color: AppTheme.emeraldGreen),
          label: l10n.navAssistant,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history_rounded, color: AppTheme.emeraldGreen),
          label: l10n.navHistory,
        ),
        NavigationDestination(
          icon: const Icon(Icons.info_outline_rounded),
          selectedIcon: const Icon(Icons.info_rounded, color: AppTheme.emeraldGreen),
          label: l10n.navAbout,
        ),
      ],
    );
  }
}

/// The actual home tab content
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.homeGradient(isDark),
        child: Stack(
          children: [
            // Floating leaf decorations
            const FloatingLeafBackground(),

            // Main scrollable content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(context, isDark),
                    const SizedBox(height: 32),
                    _buildHeroSection(context),
                    const SizedBox(height: 28),
                    _buildScanButtons(context),
                    const SizedBox(height: 24),
                    _buildAssistantBanner(context, isDark),
                    const SizedBox(height: 28),
                    _buildFeatureCards(context, isDark),
                    const SizedBox(height: 28),
                    _buildSupportedCrops(context, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBanner(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFA7F3D0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AssistantHomeScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.emeraldGreen, AppTheme.emeraldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emeraldGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.homeAiBannerTitle,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF065F46),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.homeAiBannerDesc,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF047857),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.emeraldGreen,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 450.ms).slideY(begin: 0.1).fadeIn();
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.emeraldGreen, AppTheme.emeraldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emeraldGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'AgroVision ',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppTheme.emeraldGreen,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.cropDiseaseDetection,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const Spacer(),
        // Backend status dot
        _BackendStatusDot(isDark: isDark),
        const SizedBox(width: 8),
        // Settings button
        IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            ));
          },
          icon: const Icon(Icons.settings_outlined),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.emeraldGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: AppTheme.emeraldGreen.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: AppTheme.emeraldGreen),
              const SizedBox(width: 6),
              Text(
                l10n.aiPoweredAgriculture,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ],
          ),
        ).animate().slideX(begin: -0.2, duration: 500.ms).fadeIn(),
        const SizedBox(height: 16),
        Text(
          l10n.heroTitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 28,
            height: 1.2,
          ),
        ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 100.ms).fadeIn(),
        const SizedBox(height: 12),
        Text(
          l10n.heroSubtitle,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            height: 1.5,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildScanButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Primary: Camera
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ScanScreen(openCamera: true),
              ));
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: Text(l10n.scanWithCamera),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              shadowColor: AppTheme.emeraldGreen.withOpacity(0.35),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn(),
        ),
        const SizedBox(height: 12),
        // Secondary: Gallery
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ScanScreen(openCamera: false),
              ));
            },
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            label: Text(l10n.uploadFromGallery),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ).animate(delay: 400.ms).slideY(begin: 0.2).fadeIn(),
        ),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.whatWeDetect,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.eco_rounded,
                color: AppTheme.emeraldGreen,
                title: l10n.cropId,
                subtitle: l10n.cropIdDesc,
                bg: cardBg,
                border: border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: Icons.biotech_rounded,
                color: const Color(0xFF8B5CF6),
                title: l10n.diseaseTitle,
                subtitle: l10n.diseaseDesc,
                bg: cardBg,
                border: border,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                icon: Icons.spa_rounded,
                color: const Color(0xFF10B981),
                title: l10n.treatmentTitle,
                subtitle: l10n.treatmentDesc,
                bg: cardBg,
                border: border,
              ),
            ),
          ],
        ).animate(delay: 500.ms).fadeIn(),
      ],
    );
  }

  Widget _buildSupportedCrops(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    const crops = [
      ('🫘', 'Blackgram'), ('☁️', 'Cotton'), ('🍆', 'Eggplant'),
      ('🥜', 'Groundnut'), ('🌾', 'Paddy'), ('🎋', 'Sugarcane'),
      ('🌻', 'Sunflower'), ('🍅', 'Tomato'), ('🌿', 'Turmeric'), ('🌾', 'Wheat'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supportedCrops,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: crops.map((c) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    l10n.cropName(c.$2),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ).animate(delay: 600.ms).fadeIn(),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.border,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Small animated dot showing backend status in the home app bar.
class _BackendStatusDot extends StatefulWidget {
  const _BackendStatusDot({required this.isDark});
  final bool isDark;

  @override
  State<_BackendStatusDot> createState() => _BackendStatusDotState();
}

class _BackendStatusDotState extends State<_BackendStatusDot> {
  bool? _online;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final online = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _online = online;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _checking
        ? Colors.grey
        : (_online == true ? AppTheme.emeraldGreen : Colors.orange);
    final tooltip = _checking
        ? l10n.backendConnecting
        : (_online == true ? l10n.backendOnline : l10n.backendOffline);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: _check,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _checking
                  ? SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: color),
                    )
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 5),
              Text(
                _checking
                    ? l10n.loading
                    : (_online == true ? (l10n.locale == 'ta' ? 'ஆன்லைன்' : 'Online') : (l10n.locale == 'ta' ? 'ஆஃப்லைன்' : 'Offline')),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
