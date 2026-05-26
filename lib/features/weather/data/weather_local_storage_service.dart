import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildland_companion_v2/features/weather/models/weather_observation.dart';

/// Local storage for the most recent manual weather observation.
///
/// This keeps the Weather module useful offline and leaves room for future live
/// forecast storage without coupling the UI to an API.
class WeatherLocalStorageService {
  static const String _latestObservationKey = 'latest_weather_observation';

  Future<WeatherObservation?> loadLatestObservation() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_latestObservationKey);
    if (rawJson == null || rawJson.isEmpty) return null;

    try {
      return WeatherObservation.fromJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLatestObservation(WeatherObservation observation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _latestObservationKey,
      jsonEncode(observation.toJson()),
    );
  }
}
