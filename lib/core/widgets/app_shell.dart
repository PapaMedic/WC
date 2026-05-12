import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/app_sidebar.dart';
import 'package:wildland_companion_v2/core/widgets/app_top_bar.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';

class AppShell extends StatelessWidget {
  final Widget body;
  final String title;
  final String? subtitle;
  final int currentIndex;
  final Function(int) onNavigate;

  const AppShell({
    super.key,
    required this.body,
    required this.title,
    this.subtitle,
    required this.currentIndex,
    required this.onNavigate,
  });

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
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: body,
            ),
          );
        }

        if (isMobile) {
          return WildlandBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppTopBar(
                title: title,
                subtitle: subtitle,
                isMobile: true,
              ),
              drawer: Drawer(
                backgroundColor: const Color(0xFF111511),
                child: AppSidebar(
                  currentIndex: currentIndex,
                  onNavigate: (i) {
                    Navigator.pop(context); // close drawer
                    onNavigate(i);
                  },
                ),
              ),
              body: content,
            ),
          );
        }

        return WildlandBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                SizedBox(
                  width: AppSpacing.sidebarWidth,
                  child: AppSidebar(
                    currentIndex: currentIndex,
                    onNavigate: onNavigate,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppTopBar(
                        title: title,
                        subtitle: subtitle,
                        isMobile: false,
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
