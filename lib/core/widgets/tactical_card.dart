import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';

/// General-purpose card with the tactical dark styling.
/// For the topographic overlay effect, use [TopographicCard] instead.
class TacticalCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const TacticalCard({
    super.key,
    this.title,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C201C),
            Color(0xFF181C18),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondaryAccent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }
}
