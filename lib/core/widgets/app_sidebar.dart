import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final bool respectSafeArea;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.respectSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarContent = Column(
      children: [
        _buildHeader(context),
        Container(height: 1, color: const Color(0xFF1E261E)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _NavItem(
                index: 0,
                title: 'Dashboard',
                icon: Icons.dashboard_outlined,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 1,
                title: 'Personnel',
                icon: Icons.people_outline,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 2,
                title: 'Apparatus',
                icon: Icons.fire_truck,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 3,
                title: 'Incidents',
                icon: Icons.warning_amber_outlined,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 4,
                title: 'Tickets / OF-297',
                icon: Icons.receipt_long_outlined,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 5,
                title: 'Fire Map',
                icon: Icons.map_outlined,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
              _NavItem(
                index: 6,
                title: 'Field Calculator',
                icon: Icons.calculate_outlined,
                currentIndex: currentIndex,
                onNavigate: onNavigate,
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFF1E261E)),
        _buildFooter(context),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111511), Color(0xFF0D100D)],
        ),
        border: Border(right: BorderSide(color: Color(0xFF2A2F2A), width: 1)),
      ),
      child: respectSafeArea ? SafeArea(child: sidebarContent) : sidebarContent,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.primaryAccent,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WILDLAND',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'COMPANION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: AppColors.secondaryAccent,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Field Operations Toolkit',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.secondaryAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Ready',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v2 Local Build',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final int currentIndex;
  final Function(int) onNavigate;

  const _NavItem({
    required this.index,
    required this.title,
    required this.icon,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onNavigate(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                icon,
                color:
                    isSelected ? AppColors.primaryAccent : AppColors.textMuted,
                size: 20,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              trailing: isSelected
                  ? Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              minLeadingWidth: 20,
            ),
          ),
        ),
      ),
    );
  }
}
