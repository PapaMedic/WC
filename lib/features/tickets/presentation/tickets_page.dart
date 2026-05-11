import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Tickets / OF-297',
      subtitle: 'Time & Equipment Reporting',
      currentIndex: 4,
      icon: Icons.receipt,
      description: 'OF-297 ticket system is currently under construction. No PDF or form logic yet.',
      futureFeatures: '- Digitize OF-297 Equipment Shift Tickets\n- Auto-calculate hours and breaks\n- Signature capture for operators and supervisors\n- Export to standardized PDF formats',
    );
  }
}
