import 'package:flutter/material.dart';

/// Text field wrapper for OF-297 form inputs.
class OF297TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;

  const OF297TextField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
