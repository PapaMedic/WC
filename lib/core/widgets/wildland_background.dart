import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A full-screen background widget with a dark charcoal gradient and
/// subtle mountain/tree silhouettes painted via CustomPainter.
class WildlandBackground extends StatelessWidget {
  final Widget child;

  const WildlandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0F0D), // near-black at top
                Color(0xFF141816), // very dark charcoal mid
                Color(0xFF111311), // slightly lighter at bottom
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Painted mountain/tree silhouettes
        CustomPaint(
          painter: _MountainSilhouettePainter(),
        ),
        // App content on top
        child,
      ],
    );
  }
}

class _MountainSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2119) // very dark olive-green
      ..style = PaintingStyle.fill;

    // ── Far-range mountains (lighter layer — drawn first) ──
    final farPaint = Paint()
      ..color = const Color(0xFF161D15)
      ..style = PaintingStyle.fill;

    final farPath = Path();
    farPath.moveTo(0, size.height * 0.38);
    farPath.lineTo(size.width * 0.08, size.height * 0.22);
    farPath.lineTo(size.width * 0.18, size.height * 0.34);
    farPath.lineTo(size.width * 0.30, size.height * 0.15);
    farPath.lineTo(size.width * 0.44, size.height * 0.28);
    farPath.lineTo(size.width * 0.58, size.height * 0.12);
    farPath.lineTo(size.width * 0.72, size.height * 0.26);
    farPath.lineTo(size.width * 0.84, size.height * 0.18);
    farPath.lineTo(size.width, size.height * 0.30);
    farPath.lineTo(size.width, 0);
    farPath.lineTo(0, 0);
    farPath.close();
    canvas.drawPath(farPath, farPaint);

    // ── Mid-range mountains ──
    final midPath = Path();
    midPath.moveTo(0, size.height * 0.44);
    midPath.lineTo(size.width * 0.05, size.height * 0.30);
    midPath.lineTo(size.width * 0.14, size.height * 0.42);
    midPath.lineTo(size.width * 0.24, size.height * 0.22);
    midPath.lineTo(size.width * 0.36, size.height * 0.38);
    midPath.lineTo(size.width * 0.50, size.height * 0.20);
    midPath.lineTo(size.width * 0.64, size.height * 0.36);
    midPath.lineTo(size.width * 0.76, size.height * 0.24);
    midPath.lineTo(size.width * 0.88, size.height * 0.38);
    midPath.lineTo(size.width, size.height * 0.28);
    midPath.lineTo(size.width, 0);
    midPath.lineTo(0, 0);
    midPath.close();
    canvas.drawPath(midPath, paint);

    // ── Foreground tree line ──
    final treePaint = Paint()
      ..color = const Color(0xFF131A12) // darkest silhouette
      ..style = PaintingStyle.fill;

    _drawTreeLine(canvas, size, treePaint);
  }

  void _drawTreeLine(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final rng = math.Random(42); // fixed seed for determinism
    double x = 0;
    final baseY = size.height * 0.50;

    path.moveTo(0, size.height);
    path.lineTo(0, baseY);

    while (x < size.width) {
      final treeWidth = 18.0 + rng.nextDouble() * 24;
      final treeHeight = 28.0 + rng.nextDouble() * 32;

      // Simple triangle tree
      path.lineTo(x, baseY + rng.nextDouble() * 8 - 4);
      path.lineTo(x + treeWidth / 2, baseY - treeHeight);
      path.lineTo(x + treeWidth, baseY + rng.nextDouble() * 8 - 4);

      x += treeWidth + rng.nextDouble() * 6;
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MountainSilhouettePainter oldDelegate) => false;
}
