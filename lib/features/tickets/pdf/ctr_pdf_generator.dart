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

class _CtrRawBlock {
  final int blockIndex;
  final DateTime start;
  final DateTime end;

  const _CtrRawBlock({
    required this.blockIndex,
    required this.start,
    required this.end,
  });
}

class _CtrDateSegment {
  final int blockIndex;
  final DateTime date;
  final DateTime start;
  final String on;
  final String off;

  const _CtrDateSegment({
    required this.blockIndex,
    required this.date,
    required this.start,
    required this.on,
    required this.off,
  });
}

class _CtrEmployeeBlock {
  final String employeeName;
  final String classification;
  final String remarksNo;
  final List<_CtrRawBlock> rawBlocks;

  const _CtrEmployeeBlock({
    required this.employeeName,
    required this.classification,
    required this.remarksNo,
    required this.rawBlocks,
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
      final officerSignatureBox = _officerSignatureBox(document);

      document.form.flattenAllFields();
      await _drawSignatures(document, ticket, officerSignatureBox);

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
      _supervisorTitle(ticket),
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
    Rect officerSignatureBox,
  ) async {
    final supervisorSignature = ticket.supervisorSignature;
    if (supervisorSignature != null) {
      await _signatureDrawer.drawSignature(
        page: document.pages[0],
        signature: supervisorSignature,
        box: officerSignatureBox,
      );
    }

    // Box 14 is a printed-name field, not a signature box. Do not draw the
    // operator/contractor signature unless the official CTR template adds a
    // separate operator signature area.
  }

  Rect _officerSignatureBox(PdfDocument document) {
    final field = _fieldByName(document, '12 OFFICER-IN-CHARGE Signature');
    final bounds =
        field?.bounds ?? const Rect.fromLTWH(14.8, 497.5, 161.4, 13.4);
    return Rect.fromLTWH(
      bounds.left,
      bounds.top - 5,
      bounds.width,
      bounds.height + 10,
    );
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

  String _supervisorTitle(OF297ShiftTicket ticket) {
    return ticket.supervisorSignature?.signerTitle ?? '';
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
    final employeeBlocks = <_CtrEmployeeBlock>[];
    final employeeIndexes = <String, int>{};
    final visibleDates = <DateTime>[];

    for (final entry in ticket.personnelEntries) {
      if (entry.name.trim().isEmpty && entry.position.trim().isEmpty) continue;

      final rawBlocks = _personnelRawBlocks(ticket, entry);
      final key = _employeeKey(entry);
      final existingIndex = employeeIndexes[key];
      if (existingIndex == null) {
        employeeIndexes[key] = employeeBlocks.length;
        employeeBlocks.add(
          _CtrEmployeeBlock(
            remarksNo: _rowRemarks(entry),
            employeeName: entry.name,
            classification: entry.position,
            rawBlocks: rawBlocks,
          ),
        );
      } else {
        employeeBlocks[existingIndex].rawBlocks.addAll(rawBlocks);
      }

      for (final rawBlock in rawBlocks) {
        for (final segment in _splitRawBlockByDate(rawBlock)) {
          if (!visibleDates.any((date) => _sameDate(date, segment.date))) {
            visibleDates.add(segment.date);
          }
          if (visibleDates.length == 2) break;
        }
      }
    }

    final rows = <CtrTimeRow>[];
    for (final block in employeeBlocks) {
      _logEmployeeBlock(block);
      rows.addAll(_rowsForEmployeeBlock(block, visibleDates));
    }
    return rows;
  }

  List<CtrTimeRow> _rowsForEmployeeBlock(
    _CtrEmployeeBlock block,
    List<DateTime> visibleDates,
  ) {
    final groupedSegments = <String, List<_CtrDateSegment>>{};
    for (final rawBlock in block.rawBlocks) {
      for (final segment in _splitRawBlockByDate(rawBlock)) {
        final key = _date(segment.date);
        groupedSegments.putIfAbsent(key, () => []).add(segment);
      }
    }
    for (final segments in groupedSegments.values) {
      segments.sort((left, right) {
        final startComparison = left.start.compareTo(right.start);
        if (startComparison != 0) return startComparison;
        return left.blockIndex.compareTo(right.blockIndex);
      });
    }

    final firstDate = visibleDates.isNotEmpty ? visibleDates[0] : null;
    final secondDate = visibleDates.length > 1 ? visibleDates[1] : null;
    final firstDateSegments = firstDate == null
        ? const <_CtrDateSegment>[]
        : groupedSegments[_date(firstDate)] ?? const <_CtrDateSegment>[];
    final secondDateSegments = secondDate == null
        ? const <_CtrDateSegment>[]
        : groupedSegments[_date(secondDate)] ?? const <_CtrDateSegment>[];

    return [
      CtrTimeRow(
        remarksNo: block.remarksNo,
        employeeName: block.employeeName,
        classification: block.classification,
        firstDate: firstDateSegments.isEmpty ? '' : _date(firstDate),
        firstOn: firstDateSegments.isEmpty ? '' : firstDateSegments[0].on,
        firstOff: firstDateSegments.isEmpty ? '' : firstDateSegments[0].off,
        secondDate: secondDateSegments.isEmpty ? '' : _date(secondDate),
        secondOn: secondDateSegments.isEmpty ? '' : secondDateSegments[0].on,
        secondOff: secondDateSegments.isEmpty ? '' : secondDateSegments[0].off,
      ),
      CtrTimeRow(
        remarksNo: '',
        employeeName: '',
        classification: '',
        firstDate: firstDateSegments.length < 2 ? '' : _date(firstDate),
        firstOn: firstDateSegments.length < 2 ? '' : firstDateSegments[1].on,
        firstOff: firstDateSegments.length < 2 ? '' : firstDateSegments[1].off,
        secondDate: secondDateSegments.length < 2 ? '' : _date(secondDate),
        secondOn: secondDateSegments.length < 2 ? '' : secondDateSegments[1].on,
        secondOff:
            secondDateSegments.length < 2 ? '' : secondDateSegments[1].off,
        isContinuation: true,
      ),
    ];
  }

  String _employeeKey(OF297PersonnelTimeEntry entry) {
    final name = entry.name.trim().toLowerCase();
    final position = entry.position.trim().toLowerCase();
    return '$name|$position';
  }

  void _logEmployeeBlock(_CtrEmployeeBlock block) {
    final buffer = StringBuffer('CTR EMPLOYEE: ${block.employeeName}');
    for (final rawBlock in block.rawBlocks) {
      buffer.writeln();
      buffer.write(
        'RAW BLOCK ${rawBlock.blockIndex}: '
        '${_date(rawBlock.start)} ${_time(rawBlock.start)}-${_time(rawBlock.end)}',
      );
    }
    buffer.writeln();
    buffer.write('SPLIT SEGMENTS:');
    for (final row
        in _rowsForEmployeeBlock(block, _visibleDatesForBlock(block))) {
      if (row.firstOn.isNotEmpty || row.firstOff.isNotEmpty) {
        buffer.writeln();
        buffer.write(
          '${row.firstDate} ${row.isContinuation ? 'rowB' : 'rowA'} '
          '${row.firstOn}-${row.firstOff}',
        );
      }
      if (row.secondOn.isNotEmpty || row.secondOff.isNotEmpty) {
        buffer.writeln();
        buffer.write(
          '${row.secondDate} ${row.isContinuation ? 'rowB' : 'rowA'} '
          '${row.secondOn}-${row.secondOff}',
        );
      }
    }
    developer.log(buffer.toString(), name: 'CtrPdfGenerator');
  }

  List<DateTime> _visibleDatesForBlock(_CtrEmployeeBlock block) {
    final dates = <DateTime>[];
    for (final rawBlock in block.rawBlocks) {
      for (final segment in _splitRawBlockByDate(rawBlock)) {
        if (!dates.any((date) => _sameDate(date, segment.date))) {
          dates.add(segment.date);
        }
        if (dates.length == 2) return dates;
      }
    }
    return dates;
  }

  List<_CtrDateSegment> _splitRawBlockByDate(_CtrRawBlock rawBlock) {
    final segments = <_CtrDateSegment>[];
    var cursor = rawBlock.start;
    while (cursor.isBefore(rawBlock.end)) {
      final cursorDate = _dateOnly(cursor);
      final nextMidnight = cursorDate.add(const Duration(days: 1));
      final segmentEnd =
          rawBlock.end.isBefore(nextMidnight) ? rawBlock.end : nextMidnight;
      if (segmentEnd.isAfter(cursor)) {
        segments.add(
          _CtrDateSegment(
            blockIndex: rawBlock.blockIndex,
            date: cursorDate,
            start: cursor,
            on: _time(cursor),
            off: segmentEnd.isAtSameMomentAs(nextMidnight)
                ? '2400'
                : _time(segmentEnd),
          ),
        );
      }
      cursor = segmentEnd;
    }
    return segments;
  }

  bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  List<_CtrRawBlock> _personnelRawBlocks(
    OF297ShiftTicket ticket,
    OF297PersonnelTimeEntry entry,
  ) {
    final rawBlocks = <_CtrRawBlock>[];
    if (entry.guaranteeStartTime != null && entry.guaranteeStopTime != null) {
      rawBlocks.add(
        _CtrRawBlock(
          blockIndex: 1,
          start: entry.guaranteeStartTime!,
          end: _adjustEnd(entry.guaranteeStartTime!, entry.guaranteeStopTime!),
        ),
      );
    }
    if (entry.startTime != null && entry.stopTime != null) {
      rawBlocks.add(
        _CtrRawBlock(
          blockIndex: 2,
          start: entry.startTime!,
          end: _adjustEnd(entry.startTime!, entry.stopTime!),
        ),
      );
    }

    return rawBlocks.isNotEmpty ? rawBlocks : _globalRawBlocks(ticket);
  }

  List<_CtrRawBlock> _globalRawBlocks(OF297ShiftTicket ticket) {
    final date = ticket.globalShiftDate ?? ticket.shiftStart;
    if (date == null) return const [];

    final rawBlocks = <_CtrRawBlock>[];
    void addGlobalBlock(int blockIndex, String startValue, String stopValue) {
      final startMinutes = _militaryMinutes(startValue);
      final stopMinutes = _militaryMinutes(stopValue);
      if (startMinutes == null || stopMinutes == null) return;

      final start = _dateOnly(date).add(Duration(minutes: startMinutes));
      var end = _dateOnly(date).add(Duration(minutes: stopMinutes));
      if (!end.isAfter(start)) {
        end = end.add(const Duration(days: 1));
      }
      rawBlocks.add(
        _CtrRawBlock(
          blockIndex: blockIndex,
          start: start,
          end: end,
        ),
      );
    }

    addGlobalBlock(1, ticket.globalBlock1Start, ticket.globalBlock1Stop);
    addGlobalBlock(2, ticket.globalBlock2Start, ticket.globalBlock2Stop);
    return rawBlocks;
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
    final date = DateFormat('yyyy-MM-dd').format(
      _dateOnly(
        ticket.globalShiftDate ?? ticket.shiftStart ?? ticket.createdAt,
      ),
    );
    return 'CTR_${_sanitizeFileName(ticket.incidentName)}_'
        '$date.pdf';
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return sanitized.isEmpty ? 'ticket' : sanitized;
  }
}
