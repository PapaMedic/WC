import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';

class ShiftTicketPdfPreviewDocument {
  final String fileName;
  final String pdfPath;

  const ShiftTicketPdfPreviewDocument({
    required this.fileName,
    required this.pdfPath,
  });
}

class ShiftTicketPdfPreviewScreen extends StatefulWidget {
  final String title;
  final List<ShiftTicketPdfPreviewDocument> documents;
  final List<String> warnings;
  final bool canContinueToSignatures;
  final int initialPreviewIndex;

  const ShiftTicketPdfPreviewScreen({
    super.key,
    required this.title,
    required this.documents,
    this.warnings = const [],
    this.canContinueToSignatures = false,
    this.initialPreviewIndex = 0,
  });

  @override
  State<ShiftTicketPdfPreviewScreen> createState() =>
      _ShiftTicketPdfPreviewScreenState();
}

class _ShiftTicketPdfPreviewScreenState
    extends State<ShiftTicketPdfPreviewScreen> {
  final PdfViewerController _controller = PdfViewerController();
  late int _selectedPreviewIndex = widget.initialPreviewIndex;
  late Future<File> _pdfFuture;

  ShiftTicketPdfPreviewDocument get _selectedDocument {
    return widget.documents[_selectedPreviewIndex];
  }

  @override
  void initState() {
    super.initState();
    _pdfFuture = _loadPdf(_selectedDocument);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDocument = _selectedDocument;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHeader(
              title: widget.title,
              fileName: _shortFileName(selectedDocument.fileName),
              canContinueToSignatures: widget.canContinueToSignatures,
            ),
            if (widget.warnings.isNotEmpty)
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.warnings.join('\n'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.documents.length > 1)
              Material(
                color: const Color(0xFF111511),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var i = 0; i < widget.documents.length; i++)
                          ChoiceChip(
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                _shortFileName(widget.documents[i].fileName),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            selected: i == _selectedPreviewIndex,
                            onSelected: (_) {
                              setState(() {
                                _selectedPreviewIndex = i;
                                _controller.zoomLevel = 1;
                                _pdfFuture = _loadPdf(_selectedDocument);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<File>(
                future: _pdfFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load PDF preview: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  }

                  return SfPdfViewer.file(
                    snapshot.data!,
                    key: ValueKey(snapshot.data!.path),
                    controller: _controller,
                    pageLayoutMode: PdfPageLayoutMode.single,
                    scrollDirection: PdfScrollDirection.vertical,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    enableDoubleTapZooming: true,
                    enableTextSelection: false,
                    initialZoomLevel: 1,
                    maxZoomLevel: 4,
                    pageSpacing: 0,
                    onDocumentLoadFailed: (details) {
                      debugPrint('PDF LOAD FAILED: ${details.error}');
                      debugPrint(
                        'PDF LOAD FAILED DESCRIPTION: ${details.description}',
                      );
                    },
                    onDocumentLoaded: (details) {
                      debugPrint(
                        'PDF LOADED: ${selectedDocument.pdfPath} '
                        'pages=${details.document.pages.count}',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _ZoomControls(controller: _controller),
    );
  }

  Future<File> _loadPdf(ShiftTicketPdfPreviewDocument document) async {
    final file = File(document.pdfPath);

    debugPrint('PDF PREVIEW PATH: ${document.pdfPath}');
    final exists = await file.exists();
    debugPrint('PDF EXISTS: $exists');
    if (exists) {
      debugPrint('PDF SIZE: ${await file.length()} bytes');
    }

    if (!exists) {
      throw Exception('PDF file does not exist.');
    }

    if (await file.length() == 0) {
      throw Exception('PDF file is empty.');
    }

    final bytes = await file.readAsBytes();
    final header = pdfHeader(bytes);
    debugPrint('PDF HEADER: $header');
    if (!header.startsWith('%PDF')) {
      throw Exception('Invalid PDF header: $header');
    }

    return file;
  }

  String _shortFileName(String fileName) {
    if (fileName.length <= 38) return fileName;
    return '${fileName.substring(0, 35)}...';
  }
}

class _PreviewHeader extends StatelessWidget {
  final String title;
  final String fileName;
  final bool canContinueToSignatures;

  const _PreviewHeader({
    required this.title,
    required this.fileName,
    required this.canContinueToSignatures,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111511),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
              icon: Icon(
                canContinueToSignatures
                    ? Icons.arrow_back
                    : Icons.close_outlined,
              ),
              color: AppColors.textPrimary,
              tooltip: canContinueToSignatures ? 'Back' : 'Close',
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            if (canContinueToSignatures) ...[
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final PdfViewerController controller;

  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6111511),
      elevation: 3,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                controller.zoomLevel =
                    (controller.zoomLevel + 0.25).clamp(1.0, 4.0).toDouble();
              },
              icon: const Icon(Icons.add),
              color: AppColors.textPrimary,
              tooltip: 'Zoom in',
            ),
            const SizedBox(height: 2),
            IconButton(
              onPressed: () {
                controller.zoomLevel =
                    (controller.zoomLevel - 0.25).clamp(1.0, 4.0).toDouble();
              },
              icon: const Icon(Icons.remove),
              color: AppColors.textPrimary,
              tooltip: 'Zoom out',
            ),
          ],
        ),
      ),
    );
  }
}
