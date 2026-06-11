import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';

/// Complete saved form data for an OF-297 Emergency Equipment Shift Ticket.
///
/// The form data is the source of truth. PDF generation is intentionally not
/// included here; a later exporter should read this model and render a PDF from
/// the already-saved ticket fields.
class OF297ShiftTicket {
  static const Object _unset = Object();

  final String id;
  final String incidentId;
  final String incidentName;
  final String incidentNumber;
  final String financialCode;
  final String agreementNumber;
  final String resourceOrderNumber;
  final String contractorName;
  final String contractorAddress;
  final String contractorPhone;
  final String ctrOfficeResponsibleForFire;
  final String equipmentMakeModel;
  final String equipmentType;
  final String serialVinNumber;
  final String equipmentId;
  final String operatorName;
  final bool transportRetained;
  final bool? isMobilization;
  final bool rateIsHours;
  final bool rateIsMiles;
  final DateTime? globalShiftDate;
  final String globalBlock1Start;
  final String globalBlock1Stop;
  final String globalBlock2Start;
  final String globalBlock2Stop;
  final DateTime? shiftStart;
  final DateTime? shiftEnd;
  final List<OF297EquipmentTimeEntry> equipmentEntries;
  final List<OF297PersonnelTimeEntry> personnelEntries;
  final String remarks;
  final String contractorRepresentativeName;
  final OF297Signature? contractorSignature;
  final String incidentSupervisorName;
  final OF297Signature? supervisorSignature;
  final bool isFinalized;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OF297ShiftTicket({
    required this.id,
    required this.incidentId,
    required this.incidentName,
    this.incidentNumber = '',
    this.financialCode = '',
    this.agreementNumber = '',
    this.resourceOrderNumber = '',
    this.contractorName = '',
    this.contractorAddress = '',
    this.contractorPhone = '',
    this.ctrOfficeResponsibleForFire = '',
    this.equipmentMakeModel = '',
    this.equipmentType = '',
    this.serialVinNumber = '',
    this.equipmentId = '',
    this.operatorName = '',
    this.transportRetained = false,
    this.isMobilization,
    this.rateIsHours = true,
    this.rateIsMiles = false,
    this.globalShiftDate,
    this.globalBlock1Start = '',
    this.globalBlock1Stop = '',
    this.globalBlock2Start = '',
    this.globalBlock2Stop = '',
    this.shiftStart,
    this.shiftEnd,
    this.equipmentEntries = const [],
    this.personnelEntries = const [],
    this.remarks = '',
    this.contractorRepresentativeName = '',
    this.contractorSignature,
    this.incidentSupervisorName = '',
    this.supervisorSignature,
    this.isFinalized = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => !isFinalized;

  Map<String, dynamic> toJson() => {
        'id': id,
        'incidentId': incidentId,
        'incidentName': incidentName,
        'incidentNumber': incidentNumber,
        'financialCode': financialCode,
        'agreementNumber': agreementNumber,
        'resourceOrderNumber': resourceOrderNumber,
        'contractorName': contractorName,
        'contractorAddress': contractorAddress,
        'contractorPhone': contractorPhone,
        'ctrOfficeResponsibleForFire': ctrOfficeResponsibleForFire,
        'equipmentMakeModel': equipmentMakeModel,
        'equipmentType': equipmentType,
        'serialVinNumber': serialVinNumber,
        'equipmentId': equipmentId,
        'operatorName': operatorName,
        'transportRetained': transportRetained,
        'isMobilization': isMobilization,
        'rateIsHours': rateIsHours,
        'rateIsMiles': rateIsMiles,
        'globalShiftDate': globalShiftDate?.toIso8601String(),
        'globalBlock1Start': globalBlock1Start,
        'globalBlock1Stop': globalBlock1Stop,
        'globalBlock2Start': globalBlock2Start,
        'globalBlock2Stop': globalBlock2Stop,
        'shiftStart': shiftStart?.toIso8601String(),
        'shiftEnd': shiftEnd?.toIso8601String(),
        'equipmentEntries':
            equipmentEntries.map((entry) => entry.toJson()).toList(),
        'personnelEntries':
            personnelEntries.map((entry) => entry.toJson()).toList(),
        'remarks': remarks,
        'contractorRepresentativeName': contractorRepresentativeName,
        'contractorSignature': contractorSignature?.toJson(),
        'incidentSupervisorName': incidentSupervisorName,
        'supervisorSignature': supervisorSignature?.toJson(),
        'isFinalized': isFinalized,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OF297ShiftTicket.fromJson(Map<String, dynamic> json) {
    return OF297ShiftTicket(
      id: json['id'] ?? '',
      incidentId: json['incidentId'] ?? '',
      incidentName: json['incidentName'] ?? '',
      incidentNumber: json['incidentNumber'] ?? '',
      financialCode: json['financialCode'] ?? '',
      agreementNumber: json['agreementNumber'] ?? '',
      resourceOrderNumber: json['resourceOrderNumber'] ?? '',
      contractorName: json['contractorName'] ?? '',
      contractorAddress: json['contractorAddress'] ?? '',
      contractorPhone: json['contractorPhone'] ?? '',
      ctrOfficeResponsibleForFire: json['ctrOfficeResponsibleForFire'] ?? '',
      equipmentMakeModel: json['equipmentMakeModel'] ?? '',
      equipmentType: json['equipmentType'] ?? '',
      serialVinNumber: json['serialVinNumber'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      operatorName: json['operatorName'] ?? '',
      transportRetained: json['transportRetained'] ?? false,
      isMobilization: json['isMobilization'],
      rateIsHours: json['rateIsHours'] ?? true,
      rateIsMiles: json['rateIsMiles'] ?? false,
      globalShiftDate: DateTime.tryParse(json['globalShiftDate'] ?? ''),
      globalBlock1Start: json['globalBlock1Start'] ?? '',
      globalBlock1Stop: json['globalBlock1Stop'] ?? '',
      globalBlock2Start: json['globalBlock2Start'] ?? '',
      globalBlock2Stop: json['globalBlock2Stop'] ?? '',
      shiftStart: DateTime.tryParse(json['shiftStart'] ?? ''),
      shiftEnd: DateTime.tryParse(json['shiftEnd'] ?? ''),
      equipmentEntries: ((json['equipmentEntries'] ?? []) as List<dynamic>)
          .map(
            (entry) =>
                OF297EquipmentTimeEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      personnelEntries: ((json['personnelEntries'] ?? []) as List<dynamic>)
          .map(
            (entry) =>
                OF297PersonnelTimeEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      remarks: json['remarks'] ?? '',
      contractorRepresentativeName: json['contractorRepresentativeName'] ?? '',
      contractorSignature: json['contractorSignature'] == null
          ? null
          : OF297Signature.fromJson(
              json['contractorSignature'] as Map<String, dynamic>,
            ),
      incidentSupervisorName: json['incidentSupervisorName'] ?? '',
      supervisorSignature: (json['supervisorSignature'] ??
                  json['incidentSupervisorSignature']) ==
              null
          ? null
          : OF297Signature.fromJson(
              (json['supervisorSignature'] ??
                  json['incidentSupervisorSignature']) as Map<String, dynamic>,
            ),
      isFinalized: json['isFinalized'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  OF297ShiftTicket copyWith({
    String? incidentId,
    String? incidentName,
    String? incidentNumber,
    String? financialCode,
    String? agreementNumber,
    String? resourceOrderNumber,
    String? contractorName,
    String? contractorAddress,
    String? contractorPhone,
    String? ctrOfficeResponsibleForFire,
    String? equipmentMakeModel,
    String? equipmentType,
    String? serialVinNumber,
    String? equipmentId,
    String? operatorName,
    bool? transportRetained,
    Object? isMobilization = _unset,
    bool? rateIsHours,
    bool? rateIsMiles,
    Object? globalShiftDate = _unset,
    String? globalBlock1Start,
    String? globalBlock1Stop,
    String? globalBlock2Start,
    String? globalBlock2Stop,
    DateTime? shiftStart,
    DateTime? shiftEnd,
    List<OF297EquipmentTimeEntry>? equipmentEntries,
    List<OF297PersonnelTimeEntry>? personnelEntries,
    String? remarks,
    String? contractorRepresentativeName,
    Object? contractorSignature = _unset,
    String? incidentSupervisorName,
    Object? supervisorSignature = _unset,
    bool? isFinalized,
    DateTime? updatedAt,
  }) {
    return OF297ShiftTicket(
      id: id,
      incidentId: incidentId ?? this.incidentId,
      incidentName: incidentName ?? this.incidentName,
      incidentNumber: incidentNumber ?? this.incidentNumber,
      financialCode: financialCode ?? this.financialCode,
      agreementNumber: agreementNumber ?? this.agreementNumber,
      resourceOrderNumber: resourceOrderNumber ?? this.resourceOrderNumber,
      contractorName: contractorName ?? this.contractorName,
      contractorAddress: contractorAddress ?? this.contractorAddress,
      contractorPhone: contractorPhone ?? this.contractorPhone,
      ctrOfficeResponsibleForFire:
          ctrOfficeResponsibleForFire ?? this.ctrOfficeResponsibleForFire,
      equipmentMakeModel: equipmentMakeModel ?? this.equipmentMakeModel,
      equipmentType: equipmentType ?? this.equipmentType,
      serialVinNumber: serialVinNumber ?? this.serialVinNumber,
      equipmentId: equipmentId ?? this.equipmentId,
      operatorName: operatorName ?? this.operatorName,
      transportRetained: transportRetained ?? this.transportRetained,
      isMobilization: identical(isMobilization, _unset)
          ? this.isMobilization
          : isMobilization as bool?,
      rateIsHours: rateIsHours ?? this.rateIsHours,
      rateIsMiles: rateIsMiles ?? this.rateIsMiles,
      globalShiftDate: identical(globalShiftDate, _unset)
          ? this.globalShiftDate
          : globalShiftDate as DateTime?,
      globalBlock1Start: globalBlock1Start ?? this.globalBlock1Start,
      globalBlock1Stop: globalBlock1Stop ?? this.globalBlock1Stop,
      globalBlock2Start: globalBlock2Start ?? this.globalBlock2Start,
      globalBlock2Stop: globalBlock2Stop ?? this.globalBlock2Stop,
      shiftStart: shiftStart ?? this.shiftStart,
      shiftEnd: shiftEnd ?? this.shiftEnd,
      equipmentEntries: equipmentEntries ?? this.equipmentEntries,
      personnelEntries: personnelEntries ?? this.personnelEntries,
      remarks: remarks ?? this.remarks,
      contractorRepresentativeName:
          contractorRepresentativeName ?? this.contractorRepresentativeName,
      contractorSignature: identical(contractorSignature, _unset)
          ? this.contractorSignature
          : contractorSignature as OF297Signature?,
      incidentSupervisorName:
          incidentSupervisorName ?? this.incidentSupervisorName,
      supervisorSignature: identical(supervisorSignature, _unset)
          ? this.supervisorSignature
          : supervisorSignature as OF297Signature?,
      isFinalized: isFinalized ?? this.isFinalized,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
