import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_signature_dialog.dart';

/// Read-only signature display plus draft-only capture actions.
class OF297SignatureBox extends StatelessWidget {
  final String title;
  final OF297Signature? signature;
  final bool readOnly;
  final ValueChanged<OF297Signature> onSignatureChanged;
  final VoidCallback onSignatureCleared;

  const OF297SignatureBox({
    super.key,
    required this.title,
    required this.signature,
    required this.readOnly,
    required this.onSignatureChanged,
    required this.onSignatureCleared,
  });

  @override
  Widget build(BuildContext context) {
    final capturedSignature = signature;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        color: Colors.black.withValues(alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_outlined, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (capturedSignature == null)
            Text(
              readOnly ? 'No signature captured.' : 'Signature not captured.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Text(
              capturedSignature.signerName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Signed ${DateFormat('MMM d, yyyy HH:mm').format(capturedSignature.signedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 130,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: capturedSignature.signatureBytesBase64.isEmpty
                  ? const Center(
                      child: Text(
                        'Signature image unavailable.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    )
                  : Image.memory(
                      base64Decode(capturedSignature.signatureBytesBase64),
                      fit: BoxFit.contain,
                    ),
            ),
          ],
          if (!readOnly) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => _openSignatureDialog(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    capturedSignature == null
                        ? 'Add Signature'
                        : 'Replace Signature',
                  ),
                ),
                if (capturedSignature != null)
                  TextButton.icon(
                    onPressed: onSignatureCleared,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Signature'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSignatureDialog(BuildContext context) async {
    final result = await showDialog<OF297Signature>(
      context: context,
      builder: (context) => OF297SignatureDialog(
        title: title,
        existingSignature: signature,
      ),
    );

    if (result != null) {
      onSignatureChanged(result);
    }
  }
}
