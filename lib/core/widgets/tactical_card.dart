import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';

class TacticalCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onTap;

  const TacticalCard({
    super.key,
    this.title,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: onTap != null
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
