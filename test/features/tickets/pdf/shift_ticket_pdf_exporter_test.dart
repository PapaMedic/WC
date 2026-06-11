import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/models/shift_ticket_export_format.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/ctr_pdf_generator.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_export_document.dart';
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
        if (format == ShiftTicketExportFormat.of297) {
          expect(pdf.fileName, 'OF297_Herman_Ranch_2026-06-06_A.pdf');
        } else {
          expect(pdf.fileName, 'CTR_Herman_Ranch_2026-06-06.pdf');
        }
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

  test('CTR time rows keep each employee in a two-row date block', () {
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
    expect(sameDayRows, hasLength(2));
    expect(sameDayRows[0].employeeName, 'Jordan Saw');
    expect(sameDayRows[0].classification, 'FFT1');
    expect(sameDayRows[0].firstDate, '06/06/2026');
    expect(sameDayRows[0].firstOn, '0900');
    expect(sameDayRows[0].firstOff, '2000');
    expect(sameDayRows[0].secondDate, isEmpty);
    expect(sameDayRows[0].secondOn, isEmpty);
    expect(sameDayRows[0].secondOff, isEmpty);
    expect(sameDayRows[1].employeeName, isEmpty);
    expect(sameDayRows[1].classification, isEmpty);

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
    expect(overnightRows, hasLength(4));
    expect(overnightRows[0].employeeName, 'Jordan Saw');
    expect(overnightRows[0].classification, 'ENGB');
    expect(overnightRows[0].firstDate, '06/06/2026');
    expect(overnightRows[0].firstOn, '1800');
    expect(overnightRows[0].firstOff, '2400');
    expect(overnightRows[0].secondDate, '06/07/2026');
    expect(overnightRows[0].secondOn, '0000');
    expect(overnightRows[0].secondOff, '0600');
    expect(overnightRows[1].isContinuation, isTrue);
    expect(overnightRows[1].employeeName, isEmpty);
    expect(overnightRows[1].classification, isEmpty);
    expect(overnightRows[2].employeeName, 'Alex Crew');
    expect(overnightRows[2].classification, 'FFT2');
    expect(overnightRows[3].employeeName, isEmpty);
    expect(overnightRows[3].classification, isEmpty);

    final breakTicket = OF297ShiftTicket(
      id: 'breaks',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: DateTime(2026, 6, 11),
      personnelEntries: [
        OF297PersonnelTimeEntry(
          id: 'segment-1',
          name: 'Example 1',
          position: 'FFT1',
          startTime: DateTime(2026, 6, 11, 17, 30),
          stopTime: DateTime(2026, 6, 11, 22),
        ),
        OF297PersonnelTimeEntry(
          id: 'segment-2',
          name: 'Example 1',
          position: 'FFT1',
          startTime: DateTime(2026, 6, 11, 22, 30),
          stopTime: DateTime(2026, 6, 12, 1),
        ),
        OF297PersonnelTimeEntry(
          id: 'segment-3',
          name: 'Example 1',
          position: 'FFT1',
          startTime: DateTime(2026, 6, 12, 1, 30),
          stopTime: DateTime(2026, 6, 12, 6),
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final breakRows = generator.buildCtrTimeRows(breakTicket);
    expect(breakRows, hasLength(2));
    expect(breakRows[0].employeeName, 'Example 1');
    expect(breakRows[0].classification, 'FFT1');
    expect(breakRows[0].firstDate, '06/11/2026');
    expect(breakRows[0].firstOn, '1730');
    expect(breakRows[0].firstOff, '2200');
    expect(breakRows[0].secondDate, '06/12/2026');
    expect(breakRows[0].secondOn, '0000');
    expect(breakRows[0].secondOff, '0100');
    expect(breakRows[1].employeeName, isEmpty);
    expect(breakRows[1].classification, isEmpty);
    expect(breakRows[1].firstDate, '06/11/2026');
    expect(breakRows[1].firstOn, '2230');
    expect(breakRows[1].firstOff, '2400');
    expect(breakRows[1].secondDate, '06/12/2026');
    expect(breakRows[1].secondOn, '0130');
    expect(breakRows[1].secondOff, '0600');

    final twoBlockTicket = OF297ShiftTicket(
      id: 'two-blocks',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: DateTime(2026, 6, 11),
      personnelEntries: [
        OF297PersonnelTimeEntry(
          id: 'person-1',
          name: 'Example 1',
          position: 'FFT1',
          guaranteeStartTime: DateTime(2026, 6, 11, 9),
          guaranteeStopTime: DateTime(2026, 6, 11, 17),
          startTime: DateTime(2026, 6, 11, 17, 30),
          stopTime: DateTime(2026, 6, 12, 1),
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final twoBlockRows = generator.buildCtrTimeRows(twoBlockTicket);
    expect(twoBlockRows, hasLength(2));
    expect(twoBlockRows[0].employeeName, 'Example 1');
    expect(twoBlockRows[0].classification, 'FFT1');
    expect(twoBlockRows[0].firstDate, '06/11/2026');
    expect(twoBlockRows[0].firstOn, '0900');
    expect(twoBlockRows[0].firstOff, '1700');
    expect(twoBlockRows[0].secondDate, '06/12/2026');
    expect(twoBlockRows[0].secondOn, '0000');
    expect(twoBlockRows[0].secondOff, '0100');
    expect(twoBlockRows[1].employeeName, isEmpty);
    expect(twoBlockRows[1].classification, isEmpty);
    expect(twoBlockRows[1].firstDate, '06/11/2026');
    expect(twoBlockRows[1].firstOn, '1730');
    expect(twoBlockRows[1].firstOff, '2400');
    expect(twoBlockRows[1].secondDate, isEmpty);
    expect(twoBlockRows[1].secondOn, isEmpty);
    expect(twoBlockRows[1].secondOff, isEmpty);
  });

  test('OF-297 export chunks personnel into groups of four', () {
    final date = DateTime(2026, 6, 11);
    final personnel = List.generate(5, (index) {
      return OF297PersonnelTimeEntry(
        id: 'person-${index + 1}',
        name: 'Person ${index + 1}',
        position: 'FFT${index + 1}',
        date: date,
        guaranteeStartTime: date.add(const Duration(hours: 9)),
        guaranteeStopTime: date.add(const Duration(hours: 17)),
        totalHours: 8,
      );
    });
    final ticket = OF297ShiftTicket(
      id: 'five-person-ticket',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: date,
      personnelEntries: personnel,
      createdAt: date,
      updatedAt: date,
    );

    final documents = buildOf297ExportDocuments(ticket);

    expect(documents, hasLength(2));
    expect(documents[0].fileName, 'OF297_Herman_Ranch_2026-06-11_A.pdf');
    expect(documents[1].fileName, 'OF297_Herman_Ranch_2026-06-11_B.pdf');
    expect(documents[0].personnelRows, hasLength(4));
    expect(documents[0].personnelRows[0].source.name, 'Person 1');
    expect(documents[0].personnelRows[3].source.name, 'Person 4');
    expect(documents[1].personnelRows, hasLength(1));
    expect(documents[1].personnelRows[0].source.name, 'Person 5');
    expect(documents[1].personnelRows[0].block1Start, '0900');
    expect(documents[1].personnelRows[0].block1Stop, '1700');
  });

  test('OF-297 equipment rows use independent apparatus time', () {
    final date = DateTime(2026, 6, 11);
    final ticket = OF297ShiftTicket(
      id: 'equipment-independent',
      incidentId: 'incident-1',
      incidentName: 'Herman Ranch',
      globalShiftDate: date,
      globalBlock1Start: '0900',
      globalBlock1Stop: '1700',
      globalBlock2Start: '1730',
      globalBlock2Stop: '0100',
      equipmentEntries: [
        OF297EquipmentTimeEntry(
          id: 'equipment-1',
          date: date,
          startTime: date.add(const Duration(hours: 8)),
          stopTime: date.add(const Duration(hours: 20)),
          totalHours: 12,
        ),
      ],
      createdAt: date,
      updatedAt: date,
    );

    final documents = buildOf297ExportDocuments(ticket);
    final firstDayEquipment = documents
        .firstWhere((document) => document.workDate == date)
        .equipmentRows
        .first;

    expect(firstDayEquipment.start, '0800');
    expect(firstDayEquipment.stop, '2000');
    expect(firstDayEquipment.totalHours, 12);
  });
}
