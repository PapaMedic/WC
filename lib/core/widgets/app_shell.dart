// Shared adaptive shell used across top-level app screens.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/layout/app_breakpoints.dart';
import 'package:wildland_companion_v2/core/layout/responsive_layout.dart';
import 'package:wildland_companion_v2/core/navigation/app_destination.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';
import 'package:wildland_companion_v2/core/widgets/app_sidebar.dart';
import 'package:wildland_companion_v2/core/widgets/app_top_bar.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';

class AppShell extends StatefulWidget {
  final Widget body;
  final String title;
  final String? subtitle;
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final bool constrainBodyWidth;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    this.subtitle,
    required this.currentIndex,
    required this.onNavigate,
    this.constrainBodyWidth = true,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _compactRailWidth = 80;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutClass = AppBreakpoints.layoutClassFor(width);

        assert(() {
          debugPrint(
            'Adaptive shell: '
            'width=${constraints.maxWidth}, '
            'height=${constraints.maxHeight}, '
            'dpr=${MediaQuery.devicePixelRatioOf(context)}, '
            'layoutClass=$layoutClass',
          );
          return true;
        }());

        return switch (layoutClass) {
          AppLayoutClass.compact => _buildDrawerLayout(context, width),
          AppLayoutClass.medium => _buildRailLayout(context),
          AppLayoutClass.expanded => _buildDesktopLayout(context),
        };
      },
    );
  }

  Widget _buildDrawerLayout(BuildContext context, double width) {
    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppTopBar(
          title: widget.title,
          subtitle: widget.subtitle,
          isMobile: true,
        ),
        drawer: Drawer(
          key: const ValueKey('app-overlay-drawer'),
          width: width < AppBreakpoints.compact
              ? (width * 0.82).clamp(280.0, 340.0)
              : 360,
          backgroundColor: const Color(0xFF111511),
          child: AppSidebar(
            currentIndex: widget.currentIndex,
            respectSafeArea: true,
            onNavigate: (index) {
              Navigator.of(context).pop();
              widget.onNavigate(index);
            },
          ),
        ),
        body: _pageContent(),
      ),
    );
  }

  Widget _buildRailLayout(BuildContext context) {
    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AppNavigationRail(
                    selectedIndex: widget.currentIndex,
                    width: _compactRailWidth,
                    onDestinationSelected: widget.onNavigate,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildMainArea()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: AppSpacing.sidebarWidth,
                child: AppSidebar(
                  key: const ValueKey('app-desktop-sidebar'),
                  currentIndex: widget.currentIndex,
                  onNavigate: widget.onNavigate,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _buildMainArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: widget.title,
          subtitle: widget.subtitle,
          isMobile: false,
        ),
        Expanded(child: _pageContent()),
      ],
    );
  }

  Widget _pageContent() {
    return AppContentContainer(
      fullWidth: !widget.constrainBodyWidth,
      child: widget.body,
    );
  }
}

class _AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final double width;
  final ValueChanged<int> onDestinationSelected;

  const _AppNavigationRail({
    required this.selectedIndex,
    required this.width,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('app-navigation-rail'),
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111511), Color(0xFF0D100D)],
          ),
        ),
        child: Column(
          children: [
            const _RailHeader(),
            Container(height: 1, color: const Color(0xFF1E261E)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: appDestinations.length,
                itemBuilder: (context, index) {
                  return _RailDestinationButton(
                    destination: appDestinations[index],
                    selected: index == selectedIndex,
                    onPressed: () => onDestinationSelected(index),
                  );
                },
              ),
            ),
            const _RailConnectionStatus(),
          ],
        ),
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Tooltip(
        message: 'Wildland Companion',
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.30),
            ),
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: AppColors.primaryAccent,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _RailDestinationButton extends StatelessWidget {
  final AppDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  const _RailDestinationButton({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primaryAccent : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Tooltip(
        message: destination.label,
        waitDuration: const Duration(milliseconds: 350),
        child: Material(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                      )
                    : null,
              ),
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: foreground,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailConnectionStatus extends StatelessWidget {
  const _RailConnectionStatus();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ValueListenableBuilder<bool>(
        valueListenable: NetworkState.instance.isOnlineNotifier,
        builder: (context, isOnline, child) {
          final statusColor =
              isOnline ? AppColors.secondaryAccent : Colors.redAccent;
          return Tooltip(
            message: isOnline ? 'Online' : 'Offline',
            child: Icon(
              isOnline ? Icons.cloud_done_outlined : Icons.cloud_off,
              color: statusColor,
              size: 22,
            ),
          );
        },
      ),
    );
  }
}
