// Tickets data model and serialization helpers.
/// One personnel/operator time row on an OF-297 ticket.
///
/// This model is separate from the app's Personnel roster because the ticket is
/// the source of truth once saved; later roster changes should not rewrite old
/// ticket records.
class OF297PersonnelTimeEntry {
  final String id;
  final String name;
  final String position;
  final DateTime? date;
  final DateTime? guaranteeStartTime;
  final DateTime? guaranteeStopTime;
  final DateTime? startTime;
  final DateTime? stopTime;
  final double totalHours;
  final String rateType;
  final String notes;

  const OF297PersonnelTimeEntry({
    required this.id,
    this.name = '',
    this.position = '',
    this.date,
    this.guaranteeStartTime,
    this.guaranteeStopTime,
    this.startTime,
    this.stopTime,
    this.totalHours = 0,
    this.rateType = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position,
        'date': date?.toIso8601String(),
        'guaranteeStartTime': guaranteeStartTime?.toIso8601String(),
        'guaranteeStopTime': guaranteeStopTime?.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'stopTime': stopTime?.toIso8601String(),
        'totalHours': totalHours,
        'rateType': rateType,
        'notes': notes,
      };

  factory OF297PersonnelTimeEntry.fromJson(Map<String, dynamic> json) {
    return OF297PersonnelTimeEntry(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      date: DateTime.tryParse(json['date'] ?? ''),
      guaranteeStartTime: DateTime.tryParse(json['guaranteeStartTime'] ?? ''),
      guaranteeStopTime: DateTime.tryParse(json['guaranteeStopTime'] ?? ''),
      startTime: DateTime.tryParse(json['startTime'] ?? ''),
      stopTime: DateTime.tryParse(json['stopTime'] ?? ''),
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
      rateType: json['rateType'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
