import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/incident_tickets_page.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final IncidentRepository _incidentRepository = IncidentRepository();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _shortDateFormat = DateFormat('M/d/yyyy');
  late Future<List<Incident>> _incidentsFuture;
  Incident? _selectedIncident;
  _TicketIncidentFilter _filter = _TicketIncidentFilter.active;
  DateTime? _selectedDate;
  _IncidentSort _sortBy = _IncidentSort.dateNewest;

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _incidentRepository.getAllIncidents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketsState>().loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIncident = _selectedIncident;

    if (selectedIncident != null) {
      return IncidentTicketsPage(
        incidentId: selectedIncident.id,
        incidentName: selectedIncident.incidentName,
        incidentNumber: selectedIncident.incidentNumber,
        resourceOrderNumber: selectedIncident.resourceOrderNumber,
        financialCode: selectedIncident.financialCode,
        allowCreate: selectedIncident.isActive,
        onBack: () {
          setState(() {
            _selectedIncident = null;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<TicketsState>(
        builder: (context, ticketsState, _) {
          return FutureBuilder<List<Incident>>(
            future: _incidentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allIncidents = snapshot.data ?? [];
              final incidentGroups = _filterAndSortIncidentGroups(
                allIncidents,
                ticketsState.tickets,
              );

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Shift Ticket Export',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // PDF export comes later; this module currently owns only
                    // saved draft/finalized form data.
                    'Select an incident to create or review saved shift tickets.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<_TicketIncidentFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _TicketIncidentFilter.active,
                        label: Text(
                          'Active Incident Tickets',
                          overflow: TextOverflow.ellipsis,
                        ),
                        icon: Icon(Icons.local_fire_department_outlined),
                      ),
                      ButtonSegment(
                        value: _TicketIncidentFilter.closed,
                        label: Text(
                          'Closed Incident Tickets',
                          overflow: TextOverflow.ellipsis,
                        ),
                        icon: Icon(Icons.archive_outlined),
                      ),
                      ButtonSegment(
                        value: _TicketIncidentFilter.deleted,
                        label: Text(
                          'Deleted Incident Tickets',
                          overflow: TextOverflow.ellipsis,
                        ),
                        icon: Icon(Icons.inventory_2_outlined),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) {
                      setState(() {
                        _filter = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _IncidentSearchControls(
                    searchController: _searchController,
                    selectedDate: _selectedDate,
                    sortBy: _sortBy,
                    formatDate: _dateFormat.format,
                    onSearchChanged: (_) => setState(() {}),
                    onSearchCleared: () {
                      setState(_searchController.clear);
                    },
                    onPickDate: _pickDateFilter,
                    onClearDate: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    onSortChanged: (sortBy) {
                      setState(() {
                        _sortBy = sortBy;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TacticalCard(
                    title: '${_filter.title} (${incidentGroups.length})',
                    child: incidentGroups.isEmpty
                        ? const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Text('No incidents match this view.'),
                          )
                        : Column(
                            children: incidentGroups.map((group) {
                              final incident = group.incident;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  group.isOrphaned
                                      ? Icons.link_off_outlined
                                      : Icons.warning_amber_outlined,
                                ),
                                title: Text(
                                  incident.incidentName.isEmpty
                                      ? group.fallbackName
                                      : incident.incidentName,
                                ),
                                subtitle: Text(
                                  'Date: ${_dateFormat.format(incident.createdAt)}\n'
                                  'Incident #: ${incident.incidentNumber.isEmpty ? '-' : incident.incidentNumber}\n'
                                  'Resource Order: ${incident.resourceOrderNumber.isEmpty ? '-' : incident.resourceOrderNumber}\n'
                                  'Tickets: ${group.ticketCount}',
                                ),
                                isThreeLine: true,
                                trailing:
                                    const Icon(Icons.chevron_right_outlined),
                                onTap: () {
                                  setState(() {
                                    _selectedIncident = incident;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_TicketIncidentGroup> _filterAndSortIncidentGroups(
    List<Incident> allIncidents,
    List<OF297ShiftTicket> tickets,
  ) {
    final knownIncidentIds =
        allIncidents.map((incident) => incident.id).toSet();
    final groups = allIncidents.where((incident) {
      switch (_filter) {
        case _TicketIncidentFilter.active:
          return incident.isActive;
        case _TicketIncidentFilter.closed:
          return incident.isClosed;
        case _TicketIncidentFilter.deleted:
          return incident.isDeletedArchived;
      }
    }).map((incident) {
      final ticketCount =
          tickets.where((ticket) => ticket.incidentId == incident.id).length;
      return _TicketIncidentGroup(
        incident: incident,
        ticketCount: ticketCount,
      );
    }).toList();

    if (_filter == _TicketIncidentFilter.deleted) {
      final orphanedTickets = tickets
          .where((ticket) => !knownIncidentIds.contains(ticket.incidentId))
          .toList();
      final orphanedIncidentIds =
          orphanedTickets.map((ticket) => ticket.incidentId).toSet();
      for (final incidentId in orphanedIncidentIds) {
        final incidentTickets = orphanedTickets
            .where((ticket) => ticket.incidentId == incidentId)
            .toList();
        final firstTicket = incidentTickets.first;
        groups.add(
          _TicketIncidentGroup(
            incident: Incident(
              id: incidentId,
              incidentName: firstTicket.incidentName.isEmpty
                  ? 'Orphaned Tickets'
                  : firstTicket.incidentName,
              incidentNumber: firstTicket.incidentNumber,
              resourceOrderNumber: firstTicket.resourceOrderNumber,
              financialCode: firstTicket.financialCode,
              status: Incident.statusDeletedArchived,
              createdAt: firstTicket.createdAt,
            ),
            ticketCount: incidentTickets.length,
            isOrphaned: true,
          ),
        );
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = groups.where((group) {
      final incident = group.incident;

      final selectedDate = _selectedDate;
      if (selectedDate != null &&
          !_isSameDate(incident.createdAt, selectedDate)) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchableValues = [
        incident.incidentName,
        incident.incidentNumber,
        incident.resourceOrderNumber,
        incident.financialCode,
        _dateFormat.format(incident.createdAt),
        _shortDateFormat.format(incident.createdAt),
        incident.createdAt.year.toString(),
      ].map((value) => value.toLowerCase());

      return searchableValues.any((value) => value.contains(query));
    }).toList();

    filtered.sort((a, b) {
      final left = a.incident;
      final right = b.incident;
      switch (_sortBy) {
        case _IncidentSort.dateNewest:
          return right.createdAt.compareTo(left.createdAt);
        case _IncidentSort.dateOldest:
          return left.createdAt.compareTo(right.createdAt);
        case _IncidentSort.name:
          return _compareText(left.incidentName, right.incidentName);
        case _IncidentSort.incidentNumber:
          return _compareText(left.incidentNumber, right.incidentNumber);
        case _IncidentSort.resourceOrder:
          return _compareText(
              left.resourceOrderNumber, right.resourceOrderNumber);
      }
    });

    return filtered;
  }

  Future<void> _pickDateFilter() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  int _compareText(String left, String right) {
    final normalizedLeft = left.trim().toLowerCase();
    final normalizedRight = right.trim().toLowerCase();
    if (normalizedLeft.isEmpty && normalizedRight.isEmpty) return 0;
    if (normalizedLeft.isEmpty) return 1;
    if (normalizedRight.isEmpty) return -1;
    return normalizedLeft.compareTo(normalizedRight);
  }
}

enum _IncidentSort {
  dateNewest,
  dateOldest,
  name,
  incidentNumber,
  resourceOrder,
}

enum _TicketIncidentFilter {
  active,
  closed,
  deleted;

  String get title {
    switch (this) {
      case _TicketIncidentFilter.active:
        return 'Active Incident Tickets';
      case _TicketIncidentFilter.closed:
        return 'Closed Incident Tickets';
      case _TicketIncidentFilter.deleted:
        return 'Deleted Incident Tickets';
    }
  }
}

class _TicketIncidentGroup {
  final Incident incident;
  final int ticketCount;
  final bool isOrphaned;

  const _TicketIncidentGroup({
    required this.incident,
    required this.ticketCount,
    this.isOrphaned = false,
  });

  String get fallbackName =>
      isOrphaned ? 'Orphaned Tickets' : 'Unnamed Incident';
}

class _IncidentSearchControls extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime? selectedDate;
  final _IncidentSort sortBy;
  final String Function(DateTime date) formatDate;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<_IncidentSort> onSortChanged;

  const _IncidentSearchControls({
    required this.searchController,
    required this.selectedDate,
    required this.sortBy,
    required this.formatDate,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onPickDate,
    required this.onClearDate,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search incidents',
            hintText: 'Name, date, incident #, resource order',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onSearchCleared,
                    icon: const Icon(Icons.close),
                  ),
          ),
        );

        final controls = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                selectedDate == null ? 'Date' : formatDate(selectedDate!),
              ),
            ),
            if (selectedDate != null)
              IconButton(
                tooltip: 'Clear date filter',
                onPressed: onClearDate,
                icon: const Icon(Icons.close),
              ),
            PopupMenuButton<_IncidentSort>(
              tooltip: 'Sort incidents',
              initialValue: sortBy,
              onSelected: onSortChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _IncidentSort.dateNewest,
                  child: Text('Date newest'),
                ),
                PopupMenuItem(
                  value: _IncidentSort.dateOldest,
                  child: Text('Date oldest'),
                ),
                PopupMenuItem(
                  value: _IncidentSort.name,
                  child: Text('Name'),
                ),
                PopupMenuItem(
                  value: _IncidentSort.incidentNumber,
                  child: Text('Incident #'),
                ),
                PopupMenuItem(
                  value: _IncidentSort.resourceOrder,
                  child: Text('Resource order'),
                ),
              ],
              child: _MenuControl(
                icon: Icons.sort,
                label: _sortLabel(sortBy),
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.md),
              controls,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: AppSpacing.md),
            controls,
          ],
        );
      },
    );
  }

  String _sortLabel(_IncidentSort sortBy) {
    switch (sortBy) {
      case _IncidentSort.dateNewest:
        return 'Date newest';
      case _IncidentSort.dateOldest:
        return 'Date oldest';
      case _IncidentSort.name:
        return 'Name';
      case _IncidentSort.incidentNumber:
        return 'Incident #';
      case _IncidentSort.resourceOrder:
        return 'Resource order';
    }
  }
}

class _MenuControl extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuControl({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }
}
