import 'package:flutter/material.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';

class FireMarker extends StatelessWidget {
  final bool isRx;
  final bool isResolved;
  final bool isCached;
  final double? acres;

  const FireMarker({
    super.key,
    required this.isRx,
    required this.isResolved,
    required this.isCached,
    required this.acres,
  });

  @override
  Widget build(BuildContext context) {
    final sizeColor = _colorForAcreage(acres);
    final markerColor = isResolved
        ? const Color(0xFF767B72)
        : isRx
            ? AppColors.secondaryAccent
            : sizeColor;
    final background = isResolved
        ? const Color(0xFF242722)
        : isRx
            ? const Color(0xFF1F3116)
            : _backgroundForAcreage(acres);

    return RepaintBoundary(
      child: SizedBox(
        width: 34,
        height: 34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: markerColor,
              width: 1.5,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: isRx
                    ? Text(
                        'RX',
                        style: TextStyle(
                          color: markerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Icon(
                        Icons.local_fire_department,
                        color: markerColor,
                        size: 21,
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
      ),
    );
  }

  Color _colorForAcreage(double? acres) {
    if (acres == null || acres < 10) {
      return const Color(0xFFFFD84D);
    }
    if (acres < 100) {
      return const Color(0xFFFF8A1C);
    }
    return const Color(0xFFE53935);
  }

  Color _backgroundForAcreage(double? acres) {
    if (acres == null || acres < 10) {
      return const Color(0xFF3A3108);
    }
    if (acres < 100) {
      return const Color(0xFF3A1C06);
    }
    return const Color(0xFF3A0808);
  }
}
