import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/ctr_pdf_generator.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/shift_ticket_pdf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OF-297 and CTR preview PDFs are valid and reopenable', () async {
    final date = DateTime(2026, 6, 6);
    final ticket = OF297ShiftTicket(
      id: 'ticket-1',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      incidentNumber: 'AZ-ABC-123',
      resourceOrderNumber: 'E-123',
      contractorName: 'Wildland Contracting',
      ctrOfficeResponsibleForFire: 'Tonto NF',
      equipmentMakeModel: 'Type 6 Engine',
      equipmentType: 'Engine',
      equipmentId: 'ENG-42',
      operatorName: 'Avery Operator',
      remarks: 'Example',
      globalShiftDate: date,
      globalBlock1Start: '0800',
      globalBlock1Stop: '1800',
      equipmentEntries: [
        OF297EquipmentTimeEntry(
          id: 'equipment-1',
          date: date,
          startTime: date.add(const Duration(hours: 8)),
          stopTime: date.add(const Duration(hours: 18)),
          totalHours: 10,
        ),
      ],
      personnelEntries: [
        OF297PersonnelTimeEntry(
          id: 'person-1',
          name: 'Jordan Saw',
          position: 'ENGB',
          date: date,
          startTime: date.add(const Duration(hours: 8)),
          stopTime: date.add(const Duration(hours: 18)),
          totalHours: 10,
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final exporter = ShiftTicketPdfExporter();
    for (final format in ShiftTicketExportFormat.values) {
      final generated = await exporter.generatePreviewPdfs(
        ticket,
        format: format,
      );
      expect(generated, isNotEmpty);

      for (final pdf in generated) {
        validatePdfBytes(pdf.bytes, label: pdf.fileName);
        final document = PdfDocument(inputBytes: pdf.bytes);
        try {
          expect(document.pages.count, greaterThan(0));
          if (format == ShiftTicketExportFormat.ctr) {
            final text = PdfTextExtractor(document).extractText();
            expect(text, contains('Example'));
            expect(text, contains('Tonto NF'));
            expect(text, isNot(contains('Incident ID:')));
            expect(text, isNot(contains('Resource:')));
            expect(text, isNot(contains('Type: Type 6')));
            expect(text, isNot(contains('Type 6 Engine')));
          }
        } finally {
          document.dispose();
        }
      }
    }
  });

  test('CTR time rows split overnight shifts without repeating name or class',
      () {
    final date = DateTime(2026, 6, 6);
    final generator = CtrPdfGenerator();

    final sameDayTicket = OF297ShiftTicket(
      id: 'same-day',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: date,
      personnelEntries: [
        OF297PersonnelTimeEntry(
          id: 'person-1',
          name: 'Jordan Saw',
          position: 'FFT1',
          date: date,
          startTime: DateTime(2026, 6, 6, 9),
          stopTime: DateTime(2026, 6, 6, 20),
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final sameDayRows = generator.buildCtrTimeRows(sameDayTicket);
    expect(sameDayRows, hasLength(1));
    expect(sameDayRows.first.employeeName, 'Jordan Saw');
    expect(sameDayRows.first.classification, 'FFT1');
    expect(sameDayRows.first.firstDate, '06/06/2026');
    expect(sameDayRows.first.firstOn, '0900');
    expect(sameDayRows.first.firstOff, '2000');
    expect(sameDayRows.first.secondDate, isEmpty);
    expect(sameDayRows.first.secondOn, isEmpty);
    expect(sameDayRows.first.secondOff, isEmpty);

    final overnightTicket = OF297ShiftTicket(
      id: 'overnight',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: date,
      personnelEntries: [
        OF297PersonnelTimeEntry(
          id: 'person-1',
          name: 'Jordan Saw',
          position: 'ENGB',
          date: date,
          startTime: DateTime(2026, 6, 6, 18),
          stopTime: DateTime(2026, 6, 7, 6),
        ),
        OF297PersonnelTimeEntry(
          id: 'person-2',
          name: 'Alex Crew',
          position: 'FFT2',
          date: date,
          startTime: DateTime(2026, 6, 6, 8),
          stopTime: DateTime(2026, 6, 6, 16),
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final overnightRows = generator.buildCtrTimeRows(overnightTicket);
    expect(overnightRows, hasLength(3));
    expect(overnightRows[0].employeeName, 'Jordan Saw');
    expect(overnightRows[0].classification, 'ENGB');
    expect(overnightRows[0].firstDate, '06/06/2026');
    expect(overnightRows[0].firstOn, '1800');
    expect(overnightRows[0].firstOff, '2400');
    expect(overnightRows[1].isContinuation, isTrue);
    expect(overnightRows[1].employeeName, isEmpty);
    expect(overnightRows[1].classification, isEmpty);
    expect(overnightRows[1].secondDate, '06/07/2026');
    expect(overnightRows[1].secondOn, '0000');
    expect(overnightRows[1].secondOff, '0600');
    expect(overnightRows[2].employeeName, 'Alex Crew');
    expect(overnightRows[2].classification, 'FFT2');
  });
}
