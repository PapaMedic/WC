import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class TopoDashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String accentLabel;
  final Widget child;

  const TopoDashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accentLabel,
    required this.child,
  });

  static const Color cardBg = Color(0xCC101611);
  static const Color border = Color(0xFF263226);
  static const Color text = Color(0xFFE8ECE3);
  static const Color muted = Color(0xFFA8B2A0);

  // Match this to your side menu orange.
  static const Color accent = Color(0xFFFF5A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 178),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: cardBg,
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: _TopoContourPainter(),
              ),
            ),

            // Dark left-side readability shield.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF101611).withOpacity(0.96),
                      const Color(0xFF101611).withOpacity(0.88),
                      const Color(0xFF101611).withOpacity(0.72),
                      const Color(0xFF101611).withOpacity(0.48),
                      const Color(0xFF101611).withOpacity(0.24),
                      TopoDashboardCard.accent.withOpacity(0.018),
                    ],
                    stops: const [0.0, 0.25, 0.48, 0.68, 0.86, 1.0],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: accent, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(label: accentLabel),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DefaultTextStyle(
                    style: const TextStyle(color: text),
                    child: child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 125),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TopoDashboardCard.accent.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: TopoDashboardCard.accent.withOpacity(0.45),
        ),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TopoDashboardCard.accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TopoContourPainter extends CustomPainter {
  const _TopoContourPainter();

  static const Color lineColor = Color(0xFFA8B2A0);
  static const Color accentLineColor = TopoDashboardCard.accent;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 8.0;
    const scale = 0.018;
    const contourInterval = 0.072;

    for (double level = 0.16; level <= 0.92; level += contourInterval) {
      final band = (level / contourInterval).round();
      final isIndexLine = band % 5 == 0;

      for (double y = 0; y < size.height; y += cellSize) {
        for (double x = 0; x < size.width; x += cellSize) {
          final midX = x + cellSize / 2;
          final detail = _rightSideFade(midX, size.width);

          // Density fade:
          // Left side: mostly hide minor lines.
          // Middle: show every other minor line.
          // Right side: show full contour detail.
          if (!isIndexLine) {
            if (detail < 0.22) continue;
            if (detail < 0.48 && band % 4 != 0) continue;
            if (detail < 0.72 && band % 2 != 0) continue;
          }

          final p0 = Offset(x, y);
          final p1 = Offset(x + cellSize, y);
          final p2 = Offset(x + cellSize, y + cellSize);
          final p3 = Offset(x, y + cellSize);

          final h0 = _height(p0.dx * scale, p0.dy * scale);
          final h1 = _height(p1.dx * scale, p1.dy * scale);
          final h2 = _height(p2.dx * scale, p2.dy * scale);
          final h3 = _height(p3.dx * scale, p3.dy * scale);

          final points = <Offset>[];

          void addIntersection(Offset a, Offset b, double ha, double hb) {
            final crosses =
                (ha < level && hb >= level) || (hb < level && ha >= level);

            if (!crosses || ha == hb) return;

            final t = (level - ha) / (hb - ha);
            points.add(
              Offset(
                a.dx + (b.dx - a.dx) * t,
                a.dy + (b.dy - a.dy) * t,
              ),
            );
          }

          addIntersection(p0, p1, h0, h1);
          addIntersection(p1, p2, h1, h2);
          addIntersection(p2, p3, h2, h3);
          addIntersection(p3, p0, h3, h0);

          if (points.length == 2) {
            _drawSegment(canvas, points[0], points[1], size.width, isIndexLine);
          } else if (points.length == 4) {
            _drawSegment(canvas, points[0], points[1], size.width, isIndexLine);
            _drawSegment(canvas, points[2], points[3], size.width, isIndexLine);
          }
        }
      }
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset a,
    Offset b,
    double width,
    bool isIndexLine,
  ) {
    final midX = (a.dx + b.dx) / 2;
    final fade = _rightSideFade(midX, width);

    final lineOpacity = isIndexLine
        ? ui.lerpDouble(0.01, 0.085, fade)!
        : ui.lerpDouble(0.006, 0.085, fade)!;

    if (lineOpacity <= 0.008) return;

    if (isIndexLine) {
      final glowPaint = Paint()
        ..color = accentLineColor.withOpacity(ui.lerpDouble(0.0, 0.025, fade)!)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      canvas.drawLine(a, b, glowPaint);
    }

    final paint = Paint()
      ..color = (isIndexLine ? accentLineColor : lineColor).withOpacity(lineOpacity)
      ..strokeWidth = isIndexLine ? 1.15 : 0.85
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(a, b, paint);
  }

  static double _rightSideFade(double x, double width) {
    final t = (x / width).clamp(0.0, 1.0);

    // Keeps left side quiet, then ramps up detail toward the right.
    final shifted = ((t - 0.22) / 0.78).clamp(0.0, 1.0);

    return Curves.easeInOutCubic.transform(shifted);
  }

  static double _height(double x, double y) {
    double total = 0;
    double amplitude = 1;
    double frequency = 1;
    double max = 0;

    for (int i = 0; i < 5; i++) {
      total += _valueNoise(x * frequency, y * frequency) * amplitude;
      max += amplitude;
      amplitude *= 0.5;
      frequency *= 2.0;
    }

    return total / max;
  }

  static double _valueNoise(double x, double y) {
    final xi = x.floor();
    final yi = y.floor();

    final xf = x - xi;
    final yf = y - yi;

    final a = _random(xi, yi);
    final b = _random(xi + 1, yi);
    final c = _random(xi, yi + 1);
    final d = _random(xi + 1, yi + 1);

    final u = _fade(xf);
    final v = _fade(yf);

    return _lerp(
      _lerp(a, b, u),
      _lerp(c, d, u),
      v,
    );
  }

  static double _random(int x, int y) {
    final n = math.sin(x * 127.1 + y * 311.7) * 43758.5453123;
    return n - n.floor();
  }

  static double _fade(double t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}