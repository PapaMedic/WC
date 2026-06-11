import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_generator.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';

class CtrPdfResult {
  final Uint8List bytes;
  final String fileName;
  final List<String> warnings;

  const CtrPdfResult({
    required this.bytes,
    required this.fileName,
    this.warnings = const [],
  });
}

class CtrTimeRow {
  final String remarksNo;
  final String employeeName;
  final String classification;
  final String firstDate;
  final String firstOn;
  final String firstOff;
  final String secondDate;
  final String secondOn;
  final String secondOff;
  final bool isContinuation;

  const CtrTimeRow({
    this.remarksNo = '',
    this.employeeName = '',
    this.classification = '',
    this.firstDate = '',
    this.firstOn = '',
    this.firstOff = '',
    this.secondDate = '',
    this.secondOn = '',
    this.secondOff = '',
    this.isContinuation = false,
  });
}

class _CtrInterval {
  final DateTime start;
  final DateTime end;

  const _CtrInterval({
    required this.start,
    required this.end,
  });
}

class CtrPdfGenerator {
  static const templateAssetPath = 'assets/CTR/CTR_Fillable.pdf';
  static const maxPersonnelRows = 22;

  final Of297PdfGenerator _signatureDrawer;

  CtrPdfGenerator({
    Of297PdfGenerator? signatureDrawer,
  }) : _signatureDrawer = signatureDrawer ?? Of297PdfGenerator();

  Future<CtrPdfResult> generatePreviewPdf(OF297ShiftTicket ticket) {
    return _generatePdf(ticket, requireFinalized: false);
  }

  Future<CtrPdfResult> generateFinalizedPdf(OF297ShiftTicket ticket) {
    if (!ticket.isFinalized) {
      throw StateError('Only finalized tickets can be exported to CTR.');
    }
    return _generatePdf(ticket, requireFinalized: true);
  }

  Future<CtrPdfResult> _generatePdf(
    OF297ShiftTicket ticket, {
    required bool requireFinalized,
  }) async {
    if (requireFinalized && !ticket.isFinalized) {
      throw StateError('Only finalized tickets can be exported to CTR.');
    }

    final templateData = await rootBundle.load(templateAssetPath);
    final templateBytes = pdfBytesFromByteData(templateData);
    final document = PdfDocument(
      inputBytes: templateBytes,
    );

    try {
      final ctrRows = buildCtrTimeRows(ticket);
      _fillHeader(document, ticket, ctrRows);
      _fillPersonnelRows(document, ctrRows);
      _fillRemarks(document, ticket);
      _fillSignatureSection(document, ticket);

      document.form.flattenAllFields();
      await _drawSignatures(document, ticket);

      final bytes = Uint8List.fromList(await document.save());
      validatePdfBytes(bytes, label: 'CTR ${_fileName(ticket)}');
      return CtrPdfResult(
        bytes: bytes,
        fileName: _fileName(ticket),
        warnings: _warnings(ticket, ctrRows),
      );
    } finally {
      document.dispose();
    }
  }

  void _fillHeader(
    PdfDocument document,
    OF297ShiftTicket ticket,
    List<CtrTimeRow> ctrRows,
  ) {
    setTextField(document, '1 CREW NAME', _crewName(ticket));
    setTextField(document, '2 CREW NUMBER', ticket.resourceOrderNumber);
    setTextField(
      document,
      '3 OFFICE RESPONSIBLE FOR FIRE',
      ticket.ctrOfficeResponsibleForFire,
    );
    setTextField(document, '4 FIRE NAME', ticket.incidentName);
    setTextField(document, '5 FIRE NUMBER', ticket.incidentNumber);

    setTextField(document, 'DATE', _firstDate(ctrRows, ticket));
    setTextField(document, 'DATE_2', _secondDate(ctrRows));
  }

  void _fillPersonnelRows(PdfDocument document, List<CtrTimeRow> ctrRows) {
    final rows = ctrRows.take(maxPersonnelRows).toList();
    for (var i = 0; i < rows.length; i++) {
      final row = i + 1;
      final entry = rows[i];
      setCompactTextField(document, 'RE MARKS NORow$row', entry.remarksNo);
      setTextField(document, 'NAME OF EMPLOYEERow$row', entry.employeeName);
      setCompactTextField(
        document,
        'CLASSIF ICATIONRow$row',
        entry.classification,
      );
      setCompactTextField(document, 'ONRow$row', entry.firstOn);
      setCompactTextField(document, 'OFFRow$row', entry.firstOff);
      setCompactTextField(document, 'ONRow${row}_2', entry.secondOn);
      setCompactTextField(document, 'OFFRow${row}_2', entry.secondOff);
    }
  }

  void _fillRemarks(PdfDocument document, OF297ShiftTicket ticket) {
    final chunks = _splitRemarks(ticket.remarks, 5, 70);
    for (var i = 0; i < chunks.length; i++) {
      setTextField(document, '11 REMARKSRow${i + 1}', chunks[i]);
    }
  }

  void _fillSignatureSection(PdfDocument document, OF297ShiftTicket ticket) {
    setTextField(
      document,
      '13 TITLE OfficerinCharge',
      _supervisorTitle(),
    );
    setTextField(
      document,
      '14 NAME Person Posting to Emergency Time Report',
      ticket.operatorName.isEmpty
          ? ticket.contractorSignature?.signerName ?? ''
          : ticket.operatorName,
    );
    setTextField(
      document,
      '15 DATE',
      _date(ticket.isFinalized ? ticket.updatedAt : _ticketDate(ticket)),
    );
  }

  Future<void> _drawSignatures(
    PdfDocument document,
    OF297ShiftTicket ticket,
  ) async {
    final supervisorSignature = ticket.supervisorSignature;
    if (supervisorSignature != null) {
      await _signatureDrawer.drawSignature(
        page: document.pages[0],
        signature: supervisorSignature,
        box: const Rect.fromLTWH(14.8, 497.5, 161.4, 13.4),
      );
    }

    // Box 14 is a printed-name field, not a signature box. Do not draw the
    // operator/contractor signature unless the official CTR template adds a
    // separate operator signature area.
  }

  List<String> _warnings(OF297ShiftTicket ticket, List<CtrTimeRow> ctrRows) {
    final overflowCount = ctrRows.length - maxPersonnelRows;
    if (overflowCount <= 0) return const [];
    return [
      'CTR supports $maxPersonnelRows employee rows. '
          '$overflowCount time row${overflowCount == 1 ? '' : 's'} were not included.',
    ];
  }

  void setTextField(PdfDocument document, String fieldName, String value) {
    if (value.trim().isEmpty) return;

    final field = _fieldByName(document, fieldName);
    if (field is PdfTextBoxField) {
      field.text = value;
    } else if (field == null) {
      _warnMissingField(fieldName);
    } else {
      _warnWrongFieldType(fieldName, field);
    }
  }

  void setCompactTextField(
    PdfDocument document,
    String fieldName,
    String value,
  ) {
    if (value.trim().isEmpty) return;

    final field = _fieldByName(document, fieldName);
    if (field is PdfTextBoxField) {
      field.font = PdfStandardFont(PdfFontFamily.helvetica, 6.5);
      field.textAlignment = PdfTextAlignment.center;
      field.text = value;
    } else if (field == null) {
      _warnMissingField(fieldName);
    } else {
      _warnWrongFieldType(fieldName, field);
    }
  }

  PdfField? _fieldByName(PdfDocument document, String fieldName) {
    for (var i = 0; i < document.form.fields.count; i++) {
      final field = document.form.fields[i];
      if ((field.name ?? '') == fieldName) return field;
    }
    return null;
  }

  void _warnMissingField(String fieldName) {
    developer.log(
      'CTR PDF field missing: $fieldName.',
      name: 'CtrPdfGenerator',
    );
  }

  void _warnWrongFieldType(String fieldName, PdfField field) {
    developer.log(
      'CTR PDF field "$fieldName" was ${field.runtimeType}, not a text field.',
      name: 'CtrPdfGenerator',
    );
  }

  String _crewName(OF297ShiftTicket ticket) {
    if (ticket.contractorName.trim().isNotEmpty) return ticket.contractorName;
    if (ticket.equipmentMakeModel.trim().isNotEmpty) {
      return ticket.equipmentMakeModel;
    }
    return ticket.equipmentId;
  }

  String _supervisorTitle() {
    // The ticket currently stores supervisor name/signature, but not a title.
    // Leave CTR Box 13 blank until there is a real title field to map.
    return '';
  }

  String _rowRemarks(OF297PersonnelTimeEntry entry) {
    if (entry.notes.trim().isNotEmpty) return entry.notes;
    if (entry.rateType.trim().isNotEmpty) return entry.rateType;
    return '';
  }

  String _date(DateTime? value) {
    if (value == null) return '';
    return DateFormat('MM/dd/yyyy').format(value);
  }

  DateTime? _ticketDate(OF297ShiftTicket ticket) {
    return ticket.globalShiftDate ?? ticket.shiftStart;
  }

  String _firstDate(List<CtrTimeRow> rows, OF297ShiftTicket ticket) {
    for (final row in rows) {
      if (row.firstDate.isNotEmpty) return row.firstDate;
    }
    return _date(_ticketDate(ticket));
  }

  String _secondDate(List<CtrTimeRow> rows) {
    for (final row in rows) {
      if (row.secondDate.isNotEmpty) return row.secondDate;
    }
    return '';
  }

  List<CtrTimeRow> buildCtrTimeRows(OF297ShiftTicket ticket) {
    final rows = <CtrTimeRow>[];
    for (final entry in ticket.personnelEntries) {
      if (entry.name.trim().isEmpty && entry.position.trim().isEmpty) continue;

      final interval = _personnelInterval(ticket, entry);
      if (interval == null) {
        rows.add(
          CtrTimeRow(
            remarksNo: _rowRemarks(entry),
            employeeName: entry.name,
            classification: entry.position,
          ),
        );
        continue;
      }

      rows.addAll(_rowsForInterval(entry, interval));
    }
    return rows;
  }

  List<CtrTimeRow> _rowsForInterval(
    OF297PersonnelTimeEntry entry,
    _CtrInterval interval,
  ) {
    final startDate = _dateOnly(interval.start);
    final endDate = _dateOnly(interval.end);
    final firstOff = endDate.isAfter(startDate) ? '2400' : _time(interval.end);

    final firstRow = CtrTimeRow(
      remarksNo: _rowRemarks(entry),
      employeeName: entry.name,
      classification: entry.position,
      firstDate: _date(startDate),
      firstOn: _time(interval.start),
      firstOff: firstOff,
    );

    if (!endDate.isAfter(startDate)) {
      return [firstRow];
    }

    return [
      firstRow,
      CtrTimeRow(
        remarksNo: '',
        employeeName: '',
        classification: '',
        secondDate: _date(endDate),
        secondOn: '0000',
        secondOff: _time(interval.end),
        isContinuation: true,
      ),
    ];
  }

  _CtrInterval? _personnelInterval(
    OF297ShiftTicket ticket,
    OF297PersonnelTimeEntry entry,
  ) {
    final start = entry.startTime ?? entry.guaranteeStartTime;
    final stop = entry.stopTime ?? entry.guaranteeStopTime;
    if (start != null && stop != null) {
      return _CtrInterval(start: start, end: _adjustEnd(start, stop));
    }

    return _globalInterval(ticket);
  }

  _CtrInterval? _globalInterval(OF297ShiftTicket ticket) {
    final date = ticket.globalShiftDate ?? ticket.shiftStart;
    if (date == null) return null;

    final startMinutes = _militaryMinutes(
          ticket.globalBlock1Start,
        ) ??
        _militaryMinutes(ticket.globalBlock2Start);
    final stopMinutes = _militaryMinutes(
          ticket.globalBlock2Stop,
        ) ??
        _militaryMinutes(ticket.globalBlock1Stop);
    if (startMinutes == null || stopMinutes == null) return null;

    final start = _dateOnly(date).add(Duration(minutes: startMinutes));
    var end = _dateOnly(date).add(Duration(minutes: stopMinutes));
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    return _CtrInterval(start: start, end: end);
  }

  DateTime _adjustEnd(DateTime start, DateTime stop) {
    if (stop.isBefore(start) || stop.isAtSameMomentAs(start)) {
      return stop.add(const Duration(days: 1));
    }
    return stop;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int? _militaryMinutes(String value) {
    final text = value.trim();
    if (text.length != 4) return null;

    final hour = int.tryParse(text.substring(0, 2));
    final minute = int.tryParse(text.substring(2, 4));
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  String _time(DateTime? value) {
    if (value == null) return '';
    return DateFormat('HHmm').format(value);
  }

  List<String> _splitRemarks(String value, int maxLines, int lineLength) {
    if (value.isEmpty) return const [];
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final explicitLines = normalized.split('\n');
    final lines = <String>[];

    for (final explicitLine in explicitLines) {
      if (explicitLine.isEmpty) {
        lines.add('');
      } else {
        for (var start = 0; start < explicitLine.length; start += lineLength) {
          final end = start + lineLength > explicitLine.length
              ? explicitLine.length
              : start + lineLength;
          lines.add(explicitLine.substring(start, end));
          if (lines.length == maxLines) return lines;
        }
      }
      if (lines.length == maxLines) return lines;
    }

    return lines.take(maxLines).toList(growable: false);
  }

  String _fileName(OF297ShiftTicket ticket) {
    return 'CTR_${_sanitizeFileName(ticket.incidentName)}_'
        '${_sanitizeFileName(ticket.id)}.pdf';
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'ticket' : sanitized;
  }
}
