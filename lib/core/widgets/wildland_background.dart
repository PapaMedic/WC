import 'package:flutter/material.dart';

/// A full-screen background widget using the app background image,
/// plus dark overlays so foreground UI stays readable.
class WildlandBackground extends StatelessWidget {
  final Widget child;

  const WildlandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/wc-background.png',
            fit: BoxFit.cover,
          ),
        ),

        // Main dark overlay for readability.
        Positioned.fill(
          child: Container(color: const Color(0xFF050705).withOpacity(0.68)),
        ),

        // Subtle vertical gradient for premium depth.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.30),
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Very subtle olive tint to keep the theme cohesive.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  const Color(0xFF556B2F).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
