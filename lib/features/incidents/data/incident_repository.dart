import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildland_companion_v2/features/incidents/models/incident.dart';

class IncidentRepository {
  static const String _storageKey = 'incident_list';

  Future<List<Incident>> getAllIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawJson) as List<dynamic>;

    return decoded
        .map((item) => Incident.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAllIncidents(List<Incident> incidents) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      incidents.map((incident) => incident.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addIncident(Incident incident) async {
    final incidents = await getAllIncidents();
    incidents.add(incident);
    await saveAllIncidents(incidents);
  }

  Future<Incident?> findBySourceIrwinId(String irwinId) async {
    final normalized = _normalizeIrwinId(irwinId);
    if (normalized.isEmpty) return null;

    final incidents = await getAllIncidents();
    for (final incident in incidents) {
      if (_normalizeIrwinId(incident.sourceIrwinId ?? '') == normalized) {
        return incident;
      }
    }

    return null;
  }

  Future<void> updateIncident(Incident updatedIncident) async {
    final incidents = await getAllIncidents();

    final updatedList = incidents.map((incident) {
      if (incident.id == updatedIncident.id) {
        return incident.copyWith(
          incidentName: updatedIncident.incidentName,
          incidentNumber: updatedIncident.incidentNumber,
          resourceOrderNumber: updatedIncident.resourceOrderNumber,
          financialCode: updatedIncident.financialCode,
        );
      }
      return incident;
    }).toList();

    await saveAllIncidents(updatedList);
  }

  Future<void> deleteIncident(String id) async {
    final incidents = await getAllIncidents();

    final updatedList = incidents.map((incident) {
      if (incident.id == id) {
        return incident.copyWith(
          status: Incident.statusDeletedArchived,
          isSelected: false,
        );
      }
      return incident;
    }).toList();

    await saveAllIncidents(updatedList);
  }

  Future<void> closeIncident(String id) async {
    final incidents = await getAllIncidents();

    final updatedList = incidents.map((incident) {
      if (incident.id == id) {
        return incident.copyWith(
          status: Incident.statusClosed,
          isSelected: false,
        );
      }
      return incident;
    }).toList();

    await saveAllIncidents(updatedList);
  }

  Future<void> reopenIncident(String id) async {
    final incidents = await getAllIncidents();

    final updatedList = incidents.map((incident) {
      if (incident.id == id) {
        return incident.copyWith(status: Incident.statusActive);
      }
      return incident;
    }).toList();

    await saveAllIncidents(updatedList);
  }

  Future<List<Incident>> getActiveIncidents() async {
    final incidents = await getAllIncidents();
    return incidents.where((incident) => incident.isActive).toList();
  }

  Future<List<Incident>> getClosedIncidents() async {
    final incidents = await getAllIncidents();
    return incidents.where((incident) => incident.isClosed).toList();
  }

  Future<List<Incident>> getDeletedArchivedIncidents() async {
    final incidents = await getAllIncidents();
    return incidents.where((incident) => incident.isDeletedArchived).toList();
  }

  Future<void> selectIncident(String id) async {
    final incidents = await getAllIncidents();

    final updatedList = incidents.map((incident) {
      return incident.copyWith(
        isSelected: incident.id == id && incident.isActive,
      );
    }).toList();

    await saveAllIncidents(updatedList);
  }

  Future<Incident?> getSelectedIncident() async {
    final incidents = await getAllIncidents();

    try {
      return incidents.firstWhere(
        (incident) => incident.isSelected && incident.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  String _normalizeIrwinId(String value) {
    return value.trim().toLowerCase().replaceAll('{', '').replaceAll('}', '');
  }
}
