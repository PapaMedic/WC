import 'package:wildland_companion_v2/features/tickets/data/of297_local_storage_service.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

/// Repository boundary for OF-297 ticket persistence.
///
/// Keeping this boundary now makes it easier to swap storage later without
/// changing the form pages or ticket state.
class OF297Repository {
  final OF297LocalStorageService _storageService;

  OF297Repository({
    OF297LocalStorageService? storageService,
  }) : _storageService = storageService ?? OF297LocalStorageService();

  Future<List<OF297ShiftTicket>> getTickets() {
    return _storageService.loadTickets();
  }

  Future<void> saveTickets(List<OF297ShiftTicket> tickets) {
    return _storageService.saveTickets(tickets);
  }

  Future<List<OF297PdfRecord>> getPdfRecords() {
    return _storageService.loadPdfRecords();
  }

  Future<void> savePdfRecords(List<OF297PdfRecord> records) {
    return _storageService.savePdfRecords(records);
  }
}
