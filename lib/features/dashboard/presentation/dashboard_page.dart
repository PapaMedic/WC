import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wildland_companion_v2/core/widgets/topo_dashboard_card.dart';
import 'package:wildland_companion_v2/features/apparatus/data/apparatus_repository.dart';
import 'package:wildland_companion_v2/features/apparatus/models/apparatus.dart';
import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';
import 'package:wildland_companion_v2/features/personnel/data/personnel_repository.dart';
import 'package:wildland_companion_v2/features/personnel/models/personnel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApparatusRepository _apparatusRepository = ApparatusRepository();
  final PersonnelRepository _personnelRepository = PersonnelRepository();
  final IncidentRepository _incidentRepository = IncidentRepository();

  Apparatus? _selectedApparatus;
  Incident? _selectedIncident;
  List<Personnel> _assignedPersonnel = [];

  bool _isLoading = true;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final apparatus = await _apparatusRepository.getSelectedApparatus();
    final incident = await _incidentRepository.getSelectedIncident();
    final personnel = await _personnelRepository.getAssignedPersonnel();

    if (!mounted) return;

    setState(() {
      _selectedApparatus = apparatus;
      _selectedIncident = incident;
      _assignedPersonnel = personnel;
      _now = DateTime.now();
      _isLoading = false;
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });

    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, MMM d, yyyy').format(_now);
    final timeText = DateFormat('HH:mm').format(_now);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DashboardHeader(
              title: 'Wildland Companion',
              dateText: dateText,
              timeText: timeText,
            ),
            const SizedBox(height: 18),

            TopoDashboardCard(
              icon: Icons.local_fire_department,
              title: 'Current Incident',
              accentLabel: _selectedIncident?.status ?? 'Not Selected',
              child: _selectedIncident == null
                  ? const _EmptyDashboardText(
                      message: 'No current incident selected.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PrimaryInfoText(_selectedIncident!.incidentName),
                        const SizedBox(height: 8),
                        _InfoLine(
                          label: 'Incident #',
                          value: _selectedIncident!.incidentNumber,
                        ),
                        _InfoLine(
                          label: 'Resource Order',
                          value: _selectedIncident!.resourceOrderNumber,
                        ),
                        _InfoLine(
                          label: 'Financial Code',
                          value: _selectedIncident!.financialCode,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 14),

            TopoDashboardCard(
              icon: Icons.fire_truck,
              title: 'Selected Apparatus',
              accentLabel: _selectedApparatus == null ? 'Not Selected' : 'Ready',
              child: _selectedApparatus == null
                  ? const _EmptyDashboardText(
                      message: 'No apparatus selected.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PrimaryInfoText(
                          _selectedApparatus!.equipmentMakeModel,
                        ),
                        const SizedBox(height: 8),
                        _InfoLine(
                          label: 'Type',
                          value: _selectedApparatus!.equipmentType,
                        ),
                        _InfoLine(
                          label: 'Agency',
                          value: _selectedApparatus!.agencyName,
                        ),
                        _InfoLine(
                          label: 'VIN/Serial',
                          value: _selectedApparatus!.serialVinNumber,
                        ),
                        _InfoLine(
                          label: 'License/ID',
                          value: _selectedApparatus!.licenseIdNumber,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 14),

            TopoDashboardCard(
              icon: Icons.groups,
              title: 'Assigned Crew',
              accentLabel: '${_assignedPersonnel.length} Assigned',
              child: _assignedPersonnel.isEmpty
                  ? const _EmptyDashboardText(
                      message: 'No personnel assigned.',
                    )
                  : Column(
                      children: _assignedPersonnel.map((person) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: Color(0xFFFF5A00),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name.isEmpty
                                          ? 'Unnamed Personnel'
                                          : person.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      '${person.qualification} • ${person.homeUnit}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String title;
  final String dateText;
  final String timeText;

  const _DashboardHeader({
    required this.title,
    required this.dateText,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xCC101611),
        border: Border.all(
          color: const Color(0xFF263226),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.terrain,
            size: 34,
            color: Color(0xFFFF5A00),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            timeText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PrimaryInfoText extends StatelessWidget {
  final String value;

  const _PrimaryInfoText(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value.isEmpty ? 'Unnamed' : value,
      style: Theme.of(context).textTheme.titleMedium,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: ${value.isEmpty ? '-' : value}',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class _EmptyDashboardText extends StatelessWidget {
  final String message;

  const _EmptyDashboardText({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}