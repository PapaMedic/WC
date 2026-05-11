import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';

class FireMapPage extends StatelessWidget {
  const FireMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkState.instance.isOnlineNotifier,
      builder: (context, isOnline, child) {
        if (!isOnline) {
          return const ModulePlaceholderPage(
            title: 'Fire Map',
            icon: Icons.wifi_off,
            description: 'Unable to obtain: Network failure',
            futureFeatures:
                'Connect to a network to access tactical GIS and mapping features.',
          );
        }

        return const ModulePlaceholderPage(
          title: 'Fire Map',
          icon: Icons.map,
          description:
              'Fire map module is currently under construction. No GIS or map provider added yet.',
          futureFeatures:
              '- Offline vector and topo maps\n- Drop tactical waypoints and draw perimeters\n- Overlay active fire perimeters (NIFC)\n- Measure distance and area in the field',
        );
      },
    );
  }
}
