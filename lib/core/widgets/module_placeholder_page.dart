import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/status_chip.dart';

class ModulePlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String futureFeatures;

  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.futureFeatures,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TacticalCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(icon, size: 48, color: AppColors.textMuted),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusChip(
                        label: 'Module Stub',
                        color: AppColors.primaryAccent,
                        icon: Icons.build,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TacticalCard(
            title: 'Planned Features',
            child: Text(
              futureFeatures,
              style: const TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
