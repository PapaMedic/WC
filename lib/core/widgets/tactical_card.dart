// Shared UI widget used across app screens.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';

/// Lightweight tactical card with no painters, filters, masks, or animated
/// layers.
class TacticalCard extends StatelessWidget {
  static const Color background = Color(0xFF111611);
  static const Color backgroundAlt = Color(0xFF1B2118);
  static const Color text = AppColors.textPrimary;
  static const Color muted = AppColors.textMuted;
  static const Color accent = AppColors.primaryAccent;

  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const TacticalCard({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader =
        icon != null || title != null || subtitle != null || trailing != null;

    final cardContent = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accent, size: 21),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: muted,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    fontSize: 12,
                                  ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (child != null)
            DefaultTextStyle(
              style: const TextStyle(color: text),
              child: child!,
            ),
        ],
      ),
    );

    final card = Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundAlt, background, Color(0xFF0E130E)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.secondaryAccent.withValues(alpha: 0.34),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: cardContent,
    );

    if (onTap == null) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
