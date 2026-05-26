import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/core/widgets/topo_dashboard_card.dart';
import 'package:wildland_companion_v2/features/weather/models/weather_observation.dart';

/// Compact tactical weather summary.
///
/// This is built as a reusable widget so the Dashboard can later show the same
/// latest-observation snapshot without duplicating weather calculation logic.
class WeatherSnapshotCard extends StatelessWidget {
  final WeatherObservation? observation;
  final VoidCallback? onTap;

  const WeatherSnapshotCard({
    super.key,
    required this.observation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final observation = this.observation;
    final card = TopoDashboardCard(
      icon: Icons.cloud_outlined,
      title: 'Tactical Snapshot',
      accentLabel: observation?.fireWeatherRisk ?? 'No Observation',
      child: observation == null
          ? Text(
              'Enter a manual observation to build a field snapshot.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TopoDashboardCard.muted,
                  ),
            )
          : Wrap(
              spacing: 18,
              runSpacing: 14,
              children: [
                _SnapshotMetric(
                  label: 'Temp',
                  value: _formatNumber(observation.temperatureF, suffix: 'F'),
                ),
                _SnapshotMetric(
                  label: 'RH',
                  value: _formatNumber(
                    observation.relativeHumidity,
                    suffix: '%',
                  ),
                ),
                _SnapshotMetric(
                  label: 'Dew Point',
                  value: _formatNumber(observation.dewPointF, suffix: 'F'),
                ),
                _SnapshotMetric(
                  label: 'Wind',
                  value:
                      '${_formatNumber(observation.windSpeedMph, suffix: ' mph')} ${observation.windDirection}',
                ),
                _SnapshotMetric(
                  label: 'Risk Level',
                  value: observation.fireWeatherRisk,
                ),
              ],
            ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: card,
    );
  }

  static String _formatNumber(double? value, {String suffix = ''}) {
    if (value == null) return '-';
    final formatted =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    return '$formatted$suffix';
  }
}

class _SnapshotMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.trim().isEmpty ? '-' : value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TopoDashboardCard.text,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TopoDashboardCard.muted,
                ),
          ),
        ],
      ),
    );
  }
}
