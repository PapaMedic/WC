// Shared responsive layout helpers for app-level content sizing.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/layout/app_breakpoints.dart';

EdgeInsets responsivePagePadding(double width) {
  if (width < AppBreakpoints.compact) {
    return const EdgeInsets.all(AppSpacing.md);
  }

  if (width < AppBreakpoints.navigationRail) {
    return const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    );
  }

  return const EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.lg,
  );
}

class ResponsiveContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool fullWidth;

  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fullWidth) {
      return SizedBox.expand(child: child);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AppContentContainer extends ResponsiveContentContainer {
  const AppContentContainer({
    super.key,
    required super.child,
    super.maxWidth,
    super.fullWidth,
  });
}
