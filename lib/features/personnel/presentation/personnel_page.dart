import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:wildland_companion_v2/features/personnel/data/personnel_repository.dart';
import 'package:wildland_companion_v2/features/personnel/models/personnel.dart';

class PersonnelPage extends StatefulWidget {
  const PersonnelPage({super.key});

  @override
  State<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  final PersonnelRepository _repository = PersonnelRepository();
  final Uuid _uuid = const Uuid();

  List<Personnel> _personnelList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
  }

  Future<void> _loadPersonnel() async {
    final personnel = await _repository.getAllPersonnel();

    if (!mounted) return;

    setState(() {
      _personnelList = personnel;
      _isLoading = false;
    });
  }

  Future<void> _addPersonnel() async {
    final result = await showDialog<Personnel>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final qualificationController = TextEditingController();
        final homeUnitController = TextEditingController();
        final phoneController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Personnel'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: qualificationController,
                  decoration: const InputDecoration(labelText: 'Qualification'),
                ),
                TextField(
                  controller: homeUnitController,
                  decoration: const InputDecoration(labelText: 'Home Unit'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
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
                final personnel = Personnel(
                  id: _uuid.v4(),
                  name: nameController.text.trim(),
                  qualification: qualificationController.text.trim(),
                  homeUnit: homeUnitController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                );

                Navigator.pop(context, personnel);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _repository.addPersonnel(result);
    await _loadPersonnel();
  }

  Future<void> _toggleAssigned(String id) async {
    await _repository.toggleAssigned(id);
    await _loadPersonnel();
  }

  Future<void> _deletePersonnel(String id) async {
    await _repository.deletePersonnel(id);
    await _loadPersonnel();
  }

  Future<void> _clearAssignedPersonnel() async {
    await _repository.clearAssignedPersonnel();
    await _loadPersonnel();
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount =
        _personnelList.where((personnel) => personnel.isAssigned).length;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          if (_personnelList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$assignedCount assigned to current crew',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        assignedCount == 0 ? null : _clearAssignedPersonnel,
                    child: const Text('Clear Crew'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _personnelList.isEmpty
                ? const Center(
                    child: Text('No personnel added yet.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _personnelList.length,
                    itemBuilder: (context, index) {
                      final personnel = _personnelList[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            personnel.isAssigned
                                ? Icons.check_circle
                                : Icons.person_outline,
                          ),
                          title: Text(personnel.name),
                          subtitle: Text(
                            '${personnel.qualification}\n'
                            'Home Unit: ${personnel.homeUnit}\n'
                            'Phone: ${personnel.phoneNumber}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deletePersonnel(personnel.id),
                          ),
                          onTap: () => _toggleAssigned(personnel.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPersonnel,
        icon: const Icon(Icons.add),
        label: const Text('Add Personnel'),
      ),
    );
  }
}
