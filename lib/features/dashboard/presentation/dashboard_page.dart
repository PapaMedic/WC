import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:wildland_companion_v2/app/app_router.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_companion_wordmark.dart';
import 'package:wildland_companion_v2/features/apparatus/data/apparatus_repository.dart';
import 'package:wildland_companion_v2/features/apparatus/models/apparatus.dart';
import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';
import 'package:wildland_companion_v2/features/personnel/data/personnel_repository.dart';
import 'package:wildland_companion_v2/features/personnel/models/personnel.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

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
    final ticketsState = context.read<TicketsState>();
    final apparatus = await _apparatusRepository.getSelectedApparatus();
    final incident = await _incidentRepository.getSelectedIncident();
    final personnel = await _personnelRepository.getAssignedPersonnel();
    await ticketsState.loadTickets();

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
    final ticketsState = context.watch<TicketsState>();
    final selectedIncident = _selectedIncident;
    final selectedIncidentId = selectedIncident?.id;
    // OF-297 ticket stats are scoped to the currently selected incident. They
    // do not count tickets from closed or non-selected incidents.
    final openDraftsCount = selectedIncidentId == null
        ? 0
        : ticketsState.draftCountForIncident(selectedIncidentId);
    final finalizedTicketsCount = selectedIncidentId == null
        ? 0
        : ticketsState.finalizedCountForIncident(selectedIncidentId);
    final selectedIncidentLabel = selectedIncident?.incidentName.isEmpty ?? true
        ? 'Select an incident'
        : selectedIncident!.incidentName;

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
            const SizedBox(height: 12),
            const WildlandCompanionWordmark(),
            const SizedBox(height: 16),
            _DashboardHeader(
              dateText: dateText,
              timeText: timeText,
            ),
            const SizedBox(height: 18),
            TacticalCard(
              icon: Icons.local_fire_department,
              title: 'Current Incident',
              trailing: _StatusPill(
                label: _selectedIncident?.displayStatus ?? 'Not Selected',
              ),
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
                        if (_hasFireMapValue(_selectedIncident!.acres))
                          _InfoLine(
                            label: 'Acres',
                            value: _selectedIncident!.acres ?? '',
                          ),
                        if (_hasFireMapValue(
                          _selectedIncident!.containmentPercent,
                        ))
                          _InfoLine(
                            label: 'Containment',
                            value: _formatContainment(
                              _selectedIncident!.containmentPercent ?? '',
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _TicketCountsCard(
              openDraftsCount: openDraftsCount,
              finalizedTicketsCount: finalizedTicketsCount,
              selectedIncidentLabel: selectedIncidentLabel,
              hasSelectedIncident: selectedIncidentId != null,
              onTap: selectedIncidentId == null
                  ? null
                  : () {
                      // TODO: add a TicketsPage deep link that opens the
                      // selected incident directly. For now this opens the
                      // OF-297 tickets area without changing existing routing.
                      AppRouter.navigate(context, 4);
                    },
            ),
            const SizedBox(height: 14),
            TacticalCard(
              icon: Icons.fire_truck,
              title: 'Selected Apparatus',
              trailing: _StatusPill(
                label: _selectedApparatus == null ? 'Not Selected' : 'Ready',
              ),
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
            TacticalCard(
              icon: Icons.groups,
              title: 'Assigned Crew',
              trailing: _StatusPill(
                label: '${_assignedPersonnel.length} Assigned',
              ),
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

  bool _hasFireMapValue(String? value) {
    return (_selectedIncident?.source ?? '').trim().isNotEmpty &&
        (value ?? '').trim().isNotEmpty;
  }

  String _formatContainment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.endsWith('%')) return trimmed;
    return '$trimmed%';
  }
}

class _TicketCountsCard extends StatelessWidget {
  final int openDraftsCount;
  final int finalizedTicketsCount;
  final String selectedIncidentLabel;
  final bool hasSelectedIncident;
  final VoidCallback? onTap;

  const _TicketCountsCard({
    required this.openDraftsCount,
    required this.finalizedTicketsCount,
    required this.selectedIncidentLabel,
    required this.hasSelectedIncident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      icon: Icons.receipt_long_outlined,
      title: 'OF-297 Tickets',
      trailing: _StatusPill(
        label: hasSelectedIncident ? 'Selected Incident' : 'Not Selected',
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasSelectedIncident ? selectedIncidentLabel : 'Select an incident',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TacticalCard.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TicketCountMetric(
                  label: 'Open Drafts',
                  value: hasSelectedIncident ? openDraftsCount.toString() : '0',
                  icon: Icons.edit_note_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TicketCountMetric(
                  label: 'Finalized',
                  value: hasSelectedIncident
                      ? finalizedTicketsCount.toString()
                      : '0',
                  icon: Icons.verified_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketCountMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TicketCountMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: TacticalCard.accent,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: TacticalCard.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TacticalCard.muted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.38),
        ),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String dateText;
  final String timeText;

  const _DashboardHeader({
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
            size: 24,
            color: Color(0xFFFF5A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
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
