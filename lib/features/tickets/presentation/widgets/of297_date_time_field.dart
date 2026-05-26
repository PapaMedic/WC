import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date/time picker field used by the OF-297 form.
class OF297DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool readOnly;
  final ValueChanged<DateTime?> onChanged;

  const OF297DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');

    return InkWell(
      onTap: readOnly ? null : () => _pickDateTime(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: readOnly ? null : const Icon(Icons.event_outlined),
        ),
        child: Text(
          value == null ? 'Select date/time' : formatter.format(value!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final initial = value ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) return;

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}
