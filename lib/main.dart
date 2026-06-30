// Application entry point and startup bootstrap.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/app.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';
import 'package:wildland_companion_v2/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  NetworkState.instance.initialize();
  runApp(const WildlandCompanionApp());
}
