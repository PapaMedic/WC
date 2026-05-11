import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_theme.dart';
import 'package:wildland_companion_v2/app/app_router.dart';

class WildlandCompanionApp extends StatelessWidget {
  const WildlandCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wildland Companion',
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}
