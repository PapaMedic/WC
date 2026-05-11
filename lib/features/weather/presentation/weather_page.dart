import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/module_placeholder_page.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkState.instance.isOnlineNotifier,
      builder: (context, isOnline, child) {
        if (!isOnline) {
          return const ModulePlaceholderPage(
            title: 'Weather',
            icon: Icons.wifi_off,
            description: 'Unable to obtain: Network failure',
            futureFeatures:
                'Connect to a network to access spot weather forecasts and historical observations.',
          );
        }

        return const ModulePlaceholderPage(
          title: 'Weather',
          icon: Icons.cloud,
          description:
              'Weather module is currently under construction. No API or forecast logic yet.',
          futureFeatures:
              '- Retrieve spot weather forecasts based on GPS\n- Track historical weather observations\n- Log manual belt weather kit readings\n- RH, Temp, Wind Speed/Direction, and fuel moisture calculators',
        );
      },
    );
  }
}
