import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wildland_companion_v2/core/widgets/topo_dashboard_card.dart';
import 'package:wildland_companion_v2/features/weather/data/weather_local_storage_service.dart';
import 'package:wildland_companion_v2/features/weather/models/weather_observation.dart';
import 'package:wildland_companion_v2/features/weather/widgets/weather_snapshot_card.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  static const List<String> _directions = [
    '',
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SW',
    'W',
    'NW',
    'Variable',
  ];

  static const List<String> _aspects = [
    '',
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SW',
    'W',
    'NW',
    'Flat',
  ];

  final WeatherLocalStorageService _storageService =
      WeatherLocalStorageService();
  final TextEditingController _dryBulbController = TextEditingController();
  final TextEditingController _wetBulbController = TextEditingController();
  final TextEditingController _elevationController = TextEditingController();
  final TextEditingController _windSpeedController = TextEditingController();
  final TextEditingController _slopeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  WeatherObservation? _latestObservation;
  String _windDirection = '';
  String _aspect = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestObservation();
  }

  @override
  void dispose() {
    _dryBulbController.dispose();
    _wetBulbController.dispose();
    _elevationController.dispose();
    _windSpeedController.dispose();
    _slopeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestObservation() async {
    final observation = await _storageService.loadLatestObservation();
    if (!mounted) return;

    setState(() {
      _latestObservation = observation;
      _populateControllers(observation);
      _isLoading = false;
    });
  }

  void _populateControllers(WeatherObservation? observation) {
    _dryBulbController.text = _formatInput(observation?.dryBulbF);
    _wetBulbController.text = _formatInput(observation?.wetBulbF);
    _elevationController.text = _formatInput(observation?.elevationFeet);
    _windSpeedController.text = _formatInput(observation?.windSpeedMph);
    _slopeController.text = _formatInput(observation?.slopePercent);
    _notesController.text = observation?.notes ?? '';
    _windDirection = observation?.windDirection ?? '';
    _aspect = observation?.aspect ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final draftObservation = _buildObservation();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Weather',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Offline manual observations and field calculations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          WeatherSnapshotCard(observation: draftObservation),
          const SizedBox(height: 14),
          _ManualObservationCard(
            dryBulbController: _dryBulbController,
            wetBulbController: _wetBulbController,
            elevationController: _elevationController,
            windSpeedController: _windSpeedController,
            slopeController: _slopeController,
            notesController: _notesController,
            windDirection: _windDirection,
            aspect: _aspect,
            directions: _directions,
            aspects: _aspects,
            onChanged: () => setState(() {}),
            onWindDirectionChanged: (value) {
              setState(() {
                _windDirection = value ?? '';
              });
            },
            onAspectChanged: (value) {
              setState(() {
                _aspect = value ?? '';
              });
            },
            onSave: _saveObservation,
          ),
          const SizedBox(height: 14),
          _CalculatedOutputsCard(observation: draftObservation),
          if (_latestObservation != null) ...[
            const SizedBox(height: 14),
            _LastSavedCard(observation: _latestObservation!),
          ],
        ],
      ),
    );
  }

  WeatherObservation? _buildObservation() {
    final hasAnyInput = [
      _dryBulbController.text,
      _wetBulbController.text,
      _elevationController.text,
      _windSpeedController.text,
      _slopeController.text,
      _notesController.text,
      _windDirection,
      _aspect,
    ].any((value) => value.trim().isNotEmpty);

    if (!hasAnyInput) return _latestObservation;

    return WeatherObservation(
      dryBulbF: _parseDouble(_dryBulbController.text),
      wetBulbF: _parseDouble(_wetBulbController.text),
      elevationFeet: _parseDouble(_elevationController.text),
      windSpeedMph: _parseDouble(_windSpeedController.text),
      windDirection: _windDirection,
      slopePercent: _parseDouble(_slopeController.text),
      aspect: _aspect,
      notes: _notesController.text.trim(),
      observedAt: DateTime.now(),
    );
  }

  Future<void> _saveObservation() async {
    final observation = _buildObservation();
    if (observation == null) return;

    await _storageService.saveLatestObservation(observation);
    if (!mounted) return;

    setState(() {
      _latestObservation = observation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weather observation saved.'),
        showCloseIcon: true,
      ),
    );
  }

  double? _parseDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  String _formatInput(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}

class _ManualObservationCard extends StatelessWidget {
  final TextEditingController dryBulbController;
  final TextEditingController wetBulbController;
  final TextEditingController elevationController;
  final TextEditingController windSpeedController;
  final TextEditingController slopeController;
  final TextEditingController notesController;
  final String windDirection;
  final String aspect;
  final List<String> directions;
  final List<String> aspects;
  final VoidCallback onChanged;
  final ValueChanged<String?> onWindDirectionChanged;
  final ValueChanged<String?> onAspectChanged;
  final VoidCallback onSave;

  const _ManualObservationCard({
    required this.dryBulbController,
    required this.wetBulbController,
    required this.elevationController,
    required this.windSpeedController,
    required this.slopeController,
    required this.notesController,
    required this.windDirection,
    required this.aspect,
    required this.directions,
    required this.aspects,
    required this.onChanged,
    required this.onWindDirectionChanged,
    required this.onAspectChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return TopoDashboardCard(
      icon: Icons.edit_location_alt_outlined,
      title: 'Manual Weather Observation',
      accentLabel: 'Offline',
      child: Column(
        children: [
          _ResponsiveFields(
            children: [
              _WeatherNumberField(
                label: 'Dry Bulb deg F',
                controller: dryBulbController,
                onChanged: onChanged,
              ),
              _WeatherNumberField(
                label: 'Wet Bulb deg F',
                controller: wetBulbController,
                onChanged: onChanged,
              ),
              _WeatherNumberField(
                label: 'Elevation ft',
                controller: elevationController,
                onChanged: onChanged,
              ),
              _WeatherNumberField(
                label: 'Wind Speed mph',
                controller: windSpeedController,
                onChanged: onChanged,
              ),
              _WeatherDropdownField(
                label: 'Wind Direction',
                value: windDirection,
                values: directions,
                onChanged: onWindDirectionChanged,
              ),
              _WeatherNumberField(
                label: 'Slope %',
                controller: slopeController,
                onChanged: onChanged,
              ),
              _WeatherDropdownField(
                label: 'Aspect',
                value: aspect,
                values: aspects,
                onChanged: onAspectChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Observation'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatedOutputsCard extends StatelessWidget {
  final WeatherObservation? observation;

  const _CalculatedOutputsCard({
    required this.observation,
  });

  @override
  Widget build(BuildContext context) {
    final observation = this.observation;

    return TopoDashboardCard(
      icon: Icons.calculate_outlined,
      title: 'Calculated Outputs',
      accentLabel: observation?.fireWeatherRisk ?? 'Pending',
      child: observation == null
          ? const _WeatherMutedText(
              'Enter weather values to calculate outputs.')
          : _ResponsiveFields(
              children: [
                _OutputLine(
                  label: 'Dew Point estimate',
                  value: _formatNumber(observation.dewPointF, suffix: ' deg F'),
                ),
                _OutputLine(
                  label: 'Calculated RH',
                  value: _formatNumber(
                    observation.relativeHumidity,
                    suffix: '%',
                  ),
                ),
                _OutputLine(
                  label: 'Heat Index',
                  value: observation.heatIndexF == null
                      ? 'Not applicable'
                      : _formatNumber(
                          observation.heatIndexF,
                          suffix: ' deg F',
                        ),
                ),
                _OutputLine(
                  label: 'Fire Weather Risk',
                  value: observation.fireWeatherRisk,
                ),
                _OutputLine(
                  label: 'Slope / Aspect',
                  value:
                      '${_formatNumber(observation.slopePercent, suffix: '%')} / ${observation.aspect.isEmpty ? '-' : observation.aspect}',
                ),
              ],
            ),
    );
  }

  String _formatNumber(double? value, {String suffix = ''}) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$suffix';
  }
}

class _LastSavedCard extends StatelessWidget {
  final WeatherObservation observation;

  const _LastSavedCard({
    required this.observation,
  });

  @override
  Widget build(BuildContext context) {
    return TopoDashboardCard(
      icon: Icons.history_outlined,
      title: 'Latest Saved Observation',
      accentLabel: DateFormat('HH:mm').format(observation.observedAt),
      child: Text(
        DateFormat('MMM d, yyyy HH:mm').format(observation.observedAt),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TopoDashboardCard.muted,
            ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final spacing = columns == 1 ? 0.0 : 14.0;
        final width = (constraints.maxWidth - spacing) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map(
                (child) => SizedBox(
                  width: columns == 1 ? double.infinity : width,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _WeatherNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _WeatherNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _WeatherDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _WeatherDropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : '',
      decoration: InputDecoration(labelText: label),
      items: values.map((value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value.isEmpty ? '-' : value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _OutputLine extends StatelessWidget {
  final String label;
  final String value;

  const _OutputLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TopoDashboardCard.muted,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TopoDashboardCard.text,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _WeatherMutedText extends StatelessWidget {
  final String value;

  const _WeatherMutedText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: TopoDashboardCard.muted,
          ),
    );
  }
}
