import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/app.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NetworkState.instance.initialize();
  runApp(const WildlandCompanionApp());
}
