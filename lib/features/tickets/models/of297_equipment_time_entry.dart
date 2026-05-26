/// One equipment time row on an OF-297 Emergency Equipment Shift Ticket.
///
/// These rows are kept as saved form data. PDF field mapping will be added in a
/// later pass after the draft/finalized workflow is stable.
class OF297EquipmentTimeEntry {
  final String id;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? stopTime;
  final double totalHours;
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
    this.totalHours = 0,
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
        'totalHours': totalHours,
        'mileageStart': mileageStart,
        'mileageEnd': mileageEnd,
        'totalMiles': totalMiles,
        'specialRateQuantity': specialRateQuantity,
        'rateType': rateType,
        'notes': notes,
      };

  factory OF297EquipmentTimeEntry.fromJson(Map<String, dynamic> json) {
    return OF297EquipmentTimeEntry(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? ''),
      startTime: DateTime.tryParse(json['startTime'] ?? ''),
      stopTime: DateTime.tryParse(json['stopTime'] ?? ''),
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
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
