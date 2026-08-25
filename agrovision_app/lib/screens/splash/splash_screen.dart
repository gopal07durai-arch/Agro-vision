import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/home_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Navigate to Home after splash
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: AppTheme.splashGradient,
        child: Stack(
          children: [
            // Animated radial glows
            _buildGlowCircle(
              top: MediaQuery.of(context).size.height * 0.15,
              left: MediaQuery.of(context).size.width * 0.15,
              size: 240,
              color: Colors.white.withOpacity(0.06),
            ),
            _buildGlowCircle(
              bottom: MediaQuery.of(context).size.height * 0.2,
              right: MediaQuery.of(context).size.width * 0.1,
              size: 180,
              color: Colors.white.withOpacity(0.04),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.3, 0.3),
                          curve: Curves.elasticOut,
                          duration: 800.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'AgroVision ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            color: Color(0xFF6EE7B7), // emerald-300
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.3,
                          curve: Curves.easeOut,
                          duration: 600.ms,
                          delay: 300.ms)
                      .fadeIn(duration: 600.ms, delay: 300.ms),

                  const SizedBox(height: 10),

                  Text(
                    l10n.appSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75),
                      letterSpacing: 0.2,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms),

                  const SizedBox(height: 48),

                  // Progress bar
                  SizedBox(
                    width: 180,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: _progressController.value,
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6EE7B7),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

                  const SizedBox(height: 20),

                  // Feature pills
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeaturePill(icon: Icons.camera_alt_rounded, label: l10n.featureCamera),
                      const SizedBox(width: 8),
                      _FeaturePill(icon: Icons.psychology_rounded, label: l10n.featureAiDetection),
                      const SizedBox(width: 8),
                      _FeaturePill(icon: Icons.eco_rounded, label: l10n.featureTreatment),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                ],
              ),
            ),

            // Version tag at bottom
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Text(
                'v1.0.0 · Powered by ML',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 3000.ms,
          curve: Curves.easeInOut),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
