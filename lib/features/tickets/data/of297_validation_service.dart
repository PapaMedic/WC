import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

/// Finalization rules for OF-297 tickets.
///
/// Drafts can be incomplete while users work. Finalization is the lock point,
/// so this service checks the minimum data needed before signatures lock in.
class OF297ValidationService {
  List<String> validateForFinalization(OF297ShiftTicket ticket) {
    final errors = <String>[];

    if (ticket.incidentName.trim().isEmpty) {
      errors.add('Incident name is required.');
    }
    if (ticket.agreementNumber.trim().isEmpty) {
      errors.add('Agreement number is required.');
    }
    if (ticket.resourceOrderNumber.trim().isEmpty) {
      errors.add('Resource order number is required.');
    }
    if (ticket.contractorName.trim().isEmpty) {
      errors.add('Contractor/agency name is required.');
    }
    if (ticket.equipmentId.trim().isEmpty) {
      errors.add('Equipment ID is required.');
    }
    if (ticket.operatorName.trim().isEmpty) {
      errors.add('Operator name is required.');
    }
    if (ticket.rateIsHours && ticket.shiftStart == null) {
      errors.add('Shift start is required.');
    }
    if (ticket.rateIsHours && ticket.shiftEnd == null) {
      errors.add('Shift end is required.');
    }
    if (!_hasEquipmentTimeEntry(ticket)) {
      errors.add('At least one equipment time entry is required.');
    }
    if (ticket.contractorSignature == null) {
      errors.add('Contractor/operator signature is required.');
    }
    if (ticket.supervisorSignature == null) {
      errors.add('Incident supervisor signature is required.');
    }

    return errors;
  }

  bool _hasEquipmentTimeEntry(OF297ShiftTicket ticket) {
    return ticket.equipmentEntries.any((entry) {
      if (ticket.rateIsMiles) {
        return entry.date != null ||
            entry.mileageStart != null ||
            entry.mileageEnd != null ||
            entry.totalMiles > 0 ||
            entry.notes.trim().isNotEmpty;
      }

      return entry.date != null ||
          entry.startTime != null ||
          entry.stopTime != null ||
          entry.totalHours > 0 ||
          entry.notes.trim().isNotEmpty;
    });
  }
}
