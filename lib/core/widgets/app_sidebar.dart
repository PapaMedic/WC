import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                _NavItem(index: 0, title: 'Dashboard', icon: Icons.dashboard, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 1, title: 'Personnel', icon: Icons.people, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 2, title: 'Apparatus', icon: Icons.fire_truck, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 3, title: 'Incidents', icon: Icons.warning, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 4, title: 'Tickets / OF-297', icon: Icons.receipt, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 5, title: 'Fire Map', icon: Icons.map, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 6, title: 'Weather', icon: Icons.cloud, currentIndex: currentIndex, onNavigate: onNavigate),
                _NavItem(index: 7, title: 'Field Calculator', icon: Icons.calculate, currentIndex: currentIndex, onNavigate: onNavigate),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_fire_department, color: AppColors.primaryAccent, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wildland\nCompanion', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.1, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Field Operations Toolkit', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondaryAccent, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Offline Ready', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const Text('v2 Local Build', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(icon, color: isSelected ? AppColors.primaryAccent : AppColors.textMuted, size: 22),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          selected: isSelected,
          selectedTileColor: AppColors.primaryAccent.withValues(alpha: 0.1),
          hoverColor: AppColors.cardBackground,
          onTap: () => onNavigate(index),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          dense: true,
        ),
      ),
    );
  }
}
