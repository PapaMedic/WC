import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class FieldCalculatorPage extends StatelessWidget {
  const FieldCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Field Calculator',
      currentIndex: 7,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Coming Soon',
          child: const Text('Field calculator tools coming soon.'),
        ),
      ),
    );
  }
}
