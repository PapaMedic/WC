import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wildland_companion_v2/core/repositories/cloud_ticket_repository.dart';
import 'package:wildland_companion_v2/core/repositories/user_repository.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';
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
    return _storageService.saveTickets(tickets).then((_) {
      return _syncFinalizedTickets(tickets);
    });
  }

  Future<List<OF297PdfRecord>> getPdfRecords() {
    return _storageService.loadPdfRecords();
  }

  Future<void> savePdfRecords(List<OF297PdfRecord> records) {
    return _storageService.savePdfRecords(records).then((_) async {
      final tickets = await getTickets();
      await _syncFinalizedTickets(tickets, pdfRecords: records);
    });
  }

  Future<void> _syncFinalizedTickets(
    List<OF297ShiftTicket> tickets, {
    List<OF297PdfRecord>? pdfRecords,
  }) async {
    if (!FirebaseBootstrap.isInitialized) return;

    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final appUser = await UserRepository().getUser(firebaseUser.uid);
      if (appUser == null || appUser.activeWorkspaceId.isEmpty) return;

      final pdfs = pdfRecords ?? await getPdfRecords();
      final cloudRepository = CloudTicketRepository();
      for (final ticket in tickets.where((ticket) => ticket.isFinalized)) {
        await cloudRepository.syncFinalizedTicket(
          ticket: ticket,
          user: appUser,
          pdfRecords: pdfs
              .where((record) => record.ticketId == ticket.id)
              .toList(growable: false),
        );
      }
    } catch (_) {
      // Field workflows remain local-first. A failed sync is retried on later
      // ticket/PDF saves or when a dedicated retry queue is added.
    }
  }
}
