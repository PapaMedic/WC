import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wildland_companion_v2/features/incidents/data/incident_repository.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key});

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  final IncidentRepository _repository = IncidentRepository();
  final Uuid _uuid = const Uuid();

  List<Incident> _incidents = [];
  bool _isLoading = true;

  // false = show active incidents
  // true = show closed incidents
  bool _showClosed = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  // Loads all incidents from local storage.
  Future<void> _loadIncidents() async {
    final incidents = await _repository.getAllIncidents();

    if (!mounted) return;

    setState(() {
      _incidents = incidents;
      _isLoading = false;
    });
  }

  // Opens the add incident dialog and saves a new incident.
  Future<void> _addIncident() async {
    final result = await showDialog<Incident>(
      context: context,
      builder: (context) {
        final incidentNameController = TextEditingController();
        final incidentNumberController = TextEditingController();
        final resourceOrderController = TextEditingController();
        final financialCodeController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Incident'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: incidentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Name',
                  ),
                ),
                TextField(
                  controller: incidentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Number',
                  ),
                ),
                TextField(
                  controller: resourceOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Order Number',
                  ),
                ),
                TextField(
                  controller: financialCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Financial Code',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final incident = Incident(
                  id: _uuid.v4(),
                  incidentName: incidentNameController.text.trim(),
                  incidentNumber: incidentNumberController.text.trim(),
                  resourceOrderNumber: resourceOrderController.text.trim(),
                  financialCode: financialCodeController.text.trim(),
                  createdAt: DateTime.now(),
                );

                Navigator.pop(context, incident);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _repository.addIncident(result);
    await _loadIncidents();
  }

  // Selects the current active incident.
  // Only one incident should be selected at a time.
  Future<void> _selectIncident(String id) async {
    await _repository.selectIncident(id);
    await _loadIncidents();
  }

  // Changes an incident from Active to Closed.
  // Repository should also unselect it when closed.
  Future<void> _closeIncident(String id) async {
    await _repository.closeIncident(id);
    await _loadIncidents();
  }

  // Changes a closed incident back to Active.
  Future<void> _reopenIncident(String id) async {
    await _repository.reopenIncident(id);
    await _loadIncidents();
  }

  // Deletes the incident from local storage.
  Future<void> _deleteIncident(String id) async {
    await _repository.deleteIncident(id);
    await _loadIncidents();
  }

  // Opens bottom sheet with incident details and actions.
  void _openIncidentDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 12,
            children: [
              Text(
                incident.incidentName.isEmpty
                    ? 'Unnamed Incident'
                    : incident.incidentName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              _DetailRow(
                label: 'Incident Number',
                value: incident.incidentNumber,
              ),
              _DetailRow(
                label: 'Resource Order Number',
                value: incident.resourceOrderNumber,
              ),
              _DetailRow(
                label: 'Financial Code',
                value: incident.financialCode,
              ),
              _DetailRow(
                label: 'Status',
                value: incident.status,
              ),
              _DetailRow(
                label: 'Current Incident',
                value: incident.isSelected ? 'Yes' : 'No',
              ),

              const Divider(),

              // Active incidents can be selected and closed.
              if (incident.isActive) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _selectIncident(incident.id);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Set as Current Incident'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _closeIncident(incident.id);
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Close Incident'),
                  ),
                ),
              ],

              // Closed incidents can be reopened.
              if (incident.isClosed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reopenIncident(incident.id);
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Reopen Incident'),
                  ),
                ),

              // Delete works for both active and closed incidents.
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteIncident(incident.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Incident'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filters the list based on the selected Active/Closed tab.
    final filteredIncidents = _incidents
        .where((incident) => _showClosed ? incident.isClosed : incident.isActive)
        .toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Active / Closed filter.
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
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
          ),

          // Incident list.
          Expanded(
            child: filteredIncidents.isEmpty
                ? Center(
                    child: Text(
                      _showClosed
                          ? 'No closed incidents.'
                          : 'No active incidents added yet.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];

                      return Card(
                        child: ListTile(
                          // Checkmark means this is the current selected incident.
                          leading: Icon(
                            incident.isSelected
                                ? Icons.check_circle
                                : incident.isActive
                                    ? Icons.local_fire_department
                                    : Icons.archive_outlined,
                          ),

                          title: Text(
                            incident.incidentName.isEmpty
                                ? 'Unnamed Incident'
                                : incident.incidentName,
                          ),

                          subtitle: Text(
                            'Incident #: ${incident.incidentNumber}\n'
                            'Resource Order: ${incident.resourceOrderNumber}\n'
                            'Financial Code: ${incident.financialCode}',
                          ),

                          isThreeLine: true,

                          // Three-dot menu opens details/actions.
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _openIncidentDetails(incident),
                          ),

                          // Tapping active incident selects it.
                          // Tapping closed incident opens details.
                          onTap: incident.isActive
                              ? () => _selectIncident(incident.id)
                              : () => _openIncidentDetails(incident),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Adds a new incident.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIncident,
        icon: const Icon(Icons.add),
        label: const Text('Add Incident'),
      ),
    );
  }
}

// Small reusable row for bottom sheet details.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
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
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}