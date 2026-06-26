// Single source of truth for top-level app navigation destinations.
import 'package:flutter/material.dart';

class AppDestination {
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
  final String routeName;

  const AppDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
  });
}

const appDestinations = <AppDestination>[
  AppDestination(
    label: 'Dashboard',
    subtitle: 'Overview & Quick Actions',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    routeName: 'dashboard',
  ),
  AppDestination(
    label: 'Personnel',
    subtitle: 'Crew & Roster Management',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    routeName: 'personnel',
  ),
  AppDestination(
    label: 'Apparatus',
    subtitle: 'Vehicle & Equipment Tracking',
    icon: Icons.fire_truck_outlined,
    selectedIcon: Icons.fire_truck,
    routeName: 'apparatus',
  ),
  AppDestination(
    label: 'Incidents',
    subtitle: 'Active Incident Management',
    icon: Icons.warning_amber_outlined,
    selectedIcon: Icons.warning_amber,
    routeName: 'incidents',
  ),
  AppDestination(
    label: 'Tickets / OF-297',
    subtitle: 'Time & Equipment Reporting',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    routeName: 'tickets',
  ),
  AppDestination(
    label: 'Fire Map',
    subtitle: 'Tactical GIS & Mapping',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map,
    routeName: 'fire-map',
  ),
  AppDestination(
    label: 'Field Calculator',
    subtitle: 'Tactical Utilities & Conversions',
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate,
    routeName: 'field-calculator',
  ),
];
