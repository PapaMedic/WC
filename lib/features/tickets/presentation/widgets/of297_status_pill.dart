// Tickets reusable presentation widget.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';

/// Small visual status marker for draft vs finalized tickets.
class OF297StatusPill extends StatelessWidget {
  final bool isFinalized;

  const OF297StatusPill({
    super.key,
    required this.isFinalized,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFinalized ? AppColors.statusGreen : AppColors.statusAmber;
    final label = isFinalized ? 'Finalized' : 'Draft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
