import 'dart:math' as math;

/// Offline manual weather observation captured from field readings.
///
/// This is intentionally local-first. Live API weather can later hydrate a
/// separate forecast model without replacing manual belt-weather observations.
class WeatherObservation {
  final double? dryBulbF;
  final double? wetBulbF;
  final double? elevationFeet;
  final double? windSpeedMph;
  final String windDirection;
  final double? slopePercent;
  final String aspect;
  final String notes;
  final DateTime observedAt;

  const WeatherObservation({
    this.dryBulbF,
    this.wetBulbF,
    this.elevationFeet,
    this.windSpeedMph,
    this.windDirection = '',
    this.slopePercent,
    this.aspect = '',
    this.notes = '',
    required this.observedAt,
  });

  double? get temperatureF => dryBulbF;

  double? get relativeHumidity {
    final dryBulb = dryBulbF;
    final wetBulb = wetBulbF;
    final elevation = elevationFeet;
    if (dryBulb == null || wetBulb == null || elevation == null) return null;
    if (wetBulb > dryBulb) return null;

    final dryBulbC = _fahrenheitToCelsius(dryBulb);
    final wetBulbC = _fahrenheitToCelsius(wetBulb);
    final stationPressure = _stationPressureHpa(elevation);
    final wetBulbVaporPressure = _saturationVaporPressureHpa(wetBulbC);
    final dryBulbVaporPressure = _saturationVaporPressureHpa(dryBulbC);

    // Sling psychrometer approximation. Elevation adjusts station pressure,
    // which changes the psychrometric correction from wet bulb to vapor
    // pressure. This is field-estimate math, not a live weather API product.
    final psychrometricCoefficient =
        0.00066 * (1 + 0.00115 * wetBulbC) * stationPressure;
    final actualVaporPressure =
        wetBulbVaporPressure - psychrometricCoefficient * (dryBulbC - wetBulbC);
    if (actualVaporPressure <= 0 || dryBulbVaporPressure <= 0) return null;

    return (100 * actualVaporPressure / dryBulbVaporPressure).clamp(0, 100);
  }

  double? get dewPointF {
    final dryBulb = dryBulbF;
    final wetBulb = wetBulbF;
    final elevation = elevationFeet;
    if (dryBulb == null || wetBulb == null || elevation == null) return null;
    if (wetBulb > dryBulb) return null;

    final dryBulbC = _fahrenheitToCelsius(dryBulb);
    final wetBulbC = _fahrenheitToCelsius(wetBulb);
    final stationPressure = _stationPressureHpa(elevation);
    final vaporPressure = _saturationVaporPressureHpa(wetBulbC) -
        0.00066 *
            (1 + 0.00115 * wetBulbC) *
            stationPressure *
            (dryBulbC - wetBulbC);
    if (vaporPressure <= 0) return null;

    final logRatio = math.log(vaporPressure / 6.112);
    final dewPointC = (243.5 * logRatio) / (17.67 - logRatio);
    return _celsiusToFahrenheit(dewPointC);
  }

  double? get heatIndexF {
    final temp = temperatureF;
    final rh = relativeHumidity;
    if (temp == null || rh == null || temp < 80 || rh < 40) return null;

    return -42.379 +
        2.04901523 * temp +
        10.14333127 * rh -
        0.22475541 * temp * rh -
        0.00683783 * temp * temp -
        0.05481717 * rh * rh +
        0.00122874 * temp * temp * rh +
        0.00085282 * temp * rh * rh -
        0.00000199 * temp * temp * rh * rh;
  }

  String get fireWeatherRisk {
    final rh = relativeHumidity;
    final wind = windSpeedMph;
    if (rh == null && wind == null) return 'Low';

    if ((rh != null && rh < 15) || (wind != null && wind > 25)) {
      return 'Extreme';
    }
    if ((rh != null && rh >= 15 && rh <= 24) ||
        (wind != null && wind >= 16 && wind <= 25)) {
      return 'High';
    }
    if ((rh != null && rh >= 25 && rh <= 35) ||
        (wind != null && wind >= 10 && wind <= 15)) {
      return 'Moderate';
    }
    return 'Low';
  }

  Map<String, dynamic> toJson() => {
        'dryBulbF': dryBulbF,
        'wetBulbF': wetBulbF,
        'elevationFeet': elevationFeet,
        'temperatureF': temperatureF,
        'relativeHumidity': relativeHumidity,
        'windSpeedMph': windSpeedMph,
        'windDirection': windDirection,
        'slopePercent': slopePercent,
        'aspect': aspect,
        'notes': notes,
        'observedAt': observedAt.toIso8601String(),
      };

  factory WeatherObservation.fromJson(Map<String, dynamic> json) {
    return WeatherObservation(
      dryBulbF:
          ((json['dryBulbF'] ?? json['temperatureF']) as num?)?.toDouble(),
      wetBulbF: (json['wetBulbF'] as num?)?.toDouble(),
      elevationFeet: (json['elevationFeet'] as num?)?.toDouble(),
      windSpeedMph: (json['windSpeedMph'] as num?)?.toDouble(),
      windDirection: json['windDirection'] ?? '',
      slopePercent: (json['slopePercent'] as num?)?.toDouble(),
      aspect: json['aspect'] ?? '',
      notes: json['notes'] ?? '',
      observedAt: DateTime.tryParse(json['observedAt'] ?? '') ?? DateTime.now(),
    );
  }

  double _fahrenheitToCelsius(double value) => (value - 32) * 5 / 9;

  double _celsiusToFahrenheit(double value) => value * 9 / 5 + 32;

  double _stationPressureHpa(double elevationFeet) {
    final elevationMeters = elevationFeet * 0.3048;
    return 1013.25 * math.pow(1 - 2.25577e-5 * elevationMeters, 5.25588);
  }

  double _saturationVaporPressureHpa(double tempC) {
    return 6.112 * math.exp((17.67 * tempC) / (tempC + 243.5));
  }
}
