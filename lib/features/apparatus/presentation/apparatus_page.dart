import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';

class ApparatusPage extends StatelessWidget {
  const ApparatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Apparatus',
      subtitle: 'Vehicle & Equipment Tracking',
      currentIndex: 2,
      icon: Icons.fire_truck,
      description: 'Apparatus module is currently under construction.',
      futureFeatures: '- Pre-trip inspection checklists\n- Track fuel and maintenance logs\n- View apparatus specifications\n- Assign to current incident',
    );
  }
}
