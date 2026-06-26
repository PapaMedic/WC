// Tickets data model and serialization helpers.
/// One equipment time row on an OF-297 Emergency Equipment Shift Ticket.
///
/// These rows are kept as saved form data. PDF field mapping will be added in a
/// later pass after the draft/finalized workflow is stable.
class OF297EquipmentTimeEntry {
  final String id;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? stopTime;
  final double calculatedTotalHours;
  final double totalHours;
  final bool totalHoursManuallyOverridden;
  final double? mileageStart;
  final double? mileageEnd;
  final double totalMiles;
  final double specialRateQuantity;
  final String rateType;
  final String notes;

  const OF297EquipmentTimeEntry({
    required this.id,
    this.date,
    this.startTime,
    this.stopTime,
    this.calculatedTotalHours = 0,
    this.totalHours = 0,
    this.totalHoursManuallyOverridden = false,
    this.mileageStart,
    this.mileageEnd,
    this.totalMiles = 0,
    this.specialRateQuantity = 0,
    this.rateType = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date?.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'calculatedTotalHours': calculatedTotalHours,
        'totalHours': totalHours,
        'totalHoursManuallyOverridden': totalHoursManuallyOverridden,
        'mileageStart': mileageStart,
        'mileageEnd': mileageEnd,
        'totalMiles': totalMiles,
        'specialRateQuantity': specialRateQuantity,
        'rateType': rateType,
        'notes': notes,
      };

  factory OF297EquipmentTimeEntry.fromJson(Map<String, dynamic> json) {
    final calculatedTotalHours =
        (json['calculatedTotalHours'] as num?)?.toDouble();
    final totalHours = (json['totalHours'] as num?)?.toDouble();
    final startTime = DateTime.tryParse(json['startTime'] ?? '');
    final stopTime = DateTime.tryParse(json['stopTime'] ?? '');
    final loadedCalculatedTotalHours = calculatedTotalHours ??
        _calculateHoursFromDateTimes(startTime, stopTime) ??
        totalHours ??
        0;

    return OF297EquipmentTimeEntry(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? ''),
      startTime: startTime,
      stopTime: stopTime,
      calculatedTotalHours: loadedCalculatedTotalHours,
      totalHours: totalHours ?? loadedCalculatedTotalHours,
      totalHoursManuallyOverridden:
          json['totalHoursManuallyOverridden'] ?? false,
      mileageStart: (json['mileageStart'] as num?)?.toDouble(),
      mileageEnd: (json['mileageEnd'] as num?)?.toDouble(),
      totalMiles: (json['totalMiles'] as num?)?.toDouble() ?? 0,
      specialRateQuantity:
          (json['specialRateQuantity'] as num?)?.toDouble() ?? 0,
      rateType: json['rateType'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

double? _calculateHoursFromDateTimes(DateTime? start, DateTime? stop) {
  if (start == null || stop == null) return null;
  final adjustedStop =
      stop.isBefore(start) ? stop.add(const Duration(days: 1)) : stop;
  return adjustedStop.difference(start).inMinutes / 60;
}
