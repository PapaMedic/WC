import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class FireMapPage extends StatelessWidget {
  const FireMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fire Map',
      currentIndex: 5,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Coming Soon',
          child: const Text('Fire map module coming soon. No GIS or map provider added yet.'),
        ),
      ),
    );
  }
}
