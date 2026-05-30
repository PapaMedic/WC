import 'package:intl/intl.dart';

String formatShiftDateRange(
  DateTime shiftDate,
  String startTime,
  String stopTime,
) {
  final formatter = DateFormat('MM/dd/yyyy');
  if (!_isOvernight(startTime, stopTime)) {
    return formatter.format(shiftDate);
  }

  return '${formatter.format(shiftDate)}-'
      '${formatter.format(shiftDate.add(const Duration(days: 1)))}';
}

bool shiftTimeRangeIsOvernight(String startTime, String stopTime) {
  return _isOvernight(startTime, stopTime);
}

bool _isOvernight(String startTime, String stopTime) {
  final startMinutes = parseMilitaryTimeMinutes(startTime);
  final stopMinutes = parseMilitaryTimeMinutes(stopTime);
  if (startMinutes == null || stopMinutes == null) return false;

  return stopMinutes < startMinutes;
}

int? parseMilitaryTimeMinutes(String value) {
  final text = value.trim();
  if (text.length != 4) return null;

  final hour = int.tryParse(text.substring(0, 2));
  final minute = int.tryParse(text.substring(2, 4));
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}
