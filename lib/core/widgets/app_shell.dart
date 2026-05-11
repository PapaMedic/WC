import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/features/dashboard/presentation/dashboard_page.dart';
import 'package:wildland_companion_v2/features/personnel/presentation/personnel_page.dart';
import 'package:wildland_companion_v2/features/apparatus/presentation/apparatus_page.dart';
import 'package:wildland_companion_v2/features/incidents/presentation/incidents_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/tickets_page.dart';
import 'package:wildland_companion_v2/features/fire_map/presentation/fire_map_page.dart';
import 'package:wildland_companion_v2/features/weather/presentation/weather_page.dart';
import 'package:wildland_companion_v2/features/field_calculator/presentation/field_calculator_page.dart';

class AppShell extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
  });

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.secondaryAccent),
            onPressed: () {},
            tooltip: 'Offline Ready',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.local_fire_department, color: AppColors.primaryAccent, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Wildland Companion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, 0, 'Dashboard', Icons.dashboard, const DashboardPage()),
            _buildDrawerItem(context, 1, 'Personnel', Icons.people, const PersonnelPage()),
            _buildDrawerItem(context, 2, 'Apparatus', Icons.fire_truck, const ApparatusPage()),
            _buildDrawerItem(context, 3, 'Incidents', Icons.warning, const IncidentsPage()),
            _buildDrawerItem(context, 4, 'Tickets / OF-297', Icons.receipt, const TicketsPage()),
            _buildDrawerItem(context, 5, 'Fire Map', Icons.map, const FireMapPage()),
            _buildDrawerItem(context, 6, 'Weather', Icons.cloud, const WeatherPage()),
            _buildDrawerItem(context, 7, 'Field Calculator', Icons.calculate, const FieldCalculatorPage()),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildDrawerItem(BuildContext context, int index, String title, IconData icon, Widget page) {
    final isSelected = index == currentIndex;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryAccent : AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryAccent : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.cardBackground,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          _navigateTo(context, page);
        }
      },
    );
  }
}
