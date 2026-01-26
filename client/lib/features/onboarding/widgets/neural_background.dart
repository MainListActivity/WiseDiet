import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NeuralBackground extends StatelessWidget {
  const NeuralBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeuralPainter(
        color: AppTheme.primary.withOpacity(0.3), // Using opacity as per design
      ),
      size: Size.infinite,
    );
  }
}

class _NeuralPainter extends CustomPainter {
  final Color color;

  _NeuralPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dashPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw lines approximating the design
    // M80 60 C 80 150, 250 150, 260 280 (scaled relative to screen size)

    final w = size.width;
    final h = size.height;

    // Node 1
    final p1 = Offset(w * 0.2, h * 0.15);
    // Node 2
    final p2 = Offset(w * 0.75, h * 0.65);
    // Node 3 (smaller)
    final p3 = Offset(w * 0.5, h * 0.35);

    final path1 = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(p1.dx, h * 0.35, w * 0.7, h * 0.35, p2.dx, p2.dy);

    _drawDashedPath(canvas, path1, dashPaint);

    // Another line
    // M80 60 C 120 100, 160 80, 175 140
    final path2 = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(w * 0.35, h * 0.25, w * 0.45, h * 0.2, p3.dx, p3.dy);

    canvas.drawPath(path2, paint..color = color.withOpacity(0.5));

    // Draw Nodes (Circles)
    final fillPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(p1, 3, fillPaint);
    canvas.drawCircle(p2, 3, fillPaint);
    canvas.drawCircle(p3, 2, fillPaint..color = AppTheme.primary.withOpacity(0.5));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    // Simple implementation of dashed path
    // For a smoother curve dash, we can use path_drawing package or just draw segments.
    // For this MVP, solid line with low opacity is fine, or simple dashes.
    // Let's stick to solid for now but slightly stronger to be visible.
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
