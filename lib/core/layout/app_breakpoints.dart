// Central responsive breakpoints for the app shell and shared layouts.
enum AppLayoutClass {
  compact,
  medium,
  expanded,
}

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double navigationRail = 900;
  static const double desktopSidebar = 1400;

  static AppLayoutClass layoutClassFor(double logicalWidth) {
    if (logicalWidth < navigationRail) {
      return AppLayoutClass.compact;
    }

    if (logicalWidth < desktopSidebar) {
      return AppLayoutClass.medium;
    }

    return AppLayoutClass.expanded;
  }
}
