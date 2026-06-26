// Tickets utility helpers shared by feature code.
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

Duration? calculateShiftDuration(String startTime, String stopTime) {
  final startMinutes = parseMilitaryTimeMinutes(startTime);
  final stopMinutes = parseMilitaryTimeMinutes(stopTime);
  if (startMinutes == null || stopMinutes == null) return null;

  var elapsedMinutes = stopMinutes - startMinutes;
  if (elapsedMinutes < 0) {
    elapsedMinutes += 24 * 60;
  }

  return Duration(minutes: elapsedMinutes);
}

double? calculateShiftHours(String startTime, String stopTime) {
  final duration = calculateShiftDuration(startTime, stopTime);
  if (duration == null) return null;
  return duration.inMinutes / 60;
}

String formatDurationAsHoursMinutes(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '$hours:${minutes.toString().padLeft(2, '0')}';
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
