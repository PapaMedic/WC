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
  bool _showClosed = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    final incidents = await _repository.getAllIncidents();
    if (!mounted) return;

    setState(() {
      _incidents = incidents;
      _isLoading = false;
    });
  }

  Future<void> _addIncident() async {
    final result = await _showIncidentEditor();
    if (result == null) return;

    await _repository.addIncident(result);
    await _loadIncidents();
  }

  Future<void> _editIncident(Incident incident) async {
    final result = await _showIncidentEditor(incident: incident);
    if (result == null) return;

    await _repository.updateIncident(result);
    await _loadIncidents();
  }

  Future<void> _selectIncident(String id) async {
    await _repository.selectIncident(id);
    await _loadIncidents();
  }

  Future<void> _closeIncident(String id) async {
    await _repository.closeIncident(id);
    await _loadIncidents();
  }

  Future<void> _reopenIncident(String id) async {
    await _repository.reopenIncident(id);
    await _loadIncidents();
  }

  Future<void> _deleteIncident(String id) async {
    await _repository.deleteIncident(id);
    await _loadIncidents();
  }

  Future<Incident?> _showIncidentEditor({Incident? incident}) {
    return showDialog<Incident>(
      context: context,
      builder: (context) {
        final incidentNameController = TextEditingController(
          text: incident?.incidentName ?? '',
        );
        final incidentNumberController = TextEditingController(
          text: incident?.incidentNumber ?? '',
        );
        final acresController = TextEditingController(
          text: incident?.acres ?? '',
        );
        final containmentController = TextEditingController(
          text: incident?.containmentPercent ?? '',
        );
        final jurisdictionController = TextEditingController(
          text: incident?.jurisdiction ?? '',
        );
        final agencyController = TextEditingController(
          text: incident?.agency ?? '',
        );
        final resourceOrderController = TextEditingController(
          text: incident?.resourceOrderNumber ?? '',
        );
        final financialCodeController = TextEditingController(
          text: incident?.financialCode ?? '',
        );
        final notesController = TextEditingController(
          text: incident?.notes ?? '',
        );
        var status = incident?.status ?? 'Active';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(incident == null ? 'Add Incident' : 'Edit Incident'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => status = value);
                      },
                    ),
                    TextField(
                      controller: acresController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Acres'),
                    ),
                    TextField(
                      controller: containmentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Containment %',
                      ),
                    ),
                    TextField(
                      controller: jurisdictionController,
                      decoration: const InputDecoration(
                        labelText: 'Jurisdiction / Unit',
                      ),
                    ),
                    TextField(
                      controller: agencyController,
                      decoration: const InputDecoration(labelText: 'Agency'),
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
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Details',
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
                    final updated = Incident(
                      id: incident?.id ?? _uuid.v4(),
                      incidentName: incidentNameController.text.trim(),
                      incidentNumber: incidentNumberController.text.trim(),
                      resourceOrderNumber: resourceOrderController.text.trim(),
                      financialCode: financialCodeController.text.trim(),
                      status: status,
                      isSelected:
                          status == 'Active' && (incident?.isSelected ?? false),
                      createdAt: incident?.createdAt ?? DateTime.now(),
                      source: incident?.source,
                      sourceIrwinId: incident?.sourceIrwinId,
                      sourceStatus: incident?.sourceStatus,
                      acres: acresController.text.trim(),
                      containmentPercent: containmentController.text.trim(),
                      jurisdiction: jurisdictionController.text.trim(),
                      agency: agencyController.text.trim(),
                      notes: notesController.text.trim(),
                    );

                    Navigator.pop(context, updated);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
              if (incident.incidentNumber.isNotEmpty)
                _DetailRow(
                  label: 'Incident Number',
                  value: incident.incidentNumber,
                ),
              _DetailRow(label: 'Status', value: incident.status),
              _DetailRow(
                label: 'Current Incident',
                value: incident.isSelected ? 'Yes' : 'No',
              ),
              if ((incident.acres ?? '').isNotEmpty)
                _DetailRow(label: 'Acres', value: incident.acres ?? ''),
              if ((incident.containmentPercent ?? '').isNotEmpty)
                _DetailRow(
                  label: 'Containment',
                  value: '${incident.containmentPercent}%',
                ),
              if ((incident.jurisdiction ?? '').isNotEmpty)
                _DetailRow(
                  label: 'Jurisdiction / Unit',
                  value: incident.jurisdiction ?? '',
                ),
              if ((incident.agency ?? '').isNotEmpty)
                _DetailRow(label: 'Agency', value: incident.agency ?? ''),
              if (incident.resourceOrderNumber.isNotEmpty)
                _DetailRow(
                  label: 'Resource Order Number',
                  value: incident.resourceOrderNumber,
                ),
              if (incident.financialCode.isNotEmpty)
                _DetailRow(
                  label: 'Financial Code',
                  value: incident.financialCode,
                ),
              if ((incident.source ?? '').isNotEmpty)
                _DetailRow(label: 'Source', value: incident.source ?? ''),
              if ((incident.notes ?? '').isNotEmpty)
                Text(
                  incident.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editIncident(incident);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Incident'),
                ),
              ),
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

  String _summaryForIncident(Incident incident) {
    final lines = <String>[];
    if (incident.incidentNumber.isNotEmpty) {
      lines.add('Incident #: ${incident.incidentNumber}');
    }
    if ((incident.acres ?? '').isNotEmpty) {
      lines.add('Acres: ${incident.acres}');
    }
    if ((incident.containmentPercent ?? '').isNotEmpty) {
      lines.add('Containment: ${incident.containmentPercent}%');
    }
    final jurisdictionAgency = [
      incident.jurisdiction,
      incident.agency,
    ].where((value) => (value ?? '').isNotEmpty).join(' / ');
    if (jurisdictionAgency.isNotEmpty) {
      lines.add(jurisdictionAgency);
    }
    if (lines.isEmpty) return 'No local incident details entered.';
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncidents = _incidents
        .where(
          (incident) => _showClosed ? incident.isClosed : incident.isActive,
        )
        .toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(_summaryForIncident(incident)),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editIncident(incident),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _openIncidentDetails(incident),
                              ),
                            ],
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIncident,
        icon: const Icon(Icons.add),
        label: const Text('Add Incident'),
      ),
    );
  }
}

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
