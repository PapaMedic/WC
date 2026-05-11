import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_sidebar.dart';
import 'package:wildland_companion_v2/core/widgets/app_top_bar.dart';

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
  final String? subtitle;
  final int currentIndex;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    this.subtitle,
    required this.currentIndex,
  });

  void _navigateTo(BuildContext context, int index) {
    if (index == currentIndex) return;
    
    Widget page;
    switch (index) {
      case 0: page = const DashboardPage(); break;
      case 1: page = const PersonnelPage(); break;
      case 2: page = const ApparatusPage(); break;
      case 3: page = const IncidentsPage(); break;
      case 4: page = const TicketsPage(); break;
      case 5: page = const FireMapPage(); break;
      case 6: page = const WeatherPage(); break;
      case 7: page = const FieldCalculatorPage(); break;
      default: page = const DashboardPage();
    }
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isVeryWide = constraints.maxWidth >= 1100;

        Widget content = body;
        if (isVeryWide) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: body,
            ),
          );
        }

        if (isMobile) {
          return Scaffold(
            appBar: AppTopBar(title: title, subtitle: subtitle, isMobile: true),
            drawer: Drawer(
              child: AppSidebar(
                currentIndex: currentIndex,
                onNavigate: (i) {
                  Navigator.pop(context);
                  _navigateTo(context, i);
                },
              ),
            ),
            body: content,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: AppSpacing.sidebarWidth,
                child: AppSidebar(
                  currentIndex: currentIndex,
                  onNavigate: (i) => _navigateTo(context, i),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    AppTopBar(title: title, subtitle: subtitle, isMobile: false),
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
