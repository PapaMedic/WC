// Tickets reusable presentation widget.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';

/// Modal capture flow for OF-297 signatures.
///
/// The review page owns signatures because signing is part of the final review
/// workflow, not ordinary draft editing.
class OF297SignatureDialog extends StatefulWidget {
  final String title;
  final OF297Signature? existingSignature;
  final bool requestSignerTitle;

  const OF297SignatureDialog({
    super.key,
    required this.title,
    this.existingSignature,
    this.requestSignerTitle = false,
  });

  @override
  State<OF297SignatureDialog> createState() => _OF297SignatureDialogState();
}

class _OF297SignatureDialogState extends State<OF297SignatureDialog> {
  late final TextEditingController _signerNameController;
  late final TextEditingController _signerTitleController;
  late final SignatureController _signatureController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _signerNameController = TextEditingController(
      text: widget.existingSignature?.signerName ?? '',
    );
    _signerTitleController = TextEditingController(
      text: widget.existingSignature?.signerTitle ?? '',
    );
    _signatureController = SignatureController(
      // A heavier black stroke stays legible after the signature image is
      // scaled into the small OF-297 PDF signature cell.
      penStrokeWidth: 5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signerNameController.dispose();
    _signerTitleController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final maxDialogHeight =
        media.size.height - media.padding.top - media.padding.bottom - 24;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 32 : 24,
        vertical: isLandscape ? 12 : 24,
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final signaturePadHeight = isLandscape ? 104.0 : 124.0;
            final spacing = isLandscape ? 10.0 : 16.0;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 520 : 440,
                maxHeight: maxDialogHeight,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: Padding(
                  padding: EdgeInsets.all(isLandscape ? 20 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: spacing),
                      TextField(
                        controller: _signerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Signer name',
                        ),
                      ),
                      if (widget.requestSignerTitle) ...[
                        SizedBox(height: isLandscape ? 8 : 12),
                        TextField(
                          controller: _signerTitleController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'ICT4, DIVC, TFLD, ENGB, STEN',
                          ),
                        ),
                      ],
                      SizedBox(height: spacing),
                      SizedBox(
                        height: signaturePadHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderOlive),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorText!,
                          style: const TextStyle(color: AppColors.statusRed),
                        ),
                      ],
                      SizedBox(height: spacing),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: _signatureController.clear,
                            child: const Text('Clear'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: _saveSignature,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveSignature() async {
    final signerName = _signerNameController.text.trim();
    final signerTitle = _signerTitleController.text.trim().toUpperCase();
    if (signerName.isEmpty) {
      setState(() {
        _errorText = 'Signer name is required.';
      });
      return;
    }

    if (widget.requestSignerTitle && signerTitle.isEmpty) {
      setState(() {
        _errorText = 'Title is required.';
      });
      return;
    }

    if (_signatureController.isEmpty) {
      setState(() {
        _errorText = 'Draw a signature before saving.';
      });
      return;
    }

    final pngBytes = await _signatureController.toPngBytes();
    if (pngBytes == null || pngBytes.isEmpty) {
      setState(() {
        _errorText = 'Unable to capture signature. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      OF297Signature(
        signerName: signerName,
        signerTitle: signerTitle,
        signatureBytesBase64: base64Encode(pngBytes),
        signedAt: DateTime.now(),
      ),
    );
  }
}
