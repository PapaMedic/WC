import 'package:flutter_test/flutter_test.dart';
import 'package:wildland_companion_v2/features/tickets/utils/shift_ticket_time.dart';

void main() {
  group('formatShiftDateRange', () {
    final shiftDate = DateTime(2026, 5, 29);

    test('0600 -> 1800 is same-day', () {
      expect(formatShiftDateRange(shiftDate, '0600', '1800'), '05/29/2026');
    });

    test('1800 -> 0600 is overnight', () {
      expect(
        formatShiftDateRange(shiftDate, '1800', '0600'),
        '05/29/2026-05/30/2026',
      );
    });

    test('2000 -> 0300 is overnight', () {
      expect(
        formatShiftDateRange(shiftDate, '2000', '0300'),
        '05/29/2026-05/30/2026',
      );
    });

    test('0001 -> 2359 is same-day', () {
      expect(formatShiftDateRange(shiftDate, '0001', '2359'), '05/29/2026');
    });

    test('2359 -> 0001 is overnight', () {
      expect(
        formatShiftDateRange(shiftDate, '2359', '0001'),
        '05/29/2026-05/30/2026',
      );
    });
  });
}
