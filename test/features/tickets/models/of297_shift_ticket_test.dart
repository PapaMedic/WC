// Tests covering OF-297 shift ticket persistence.
import 'package:flutter_test/flutter_test.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';

void main() {
  test('persists apparatus same as crew times flag', () {
    final now = DateTime(2026, 6, 11);
    final ticket = OF297ShiftTicket(
      id: 'ticket-1',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      apparatusSameAsCrewTimes: true,
      createdAt: now,
      updatedAt: now,
    );

    final decoded = OF297ShiftTicket.fromJson(ticket.toJson());

    expect(decoded.apparatusSameAsCrewTimes, isTrue);
  });

  test('defaults apparatus same as crew times to false for old records', () {
    final decoded = OF297ShiftTicket.fromJson({
      'id': 'legacy-ticket',
      'incidentId': 'incident-1',
      'incidentName': 'Herman Ranch',
    });

    expect(decoded.apparatusSameAsCrewTimes, isFalse);
  });
}
