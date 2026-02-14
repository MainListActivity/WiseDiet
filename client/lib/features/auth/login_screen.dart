import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _googleLoading = false;
  bool _githubLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleGithubLogin() async {
    setState(() => _githubLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGithub();
    } finally {
      if (mounted) setState(() => _githubLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final shortestSide = mq.size.shortestSide;
    final scaleFactor = (shortestSide / 390).clamp(0.75, 1.4);

    // Responsive sizing
    final logoContainerSize = (112.0 * scaleFactor).clamp(88.0, 150.0);
    final logoPadding = (logoContainerSize * 0.18).clamp(14.0, 28.0);
    final titleSize = (28.0 * scaleFactor).clamp(22.0, 36.0);
    final sloganSize = (15.0 * scaleFactor).clamp(12.0, 20.0);
    final buttonTextSize = (15.0 * scaleFactor).clamp(13.0, 18.0);
    final iconSize = (18.0 * scaleFactor).clamp(14.0, 24.0);
    final footerSize = (11.0 * scaleFactor).clamp(9.0, 14.0);
    final horizontalPadding = (32.0 * scaleFactor).clamp(24.0, 48.0);

    final logoAsset = isDark
        ? 'assets/images/logo_dark.svg'
        : 'assets/images/logo_light.svg';

    // Colors
    final cardColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : Colors.white;
    final borderColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : const Color(0xFFE8E8E8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF2C3E50);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF2C3E50).withValues(alpha: 0.7);
    final textMuted = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFF2C3E50).withValues(alpha: 0.4);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFD0D0D0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  // ═══ Top flex spacer (3 份) ═══
                  const Expanded(flex: 3, child: SizedBox.shrink()),

                  // ═══ Logo ═══
                  _buildLogo(
                    context,
                    logoAsset: logoAsset,
                    containerSize: logoContainerSize,
                    padding: logoPadding,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24 * scaleFactor),

                  // ═══ Title & Slogan ═══
                  Text(
                    'Join WiseDiet',
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  Text(
                    'Smart Diet, Smart You',
                    style: GoogleFonts.inter(
                      fontSize: sloganSize,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),

                  // ═══ Middle flex spacer (2 份) ═══
                  const Expanded(flex: 2, child: SizedBox.shrink()),

                  // ═══ Google Button ═══
                  _buildSocialButton(
                    context,
                    label: 'Continue with Google',
                    icon: FaIcon(
                      FontAwesomeIcons.google,
                      size: iconSize,
                      color: textPrimary,
                    ),
                    isLoading: _googleLoading,
                    onPressed: _handleGoogleLogin,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textPrimary,
                    textSize: buttonTextSize,
                    scaleFactor: scaleFactor,
                  ),
                  SizedBox(height: 12 * scaleFactor),

                  // ═══ GitHub Button ═══
                  _buildSocialButton(
                    context,
                    label: 'Continue with GitHub',
                    icon: FaIcon(
                      FontAwesomeIcons.github,
                      size: iconSize,
                      color: textPrimary,
                    ),
                    isLoading: _githubLoading,
                    onPressed: _handleGithubLogin,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textPrimary,
                    textSize: buttonTextSize,
                    scaleFactor: scaleFactor,
                  ),

                  // ═══ Divider ═══
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 18 * scaleFactor,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(color: dividerColor, thickness: 0.5),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                          ),
                          child: Text(
                            'OR LOGIN WITH EMAIL',
                            style: GoogleFonts.inter(
                              fontSize: footerSize,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: dividerColor, thickness: 0.5),
                        ),
                      ],
                    ),
                  ),

                  // ═══ Email Sign-in ═══
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement email sign-in
                    },
                    icon: Icon(
                      Icons.mail_outline_rounded,
                      size: iconSize,
                      color: textPrimary,
                    ),
                    label: Text(
                      'Sign in with Email',
                      style: GoogleFonts.inter(
                        fontSize: buttonTextSize * 0.9,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 12 * scaleFactor,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // ═══ Bottom flex spacer (2 份) ═══
                  const Expanded(flex: 2, child: SizedBox.shrink()),

                  // ═══ Terms & Privacy Footer ═══
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 16 * scaleFactor,
                      left: 8,
                      right: 8,
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: footerSize,
                          color: textMuted,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'By continuing, you acknowledge that you have\nread and agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: textMuted.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: textMuted.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo with circular container, subtle shadow, and border
  Widget _buildLogo(
    BuildContext context, {
    required String logoAsset,
    required double containerSize,
    required double padding,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: SvgPicture.asset(logoAsset, fit: BoxFit.contain),
    );
  }

  /// Social Sign-in Button
  Widget _buildSocialButton(
    BuildContext context, {
    required String label,
    required Widget icon,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required double textSize,
    required double scaleFactor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.06),
          highlightColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: 16 * scaleFactor,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isLoading
                  ? [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ]
                  : [
                      icon,
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: textSize,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
