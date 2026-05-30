import 'dart:typed_data';

import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_export_document.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_generator.dart';

class ShiftTicketGeneratedPdf {
  final String fileName;
  final Uint8List bytes;

  const ShiftTicketGeneratedPdf({
    required this.fileName,
    required this.bytes,
  });
}

class ShiftTicketPdfExporter {
  final Of297PdfGenerator _of297Generator;

  ShiftTicketPdfExporter({
    Of297PdfGenerator? of297Generator,
  }) : _of297Generator = of297Generator ?? Of297PdfGenerator();

  Future<Uint8List> generatePreviewPdf(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        return _of297Generator.generatePreviewPdf(ticket);
      case ShiftTicketExportFormat.etr:
      case ShiftTicketExportFormat.ctr:
        throw UnsupportedError('${format.label} export is not available yet.');
    }
  }

  Future<List<ShiftTicketGeneratedPdf>> generatePreviewPdfs(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) async {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        final documents = buildOf297ExportDocuments(ticket);
        final generated = <ShiftTicketGeneratedPdf>[];
        for (final document in documents) {
          generated.add(
            ShiftTicketGeneratedPdf(
              fileName: document.fileName,
              bytes: await _of297Generator.generatePreviewPdfForDocument(
                ticket,
                document,
              ),
            ),
          );
        }
        return generated;
      case ShiftTicketExportFormat.etr:
      case ShiftTicketExportFormat.ctr:
        throw UnsupportedError('${format.label} export is not available yet.');
    }
  }

  Future<Uint8List> generateFinalizedPdf(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        return _of297Generator.generateFinalizedPdf(ticket);
      case ShiftTicketExportFormat.etr:
      case ShiftTicketExportFormat.ctr:
        throw UnsupportedError('${format.label} export is not available yet.');
    }
  }

  Future<List<ShiftTicketGeneratedPdf>> generateFinalizedPdfs(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) async {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        final documents = buildOf297ExportDocuments(ticket);
        final generated = <ShiftTicketGeneratedPdf>[];
        for (final document in documents) {
          generated.add(
            ShiftTicketGeneratedPdf(
              fileName: document.fileName,
              bytes: await _of297Generator.generateFinalizedPdfForDocument(
                ticket,
                document,
              ),
            ),
          );
        }
        return generated;
      case ShiftTicketExportFormat.etr:
      case ShiftTicketExportFormat.ctr:
        throw UnsupportedError('${format.label} export is not available yet.');
    }
  }
}
