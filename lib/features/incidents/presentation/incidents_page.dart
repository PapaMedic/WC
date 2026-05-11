import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class IncidentsPage extends StatelessWidget {
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Incidents',
      currentIndex: 3,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Coming Soon',
          child: const Text('Incident management coming soon. No active incident logic yet.'),
        ),
      ),
    );
  }
}
