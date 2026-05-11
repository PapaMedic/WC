import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/app_shell.dart';
import 'package:wildland_companion_v2/features/dashboard/presentation/dashboard_page.dart';
import 'package:wildland_companion_v2/features/personnel/presentation/personnel_page.dart';
import 'package:wildland_companion_v2/features/apparatus/presentation/apparatus_page.dart';
import 'package:wildland_companion_v2/features/incidents/presentation/incidents_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/tickets_page.dart';
import 'package:wildland_companion_v2/features/fire_map/presentation/fire_map_page.dart';
import 'package:wildland_companion_v2/features/weather/presentation/weather_page.dart';
import 'package:wildland_companion_v2/features/field_calculator/presentation/field_calculator_page.dart';

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

  void navigateTo(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    String title;
    String? subtitle;

    switch (_currentIndex) {
      case 0:
        body = const DashboardPage();
        title = 'Dashboard';
        subtitle = 'Overview & Quick Actions';
        break;
      case 1:
        body = const PersonnelPage();
        title = 'Personnel';
        subtitle = 'Crew & Roster Management';
        break;
      case 2:
        body = const ApparatusPage();
        title = 'Apparatus';
        subtitle = 'Vehicle & Equipment Tracking';
        break;
      case 3:
        body = const IncidentsPage();
        title = 'Incidents';
        subtitle = 'Active Incident Management';
        break;
      case 4:
        body = const TicketsPage();
        title = 'Tickets / OF-297';
        subtitle = 'Time & Equipment Reporting';
        break;
      case 5:
        body = const FireMapPage();
        title = 'Fire Map';
        subtitle = 'Tactical GIS & Mapping';
        break;
      case 6:
        body = const WeatherPage();
        title = 'Weather';
        subtitle = 'Spot Forecasts & Conditions';
        break;
      case 7:
        body = const FieldCalculatorPage();
        title = 'Field Calculator';
        subtitle = 'Tactical Utilities & Conversions';
        break;
      default:
        body = const DashboardPage();
        title = 'Dashboard';
        subtitle = 'Overview & Quick Actions';
    }

    return AppShell(
      title: title,
      subtitle: subtitle,
      currentIndex: _currentIndex,
      onNavigate: navigateTo,
      body: body,
    );
  }
}
