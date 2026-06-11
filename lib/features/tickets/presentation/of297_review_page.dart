import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/tickets/data/of297_validation_service.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_export_document.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_service.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/shift_ticket_pdf_exporter.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/of297_form_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_signature_box.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_status_pill.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/shift_ticket_pdf_preview_screen.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';
import 'package:wildland_companion_v2/features/tickets/utils/shift_ticket_time.dart';

/// Read-only review, signature capture, and finalization for OF-297 tickets.
///
/// The editable form creates draft data. This page is the lock point: users
/// review, capture both signatures, validate required fields, and finalize.
class OF297ReviewPage extends StatefulWidget {
  final String incidentId;
  final String incidentName;
  final String ticketId;

  const OF297ReviewPage({
    super.key,
    required this.incidentId,
    required this.incidentName,
    required this.ticketId,
  });

  @override
  State<OF297ReviewPage> createState() => _OF297ReviewPageState();
}

class _OF297ReviewPageState extends State<OF297ReviewPage> {
  final ShiftTicketPdfExporter _pdfExporter = ShiftTicketPdfExporter();
  final Of297PdfService _pdfService = Of297PdfService();
  bool _isGeneratingPdf = false;
  bool _documentReviewed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketsState>(
      builder: (context, ticketsState, _) {
        final ticket = ticketsState.ticketById(widget.ticketId);

        if (ticket == null) {
          return const WildlandBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: Text('Ticket not found.')),
            ),
          );
        }

        return WildlandBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Review Shift Ticket'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    child: OF297StatusPill(isFinalized: ticket.isFinalized),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TacticalCard(
                  title: 'Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OF297StatusPill(isFinalized: ticket.isFinalized),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ticket.isFinalized
                            ? 'This ticket is finalized and locked.'
                            : 'Review the draft, capture signatures, then finalize.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Shift Ticket Export',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OF-297 is the primary ticket. CTR is available as a legacy crew time report output from the same finalized data.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _showPdfPreview(
                                      context,
                                      ticket,
                                      ShiftTicketExportFormat.of297,
                                    ),
                            icon: const Icon(Icons.preview_outlined),
                            label: const Text('Preview OF-297'),
                          ),
                          if (ticket.isFinalized)
                            FilledButton.icon(
                              onPressed: _isGeneratingPdf
                                  ? null
                                  : () => _generateAndSavePdf(
                                        context,
                                        ticket,
                                        ShiftTicketExportFormat.of297,
                                      ),
                              icon: _isGeneratingPdf
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_alt_outlined),
                              label: Text(
                                _isGeneratingPdf
                                    ? 'Generating PDF...'
                                    : 'Export OF-297',
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => _editTicket(context, ticket),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          OutlinedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _showPdfPreview(
                                      context,
                                      ticket,
                                      ShiftTicketExportFormat.ctr,
                                    ),
                            icon: const Icon(Icons.preview_outlined),
                            label: const Text('Preview CTR'),
                          ),
                          if (ticket.isFinalized)
                            OutlinedButton.icon(
                              onPressed: _isGeneratingPdf
                                  ? null
                                  : () => _generateAndSavePdf(
                                        context,
                                        ticket,
                                        ShiftTicketExportFormat.ctr,
                                      ),
                              icon: const Icon(Icons.save_alt_outlined),
                              label: const Text('Export CTR'),
                            ),
                        ],
                      ),
                      if (!ticket.isFinalized && !_documentReviewed) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Review the OF-297 document before collecting signatures.',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'CTR Details',
                  child: _ReviewLine(
                    label: 'Office Responsible For Fire',
                    value: ticket.ctrOfficeResponsibleForFire,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Generated Documents',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _exportFileNames(ticket)
                        .map((fileName) => Text('- $fileName'))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Incident / Agreement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewLine(
                        label: 'Incident',
                        value: ticket.incidentName.isEmpty
                            ? widget.incidentName
                            : ticket.incidentName,
                      ),
                      _ReviewLine(
                        label: 'Incident ID',
                        value: widget.incidentId,
                      ),
                      _ReviewLine(
                        label: 'Incident #',
                        value: ticket.incidentNumber,
                      ),
                      _ReviewLine(
                        label: 'Agreement #',
                        value: ticket.agreementNumber,
                      ),
                      _ReviewLine(
                        label: 'Resource Order',
                        value: ticket.resourceOrderNumber,
                      ),
                      _ReviewLine(
                        label: 'Financial Code',
                        value: ticket.financialCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Contractor',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewLine(
                        label: 'Contractor/Agency',
                        value: ticket.contractorName,
                      ),
                      _ReviewLine(
                        label: 'Contractor Representative',
                        value: ticket.contractorRepresentativeName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Equipment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReviewLine(
                        label: 'Make/Model',
                        value: ticket.equipmentMakeModel,
                      ),
                      _ReviewLine(
                        label: 'Type',
                        value: ticket.equipmentType,
                      ),
                      _ReviewLine(
                        label: 'Serial/VIN',
                        value: ticket.serialVinNumber,
                      ),
                      _ReviewLine(
                        label: 'License/ID',
                        value: ticket.equipmentId,
                      ),
                      _ReviewLine(
                        label: 'Transport Retained',
                        value: ticket.transportRetained ? 'Yes' : 'No',
                      ),
                      _ReviewLine(
                        label: 'Mobilization',
                        value: ticket.isMobilization == null
                            ? '-'
                            : ticket.isMobilization!
                                ? 'Mobilization'
                                : 'Demobilization',
                      ),
                      _ReviewLine(
                        label: 'Rate Basis',
                        value: ticket.rateIsMiles
                            ? 'Miles'
                            : ticket.rateIsHours
                                ? 'Hours'
                                : '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Equipment Time Entries',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ticket.equipmentEntries.isEmpty
                        ? [const Text('No equipment rows entered.')]
                        : ticket.equipmentEntries.asMap().entries.map((item) {
                            final entry = item.value;
                            final start = ticket.rateIsMiles
                                ? _formatNullableNumber(entry.mileageStart)
                                : _formatTime(entry.startTime);
                            final stop = ticket.rateIsMiles
                                ? _formatNullableNumber(entry.mileageEnd)
                                : _formatTime(entry.stopTime);
                            final total = ticket.rateIsMiles
                                ? _formatNumber(entry.totalMiles)
                                : _formatNumber(entry.totalHours);
                            final totalLabel =
                                ticket.rateIsMiles ? 'Total Miles' : 'Total';
                            return _ReviewLine(
                              label: 'Row ${item.key + 1}',
                              value:
                                  '${_formatDateForTicket(ticket, entry.date)} '
                                  '$start-$stop '
                                  '$totalLabel: $total '
                                  'Qty: ${_formatNumber(entry.specialRateQuantity)} '
                                  'Type: ${entry.rateType} Notes: ${entry.notes}',
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Personnel Time Entries',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ticket.personnelEntries.isEmpty
                        ? [const Text('No personnel rows entered.')]
                        : ticket.personnelEntries.asMap().entries.map((item) {
                            final entry = item.value;
                            return _ReviewLine(
                              label: 'Row ${item.key + 1}',
                              value:
                                  '${_formatDateForTicket(ticket, entry.date)} '
                                  '${entry.name} ${entry.position} '
                                  '24/25: ${_formatTime(entry.guaranteeStartTime)}-${_formatTime(entry.guaranteeStopTime)} '
                                  '26/27: ${_formatTime(entry.startTime)}-${_formatTime(entry.stopTime)} '
                                  'Total: ${_formatNumber(entry.totalHours)} Notes: ${entry.notes}',
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Remarks',
                  child:
                      _ReviewLine(label: '30. Remarks', value: ticket.remarks),
                ),
                const SizedBox(height: AppSpacing.lg),
                TacticalCard(
                  title: 'Signatures',
                  child: Column(
                    children: [
                      OF297SignatureBox(
                        title: 'Contractor/Operator Signature',
                        signature: ticket.contractorSignature,
                        readOnly: ticket.isFinalized || !_documentReviewed,
                        onSignatureChanged: (signature) {
                          ticketsState.updateContractorSignature(
                            ticket.id,
                            signature,
                          );
                        },
                        onSignatureCleared: () {
                          ticketsState.clearContractorSignature(ticket.id);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OF297SignatureBox(
                        title: 'Incident Supervisor Signature',
                        signature: ticket.supervisorSignature,
                        readOnly: ticket.isFinalized || !_documentReviewed,
                        onSignatureChanged: (signature) {
                          ticketsState.updateSupervisorSignature(
                            ticket.id,
                            signature,
                          );
                        },
                        onSignatureCleared: () {
                          ticketsState.clearSupervisorSignature(ticket.id);
                        },
                      ),
                    ],
                  ),
                ),
                if (!ticket.isFinalized) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => _finalizeTicket(context, ticket.id),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Finalize Ticket'),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => _duplicateTicket(context, ticket),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Duplicate Ticket'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finalizeTicket(BuildContext context, String ticketId) async {
    final ticketsState = context.read<TicketsState>();
    final ticket = ticketsState.ticketById(ticketId);
    if (ticket == null) return;

    if (!_documentReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review the document snapshot before finalizing.'),
        ),
      );
      return;
    }

    final errors = OF297ValidationService().validateForFinalization(ticket);
    if (errors.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Required Fields'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: errors.map((error) => Text('- $error')).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Shift Ticket?'),
        content: const Text(
          'Finalize this shift ticket? This will lock the ticket and prevent further edits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ticketsState.finalizeTicket(ticket.id);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _generateAndSavePdf(
    BuildContext context,
    OF297ShiftTicket ticket,
    ShiftTicketExportFormat format,
  ) async {
    final sharePositionOrigin = _pdfService.sharePositionOriginFor(context);

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final generatedPdfs = await _pdfExporter.generateFinalizedPdfs(
        ticket,
        format: format,
      );
      final files = await _pdfService.savePdfFilesAs(
        sharePositionOrigin: sharePositionOrigin,
        pdfFiles: generatedPdfs
            .map(
              (pdf) => Of297PdfFile(
                fileName: pdf.fileName,
                pdfBytes: pdf.bytes,
              ),
            )
            .toList(),
      );

      if (files.isEmpty) {
        return;
      }

      if (!context.mounted) return;
      final generatedAt = DateTime.now();
      final warnings = _warningsFor(generatedPdfs);
      final ticketsState = context.read<TicketsState>();
      for (final file in files) {
        await ticketsState.addPdfRecord(
          OF297PdfRecord(
            id: '${ticket.id}_${file.uri.pathSegments.last}_'
                '${generatedAt.microsecondsSinceEpoch}',
            ticketId: ticket.id,
            incidentId: ticket.incidentId,
            incidentName: ticket.incidentName,
            fileName: file.uri.pathSegments.last,
            filePath: file.path,
            fileSizeBytes: await file.length(),
            generatedAt: generatedAt,
          ),
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            [
              files.length == 1
                  ? '${format.label} PDF saved.'
                  : '${files.length} ${format.label} PDF files saved.',
              ...warnings,
            ].join(' '),
          ),
          showCloseIcon: true,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              final actionOrigin = _pdfService.sharePositionOriginFor(context);
              if (files.length == 1) {
                _pdfService.sharePdf(
                  files.first,
                  sharePositionOrigin: actionOrigin,
                );
              } else {
                _pdfService.sharePdfs(
                  files,
                  sharePositionOrigin: actionOrigin,
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to generate PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _duplicateTicket(
    BuildContext context,
    OF297ShiftTicket ticket,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate finalized OF-297?'),
        content: const Text(
          'This will create a new editable draft using this ticket\'s incident, contractor, equipment, and operator information. Signatures and PDF export history will be cleared so the new ticket can be reviewed and signed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final duplicatedTicket =
        await context.read<TicketsState>().duplicateTicketAsDraft(ticket.id);
    if (duplicatedTicket == null || !context.mounted) return;

    // The original finalized ticket remains immutable. This opens the new draft
    // form so the user can enter fresh shift values, review, sign, finalize,
    // and export it as a separate OF-297 record later.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OF297FormPage(
          incidentId: duplicatedTicket.incidentId,
          incidentName: duplicatedTicket.incidentName,
          incidentNumber: duplicatedTicket.incidentNumber,
          resourceOrderNumber: duplicatedTicket.resourceOrderNumber,
          financialCode: duplicatedTicket.financialCode,
          ticketId: duplicatedTicket.id,
        ),
      ),
    );
  }

  Future<void> _showPdfPreview(
    BuildContext context,
    OF297ShiftTicket ticket,
    ShiftTicketExportFormat format,
  ) async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final generatedPdfs = await _pdfExporter.generatePreviewPdfs(
        ticket,
        format: format,
      );
      if (generatedPdfs.isEmpty) return;
      final previewDocuments = await _writePreviewPdfsToTempFiles(
        generatedPdfs,
        ticket,
        format,
      );
      if (!context.mounted) return;

      final warnings = _warningsFor(generatedPdfs);
      final continued = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => ShiftTicketPdfPreviewScreen(
            title: 'Review ${format.label} Document',
            documents: previewDocuments,
            warnings: warnings,
            canContinueToSignatures:
                !ticket.isFinalized && format == ShiftTicketExportFormat.of297,
            initialPreviewIndex: 0,
          ),
        ),
      );

      if (!ticket.isFinalized &&
          format == ShiftTicketExportFormat.of297 &&
          continued == true &&
          mounted) {
        setState(() {
          _documentReviewed = true;
        });
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to preview document: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<List<ShiftTicketPdfPreviewDocument>> _writePreviewPdfsToTempFiles(
    List<ShiftTicketGeneratedPdf> generatedPdfs,
    OF297ShiftTicket ticket,
    ShiftTicketExportFormat format,
  ) async {
    final tempDirectory = await getTemporaryDirectory();
    final previewDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}wildland_pdf_previews',
    );
    await previewDirectory.create(recursive: true);

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final documents = <ShiftTicketPdfPreviewDocument>[];
    for (var i = 0; i < generatedPdfs.length; i++) {
      final generatedPdf = generatedPdfs[i];
      validatePdfBytes(generatedPdf.bytes, label: generatedPdf.fileName);

      final fileName = _ensurePdfExtension(
        _sanitizeFileName(
          '${format.name}_${ticket.id}_${timestamp}_${i}_${generatedPdf.fileName}',
        ),
      );
      final file = File(
        '${previewDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsBytes(generatedPdf.bytes, flush: true);

      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      final writtenBytes = exists ? await file.readAsBytes() : null;
      final header = writtenBytes == null ? '' : pdfHeader(writtenBytes);
      debugPrint('PDF OUTPUT PATH: ${file.path}');
      debugPrint('PDF PREVIEW PATH: ${file.path}');
      debugPrint('PDF EXISTS: $exists');
      debugPrint('PDF SIZE: $size bytes');
      debugPrint('PDF HEADER: $header');

      if (!exists) {
        throw Exception('${generatedPdf.fileName} preview file was not saved.');
      }
      if (size == 0) {
        throw Exception('${generatedPdf.fileName} preview file is empty.');
      }
      if (writtenBytes == null || !header.startsWith('%PDF')) {
        throw Exception(
          '${generatedPdf.fileName} preview file has invalid PDF header: $header',
        );
      }

      documents.add(
        ShiftTicketPdfPreviewDocument(
          fileName: generatedPdf.fileName,
          pdfPath: file.path,
        ),
      );
    }

    return documents;
  }

  Future<void> _editTicket(
    BuildContext context,
    OF297ShiftTicket ticket,
  ) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OF297FormPage(
          incidentId: ticket.incidentId,
          incidentName: ticket.incidentName,
          incidentNumber: ticket.incidentNumber,
          resourceOrderNumber: ticket.resourceOrderNumber,
          financialCode: ticket.financialCode,
          ticketId: ticket.id,
        ),
      ),
    );
  }

  String _formatDateOnly(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('MMM d, yyyy').format(value);
  }

  String _formatDateForTicket(OF297ShiftTicket ticket, DateTime? rowDate) {
    final shiftDate = rowDate ?? ticket.globalShiftDate;
    if (shiftDate == null) return '-';

    if (shiftTimeRangeIsOvernight(
      ticket.globalBlock2Start,
      ticket.globalBlock2Stop,
    )) {
      return formatShiftDateRange(
        shiftDate,
        ticket.globalBlock2Start,
        ticket.globalBlock2Stop,
      );
    }

    if (ticket.globalBlock1Start.isNotEmpty &&
        ticket.globalBlock1Stop.isNotEmpty) {
      return formatShiftDateRange(
        shiftDate,
        ticket.globalBlock1Start,
        ticket.globalBlock1Stop,
      );
    }

    if (ticket.globalBlock2Start.isNotEmpty &&
        ticket.globalBlock2Stop.isNotEmpty) {
      return formatShiftDateRange(
        shiftDate,
        ticket.globalBlock2Start,
        ticket.globalBlock2Stop,
      );
    }

    return _formatDateOnly(rowDate);
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('HHmm').format(value);
  }

  String _formatNumber(double value) {
    if (value == 0) return '-';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _formatNullableNumber(double? value) {
    if (value == null || value == 0) return '-';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  List<String> _exportFileNames(OF297ShiftTicket ticket) {
    return [
      ...buildOf297ExportDocuments(ticket).map(
        (document) => _displayFileName(document.fileName),
      ),
      _displayFileName(
        'CTR_${_sanitizeFileName(ticket.incidentName)}_'
        '${_sanitizeFileName(ticket.id)}.pdf',
      ),
    ];
  }

  List<String> _warningsFor(List<ShiftTicketGeneratedPdf> generatedPdfs) {
    return generatedPdfs
        .expand((pdf) => pdf.warnings)
        .toSet()
        .toList(growable: false);
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'ticket' : sanitized;
  }

  String _ensurePdfExtension(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
  }

  String _displayFileName(String fileName) {
    final extension = fileName.toLowerCase().endsWith('.pdf') ? '.pdf' : '';
    final baseName = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    if (baseName.length <= 34) return '$baseName$extension';
    return '${baseName.substring(0, 31)}...$extension';
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: ${value.isEmpty ? '-' : value}'),
    );
  }
}
