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

  const OF297SignatureDialog({
    super.key,
    required this.title,
    this.existingSignature,
  });

  @override
  State<OF297SignatureDialog> createState() => _OF297SignatureDialogState();
}

class _OF297SignatureDialogState extends State<OF297SignatureDialog> {
  late final TextEditingController _signerNameController;
  late final SignatureController _signatureController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _signerNameController = TextEditingController(
      text: widget.existingSignature?.signerName ?? '',
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
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _signerNameController,
              decoration: const InputDecoration(
                labelText: 'Signer name',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 220,
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
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.statusRed),
              ),
            ],
          ],
        ),
      ),
      actions: [
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
    );
  }

  Future<void> _saveSignature() async {
    final signerName = _signerNameController.text.trim();
    if (signerName.isEmpty) {
      setState(() {
        _errorText = 'Signer name is required.';
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
        signatureBytesBase64: base64Encode(pngBytes),
        signedAt: DateTime.now(),
      ),
    );
  }
}
