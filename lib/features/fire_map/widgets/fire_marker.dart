import 'package:flutter/material.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';

class FireMarker extends StatelessWidget {
  final bool isSelected;
  final bool isRx;
  final bool isResolved;
  final bool isCached;
  final String label;

  const FireMarker({
    super.key,
    required this.isSelected,
    required this.isRx,
    required this.isResolved,
    required this.isCached,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor = isResolved
        ? const Color(0xFF767B72)
        : isRx
            ? AppColors.secondaryAccent
            : AppColors.primaryAccent;
    final background = isResolved
        ? const Color(0xFF242722)
        : isRx
            ? const Color(0xFF1F3116)
            : const Color(0xFF3A1206);
    final glowAlpha = isResolved ? 0.13 : 0.38;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: isSelected ? 42 : 34,
          height: isSelected ? 42 : 34,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : markerColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: markerColor.withValues(alpha: glowAlpha),
                blurRadius: isResolved ? 5 : (isSelected ? 16 : 8),
                spreadRadius: isResolved ? 0 : (isSelected ? 2 : 0),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: isRx
                    ? Text(
                        'RX',
                        style: TextStyle(
                          color:
                              isSelected ? AppColors.textPrimary : markerColor,
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Icon(
                        Icons.local_fire_department,
                        color: isSelected ? AppColors.textPrimary : markerColor,
                        size: isSelected ? 26 : 21,
                      ),
              ),
              if (isCached)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151A15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.statusAmber,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppColors.statusAmber,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE6111511),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
