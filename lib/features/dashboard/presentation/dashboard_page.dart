import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/status_chip.dart';
import 'package:wildland_companion_v2/core/widgets/dashboard_stat_card.dart';
import 'package:wildland_companion_v2/core/widgets/quick_action_card.dart';

import 'package:wildland_companion_v2/features/personnel/presentation/personnel_page.dart';
import 'package:wildland_companion_v2/features/apparatus/presentation/apparatus_page.dart';
import 'package:wildland_companion_v2/features/incidents/presentation/incidents_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/tickets_page.dart';
import 'package:wildland_companion_v2/features/fire_map/presentation/fire_map_page.dart';
import 'package:wildland_companion_v2/features/weather/presentation/weather_page.dart';
import 'package:wildland_companion_v2/features/field_calculator/presentation/field_calculator_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Dashboard',
      subtitle: 'Overview & Quick Actions',
      currentIndex: 0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          int statColumns = 2;
          if (constraints.maxWidth >= 1100) {
            statColumns = 4;
          } else if (constraints.maxWidth < 350) {
            statColumns = 1;
          }

          int actionColumns = statColumns == 1 ? 2 : statColumns;
          if (constraints.maxWidth >= 1100) {
            actionColumns = 6;
          } else if (constraints.maxWidth >= 700) {
            actionColumns = 3;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsGrid(statColumns),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickActions(context, actionColumns),
                const SizedBox(height: AppSpacing.lg),
                _buildReadinessPanel(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return TacticalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              StatusChip(label: 'Offline Ready', color: AppColors.secondaryAccent, icon: Icons.cloud_done),
              SizedBox(width: AppSpacing.sm),
              StatusChip(label: 'Local Only', color: AppColors.textMuted, icon: Icons.save),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No Active Incident', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Start or select an incident to begin field tracking.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IncidentsPage())),
                icon: const Icon(Icons.add),
                label: const Text('New Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IncidentsPage())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Open Incidents'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int columns) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.5,
      children: const [
        DashboardStatCard(title: 'Personnel', value: '0 Assigned', icon: Icons.people),
        DashboardStatCard(title: 'Apparatus', value: '0 In Use', icon: Icons.fire_truck),
        DashboardStatCard(title: 'Tickets', value: '0 OF-297', icon: Icons.receipt),
        DashboardStatCard(title: 'Weather', value: 'Not Loaded', icon: Icons.cloud),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, int columns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK ACTIONS', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(title: 'Add\nPersonnel', icon: Icons.person_add, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PersonnelPage()))),
            QuickActionCard(title: 'Add\nApparatus', icon: Icons.fire_truck, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ApparatusPage()))),
            QuickActionCard(title: 'New\nOF-297', icon: Icons.receipt_long, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TicketsPage()))),
            QuickActionCard(title: 'Fire\nMap', icon: Icons.map, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FireMapPage()))),
            QuickActionCard(title: 'Check\nWeather', icon: Icons.cloud, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WeatherPage()))),
            QuickActionCard(title: 'Field\nCalc', icon: Icons.calculate, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FieldCalculatorPage()))),
          ],
        ),
      ],
    );
  }

  Widget _buildReadinessPanel() {
    return TacticalCard(
      title: 'Readiness Panel',
      child: Column(
        children: const [
          _ReadinessRow(label: 'Incident', status: 'Not selected'),
          _ReadinessRow(label: 'Crew', status: 'Not assigned'),
          _ReadinessRow(label: 'Apparatus', status: 'Not assigned'),
          _ReadinessRow(label: 'Weather', status: 'Not loaded'),
          _ReadinessRow(label: 'OF-297', status: 'Not started', isLast: true),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isLast;

  const _ReadinessRow({required this.label, required this.status, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
          Text(status, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
