import 'package:intl/intl.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/utils/shift_ticket_time.dart';

class Of297ExportDocument {
  final DateTime workDate;
  final String incidentName;
  final String suffix;
  final List<Of297ExportPersonnelRow> personnelRows;
  final List<Of297ExportEquipmentRow> equipmentRows;

  const Of297ExportDocument({
    required this.workDate,
    required this.incidentName,
    required this.suffix,
    required this.personnelRows,
    required this.equipmentRows,
  });

  String get fileName {
    final date = DateFormat('yyyy-MM-dd').format(workDate);
    return 'OF297_${_sanitizeFileName(incidentName)}_${date}_$suffix.pdf';
  }
}

class Of297ExportPersonnelRow {
  final OF297PersonnelTimeEntry source;
  final String date;
  final String block1Start;
  final String block1Stop;
  final String block2Start;
  final String block2Stop;
  final double totalHours;

  const Of297ExportPersonnelRow({
    required this.source,
    required this.date,
    required this.block1Start,
    required this.block1Stop,
    required this.block2Start,
    required this.block2Stop,
    required this.totalHours,
  });
}

class Of297ExportEquipmentRow {
  final OF297EquipmentTimeEntry source;
  final String date;
  final String start;
  final String stop;
  final double totalHours;

  const Of297ExportEquipmentRow({
    required this.source,
    required this.date,
    required this.start,
    required this.stop,
    required this.totalHours,
  });
}

List<Of297ExportDocument> buildOf297ExportDocuments(
  OF297ShiftTicket ticket,
) {
  final workDate = _dateOnly(
    ticket.globalShiftDate ??
        _firstEntryDate(ticket) ??
        ticket.shiftStart ??
        ticket.createdAt,
  );
  final dateSegments = _dateSegments(ticket, workDate);
  final personnelRows = ticket.personnelEntries
      .where((entry) => entry.name.trim().isNotEmpty)
      .toList();
  final personnelChunks = _chunkPersonnelRows(personnelRows);
  final continuationCount = personnelChunks.length;
  final documents = <Of297ExportDocument>[];

  for (final date in dateSegments) {
    final suffixes = _suffixes(continuationCount);
    for (var i = 0; i < continuationCount; i++) {
      documents.add(
        Of297ExportDocument(
          workDate: date,
          incidentName: ticket.incidentName,
          suffix: suffixes[i],
          personnelRows: personnelChunks[i]
              .map((entry) => _personnelRowForDate(ticket, entry, date))
              .where((row) => row.totalHours > 0)
              .toList(),
          equipmentRows: _equipmentRowsForDate(ticket, date),
        ),
      );
    }
  }

  return documents;
}

List<DateTime> _dateSegments(OF297ShiftTicket ticket, DateTime workDate) {
  final intervals = [
    ..._globalIntervals(ticket, workDate),
    for (final entry in ticket.equipmentEntries) ..._equipmentIntervals(entry),
    for (final entry in ticket.personnelEntries)
      ..._personnelIntervals(ticket, entry),
  ];
  if (intervals.isEmpty) return [workDate];

  final dates = <DateTime>{};
  for (final interval in intervals) {
    var cursor = _dateOnly(interval.start);
    final lastDate = _dateOnly(
      interval.end.subtract(const Duration(microseconds: 1)),
    );
    while (!cursor.isAfter(lastDate)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  final sortedDates = dates.toList()..sort();
  return sortedDates.isEmpty ? [workDate] : sortedDates;
}

List<_GlobalInterval> _globalIntervals(
  OF297ShiftTicket ticket,
  DateTime workDate,
) {
  final intervals = <_GlobalInterval>[];
  final block1 = _buildInterval(
    workDate,
    ticket.globalBlock1Start,
    ticket.globalBlock1Stop,
    1,
  );
  final block2 = _buildInterval(
    workDate,
    ticket.globalBlock2Start,
    ticket.globalBlock2Stop,
    2,
  );

  if (block1 != null) intervals.add(block1);
  if (block2 != null) intervals.add(block2);

  if (intervals.isEmpty &&
      ticket.shiftStart != null &&
      ticket.shiftEnd != null) {
    intervals.add(
      _GlobalInterval(
        blockNumber: 1,
        start: ticket.shiftStart!,
        end: ticket.shiftEnd!.isBefore(ticket.shiftStart!)
            ? ticket.shiftEnd!.add(const Duration(days: 1))
            : ticket.shiftEnd!,
      ),
    );
  }

  return intervals;
}

_GlobalInterval? _buildInterval(
  DateTime workDate,
  String startValue,
  String stopValue,
  int blockNumber,
) {
  final startMinutes = parseMilitaryTimeMinutes(startValue);
  final stopMinutes = parseMilitaryTimeMinutes(stopValue);
  if (startMinutes == null || stopMinutes == null) return null;

  final start = workDate.add(Duration(minutes: startMinutes));
  var end = workDate.add(Duration(minutes: stopMinutes));
  if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
    end = end.add(const Duration(days: 1));
  }

  return _GlobalInterval(
    blockNumber: blockNumber,
    start: start,
    end: end,
  );
}

DateTime _adjustEnd(DateTime start, DateTime stop) {
  if (stop.isBefore(start) || stop.isAtSameMomentAs(start)) {
    return stop.add(const Duration(days: 1));
  }
  return stop;
}

Of297ExportPersonnelRow _personnelRowForDate(
  OF297ShiftTicket ticket,
  OF297PersonnelTimeEntry entry,
  DateTime date,
) {
  final blockTexts = <int, _SegmentText>{};
  final intervals = _personnelIntervals(ticket, entry);
  final sourceIntervals = intervals.isNotEmpty
      ? intervals
      : _globalIntervals(ticket, _baseDateForEntry(ticket, entry));
  for (final interval in sourceIntervals) {
    final segment = _segmentTextForDate(interval.start, interval.end, date);
    if (segment != null) {
      blockTexts[interval.blockNumber] = segment;
    }
  }

  final block1 = blockTexts[1] ?? _SegmentText.empty;
  final block2 = blockTexts[2] ?? _SegmentText.empty;
  return Of297ExportPersonnelRow(
    source: entry,
    date: _displayDate(date),
    block1Start: block1.start,
    block1Stop: block1.stop,
    block2Start: block2.start,
    block2Stop: block2.stop,
    totalHours: block1.hours + block2.hours,
  );
}

List<_GlobalInterval> _personnelIntervals(
  OF297ShiftTicket ticket,
  OF297PersonnelTimeEntry entry,
) {
  final intervals = <_GlobalInterval>[];
  if (entry.guaranteeStartTime != null && entry.guaranteeStopTime != null) {
    intervals.add(
      _GlobalInterval(
        blockNumber: 1,
        start: entry.guaranteeStartTime!,
        end: _adjustEnd(entry.guaranteeStartTime!, entry.guaranteeStopTime!),
      ),
    );
  }
  if (entry.startTime != null && entry.stopTime != null) {
    intervals.add(
      _GlobalInterval(
        blockNumber: 2,
        start: entry.startTime!,
        end: _adjustEnd(entry.startTime!, entry.stopTime!),
      ),
    );
  }

  return intervals;
}

List<Of297ExportEquipmentRow> _equipmentRowsForDate(
  OF297ShiftTicket ticket,
  DateTime date,
) {
  final rows = <Of297ExportEquipmentRow>[];
  for (final entry in ticket.equipmentEntries) {
    if (!_hasEquipmentContent(ticket, entry)) continue;

    final segment = _equipmentSegmentFromEntry(entry, date);
    if (segment == null || segment.hours <= 0) continue;

    rows.add(
      Of297ExportEquipmentRow(
        source: entry,
        date: _displayDate(date),
        start: segment.start,
        stop: segment.stop,
        totalHours: segment.hours,
      ),
    );
  }

  return rows;
}

List<_GlobalInterval> _equipmentIntervals(OF297EquipmentTimeEntry entry) {
  final start = entry.startTime;
  final stop = entry.stopTime;
  if (start == null || stop == null) return const [];

  return [
    _GlobalInterval(
      blockNumber: 1,
      start: start,
      end: _adjustEnd(start, stop),
    ),
  ];
}

_SegmentText? _equipmentSegmentFromEntry(
  OF297EquipmentTimeEntry entry,
  DateTime date,
) {
  final start = entry.startTime;
  final stop = entry.stopTime;
  if (start == null || stop == null) return null;
  return _segmentTextForDate(start, _adjustEnd(start, stop), date);
}

_SegmentText? _segmentTextForDate(DateTime start, DateTime end, DateTime date) {
  final dayStart = _dateOnly(date);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final segmentStart = start.isAfter(dayStart) ? start : dayStart;
  final segmentEnd = end.isBefore(dayEnd) ? end : dayEnd;
  if (!segmentEnd.isAfter(segmentStart)) return null;

  return _SegmentText(
    start: _formatSegmentTime(segmentStart),
    stop: segmentEnd.isAtSameMomentAs(dayEnd)
        ? '2400'
        : _formatSegmentTime(segmentEnd),
    hours: segmentEnd.difference(segmentStart).inMinutes / 60,
  );
}

String _formatSegmentTime(DateTime value) {
  return DateFormat('HHmm').format(value);
}

List<List<OF297PersonnelTimeEntry>> _chunkPersonnelRows(
  List<OF297PersonnelTimeEntry> rows,
) {
  if (rows.isEmpty) return const [[]];

  final chunks = <List<OF297PersonnelTimeEntry>>[];
  for (var i = 0; i < rows.length; i += 4) {
    final end = i + 4 > rows.length ? rows.length : i + 4;
    chunks.add(rows.sublist(i, end));
  }
  return chunks;
}

List<String> _suffixes(int count) {
  return List.generate(count, (index) => String.fromCharCode(65 + index));
}

String _sanitizeFileName(String value) {
  final sanitized = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return sanitized.isEmpty ? 'Incident' : sanitized;
}

DateTime _baseDateForEntry(
  OF297ShiftTicket ticket,
  OF297PersonnelTimeEntry entry,
) {
  return _dateOnly(entry.date ?? ticket.globalShiftDate ?? ticket.createdAt);
}

DateTime? _firstEntryDate(OF297ShiftTicket ticket) {
  for (final entry in ticket.equipmentEntries) {
    if (entry.date != null) return entry.date;
  }
  for (final entry in ticket.personnelEntries) {
    if (entry.date != null) return entry.date;
  }
  return null;
}

bool _hasEquipmentContent(
  OF297ShiftTicket ticket,
  OF297EquipmentTimeEntry entry,
) {
  if (ticket.rateIsMiles) {
    return entry.date != null ||
        entry.mileageStart != null ||
        entry.mileageEnd != null ||
        entry.totalMiles > 0 ||
        entry.specialRateQuantity > 0 ||
        entry.rateType.trim().isNotEmpty ||
        entry.notes.trim().isNotEmpty;
  }

  return entry.date != null ||
      entry.startTime != null ||
      entry.stopTime != null ||
      entry.totalHours > 0 ||
      entry.specialRateQuantity > 0 ||
      entry.rateType.trim().isNotEmpty ||
      entry.notes.trim().isNotEmpty;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _displayDate(DateTime value) {
  return DateFormat('MM/dd/yyyy').format(value);
}

class _GlobalInterval {
  final int blockNumber;
  final DateTime start;
  final DateTime end;

  const _GlobalInterval({
    required this.blockNumber,
    required this.start,
    required this.end,
  });
}

class _SegmentText {
  static const empty = _SegmentText(start: '', stop: '', hours: 0);

  final String start;
  final String stop;
  final double hours;

  const _SegmentText({
    required this.start,
    required this.stop,
    required this.hours,
  });
}
