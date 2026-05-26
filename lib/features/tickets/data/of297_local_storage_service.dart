import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

/// Reads and writes OF-297 tickets to local device storage.
///
/// This mirrors the existing app pattern used by apparatus, personnel, and
/// incidents. Tickets remain the source of truth; PDF records only remember
/// finalized exports that were saved to disk.
class OF297LocalStorageService {
  static const String _ticketsStorageKey = 'of297_shift_tickets';
  static const String _pdfRecordsStorageKey = 'of297_pdf_records';

  Future<List<OF297ShiftTicket>> loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_ticketsStorageKey);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map(
            (item) => OF297ShiftTicket.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTickets(List<OF297ShiftTicket> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      tickets.map((ticket) => ticket.toJson()).toList(),
    );

    await prefs.setString(_ticketsStorageKey, encoded);
  }

  Future<List<OF297PdfRecord>> loadPdfRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_pdfRecordsStorageKey);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => OF297PdfRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePdfRecords(List<OF297PdfRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );

    await prefs.setString(_pdfRecordsStorageKey, encoded);
  }
}
