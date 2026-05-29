import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';

bool isResolved(FireIncident incident) {
  if ((incident.containmentPercent ?? 0) >= 100) return true;
  if (incident.containmentDate != null) return true;
  if (incident.controlDate != null) return true;
  if (incident.finalFireReportApprovedDate != null) return true;
  if (incident.isFlaggedInactive) return true;

  final sourceText = [
    incident.status,
    incident.importantUpdates,
    incident.rawProperties['IncidentStatus'],
    incident.rawProperties['FireStatus'],
    incident.rawProperties['FeatureStatus'],
    incident.rawProperties['ICS209ReportStatus'],
    incident.rawProperties['FinalFireReportStatus'],
  ].whereType<Object>().join(' ').toLowerCase();

  return sourceText.contains('contained') ||
      sourceText.contains('controlled') ||
      sourceText.contains(' out') ||
      sourceText == 'out' ||
      sourceText.contains('resolved') ||
      sourceText.contains('final fire report approved') ||
      sourceText.contains('no longer active');
}

String incidentStatusLabel(FireIncident incident) {
  final text = [
    incident.status,
    incident.importantUpdates,
    incident.rawProperties['IncidentStatus'],
    incident.rawProperties['FireStatus'],
    incident.rawProperties['ICS209ReportStatus'],
  ].whereType<Object>().join(' ').toLowerCase();

  if (text.contains('controlled') || incident.controlDate != null) {
    return 'Controlled';
  }
  if (text.contains(' out') || text == 'out') {
    return 'Out';
  }
  if (isResolved(incident)) {
    return 'Contained';
  }
  return 'Active';
}
