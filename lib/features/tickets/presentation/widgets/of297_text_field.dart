// Tickets reusable presentation widget.
import 'package:flutter/material.dart';

/// Text field wrapper for OF-297 form inputs.
class OF297TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const OF297TextField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
