// Tests covering OF-297 equipment time entry persistence.
import 'package:flutter_test/flutter_test.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';

void main() {
  test('persists manually adjusted apparatus total metadata', () {
    final entry = OF297EquipmentTimeEntry(
      id: 'equipment-1',
      calculatedTotalHours: 12,
      totalHours: 11.5,
      totalHoursManuallyOverridden: true,
    );

    final decoded = OF297EquipmentTimeEntry.fromJson(entry.toJson());

    expect(decoded.calculatedTotalHours, 12);
    expect(decoded.totalHours, 11.5);
    expect(decoded.totalHoursManuallyOverridden, isTrue);
  });

  test('calculates total for old records with start and stop but no total', () {
    final start = DateTime(2026, 6, 11, 18);
    final stop = DateTime(2026, 6, 12, 2);

    final decoded = OF297EquipmentTimeEntry.fromJson({
      'id': 'legacy-equipment',
      'startTime': start.toIso8601String(),
      'stopTime': stop.toIso8601String(),
    });

    expect(decoded.calculatedTotalHours, 8);
    expect(decoded.totalHours, 8);
    expect(decoded.totalHoursManuallyOverridden, isFalse);
  });
}
