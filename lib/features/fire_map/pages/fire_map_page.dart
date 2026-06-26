// Fire Map screen UI and user interaction flow.
import 'dart:async';
import 'dart:math' as math;

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
  List<FireIncident> _filteredIncidents = [];
  List<_MarkerItem> _markerItems = [];
  final ValueNotifier<FireIncident?> _selectedIncidentNotifier =
      ValueNotifier<FireIncident?>(null);
  final ValueNotifier<bool> _isCreatingIncidentNotifier =
      ValueNotifier<bool>(false);
  FireMapFeedStatus _feedStatus = FireMapFeedStatus.live;
  DateTime? _lastUpdated;
  String? _errorMessage;
  bool _isLoadingIncidents = true;
  bool _showRxBurns = true;
  Timer? _mapUpdateDebounce;
  MapCamera? _latestCamera;

  List<FireIncident> get _visibleIncidents {
    if (_showRxBurns) return _incidents;
    return _incidents.where((incident) => !incident.isRx).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  @override
  void dispose() {
    _mapUpdateDebounce?.cancel();
    _selectedIncidentNotifier.dispose();
    _isCreatingIncidentNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingIncidents = true;
      _errorMessage = null;
    });

    try {
      if (!forceRefresh) {
        final cached = await _service.loadCachedIncidents();
        if (cached != null) {
          if (!mounted) return;
          setState(() {
            _incidents = cached.data;
            _feedStatus = FireMapFeedStatus.live;
            _lastUpdated = null;
          });
          _refreshVisibleMarkers();
          _fitIncidentMarkers();
        }
      }

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
      _refreshVisibleMarkers();
      _fitIncidentMarkers();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _incidents = [];
        _filteredIncidents = [];
        _markerItems = [];
        _feedStatus = FireMapFeedStatus.offline;
        _errorMessage =
            'Failed to fetch active fires and no cached incident data is available. $error';
        _isLoadingIncidents = false;
      });
    }
  }

  void _selectIncident(FireIncident incident) {
    _selectedIncidentNotifier.value = incident;
  }

  Future<void> _createLocalIncident() async {
    final fire = _selectedIncidentNotifier.value;
    if (fire == null || _isCreatingIncidentNotifier.value) return;

    _isCreatingIncidentNotifier.value = true;

    try {
      final existing = fire.irwinId == null
          ? null
          : await _incidentRepository.findBySourceIrwinId(fire.irwinId!);
      if (!mounted) return;

      if (existing != null) {
        await _incidentRepository.updateIncidentSourceDetails(
          _incidentFromFire(fire, existing.id, existing.createdAt),
        );
        await _incidentRepository.selectIncident(existing.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated local incident: ${fire.name}')),
        );
        return;
      }

      final incident = _incidentFromFire(fire, _uuid.v4(), DateTime.now());
      await _incidentRepository.addIncident(incident);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created local incident: ${fire.name}')),
      );
    } finally {
      if (mounted) _isCreatingIncidentNotifier.value = false;
    }
  }

  Incident _incidentFromFire(FireIncident fire, String id, DateTime createdAt) {
    return Incident(
      id: id,
      incidentName: fire.name,
      incidentNumber: '',
      resourceOrderNumber: '',
      financialCode: '',
      createdAt: createdAt,
      source: 'NIFC/WFIGS',
      sourceIrwinId: fire.irwinId,
      sourceStatus: incidentStatusLabel(fire),
      acres: _formatNumber(fire.acres),
      containmentPercent: _formatNumber(fire.containmentPercent),
      jurisdiction: fire.jurisdiction,
      agency: fire.agency,
      notes: _buildIncidentNotes(fire),
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

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _latestCamera = camera;
    _scheduleVisibleMarkerUpdate();
  }

  void _refreshVisibleMarkers() {
    _applyVisibleMarkers(_latestCamera);
  }

  void _scheduleVisibleMarkerUpdate() {
    _mapUpdateDebounce?.cancel();
    _mapUpdateDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _applyVisibleMarkers(_latestCamera);
    });
  }

  void _applyVisibleMarkers(MapCamera? camera) {
    final source = _visibleIncidents;
    final bounded = camera == null
        ? source.take(350).toList()
        : source
            .where((incident) => _boundsContain(
                  camera.visibleBounds,
                  incident.latitude,
                  incident.longitude,
                ))
            .take(450)
            .toList();

    final items = camera != null && camera.zoom < 5.3
        ? _clusterIncidents(bounded, camera.zoom)
        : bounded.map(_MarkerItem.incident).toList();

    setState(() {
      _filteredIncidents = bounded;
      _markerItems = items;
    });
  }

  bool _boundsContain(LatLngBounds bounds, double latitude, double longitude) {
    return latitude >= bounds.south &&
        latitude <= bounds.north &&
        longitude >= bounds.west &&
        longitude <= bounds.east;
  }

  List<_MarkerItem> _clusterIncidents(
      List<FireIncident> incidents, double zoom) {
    if (incidents.length < 80) {
      return incidents.map(_MarkerItem.incident).toList();
    }

    final cellSize = zoom < 4.2 ? 4.0 : 2.0;
    final buckets = <String, List<FireIncident>>{};
    for (final incident in incidents) {
      final latBucket = (incident.latitude / cellSize).floor();
      final lonBucket = (incident.longitude / cellSize).floor();
      final key = '$latBucket:$lonBucket';
      buckets.putIfAbsent(key, () => <FireIncident>[]).add(incident);
    }

    return buckets.values.map((bucket) {
      if (bucket.length == 1) return _MarkerItem.incident(bucket.first);

      final latitude =
          bucket.fold<double>(0, (sum, incident) => sum + incident.latitude) /
              bucket.length;
      final longitude =
          bucket.fold<double>(0, (sum, incident) => sum + incident.longitude) /
              bucket.length;
      final hasActive = bucket.any((incident) => !isResolved(incident));

      return _MarkerItem.cluster(
        latitude: latitude,
        longitude: longitude,
        count: bucket.length,
        hasActive: hasActive,
      );
    }).toList();
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
                options: MapOptions(
                  initialCenter: const LatLng(39.5, -98.35),
                  initialZoom: 4,
                  minZoom: 3,
                  maxZoom: 15,
                  keepAlive: true,
                  onMapReady: _refreshVisibleMarkers,
                  onPositionChanged: _onMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'wildland_companion_v2',
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
                        setState(() {
                          _showRxBurns = value;
                        });
                        final selected = _selectedIncidentNotifier.value;
                        if (selected?.isRx == true && !value) {
                          _selectedIncidentNotifier.value = null;
                        }
                        _refreshVisibleMarkers();
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
                      onPressed: _isLoadingIncidents
                          ? null
                          : () => _loadIncidents(forceRefresh: true),
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
              if (!_isLoadingIncidents &&
                  _visibleIncidents.isNotEmpty &&
                  _filteredIncidents.isEmpty)
                const _MapBanner(
                  icon: Icons.travel_explore,
                  message: 'No fires in the current map view.',
                ),
              if (_errorMessage != null && _incidents.isNotEmpty)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _InlineNotice(message: _errorMessage!),
                ),
              _SelectedIncidentCard(
                selectedIncidentNotifier: _selectedIncidentNotifier,
                isCreatingIncidentNotifier: _isCreatingIncidentNotifier,
                feedStatus: status,
                lastUpdated: _lastUpdated,
                onCreateLocalIncident: _createLocalIncident,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    return _markerItems.map((item) {
      final incident = item.incident;
      return Marker(
        point: LatLng(item.latitude, item.longitude),
        width: item.isCluster ? 42 : 38,
        height: item.isCluster ? 42 : 38,
        child: Tooltip(
          message: item.isCluster
              ? '${item.count} incidents'
              : incident?.name ?? 'Fire incident',
          child: GestureDetector(
            onTap: incident == null ? null : () => _selectIncident(incident),
            child: Center(
              child: item.isCluster
                  ? _ClusterMarker(
                      count: item.count,
                      hasActive: item.hasActive,
                    )
                  : FireMarker(
                      isRx: incident!.isRx,
                      isResolved: isResolved(incident),
                      isCached: _feedStatus == FireMapFeedStatus.cached,
                      acres: incident.acres,
                    ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _MarkerItem {
  final FireIncident? incident;
  final double latitude;
  final double longitude;
  final int count;
  final bool hasActive;

  const _MarkerItem._({
    required this.incident,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.hasActive,
  });

  bool get isCluster => incident == null;

  factory _MarkerItem.incident(FireIncident incident) {
    return _MarkerItem._(
      incident: incident,
      latitude: incident.latitude,
      longitude: incident.longitude,
      count: 1,
      hasActive: !isResolved(incident),
    );
  }

  factory _MarkerItem.cluster({
    required double latitude,
    required double longitude,
    required int count,
    required bool hasActive,
  }) {
    return _MarkerItem._(
      incident: null,
      latitude: latitude,
      longitude: longitude,
      count: count,
      hasActive: hasActive,
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  final int count;
  final bool hasActive;

  const _ClusterMarker({
    required this.count,
    required this.hasActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasActive ? AppColors.primaryAccent : const Color(0xFF767B72);
    final displayCount = math.min(count, 999);

    return RepaintBoundary(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasActive ? const Color(0xFF331409) : const Color(0xFF242722),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          displayCount == count ? '$count' : '999+',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SelectedIncidentCard extends StatelessWidget {
  final ValueNotifier<FireIncident?> selectedIncidentNotifier;
  final ValueNotifier<bool> isCreatingIncidentNotifier;
  final FireMapFeedStatus feedStatus;
  final DateTime? lastUpdated;
  final VoidCallback onCreateLocalIncident;

  const _SelectedIncidentCard({
    required this.selectedIncidentNotifier,
    required this.isCreatingIncidentNotifier,
    required this.feedStatus,
    required this.lastUpdated,
    required this.onCreateLocalIncident,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<FireIncident?>(
        valueListenable: selectedIncidentNotifier,
        builder: (context, incident, child) {
          if (incident == null) return const SizedBox.shrink();

          return ValueListenableBuilder<bool>(
            valueListenable: isCreatingIncidentNotifier,
            builder: (context, isCreatingIncident, child) {
              return FireIncidentDetailCard(
                incident: incident,
                feedStatus: feedStatus,
                lastUpdated: lastUpdated,
                isCreatingIncident: isCreatingIncident,
                onCreateLocalIncident: onCreateLocalIncident,
                onClose: () => selectedIncidentNotifier.value = null,
              );
            },
          );
        },
      ),
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
