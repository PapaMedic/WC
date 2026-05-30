import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/state/network_state.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident_status.dart';
import 'package:wildland_companion_v2/features/fire_map/services/fire_map_service.dart';
import 'package:wildland_companion_v2/features/fire_map/widgets/fire_incident_bottom_sheet.dart';
import 'package:wildland_companion_v2/features/fire_map/widgets/fire_map_status_chip.dart';
import 'package:wildland_companion_v2/features/fire_map/widgets/fire_marker.dart';
import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';

class FireMapPage extends StatefulWidget {
  const FireMapPage({super.key});

  @override
  State<FireMapPage> createState() => _FireMapPageState();
}

class _FireMapPageState extends State<FireMapPage> {
  final MapController _mapController = MapController();
  final FireMapService _service = FireMapService();
  final IncidentRepository _incidentRepository = IncidentRepository();
  final Uuid _uuid = const Uuid();

  List<FireIncident> _incidents = [];
  FireIncident? _selectedIncident;
  FireMapFeedStatus _feedStatus = FireMapFeedStatus.live;
  DateTime? _lastUpdated;
  String? _errorMessage;
  bool _isLoadingIncidents = true;
  bool _isCreatingIncident = false;
  bool _bottomSheetOpen = false;
  bool _showRxBurns = true;

  List<FireIncident> get _visibleIncidents {
    if (_showRxBurns) return _incidents;
    return _incidents.where((incident) => !incident.isRx).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoadingIncidents = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.fetchActiveIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = result.data;
        _feedStatus =
            result.isCached ? FireMapFeedStatus.cached : FireMapFeedStatus.live;
        _lastUpdated = result.lastUpdated;
        _errorMessage = result.message;
        _isLoadingIncidents = false;
      });
      _fitIncidentMarkers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _incidents = [];
        _feedStatus = FireMapFeedStatus.offline;
        _errorMessage =
            'Failed to fetch active fires and no cached incident data is available. $error';
        _isLoadingIncidents = false;
      });
    }
  }

  Future<void> _selectIncident(FireIncident incident) async {
    setState(() {
      _selectedIncident = incident;
    });

    _mapController.move(LatLng(incident.latitude, incident.longitude), 8);
    _showIncidentSheet();
  }

  void _showIncidentSheet({bool replace = false}) {
    final incident = _selectedIncident;
    if (incident == null || !mounted) return;
    if (replace && _bottomSheetOpen) {
      Navigator.of(context).pop();
      _bottomSheetOpen = false;
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted && _selectedIncident?.id == incident.id) {
          _showIncidentSheet();
        }
      });
      return;
    }

    _bottomSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FireIncidentBottomSheet(
          incident: incident,
          feedStatus: _feedStatus,
          lastUpdated: _lastUpdated,
          isCreatingIncident: _isCreatingIncident,
          onCreateLocalIncident: _createLocalIncident,
        );
      },
    ).whenComplete(() => _bottomSheetOpen = false);
  }

  Future<void> _createLocalIncident() async {
    final fire = _selectedIncident;
    if (fire == null || _isCreatingIncident) return;

    setState(() => _isCreatingIncident = true);

    try {
      final existing = fire.irwinId == null
          ? null
          : await _incidentRepository.findBySourceIrwinId(fire.irwinId!);
      if (!mounted) return;

      if (existing != null) {
        Navigator.of(context).pop();
        final shouldSelect = await _showDuplicateDialog(existing);
        if (shouldSelect == true) {
          await _incidentRepository.selectIncident(existing.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${existing.incidentName} selected.')),
          );
        }
        return;
      }

      final incident = Incident(
        id: _uuid.v4(),
        incidentName: fire.name,
        incidentNumber: '',
        resourceOrderNumber: '',
        financialCode: '',
        createdAt: DateTime.now(),
        source: 'NIFC/WFIGS',
        sourceIrwinId: fire.irwinId,
        sourceStatus: incidentStatusLabel(fire),
        acres: _formatNumber(fire.acres),
        containmentPercent: _formatNumber(fire.containmentPercent),
        jurisdiction: fire.jurisdiction,
        agency: fire.agency,
        notes: _buildIncidentNotes(fire),
      );
      await _incidentRepository.addIncident(incident);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created local incident: ${fire.name}')),
      );
    } finally {
      if (mounted) setState(() => _isCreatingIncident = false);
    }
  }

  Future<bool?> _showDuplicateDialog(Incident existing) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Incident Already Exists'),
          content: Text(
            '${existing.incidentName} already exists locally from this fire source record.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Select Existing'),
            ),
          ],
        );
      },
    );
  }

  String _buildIncidentNotes(FireIncident fire) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    String date(DateTime? value) =>
        value == null ? '-' : dateFormat.format(value.toLocal());

    return [
      'source = NIFC/WFIGS',
      'fire name = ${fire.name}',
      'acres = ${fire.acres ?? '-'}',
      'containment = ${fire.containmentPercent ?? '-'}',
      'jurisdiction = ${fire.jurisdiction ?? '-'}',
      'agency = ${fire.agency ?? '-'}',
      'discovery date = ${date(fire.discoveryDate)}',
      'last updated = ${date(fire.modifiedDate)}',
    ].join('\n');
  }

  String? _formatNumber(double? value) {
    if (value == null) return null;
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  void _fitIncidentMarkers() {
    final incidents = _visibleIncidents;
    if (incidents.isEmpty) return;
    final points = incidents
        .map((incident) => LatLng(incident.latitude, incident.longitude))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(54),
          maxZoom: 7,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkState.instance.isOnlineNotifier,
      builder: (context, isOnline, child) {
        final status = isOnline ? _feedStatus : FireMapFeedStatus.offline;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(39.5, -98.35),
                  initialZoom: 4,
                  minZoom: 3,
                  maxZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'wildland_companion_v2',
                    tileBuilder: _darkenTile,
                  ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FireMapStatusChip(
                      status: status,
                      lastUpdated: _lastUpdated,
                    ),
                    const SizedBox(height: 8),
                    _RxFilterChip(
                      showRxBurns: _showRxBurns,
                      rxCount:
                          _incidents.where((incident) => incident.isRx).length,
                      onChanged: (value) {
                        final shouldCloseSheet =
                            _selectedIncident?.isRx == true &&
                                !value &&
                                _bottomSheetOpen;
                        setState(() {
                          _showRxBurns = value;
                          if (_selectedIncident?.isRx == true && !value) {
                            _selectedIncident = null;
                          }
                        });
                        if (shouldCloseSheet) {
                          Navigator.of(context).pop();
                          _bottomSheetOpen = false;
                        }
                        _fitIncidentMarkers();
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.refresh,
                      tooltip: 'Refresh',
                      onPressed: _isLoadingIncidents ? null : _loadIncidents,
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.my_location_outlined,
                      tooltip: 'Locate me',
                      onPressed: null,
                    ),
                  ],
                ),
              ),
              if (_isLoadingIncidents)
                const _MapBanner(
                  icon: Icons.sync,
                  message: 'Loading active wildfire incidents...',
                ),
              if (!_isLoadingIncidents && _visibleIncidents.isEmpty)
                _MapBanner(
                  icon: Icons.local_fire_department_outlined,
                  message: _incidents.isEmpty
                      ? (_errorMessage ?? 'No active fires found.')
                      : 'No active fires match the current filters.',
                ),
              if (_errorMessage != null && _incidents.isNotEmpty)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _InlineNotice(message: _errorMessage!),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    return _visibleIncidents.map((incident) {
      final isSelected = _selectedIncident?.id == incident.id;
      return Marker(
        point: LatLng(incident.latitude, incident.longitude),
        width: isSelected ? 170 : 54,
        height: isSelected ? 92 : 54,
        child: Tooltip(
          message: incident.name,
          child: GestureDetector(
            onTap: () => _selectIncident(incident),
            child: Center(
              child: FireMarker(
                isSelected: isSelected,
                isRx: incident.isRx,
                isResolved: isResolved(incident),
                isCached: _feedStatus == FireMapFeedStatus.cached,
                acres: incident.acres,
                label: incident.name,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _darkenTile(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.42,
        0,
        0,
        0,
        0,
        0,
        0.46,
        0,
        0,
        0,
        0,
        0,
        0.40,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }
}

class _RxFilterChip extends StatelessWidget {
  final bool showRxBurns;
  final int rxCount;
  final ValueChanged<bool> onChanged;

  const _RxFilterChip({
    required this.showRxBurns,
    required this.rxCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6111511),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!showRxBurns),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: showRxBurns ? AppColors.borderOlive : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showRxBurns
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                color: showRxBurns
                    ? AppColors.secondaryAccent
                    : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'RX burns ($rxCount)',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xE6111511),
        borderRadius: BorderRadius.circular(8),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color:
              onPressed == null ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;

  const _InlineNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF2111511),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _MapBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MapBanner({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF2111511),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderOlive),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryAccent),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
