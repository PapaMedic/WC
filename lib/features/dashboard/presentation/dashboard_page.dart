import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/section_header.dart';
import 'package:wildland_companion_v2/features/incidents/presentation/incidents_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/tickets_page.dart';
import 'package:wildland_companion_v2/features/fire_map/presentation/fire_map_page.dart';
import 'package:wildland_companion_v2/features/weather/presentation/weather_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
      currentIndex: 0,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Status'),
              Chip(
                label: const Text('Offline Ready', style: TextStyle(color: AppColors.scaffoldBackground, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.secondaryAccent,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const TacticalCard(
            title: 'Current Incident',
            child: Text(
              'No Active Incident',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ),
          const SectionHeader(title: 'Quick Stats'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: const [
              _StatCard(title: 'Personnel', value: '0 Assigned'),
              _StatCard(title: 'Apparatus', value: '0 In Use'),
              _StatCard(title: 'Tickets', value: '0 OF-297'),
              _StatCard(title: 'Weather', value: 'Not Loaded'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Quick Actions'),
          TacticalCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.add_circle_outline,
                  title: 'New Incident',
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const IncidentsPage()));
                  },
                ),
                _ActionTile(
                  icon: Icons.receipt_long,
                  title: 'New OF-297 Ticket',
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TicketsPage()));
                  },
                ),
                _ActionTile(
                  icon: Icons.map_outlined,
                  title: 'Open Fire Map',
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FireMapPage()));
                  },
                ),
                _ActionTile(
                  icon: Icons.cloud_outlined,
                  title: 'Open Weather',
                  onTap: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WeatherPage()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
