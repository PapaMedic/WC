import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wildland_companion_v2/features/apparatus/data/apparatus_repository.dart';
import 'package:wildland_companion_v2/features/apparatus/models/apparatus.dart';

class ApparatusPage extends StatefulWidget {
  const ApparatusPage({super.key});

  @override
  State<ApparatusPage> createState() => _ApparatusPageState();
}

class _ApparatusPageState extends State<ApparatusPage> {
  final ApparatusRepository _repository = ApparatusRepository();
  final Uuid _uuid = const Uuid();

  List<Apparatus> _apparatusList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApparatus();
  }

  Future<void> _loadApparatus() async {
    final apparatus = await _repository.getAllApparatus();

    if (!mounted) return;

    setState(() {
      _apparatusList = apparatus;
      _isLoading = false;
    });
  }

  Future<void> _addApparatus() async {
    final result = await showDialog<Apparatus>(
      context: context,
      builder: (context) {
        final agencyController = TextEditingController();
        final makeModelController = TextEditingController();
        final equipmentTypeController = TextEditingController();
        final serialVinController = TextEditingController();
        final licenseController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Apparatus'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: agencyController,
                  decoration: const InputDecoration(
                    labelText: 'Agency Name',
                  ),
                ),
                TextField(
                  controller: makeModelController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Make/Model',
                  ),
                ),
                TextField(
                  controller: equipmentTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Type',
                  ),
                ),
                TextField(
                  controller: serialVinController,
                  decoration: const InputDecoration(
                    labelText: 'Serial/VIN Number',
                  ),
                ),
                TextField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License/ID Number',
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
                final apparatus = Apparatus(
                  id: _uuid.v4(),
                  agencyName: agencyController.text.trim(),
                  equipmentMakeModel: makeModelController.text.trim(),
                  equipmentType: equipmentTypeController.text.trim(),
                  serialVinNumber: serialVinController.text.trim(),
                  licenseIdNumber: licenseController.text.trim(),
                );

                Navigator.pop(context, apparatus);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _repository.addApparatus(result);
    await _loadApparatus();
  }

  Future<void> _selectApparatus(String id) async {
    await _repository.selectApparatus(id);
    await _loadApparatus();
  }

  Future<void> _deleteApparatus(String id) async {
    await _repository.deleteApparatus(id);
    await _loadApparatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: _apparatusList.isEmpty
          ? const Center(
              child: Text('No apparatus added yet.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _apparatusList.length,
              itemBuilder: (context, index) {
                final apparatus = _apparatusList[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      apparatus.isSelected
                          ? Icons.check_circle
                          : Icons.fire_truck,
                    ),
                    title: Text(apparatus.equipmentMakeModel),
                    subtitle: Text(
                      '${apparatus.equipmentType}\n'
                      'Agency: ${apparatus.agencyName}\n'
                      'License: ${apparatus.licenseIdNumber}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteApparatus(apparatus.id),
                    ),
                    onTap: () => _selectApparatus(apparatus.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addApparatus,
        icon: const Icon(Icons.add),
        label: const Text('Add Apparatus'),
      ),
    );
  }
}
