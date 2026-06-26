// Tickets PDF generation and export support.
import 'dart:typed_data';

import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/ctr_pdf_generator.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_export_document.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_generator.dart';

class ShiftTicketGeneratedPdf {
  final String fileName;
  final Uint8List bytes;
  final List<String> warnings;

  const ShiftTicketGeneratedPdf({
    required this.fileName,
    required this.bytes,
    this.warnings = const [],
  });
}

class ShiftTicketPdfExporter {
  final Of297PdfGenerator _of297Generator;
  final CtrPdfGenerator _ctrGenerator;

  ShiftTicketPdfExporter({
    Of297PdfGenerator? of297Generator,
    CtrPdfGenerator? ctrGenerator,
  })  : _of297Generator = of297Generator ?? Of297PdfGenerator(),
        _ctrGenerator = ctrGenerator ?? CtrPdfGenerator();

  Future<Uint8List> generatePreviewPdf(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        return _of297Generator.generatePreviewPdf(ticket);
      case ShiftTicketExportFormat.ctr:
        return _ctrGenerator.generatePreviewPdf(ticket).then(
              (result) => result.bytes,
            );
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
      case ShiftTicketExportFormat.ctr:
        final result = await _ctrGenerator.generatePreviewPdf(ticket);
        return [
          ShiftTicketGeneratedPdf(
            fileName: result.fileName,
            bytes: result.bytes,
            warnings: result.warnings,
          ),
        ];
    }
  }

  Future<Uint8List> generateFinalizedPdf(
    OF297ShiftTicket ticket, {
    required ShiftTicketExportFormat format,
  }) {
    switch (format) {
      case ShiftTicketExportFormat.of297:
        return _of297Generator.generateFinalizedPdf(ticket);
      case ShiftTicketExportFormat.ctr:
        return _ctrGenerator.generateFinalizedPdf(ticket).then(
              (result) => result.bytes,
            );
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
      case ShiftTicketExportFormat.ctr:
        final result = await _ctrGenerator.generateFinalizedPdf(ticket);
        return [
          ShiftTicketGeneratedPdf(
            fileName: result.fileName,
            bytes: result.bytes,
            warnings: result.warnings,
          ),
        ];
    }
  }
}
