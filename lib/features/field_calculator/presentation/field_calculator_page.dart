// Field Calculator screen UI and user interaction flow.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';

class FieldCalculatorPage extends StatelessWidget {
  const FieldCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Field Calculator',
      icon: Icons.calculate,
      description: 'Field calculator tools are currently under construction.',
      futureFeatures:
          '- Fine Dead Fuel Moisture (FDFM) calculations\n- Probability of Ignition (PIG) tables\n- Pump and hose friction loss estimates\n- Quick unit conversions (chains to miles, etc.)',
    );
  }
}
