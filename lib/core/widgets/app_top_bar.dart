import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool isMobile;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: isMobile ? null : const SizedBox.shrink(),
      leadingWidth: isMobile ? 56 : 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<bool>(
            valueListenable: NetworkState.instance.isOnlineNotifier,
            builder: (context, isOnline, child) {
              return Row(
                children: [
                  if (!isMobile)
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? AppColors.secondaryAccent
                            : Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: isOnline
                        ? AppColors.secondaryAccent
                        : Colors.redAccent,
                    size: 20,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
