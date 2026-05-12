import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';

/// A card with a dark gradient background, subtle olive border, and a
/// decorative topographic contour pattern painted on the right side only.
class TopographicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const TopographicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C201C), // dark charcoal-olive
            Color(0xFF181C18),
            Color(0xFF141714),
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: AppColors.secondaryAccent.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Topographic overlay on right side
            Positioned.fill(
              child: CustomPaint(
                painter: _TopoPainter(),
              ),
            ),
            // Actual content
            if (onTap != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(padding: padding, child: child),
                ),
              )
            else
              Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Only draw on the right 55% of the card
    final startX = size.width * 0.45;

    // Create a clip rect to confine the drawing to the right portion
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(startX, 0, size.width, size.height));

    // Draw concentric, slightly irregular oval contour lines
    final centerX = size.width * 0.85;
    final centerY = size.height * 0.5;

    for (int i = 1; i <= 8; i++) {
      final rx = (i * size.width * 0.10).clamp(0, size.width * 0.8);
      final ry = (i * size.height * 0.09).clamp(0, size.height * 1.2);

      // Slight angular distortion per ring
      final angle = i * 0.08;

      final path = Path();
      const steps = 64;
      for (int s = 0; s <= steps; s++) {
        final t = 2 * math.pi * s / steps;
        final x = centerX + rx * math.cos(t + angle) * (1 + 0.06 * math.sin(3 * t));
        final y = centerY + ry * math.sin(t) * (1 + 0.04 * math.cos(2 * t + angle));
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      // Slightly vary opacity per ring
      paint.color = AppColors.secondaryAccent.withValues(
        alpha: (0.06 + (8 - i) * 0.005).clamp(0.0, 1.0),
      );
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TopoPainter oldDelegate) => false;
}
