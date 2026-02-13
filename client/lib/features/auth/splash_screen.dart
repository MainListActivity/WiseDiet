import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

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
    final logoSize = (192 * scaleFactor).clamp(120.0, 280.0);
    final haloSize = logoSize * 1.25;
    final logoInnerPadding = logoSize * 0.083; // ~16/192

    final titleSize = (40 * scaleFactor).clamp(28.0, 56.0);
    final sloganSize = (18 * scaleFactor).clamp(14.0, 26.0);
    final loadingBarWidth = (140 * scaleFactor).clamp(100.0, 200.0);
    final loadingTextSize = (11 * scaleFactor).clamp(9.0, 15.0);

    // Spacing
    final logoToTextGap = (40 * scaleFactor).clamp(24.0, 60.0);
    final bottomPadding = (32 * scaleFactor).clamp(16.0, 48.0);

    // Text offset calculation for Stack layout
    final textTopOffset = haloSize / 2 + logoToTextGap;

    final topBlobSize = screenWidth * 0.8;
    final bottomBlobSize = screenWidth * 0.65;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Theme aware
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --- Decorative Background Blobs ---
          Positioned(
            top: -screenHeight * 0.1,
            right: -screenWidth * 0.1,
            child: Container(
              width: topBlobSize,
              height: topBlobSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -screenHeight * 0.1,
            left: -screenWidth * 0.1,
            child: Container(
              width: bottomBlobSize,
              height: bottomBlobSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // --- Logo Section (Absolute Center) ---
          ScaleTransition(
            scale: _logoScaleAnimation,
            child: _buildLogoSection(
              context,
              logoSize: logoSize,
              haloSize: haloSize,
              innerPadding: logoInnerPadding,
            ),
          ),

          // --- Text Section ---
          FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(0, textTopOffset + logoSize / 4),
              child: _buildTextSection(
                context,
                titleSize: titleSize,
                sloganSize: sloganSize,
              ),
            ),
          ),

          // --- Footer / Loading ---
          Positioned(
            bottom: bottomPadding,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildFooterSection(
                context,
                barWidth: loadingBarWidth,
                textSize: loadingTextSize,
              ),
            ),
          ),
        ],
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

    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo
        Container(
          width: haloSize,
          height: haloSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
          ),
        ),
        // Logo Container
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // In dark mode use dark surface, light mode use white
            color: isDark ? const Color(0xFF1E2621) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                blurRadius: logoSize * 0.21,
                spreadRadius: 2,
                offset: Offset(0, logoSize * 0.042),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(logoSize, logoSize),
                  painter: _DotGridPainter(
                    color: theme.colorScheme.primary.withValues(alpha: 0.03),
                    spacing: math.max(12, logoSize * 0.083),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(innerPadding),
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: logoSize - innerPadding * 2,
                    height: logoSize - innerPadding * 2,
                    // If flutter_svg doesn't respect media query, this might need manual ColorFilter.
                    // But standard logo.svg usually has dark mode classes.
                    // For safety, we can trust the SVG or if needed use a ColorFilter in future.
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection(
    BuildContext context, {
    required double titleSize,
    required double sloganSize,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WiseDiet',
          style: GoogleFonts.spaceGrotesk(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            // Adaptive text color
            color: isDark ? Colors.white : const Color(0xFF131514),
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        SizedBox(height: titleSize * 0.2),
        Text(
          'Smart Diet, Smart You',
          style: GoogleFonts.spaceGrotesk(
            fontSize: sloganSize,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.secondary.withValues(alpha: 0.9),
            letterSpacing: 1.2,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          width: barWidth,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: textSize * 1.1),
                  Text(
                    'LOADING',
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.3,
          child: Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: textSize * 0.9,
              fontFamily: 'monospace',
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _DotGridPainter({required this.color, this.spacing = 16.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) =>
      color != oldDelegate.color || spacing != oldDelegate.spacing;
}
