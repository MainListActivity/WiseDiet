import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../providers/onboarding_provider.dart';
import '../services/onboarding_service.dart';

class LoadingAnalysisScreen extends ConsumerStatefulWidget {
  const LoadingAnalysisScreen({
    super.key,
    this.autoProcess = true,
    this.processingDuration = const Duration(seconds: 10),
    OnboardingService? service,
  }) : _service = service;

  final bool autoProcess;
  final Duration processingDuration;
  final OnboardingService? _service;

  @override
  ConsumerState<LoadingAnalysisScreen> createState() =>
      _LoadingAnalysisScreenState();
}

class _LoadingAnalysisScreenState extends ConsumerState<LoadingAnalysisScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  late final OnboardingService _service;

  static List<_FloatingTagData> _buildFloatingTags(AppLocalizations l10n) {
    return [
      _FloatingTagData(
        label: l10n.tagMuscleGain,
        alignment: const Alignment(-0.92, -0.36),
        phase: 0.0,
      ),
      _FloatingTagData(
        label: l10n.tagVegan,
        alignment: const Alignment(0.94, -0.14),
        phase: 1.1,
      ),
      _FloatingTagData(
        label: l10n.tagHighProtein,
        alignment: const Alignment(-0.78, 0.34),
        phase: 2.2,
      ),
      _FloatingTagData(
        label: l10n.tagLowGI,
        alignment: const Alignment(0.88, 0.42),
        phase: 3.0,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _service =
        widget._service ??
        OnboardingService(client: ref.read(apiClientProvider));

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.processingDuration,
    )..forward();

    if (widget.autoProcess) {
      _processData();
    }
  }

  Future<void> _processData() async {
    try {
      final profile = ref.read(onboardingProvider);

      await _service.submitProfile(profile);
      await Future.delayed(const Duration(seconds: 2));
      final strategy = await _service.getStrategy();

      if (!mounted) {
        return;
      }

      if (_progressController.value < 1.0) {
        _progressController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 550),
        );
      }

      context.go('/onboarding/strategy', extra: strategy);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorPrefix(e.toString()))));
      context.go('/onboarding/family');
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = (_progressController.value * 100).clamp(0, 100).toInt();
    final floatingTags = _buildFloatingTags(l10n);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _ringController,
          _floatController,
          _progressController,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF2F7FF),
                      Color(0xFFE9F1FF),
                      Color(0xFFF8FCFF),
                    ],
                  ),
                ),
              ),
              const CustomPaint(painter: _GridDotPainter()),
              Positioned(
                left: -90,
                top: 70,
                child: _BlurOrb(
                  color: AppTheme.primary.withOpacity(0.14),
                  size: 210,
                ),
              ),
              Positioned(
                right: -70,
                bottom: 120,
                child: _BlurOrb(
                  color: AppTheme.secondary.withOpacity(0.12),
                  size: 190,
                ),
              ),
              Align(
                child: SizedBox(
                  width: 330,
                  height: 330,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _ringController,
                        child: Container(
                          key: const Key('data-vortex-rings'),
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.16),
                                blurRadius: 40,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _VortexRingPainter(
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.25),
                              AppTheme.primary.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.psychology,
                        size: 46,
                        color: AppTheme.primary,
                      ),
                      ...floatingTags.map(
                        (tag) => _FloatingTag(
                          data: tag,
                          animationValue: _floatController.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.62),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.aiAnalyzingNeeds,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.buildingStrategy,
                      style: const TextStyle(color: Color(0xFF6A7280)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$progress%',
                      key: const Key('analysis-progress-percent'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 220,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: Colors.white.withOpacity(0.7),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.93),
                child: Text(
                  l10n.poweredByWiseDietAi,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.7,
                    color: Color(0xFF7E8CA0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingTagData {
  const _FloatingTagData({
    required this.label,
    required this.alignment,
    required this.phase,
  });

  final String label;
  final Alignment alignment;
  final double phase;
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({required this.data, required this.animationValue});

  final _FloatingTagData data;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin((animationValue * 2 * math.pi) + data.phase);
    final offset = Offset(wave * 9, -wave * 6);

    return Align(
      alignment: data.alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppTheme.primary.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.16),
                blurRadius: 20,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Text(
            data.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppTheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

class _GridDotPainter extends CustomPainter {
  const _GridDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 26.0;
    final dotPaint = Paint()..color = AppTheme.primary.withOpacity(0.08);

    for (double x = 12; x < size.width; x += step) {
      for (double y = 12; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VortexRingPainter extends CustomPainter {
  const _VortexRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radii = [58.0, 84.0, 112.0, 136.0];

    for (int i = 0; i < radii.length; i++) {
      _drawDashedCircle(
        canvas,
        center,
        radius: radii[i],
        dashCount: 44 + (i * 8),
        strokeWidth: i == 0 ? 2.2 : 1.5,
        color: color.withOpacity(0.78 - i * 0.14),
      );
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center, {
    required double radius,
    required int dashCount,
    required double strokeWidth,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = (2 * math.pi) / dashCount;
    const visibleRatio = 0.54;
    for (int i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * visibleRatio,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VortexRingPainter oldDelegate) =>
      oldDelegate.color != color;
}
