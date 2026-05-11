import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class ApparatusPage extends StatelessWidget {
  const ApparatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Apparatus',
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Module Stub',
          child: const Text('Apparatus tracking coming soon.'),
        ),
      ),
    );
  }
}
