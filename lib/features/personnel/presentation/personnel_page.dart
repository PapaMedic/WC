import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';

class PersonnelPage extends StatelessWidget {
  const PersonnelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Personnel',
      icon: Icons.people,
      description: 'Personnel module is currently under construction.',
      futureFeatures:
          '- Track qualifications and training records\n- Manage crew manifests\n- Monitor rest/work cycles\n- Offline syncing of crew data',
    );
  }
}
