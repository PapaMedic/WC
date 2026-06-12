import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/app.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  NetworkState.instance.initialize();
  runApp(const WildlandCompanionApp());
}
