import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_theme.dart';
import 'package:wildland_companion_v2/app/app_router.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

class WildlandCompanionApp extends StatelessWidget {
  const WildlandCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // OF-297 tickets are app-level state because the ticket list, form, and
      // review screens all need the same draft/finalized records.
      create: (_) => TicketsState(),
      child: MaterialApp(
        title: 'Wildland Companion',
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
