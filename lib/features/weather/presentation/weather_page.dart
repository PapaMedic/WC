import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Weather',
      currentIndex: 6,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: TacticalCard(
          title: 'Coming Soon',
          child: const Text('Weather module coming soon. No API or forecast logic yet.'),
        ),
      ),
    );
  }
}
