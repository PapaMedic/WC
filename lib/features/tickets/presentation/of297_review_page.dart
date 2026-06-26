// Tickets screen UI and user interaction flow.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/tickets/data/of297_validation_service.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_pdf_record.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_service.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/shift_ticket_pdf_exporter.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/of297_form_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_signature_box.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_status_pill.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/shift_ticket_pdf_preview_screen.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

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
  final PdfViewerController _inlinePdfController = PdfViewerController();
  final ScrollController _scrollController = ScrollController();
  bool _isGeneratingPdf = false;
  bool _documentReviewed = false;
  String? _previewTicketKey;
  bool _isGeneratingOf297Preview = false;
  bool _isGeneratingCtrPreview = false;
  String? _of297PreviewError;
  String? _ctrPreviewError;
  final List<ShiftTicketPdfPreviewDocument> _previewDocuments = [];
  String? _selectedPreviewDocumentId;
  final Map<String, int> _previewPageByDocumentId = {};

  @override
  void dispose() {
    _scrollController.dispose();
    _inlinePdfController.dispose();
    super.dispose();
  }

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
            resizeToAvoidBottomInset: true,
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
            body: _buildReviewBody(context, ticketsState, ticket),
            bottomNavigationBar: _ReviewActionBar(
              ticket: ticket,
              isGeneratingPdf: _isGeneratingPdf,
              onEdit: ticket.isFinalized
                  ? null
                  : () => _editTicket(context, ticket),
              onSaveDraft: ticket.isFinalized
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft is saved.')),
                      );
                    },
              onExportOf297: !ticket.isFinalized || _isGeneratingPdf
                  ? null
                  : () => _generateAndSavePdf(
                        context,
                        ticket,
                        ShiftTicketExportFormat.of297,
                      ),
              onExportCtr: !ticket.isFinalized || _isGeneratingPdf
                  ? null
                  : () => _generateAndSavePdf(
                        context,
                        ticket,
                        ShiftTicketExportFormat.ctr,
                      ),
              onFinalize: ticket.isFinalized
                  ? null
                  : () => _finalizeTicket(context, ticket.id),
              onDuplicate: ticket.isFinalized
                  ? () => _duplicateTicket(context, ticket)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewBody(
    BuildContext context,
    TicketsState ticketsState,
    OF297ShiftTicket ticket,
  ) {
    _ensurePreviewDocuments(ticket);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final selectedDocument = _selectedPreviewDocument;
        final contentMaxWidth = wide ? 860.0 : double.infinity;

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              _PreviewDocumentSelector(
                documents: _previewDocuments,
                selectedDocumentId: _selectedPreviewDocumentId,
                ctrError: _ctrPreviewError,
                isGeneratingCtr: _isGeneratingCtrPreview,
                onSelected: (document) {
                  setState(() {
                    _selectedPreviewDocumentId = document.id;
                  });
                },
                onRetryCtr: () => _generateCtrPreview(ticket),
              ),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('of297-review-scroll'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: contentMaxWidth),
                              child: AspectRatio(
                                aspectRatio: 0.78,
                                child: _InlinePdfPreview(
                                  document: selectedDocument,
                                  isLoading: _isSelectedDocumentLoading,
                                  errorText: _selectedPreviewErrorText,
                                  controller: _inlinePdfController,
                                  currentPage: selectedDocument == null
                                      ? 1
                                      : _previewPageByDocumentId[
                                              selectedDocument.id] ??
                                          1,
                                  onRetry: () => _retrySelectedPreview(ticket),
                                  onPageChanged: (page) {
                                    final document = _selectedPreviewDocument;
                                    if (document == null) return;
                                    _previewPageByDocumentId[document.id] =
                                        page;
                                  },
                                  onOpenFullScreen: selectedDocument == null
                                      ? null
                                      : () => _openSelectedPreviewFullScreen(
                                            context,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: contentMaxWidth),
                              child: _SignaturePanel(
                                ticket: ticket,
                                documentReviewed: _documentReviewed,
                                onContractorSignatureChanged: (signature) {
                                  ticketsState.updateContractorSignature(
                                    ticket.id,
                                    signature,
                                  );
                                },
                                onContractorSignatureCleared: () {
                                  ticketsState.clearContractorSignature(
                                    ticket.id,
                                  );
                                },
                                onSupervisorSignatureChanged: (signature) {
                                  ticketsState.updateSupervisorSignature(
                                    ticket.id,
                                    signature,
                                  );
                                },
                                onSupervisorSignatureCleared: () {
                                  ticketsState.clearSupervisorSignature(
                                    ticket.id,
                                  );
                                },
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ShiftTicketPdfPreviewDocument? get _selectedPreviewDocument {
    if (_previewDocuments.isEmpty) return null;
    final selectedId = _selectedPreviewDocumentId;
    if (selectedId != null) {
      for (final document in _previewDocuments) {
        if (document.id == selectedId) return document;
      }
    }
    return _previewDocuments.first;
  }

  bool get _isSelectedDocumentLoading {
    final selected = _selectedPreviewDocument;
    if (selected == null) {
      return _isGeneratingOf297Preview || _isGeneratingCtrPreview;
    }
    return switch (selected.type) {
      ShiftTicketExportFormat.of297 => _isGeneratingOf297Preview,
      ShiftTicketExportFormat.ctr => _isGeneratingCtrPreview,
    };
  }

  String? get _selectedPreviewErrorText {
    final selected = _selectedPreviewDocument;
    if (selected == null) return _of297PreviewError ?? _ctrPreviewError;
    return switch (selected.type) {
      ShiftTicketExportFormat.of297 => _of297PreviewError,
      ShiftTicketExportFormat.ctr => _ctrPreviewError,
    };
  }

  void _ensurePreviewDocuments(OF297ShiftTicket ticket) {
    final key = '${ticket.id}:${ticket.updatedAt.microsecondsSinceEpoch}:'
        '${ticket.contractorSignature?.signedAt.microsecondsSinceEpoch}:'
        '${ticket.supervisorSignature?.signedAt.microsecondsSinceEpoch}';
    if (_previewTicketKey == key) return;

    _previewTicketKey = key;
    _of297PreviewError = null;
    _ctrPreviewError = null;
    _previewDocuments.clear();
    _selectedPreviewDocumentId = null;
    _previewPageByDocumentId.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _previewTicketKey != key) return;
      _generateOf297Preview(ticket);
      _generateCtrPreview(ticket);
    });
  }

  Future<void> _generateOf297Preview(
    OF297ShiftTicket ticket,
  ) async {
    if (mounted) {
      setState(() {
        _isGeneratingOf297Preview = true;
        _of297PreviewError = null;
      });
    }

    try {
      final generatedPdfs = await _pdfExporter.generatePreviewPdfs(
        ticket,
        format: ShiftTicketExportFormat.of297,
      );
      final documents = await _writePreviewPdfsToTempFiles(
        generatedPdfs,
        ticket,
        ShiftTicketExportFormat.of297,
      );
      final labeled = _labelPreviewDocuments(documents);
      if (!mounted) return;
      setState(() {
        _previewDocuments.removeWhere(
          (document) => document.type == ShiftTicketExportFormat.of297,
        );
        _previewDocuments.insertAll(0, labeled);
        _selectedPreviewDocumentId ??=
            labeled.isEmpty ? null : labeled.first.id;
        _isGeneratingOf297Preview = false;
      });
      if (!ticket.isFinalized && !_documentReviewed) {
        setState(() => _documentReviewed = true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _of297PreviewError = 'Unable to generate OF-297 preview: $error';
        _isGeneratingOf297Preview = false;
      });
    }
  }

  Future<void> _generateCtrPreview(OF297ShiftTicket ticket) async {
    if (mounted) {
      setState(() {
        _isGeneratingCtrPreview = true;
        _ctrPreviewError = null;
      });
    }

    try {
      final generatedPdfs = await _pdfExporter.generatePreviewPdfs(
        ticket,
        format: ShiftTicketExportFormat.ctr,
      );
      final documents = await _writePreviewPdfsToTempFiles(
        generatedPdfs,
        ticket,
        ShiftTicketExportFormat.ctr,
      );
      final labeled = _labelPreviewDocuments(documents);
      if (!mounted) return;
      setState(() {
        _previewDocuments.removeWhere(
          (document) => document.type == ShiftTicketExportFormat.ctr,
        );
        _previewDocuments.addAll(labeled);
        _isGeneratingCtrPreview = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ctrPreviewError = 'Unable to generate CTR preview: $error';
        _isGeneratingCtrPreview = false;
      });
    }
  }

  List<ShiftTicketPdfPreviewDocument> _labelPreviewDocuments(
    List<ShiftTicketPdfPreviewDocument> documents,
  ) {
    final of297Count = documents
        .where((document) => document.type == ShiftTicketExportFormat.of297)
        .length;
    return documents.map((document) {
      final displayName = switch (document.type) {
        ShiftTicketExportFormat.of297 =>
          of297Count == 1 ? 'OF-297' : 'OF-297 ${document.documentIndex + 1}',
        ShiftTicketExportFormat.ctr => 'CTR',
      };
      return ShiftTicketPdfPreviewDocument(
        id: document.id,
        displayName: displayName,
        type: document.type,
        documentIndex: document.documentIndex,
        fileName: document.fileName,
        pdfPath: document.pdfPath,
      );
    }).toList();
  }

  void _retrySelectedPreview(OF297ShiftTicket ticket) {
    final selected = _selectedPreviewDocument;
    if (selected?.type == ShiftTicketExportFormat.ctr) {
      _generateCtrPreview(ticket);
    } else {
      _generateOf297Preview(ticket);
    }
  }

  Future<void> _openSelectedPreviewFullScreen(BuildContext context) async {
    final selected = _selectedPreviewDocument;
    if (selected == null) return;
    final initialPage = _previewPageByDocumentId[selected.id] ?? 1;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ShiftTicketPdfPreviewScreen(
          title: selected.displayName,
          documents: [selected],
          initialPreviewIndex: 0,
          initialPage: initialPage,
        ),
      ),
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
          id: '${format.name}-$i',
          displayName: format == ShiftTicketExportFormat.of297
              ? 'OF-297 ${i + 1}'
              : 'CTR',
          type: format,
          documentIndex: i,
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
}

class _InlinePdfPreview extends StatelessWidget {
  final ShiftTicketPdfPreviewDocument? document;
  final bool isLoading;
  final String? errorText;
  final PdfViewerController controller;
  final int currentPage;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onOpenFullScreen;

  const _InlinePdfPreview({
    required this.document,
    required this.isLoading,
    required this.errorText,
    required this.controller,
    required this.currentPage,
    required this.onRetry,
    required this.onPageChanged,
    required this.onOpenFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final document = this.document;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: document != null,
      label: document == null
          ? 'PDF preview loading'
          : 'Open selected PDF full screen',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildPreviewContent(context, document),
            ),
            if (document != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Material(
                  color: colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onOpenFullScreen,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 18),
                          SizedBox(width: 4),
                          Text('Tap to open full screen'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    ShiftTicketPdfPreviewDocument? document,
  ) {
    if (isLoading && document == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null && document == null) {
      return _PreviewError(message: errorText!, onRetry: onRetry);
    }

    if (document == null) {
      return const Center(child: Text('No PDF preview available.'));
    }

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: onOpenFullScreen,
      child: SfPdfViewer.file(
        File(document.pdfPath),
        key: ValueKey(document.pdfPath),
        controller: controller,
        pageLayoutMode: PdfPageLayoutMode.single,
        scrollDirection: PdfScrollDirection.vertical,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: false,
        initialZoomLevel: 1,
        maxZoomLevel: 3,
        pageSpacing: 0,
        onDocumentLoaded: (details) {
          final page = currentPage.clamp(1, details.document.pages.count);
          if (page > 1) controller.jumpToPage(page);
        },
        onPageChanged: (details) => onPageChanged(details.newPageNumber),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PreviewError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePanel extends StatelessWidget {
  final OF297ShiftTicket ticket;
  final bool documentReviewed;
  final ValueChanged<OF297Signature> onContractorSignatureChanged;
  final VoidCallback onContractorSignatureCleared;
  final ValueChanged<OF297Signature> onSupervisorSignatureChanged;
  final VoidCallback onSupervisorSignatureCleared;

  const _SignaturePanel({
    required this.ticket,
    required this.documentReviewed,
    required this.onContractorSignatureChanged,
    required this.onContractorSignatureCleared,
    required this.onSupervisorSignatureChanged,
    required this.onSupervisorSignatureCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6111511),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            children: [
              OF297SignatureBox(
                title: 'Contractor/Operator Signature',
                signature: ticket.contractorSignature,
                readOnly: ticket.isFinalized || !documentReviewed,
                onSignatureChanged: onContractorSignatureChanged,
                onSignatureCleared: onContractorSignatureCleared,
              ),
              const SizedBox(height: AppSpacing.md),
              OF297SignatureBox(
                title: 'Incident Supervisor Signature',
                signature: ticket.supervisorSignature,
                readOnly: ticket.isFinalized || !documentReviewed,
                requestSignerTitle: true,
                onSignatureChanged: onSupervisorSignatureChanged,
                onSignatureCleared: onSupervisorSignatureCleared,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewDocumentSelector extends StatelessWidget {
  final List<ShiftTicketPdfPreviewDocument> documents;
  final String? selectedDocumentId;
  final String? ctrError;
  final bool isGeneratingCtr;
  final ValueChanged<ShiftTicketPdfPreviewDocument> onSelected;
  final VoidCallback onRetryCtr;

  const _PreviewDocumentSelector({
    required this.documents,
    required this.selectedDocumentId,
    required this.ctrError,
    required this.isGeneratingCtr,
    required this.onSelected,
    required this.onRetryCtr,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111511),
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: documents.length + (ctrError == null ? 0 : 1),
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index >= documents.length) {
              return Tooltip(
                message: 'Retry CTR preview generation',
                child: ActionChip(
                  avatar: isGeneratingCtr
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('CTR retry'),
                  onPressed: isGeneratingCtr ? null : onRetryCtr,
                ),
              );
            }

            final document = documents[index];
            final selected = document.id == selectedDocumentId ||
                (selectedDocumentId == null && index == 0);
            final tooltip = switch (document.type) {
              ShiftTicketExportFormat.of297 =>
                'Preview OF-297 document ${document.documentIndex + 1}',
              ShiftTicketExportFormat.ctr => 'Preview CTR document',
            };

            return Tooltip(
              message: tooltip,
              child: ChoiceChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 64),
                  child: Text(
                    document.displayName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: selected,
                showCheckmark: true,
                onSelected: (_) => onSelected(document),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewActionBar extends StatelessWidget {
  final OF297ShiftTicket ticket;
  final bool isGeneratingPdf;
  final VoidCallback? onEdit;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onExportOf297;
  final VoidCallback? onExportCtr;
  final VoidCallback? onFinalize;
  final VoidCallback? onDuplicate;

  const _ReviewActionBar({
    required this.ticket,
    required this.isGeneratingPdf,
    this.onEdit,
    this.onSaveDraft,
    this.onExportOf297,
    this.onExportCtr,
    this.onFinalize,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final finalizedActions = <Widget>[
      Tooltip(
        message: 'Export all OF-297 documents',
        child: FilledButton.icon(
          onPressed: onExportOf297,
          icon: isGeneratingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt_outlined),
          label: const Text('Export OF-297'),
        ),
      ),
      Tooltip(
        message: 'Export CTR document',
        child: OutlinedButton.icon(
          onPressed: onExportCtr,
          icon: const Icon(Icons.save_alt_outlined),
          label: const Text('Export CTR'),
        ),
      ),
      Tooltip(
        message: 'Duplicate finalized ticket',
        child: OutlinedButton.icon(
          onPressed: onDuplicate,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Duplicate Ticket'),
        ),
      ),
    ];
    final draftActions = <Widget>[
      OutlinedButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Ticket'),
      ),
      OutlinedButton.icon(
        onPressed: onSaveDraft,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save Draft'),
      ),
      FilledButton.icon(
        onPressed: onFinalize,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Finalize'),
      ),
    ];
    final actions = ticket.isFinalized ? finalizedActions : draftActions;

    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xFF111511),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        actions[i],
                        if (i != actions.length - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
