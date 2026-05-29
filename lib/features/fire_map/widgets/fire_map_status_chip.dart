import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';

enum FireMapFeedStatus { live, cached, offline }

class FireMapStatusChip extends StatelessWidget {
  final FireMapFeedStatus status;
  final DateTime? lastUpdated;

  const FireMapStatusChip({
    super.key,
    required this.status,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FireMapFeedStatus.live => AppColors.statusGreen,
      FireMapFeedStatus.cached => AppColors.statusAmber,
      FireMapFeedStatus.offline => AppColors.statusRed,
    };
    final label = switch (status) {
      FireMapFeedStatus.live => 'Live',
      FireMapFeedStatus.cached => 'Cached',
      FireMapFeedStatus.offline => 'Offline',
    };
    final updated = lastUpdated == null
        ? null
        : DateFormat('MMM d, HH:mm').format(lastUpdated!.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xE6111511),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            updated == null ? label : '$label  |  Last updated: $updated',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
