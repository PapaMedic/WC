// Tickets reusable presentation widget.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

/// Reusable OF-297 form section container.
///
/// Keeping form sections consistent makes the ticket workflow feel like the
/// rest of the app while the form grows over time.
class OF297SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const OF297SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      title: title,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: child,
      ),
    );
  }
}
