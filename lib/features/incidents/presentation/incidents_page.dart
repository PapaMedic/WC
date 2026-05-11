import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';

class IncidentsPage extends StatelessWidget {
  const IncidentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Incidents',
      subtitle: 'Active Incident Management',
      currentIndex: 3,
      icon: Icons.warning,
      description: 'Incident management module is currently under construction.',
      futureFeatures: '- Create and manage new incidents\n- Track incident progress and details\n- Assign personnel and apparatus to active incidents\n- View historical incident data',
    );
  }
}
