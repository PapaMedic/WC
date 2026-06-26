// Application-level routing and shell wiring.
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/features/dashboard/presentation/dashboard_page.dart';
import 'package:wildland_companion_v2/features/personnel/presentation/personnel_page.dart';
import 'package:wildland_companion_v2/features/apparatus/presentation/apparatus_page.dart';
import 'package:wildland_companion_v2/features/incidents/presentation/incidents_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/tickets_page.dart';
import 'package:wildland_companion_v2/features/fire_map/pages/fire_map_page.dart';
import 'package:wildland_companion_v2/features/field_calculator/presentation/field_calculator_page.dart';
import 'package:wildland_companion_v2/core/navigation/app_destination.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  static void navigate(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppRouterState>();
    state?.navigateTo(index);
  }

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;
  late final List<GlobalKey> _pageKeys = List.generate(
    appDestinations.length,
    (_) => GlobalKey(),
  );

  void navigateTo(int index) {
    if (index < 0 || index >= appDestinations.length) return;
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    switch (_currentIndex) {
      case 0:
        body = const DashboardPage();
        break;
      case 1:
        body = const PersonnelPage();
        break;
      case 2:
        body = const ApparatusPage();
        break;
      case 3:
        body = const IncidentsPage();
        break;
      case 4:
        body = const TicketsPage();
        break;
      case 5:
        body = const FireMapPage();
        break;
      case 6:
        body = const FieldCalculatorPage();
        break;
      default:
        body = const DashboardPage();
    }

    final destination = appDestinations[_currentIndex];

    return AppShell(
      title: destination.label,
      subtitle: destination.subtitle,
      currentIndex: _currentIndex,
      onNavigate: navigateTo,
      constrainBodyWidth: _currentIndex != 5,
      body: KeyedSubtree(
        key: _pageKeys[_currentIndex],
        child: body,
      ),
    );
  }
}
