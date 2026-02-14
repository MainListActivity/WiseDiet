import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    // Start from scale 1.0 to match native splash, subtle breathe to 1.05
    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            widget.onFinished();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    final shortestSide = mq.size.shortestSide;
    final theme = Theme.of(context);

    // --- Responsive scaling ---
    final scaleFactor = (shortestSide / 390).clamp(0.7, 1.6);
    final logoSize = (160 * scaleFactor).clamp(100.0, 240.0);
    final haloSize = logoSize * 1.3;
    final logoInnerPadding = logoSize * 0.083;

    final titleSize = (36 * scaleFactor).clamp(26.0, 52.0);
    final sloganSize = (15 * scaleFactor).clamp(12.0, 22.0);
    final loadingBarWidth = (160 * scaleFactor).clamp(100.0, 220.0);
    final loadingTextSize = (11 * scaleFactor).clamp(9.0, 15.0);

    // Spacing
    final logoToTextGap = (28 * scaleFactor).clamp(18.0, 44.0);
    final bottomPadding = (40 * scaleFactor).clamp(24.0, 56.0);

    final topBlobSize = screenWidth * 0.75;
    final bottomBlobSize = screenWidth * 0.6;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // --- Decorative Background Blobs ---
            Positioned(
              top: -screenHeight * 0.12,
              right: -screenWidth * 0.15,
              child: Container(
                width: topBlobSize,
                height: topBlobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.10),
                      theme.colorScheme.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -screenHeight * 0.08,
              left: -screenWidth * 0.15,
              child: Container(
                width: bottomBlobSize,
                height: bottomBlobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.06),
                      theme.colorScheme.secondary.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ),

            // --- Main Content ---
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    // Top spacer
                    const Expanded(flex: 3, child: SizedBox.shrink()),

                    // Logo + Text group, centered
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: _buildLogoSection(
                        context,
                        logoSize: logoSize,
                        haloSize: haloSize,
                        innerPadding: logoInnerPadding,
                      ),
                    ),
                    SizedBox(height: logoToTextGap),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTextSection(
                        context,
                        titleSize: titleSize,
                        sloganSize: sloganSize,
                      ),
                    ),

                    // Bottom spacer
                    const Expanded(flex: 3, child: SizedBox.shrink()),

                    // Footer / Loading at bottom — CENTERED
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildFooterSection(
                        context,
                        barWidth: loadingBarWidth,
                        textSize: loadingTextSize,
                      ),
                    ),
                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(
    BuildContext context, {
    required double logoSize,
    required double haloSize,
    required double innerPadding,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use separate SVGs with hardcoded colors (flutter_svg doesn't support CSS var())
    final logoAsset = isDark
        ? 'assets/images/logo_dark.svg'
        : 'assets/images/logo_light.svg';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer halo glow
        Container(
          width: haloSize,
          height: haloSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.06),
                theme.colorScheme.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Logo — SVG already contains its own circular background & border
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                blurRadius: logoSize * 0.3,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: logoSize * 0.15,
                offset: Offset(0, logoSize * 0.03),
              ),
            ],
          ),
          child: SvgPicture.asset(logoAsset, width: logoSize, height: logoSize),
        ),
      ],
    );
  }

  Widget _buildTextSection(
    BuildContext context, {
    required double titleSize,
    required double sloganSize,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.appTitle,
          style: GoogleFonts.inter(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF131514),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        SizedBox(height: titleSize * 0.25),
        Text(
          l10n.slogan,
          style: GoogleFonts.inter(
            fontSize: sloganSize,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : theme.colorScheme.secondary.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection(
    BuildContext context, {
    required double barWidth,
    required double textSize,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Loading progress bar
          SizedBox(
            width: barWidth,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        // Fill
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                  theme.colorScheme.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: textSize * 1.2),
          // Loading text
          Text(
            l10n.loading,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: textSize,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25),
              letterSpacing: 4.0,
            ),
          ),
          const SizedBox(height: 10),
          // Version
          Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: textSize * 0.85,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
