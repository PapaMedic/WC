import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:wildland_companion_v2/features/tickets/data/of297_repository.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

/// App state for OF-297 tickets.
///
/// Draft tickets can be edited or deleted. Finalized tickets are locked so the
/// saved form remains a reliable record for a future PDF exporter.
class TicketsState extends ChangeNotifier {
  static const Uuid _uuid = Uuid();

  final OF297Repository _repository;

  TicketsState({
    OF297Repository? repository,
  }) : _repository = repository ?? OF297Repository();

  final List<OF297ShiftTicket> _tickets = [];
  final List<OF297PdfRecord> _pdfRecords = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  List<OF297ShiftTicket> get tickets => List.unmodifiable(_tickets);
  List<OF297PdfRecord> get pdfRecords => List.unmodifiable(_pdfRecords);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  Future<void> loadTickets({bool force = false}) async {
    if (_isLoading || (_isLoaded && !force)) return;

    _isLoading = true;
    notifyListeners();

    final storedTickets = await _repository.getTickets();
    final storedPdfRecords = await _repository.getPdfRecords();
    _tickets
      ..clear()
      ..addAll(storedTickets);
    _pdfRecords
      ..clear()
      ..addAll(storedPdfRecords);

    _isLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  List<OF297ShiftTicket> ticketsForIncident(String incidentId) {
    return _tickets.where((ticket) => ticket.incidentId == incidentId).toList();
  }

  List<OF297ShiftTicket> draftTicketsForIncident(String incidentId) {
    return ticketsForIncident(incidentId)
        .where((ticket) => ticket.isDraft)
        .toList();
  }

  List<OF297ShiftTicket> finalizedTicketsForIncident(String incidentId) {
    return ticketsForIncident(incidentId)
        .where((ticket) => ticket.isFinalized)
        .toList();
  }

  int draftCountForIncident(String incidentId) {
    return draftTicketsForIncident(incidentId).length;
  }

  int finalizedCountForIncident(String incidentId) {
    return finalizedTicketsForIncident(incidentId).length;
  }

  List<OF297PdfRecord> pdfRecordsForTicket(String ticketId) {
    return _pdfRecords.where((record) => record.ticketId == ticketId).toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  List<OF297PdfRecord> pdfRecordsForIncident(String incidentId) {
    return _pdfRecords
        .where((record) => record.incidentId == incidentId)
        .toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }

  OF297ShiftTicket? ticketById(String id) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTicket(OF297ShiftTicket ticket) async {
    _tickets.add(ticket);
    await _saveAndNotify();
  }

  Future<void> updateTicket(OF297ShiftTicket updatedTicket) async {
    final index =
        _tickets.indexWhere((ticket) => ticket.id == updatedTicket.id);
    if (index == -1 || _tickets[index].isFinalized) {
      return;
    }

    _tickets[index] = updatedTicket.copyWith(updatedAt: DateTime.now());
    await _saveAndNotify();
  }

  Future<void> deleteDraftTicket(String id) async {
    final ticket = ticketById(id);
    if (ticket == null || ticket.isFinalized) {
      return;
    }

    _tickets.removeWhere((item) => item.id == id);
    await _saveAndNotify();
  }

  Future<void> finalizeTicket(String id) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == id);
    if (index == -1 || _tickets[index].isFinalized) {
      return;
    }

    _tickets[index] = _tickets[index].copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
    await _saveAndNotify();
  }

  Future<void> addPdfRecord(OF297PdfRecord record) async {
    final existingIndex =
        _pdfRecords.indexWhere((existing) => existing.id == record.id);

    if (existingIndex == -1) {
      _pdfRecords.add(record);
    } else {
      _pdfRecords[existingIndex] = record;
    }

    await _savePdfRecordsAndNotify();
  }

  Future<OF297ShiftTicket?> duplicateTicketAsDraft(
    String sourceTicketId,
  ) async {
    final sourceTicket = ticketById(sourceTicketId);
    if (sourceTicket == null || !sourceTicket.isFinalized) {
      return null;
    }

    final now = DateTime.now();

    // Duplicating never mutates the original finalized ticket. The duplicate is
    // a new editable billing-record draft that reuses stable incident,
    // contractor, equipment, and operator context.
    final duplicatedTicket = OF297ShiftTicket(
      id: _uuid.v4(),
      incidentId: sourceTicket.incidentId,
      incidentName: sourceTicket.incidentName,
      incidentNumber: sourceTicket.incidentNumber,
      financialCode: sourceTicket.financialCode,
      agreementNumber: sourceTicket.agreementNumber,
      resourceOrderNumber: sourceTicket.resourceOrderNumber,
      contractorName: sourceTicket.contractorName,
      contractorAddress: sourceTicket.contractorAddress,
      contractorPhone: sourceTicket.contractorPhone,
      ctrOfficeResponsibleForFire: sourceTicket.ctrOfficeResponsibleForFire,
      equipmentMakeModel: sourceTicket.equipmentMakeModel,
      equipmentType: sourceTicket.equipmentType,
      serialVinNumber: sourceTicket.serialVinNumber,
      equipmentId: sourceTicket.equipmentId,
      operatorName: sourceTicket.operatorName,
      transportRetained: sourceTicket.transportRetained,
      isMobilization: sourceTicket.isMobilization,
      rateIsHours: sourceTicket.rateIsHours,
      rateIsMiles: sourceTicket.rateIsMiles,
      globalShiftDate: sourceTicket.globalShiftDate,
      globalBlock1Start: sourceTicket.globalBlock1Start,
      globalBlock1Stop: sourceTicket.globalBlock1Stop,
      globalBlock2Start: sourceTicket.globalBlock2Start,
      globalBlock2Stop: sourceTicket.globalBlock2Stop,
      equipmentEntries:
          sourceTicket.equipmentEntries.map(_duplicateEquipmentRow).toList(),
      personnelEntries:
          sourceTicket.personnelEntries.map(_duplicatePersonnelRow).toList(),
      // Signatures and finalization are legal review artifacts. Every OF-297
      // needs fresh review/signing, and this draft has not been exported yet.
      contractorSignature: null,
      supervisorSignature: null,
      isFinalized: false,
      createdAt: now,
      updatedAt: now,
    );

    _tickets.add(duplicatedTicket);
    await _saveAndNotify();
    return duplicatedTicket;
  }

  Future<void> updateContractorSignature(
    String ticketId,
    OF297Signature signature,
  ) async {
    await _updateSignature(
      ticketId,
      (ticket) => ticket.copyWith(
        contractorSignature: signature,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateSupervisorSignature(
    String ticketId,
    OF297Signature signature,
  ) async {
    await _updateSignature(
      ticketId,
      (ticket) => ticket.copyWith(
        supervisorSignature: signature,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearContractorSignature(String ticketId) async {
    await _updateSignature(
      ticketId,
      (ticket) => ticket.copyWith(
        contractorSignature: null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearSupervisorSignature(String ticketId) async {
    await _updateSignature(
      ticketId,
      (ticket) => ticket.copyWith(
        supervisorSignature: null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _updateSignature(
    String ticketId,
    OF297ShiftTicket Function(OF297ShiftTicket ticket) update,
  ) async {
    final index = _tickets.indexWhere((ticket) => ticket.id == ticketId);
    if (index == -1 || _tickets[index].isFinalized) {
      return;
    }

    _tickets[index] = update(_tickets[index]);
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _repository.saveTickets(_tickets);
    notifyListeners();
  }

  Future<void> _savePdfRecordsAndNotify() async {
    await _repository.savePdfRecords(_pdfRecords);
    notifyListeners();
  }

  OF297EquipmentTimeEntry _duplicateEquipmentRow(
    OF297EquipmentTimeEntry source,
  ) {
    return OF297EquipmentTimeEntry(
      id: _uuid.v4(),
      // Shift-specific date/time/mileage/total fields are cleared so the next
      // operational period is entered deliberately.
      specialRateQuantity: source.specialRateQuantity,
      rateType: source.rateType,
    );
  }

  OF297PersonnelTimeEntry _duplicatePersonnelRow(
    OF297PersonnelTimeEntry source,
  ) {
    return OF297PersonnelTimeEntry(
      id: _uuid.v4(),
      name: source.name,
      position: source.position,
      rateType: source.rateType,
    );
  }
}
