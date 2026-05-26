import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/incident_tickets_page.dart';

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
  bool _showClosed = false;
  DateTime? _selectedDate;
  _IncidentSort _sortBy = _IncidentSort.dateNewest;

  @override
  void initState() {
    super.initState();
    _incidentsFuture = _incidentRepository.getAllIncidents();
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
        onBack: () {
          setState(() {
            _selectedIncident = null;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Incident>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final incidents = _filterAndSortIncidents(snapshot.data ?? []);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'OF-297 Tickets',
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Active'),
                    icon: Icon(Icons.local_fire_department_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Closed'),
                    icon: Icon(Icons.archive_outlined),
                  ),
                ],
                selected: {_showClosed},
                onSelectionChanged: (value) {
                  setState(() {
                    _showClosed = value.first;
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
                title:
                    '${_showClosed ? 'Closed' : 'Active'} Incidents (${incidents.length})',
                child: incidents.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text('No incidents match this view.'),
                      )
                    : Column(
                        children: incidents.map((incident) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.warning_amber_outlined),
                            title: Text(
                              incident.incidentName.isEmpty
                                  ? 'Unnamed Incident'
                                  : incident.incidentName,
                            ),
                            subtitle: Text(
                              'Date: ${_dateFormat.format(incident.createdAt)}\n'
                              'Incident #: ${incident.incidentNumber.isEmpty ? '-' : incident.incidentNumber}\n'
                              'Resource Order: ${incident.resourceOrderNumber.isEmpty ? '-' : incident.resourceOrderNumber}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right_outlined),
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
      ),
    );
  }

  List<Incident> _filterAndSortIncidents(List<Incident> allIncidents) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allIncidents.where((incident) {
      final statusMatches = _showClosed ? incident.isClosed : incident.isActive;
      if (!statusMatches) return false;

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
      switch (_sortBy) {
        case _IncidentSort.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case _IncidentSort.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
        case _IncidentSort.name:
          return _compareText(a.incidentName, b.incidentName);
        case _IncidentSort.incidentNumber:
          return _compareText(a.incidentNumber, b.incidentNumber);
        case _IncidentSort.resourceOrder:
          return _compareText(a.resourceOrderNumber, b.resourceOrderNumber);
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
