// Shared UI widget used across app screens.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';

class WildlandCompanionWordmark extends StatelessWidget {
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  const WildlandCompanionWordmark({
    super.key,
    this.maxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 420.0;
          final targetWidth =
              maxWidth ?? (availableWidth < 500 ? 300.0 : 420.0);
          final constrainedWidth = availableWidth < 220
              ? availableWidth
              : targetWidth.clamp(220.0, availableWidth);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constrainedWidth.toDouble(),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'WILDLAND',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  _CompanionLine(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompanionLine extends StatelessWidget {
  const _CompanionLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _AccentLine()),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'COMPANION',
              maxLines: 1,
              style: TextStyle(
                color: AppColors.secondaryAccent,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: MediaQuery.sizeOf(context).width < 360 ? 5 : 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: _AccentLine()),
      ],
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.primaryAccent,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
