import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

class FinalizedTicketRecord {
  final String ticketId;
  final String workspaceId;
  final WorkspaceType workspaceType;
  final String? organizationId;
  final String ownerUid;
  final String incidentId;
  final String incidentName;
  final String incidentNumber;
  final String resourceOrderNumber;
  final String financialCode;
  final String apparatusId;
  final String apparatusName;
  final String crewName;
  final String createdByUid;
  final String createdByName;
  final DateTime finalizedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int personnelCount;
  final double totalPersonnelHours;
  final double totalApparatusHours;
  final List<String> pdfStoragePaths;
  final String? ctrPdfStoragePath;
  final String ticketType;
  final String syncStatus;
  final String status;

  const FinalizedTicketRecord({
    required this.ticketId,
    required this.workspaceId,
    required this.workspaceType,
    this.organizationId,
    required this.ownerUid,
    required this.incidentId,
    required this.incidentName,
    required this.incidentNumber,
    required this.resourceOrderNumber,
    required this.financialCode,
    required this.apparatusId,
    required this.apparatusName,
    required this.crewName,
    required this.createdByUid,
    required this.createdByName,
    required this.finalizedAt,
    this.startDate,
    this.endDate,
    required this.personnelCount,
    required this.totalPersonnelHours,
    required this.totalApparatusHours,
    this.pdfStoragePaths = const [],
    this.ctrPdfStoragePath,
    this.ticketType = 'of297',
    this.syncStatus = 'pending',
    this.status = 'finalized',
  });

  factory FinalizedTicketRecord.fromTicket({
    required OF297ShiftTicket ticket,
    required String workspaceId,
    required WorkspaceType workspaceType,
    String? organizationId,
    required String ownerUid,
    required String createdByName,
    List<String> pdfStoragePaths = const [],
    String? ctrPdfStoragePath,
    String syncStatus = 'pending',
  }) {
    final totalPersonnelHours = ticket.personnelEntries.fold<double>(
      0,
      (runningTotal, entry) => runningTotal + entry.totalHours,
    );
    final totalApparatusHours = ticket.equipmentEntries.fold<double>(
      0,
      (runningTotal, entry) => runningTotal + entry.totalHours,
    );

    return FinalizedTicketRecord(
      ticketId: ticket.id,
      workspaceId: workspaceId,
      workspaceType: workspaceType,
      organizationId: organizationId,
      ownerUid: ownerUid,
      incidentId: ticket.incidentId,
      incidentName: ticket.incidentName,
      incidentNumber: ticket.incidentNumber,
      resourceOrderNumber: ticket.resourceOrderNumber,
      financialCode: ticket.financialCode,
      apparatusId: ticket.equipmentId,
      apparatusName: ticket.equipmentMakeModel,
      crewName: ticket.contractorName,
      createdByUid: ownerUid,
      createdByName: createdByName,
      finalizedAt: ticket.updatedAt,
      startDate: ticket.shiftStart ?? ticket.globalShiftDate,
      endDate: ticket.shiftEnd ?? ticket.globalShiftDate,
      personnelCount: ticket.personnelEntries.length,
      totalPersonnelHours: totalPersonnelHours,
      totalApparatusHours: totalApparatusHours,
      pdfStoragePaths: pdfStoragePaths,
      ctrPdfStoragePath: ctrPdfStoragePath,
      syncStatus: syncStatus,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ticketId': ticketId,
        'workspaceId': workspaceId,
        'workspaceType': workspaceType.value,
        'organizationId': organizationId,
        'ownerUid': ownerUid,
        'incidentId': incidentId,
        'incidentName': incidentName,
        'incidentNumber': incidentNumber,
        'resourceOrderNumber': resourceOrderNumber,
        'financialCode': financialCode,
        'apparatusId': apparatusId,
        'apparatusName': apparatusName,
        'crewName': crewName,
        'createdByUid': createdByUid,
        'createdByName': createdByName,
        'finalizedAt': Timestamp.fromDate(finalizedAt),
        'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'personnelCount': personnelCount,
        'totalPersonnelHours': totalPersonnelHours,
        'totalApparatusHours': totalApparatusHours,
        'pdfStoragePaths': pdfStoragePaths,
        'ctrPdfStoragePath': ctrPdfStoragePath,
        'ticketType': ticketType,
        'syncStatus': syncStatus,
        'status': status,
      };

  factory FinalizedTicketRecord.fromFirestore(Map<String, dynamic> data) {
    return FinalizedTicketRecord(
      ticketId: data['ticketId'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      workspaceType: WorkspaceTypeX.fromValue(data['workspaceType']),
      organizationId: data['organizationId'],
      ownerUid: data['ownerUid'] ?? '',
      incidentId: data['incidentId'] ?? '',
      incidentName: data['incidentName'] ?? '',
      incidentNumber: data['incidentNumber'] ?? '',
      resourceOrderNumber: data['resourceOrderNumber'] ?? '',
      financialCode: data['financialCode'] ?? '',
      apparatusId: data['apparatusId'] ?? '',
      apparatusName: data['apparatusName'] ?? '',
      crewName: data['crewName'] ?? '',
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
      finalizedAt: _readDate(data['finalizedAt']) ?? DateTime.now(),
      startDate: _readDate(data['startDate']),
      endDate: _readDate(data['endDate']),
      personnelCount: (data['personnelCount'] as num?)?.toInt() ?? 0,
      totalPersonnelHours:
          (data['totalPersonnelHours'] as num?)?.toDouble() ?? 0,
      totalApparatusHours:
          (data['totalApparatusHours'] as num?)?.toDouble() ?? 0,
      pdfStoragePaths: List<String>.from(data['pdfStoragePaths'] ?? const []),
      ctrPdfStoragePath: data['ctrPdfStoragePath'],
      ticketType: data['ticketType'] ?? 'of297',
      syncStatus: data['syncStatus'] ?? 'local_only',
      status: data['status'] ?? 'finalized',
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
