import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tickets / OF-297',
      currentIndex: 4,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Coming Soon',
          child: const Text('OF-297 ticket system coming soon. No PDF or form logic yet.'),
        ),
      ),
    );
  }
}
