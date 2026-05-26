import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_field_map.dart';

/// Generates printable OF-297 PDFs from finalized ticket data.
///
/// The Flutter ticket remains the source of truth. The official PDF is treated
/// only as a finalized export layer so users cannot accidentally bypass review,
/// signatures, or immutable finalization rules.
class Of297PdfGenerator {
  Future<Uint8List> generateFinalizedPdf(OF297ShiftTicket ticket) async {
    if (!ticket.isFinalized) {
      throw StateError('Only finalized OF-297 tickets can be exported to PDF.');
    }

    final templateData =
        await rootBundle.load(Of297PdfFieldMap.templateAssetPath);
    final document = PdfDocument(
      inputBytes: templateData.buffer.asUint8List(),
    );

    try {
      _fillTopSection(document, ticket);
      _fillEquipmentRows(document, ticket);
      _fillPersonnelRows(document, ticket);
      _fillBottomSection(document, ticket);
      final signatureBoxes = _signatureBoxes(document);

      // Flattening makes the exported billing record stable/read-only.
      // TODO: verify flattened output formatting with real agency billing workflows.
      document.form.flattenAllFields();

      _drawSignatures(document, ticket, signatureBoxes);

      final bytes = document.saveSync();
      return Uint8List.fromList(bytes);
    } finally {
      document.dispose();
    }
  }

  void _fillTopSection(PdfDocument document, OF297ShiftTicket ticket) {
    setTextField(
        document, Of297PdfFieldMap.agreementNumber, ticket.agreementNumber);
    setTextField(
        document, Of297PdfFieldMap.contractorName, ticket.contractorName);
    setTextField(
      document,
      Of297PdfFieldMap.resourceOrderNumber,
      ticket.resourceOrderNumber,
    );
    setTextField(document, Of297PdfFieldMap.incidentName, ticket.incidentName);
    setTextField(
        document, Of297PdfFieldMap.incidentNumber, ticket.incidentNumber);
    setTextField(
        document, Of297PdfFieldMap.financialCode, ticket.financialCode);
    setTextField(
      document,
      Of297PdfFieldMap.equipmentMakeModel,
      ticket.equipmentMakeModel,
    );
    setTextField(
        document, Of297PdfFieldMap.equipmentType, ticket.equipmentType);
    setTextField(
        document, Of297PdfFieldMap.serialVinNumber, ticket.serialVinNumber);
    setTextField(document, Of297PdfFieldMap.equipmentId, ticket.equipmentId);

    setCheckbox(
      document,
      Of297PdfFieldMap.transportRetainedYes,
      ticket.transportRetained,
    );
    setCheckbox(
      document,
      Of297PdfFieldMap.transportRetainedNo,
      !ticket.transportRetained,
    );
    setCheckbox(
      document,
      Of297PdfFieldMap.mobilization,
      ticket.isMobilization == true,
    );
    setCheckbox(
      document,
      Of297PdfFieldMap.demobilization,
      ticket.isMobilization == false,
    );
    setCheckbox(document, Of297PdfFieldMap.rateHours, ticket.rateIsHours);
    setCheckbox(document, Of297PdfFieldMap.rateMiles, ticket.rateIsMiles);
  }

  void _fillEquipmentRows(PdfDocument document, OF297ShiftTicket ticket) {
    for (var i = 0; i < ticket.equipmentEntries.length && i < 4; i++) {
      final row = i + 1;
      final entry = ticket.equipmentEntries[i];
      setTextField(
          document, Of297PdfFieldMap.equipmentDate(row), _date(entry.date));
      setTextField(
        document,
        Of297PdfFieldMap.equipmentStart(row),
        ticket.rateIsMiles
            ? _nullableNumber(entry.mileageStart)
            : _time(entry.startTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentStop(row),
        ticket.rateIsMiles
            ? _nullableNumber(entry.mileageEnd)
            : _time(entry.stopTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentTotal(row),
        ticket.rateIsMiles
            ? _number(entry.totalMiles)
            : _number(entry.totalHours),
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentQuantity(row),
        _number(entry.specialRateQuantity),
      );
      setTextField(
          document, Of297PdfFieldMap.equipmentRateType(row), entry.rateType);
      setTextField(document, Of297PdfFieldMap.equipmentNotes(row), entry.notes);
    }
  }

  void _fillPersonnelRows(PdfDocument document, OF297ShiftTicket ticket) {
    for (var i = 0; i < ticket.personnelEntries.length && i < 4; i++) {
      final row = i + 1;
      final entry = ticket.personnelEntries[i];
      setTextField(
          document, Of297PdfFieldMap.personnelDate(row), _date(entry.date));
      setTextField(document, Of297PdfFieldMap.personnelName(row), entry.name);
      setTextField(
        document,
        Of297PdfFieldMap.personnelStartOne(row),
        _time(entry.guaranteeStartTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStopOne(row),
        _time(entry.guaranteeStopTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStartTwo(row),
        _time(entry.startTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStopTwo(row),
        _time(entry.stopTime),
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelTotal(row),
        _number(entry.totalHours),
      );
      setTextField(document, Of297PdfFieldMap.personnelNotes(row), entry.notes);
    }
  }

  void _fillBottomSection(PdfDocument document, OF297ShiftTicket ticket) {
    setTextField(document, Of297PdfFieldMap.remarks, ticket.remarks);
    setTextField(
      document,
      Of297PdfFieldMap.contractorRepresentativeName,
      ticket.contractorRepresentativeName.isEmpty
          ? ticket.contractorSignature?.signerName ?? ''
          : ticket.contractorRepresentativeName,
    );
    setTextField(
      document,
      Of297PdfFieldMap.supervisorName,
      ticket.incidentSupervisorName.isEmpty
          ? ticket.supervisorSignature?.signerName ?? ''
          : ticket.incidentSupervisorName,
    );
  }

  Map<String, Rect> _signatureBoxes(PdfDocument document) {
    return {
      Of297PdfFieldMap.contractorSignature:
          _fieldByName(document, Of297PdfFieldMap.contractorSignature)
                  ?.bounds ??
              const Rect.fromLTWH(315, 345, 250, 42),
      Of297PdfFieldMap.supervisorSignature:
          _fieldByName(document, Of297PdfFieldMap.supervisorSignature)
                  ?.bounds ??
              const Rect.fromLTWH(315, 372, 250, 42),
    };
  }

  void _drawSignatures(
    PdfDocument document,
    OF297ShiftTicket ticket,
    Map<String, Rect> signatureBoxes,
  ) {
    final page = document.pages[0];

    // TODO: fine-tune these coordinates after visual testing against the
    // official OF297-24.pdf. Signature placement depends on PDF page coordinate
    // bounds, and the debug helper should be used first if alignment drifts.
    final contractorSignature = ticket.contractorSignature;
    if (contractorSignature != null) {
      drawSignature(
        page: page,
        signature: contractorSignature,
        box: signatureBoxes[Of297PdfFieldMap.contractorSignature]!,
      );
    }

    final supervisorSignature = ticket.supervisorSignature;
    if (supervisorSignature != null) {
      drawSignature(
        page: page,
        signature: supervisorSignature,
        box: signatureBoxes[Of297PdfFieldMap.supervisorSignature]!,
      );
    }
  }

  Future<void> drawSignature({
    required PdfPage page,
    required OF297Signature signature,
    required Rect box,
  }) async {
    _drawSignature(
      page: page,
      signature: signature,
      box: box,
    );
  }

  void _drawSignature({
    required PdfPage page,
    required OF297Signature signature,
    required Rect box,
  }) {
    if (signature.signatureBytesBase64.isEmpty) return;

    final imageBytes = _cropSignatureWhitespace(
      base64Decode(signature.signatureBytesBase64),
    );
    final image = PdfBitmap(imageBytes);
    const padding = 0.5;
    final target = Rect.fromLTWH(
      box.left + padding,
      box.top + padding,
      math.max(1, box.width - padding * 2),
      math.max(1, box.height - padding * 2),
    );
    final imageRatio = image.width / image.height;
    final targetRatio = target.width / target.height;
    final drawWidth =
        imageRatio > targetRatio ? target.width : target.height * imageRatio;
    final drawHeight =
        imageRatio > targetRatio ? target.width / imageRatio : target.height;
    final drawRect = Rect.fromLTWH(
      target.left + (target.width - drawWidth) / 2,
      target.top + (target.height - drawHeight) / 2,
      drawWidth,
      drawHeight,
    );

    // Signature PNGs are captured from a touch canvas, then scaled down into a
    // narrow official PDF cell. Drawing the same bitmap with tiny offsets keeps
    // anti-aliased strokes readable without changing placement or the source
    // signature data.
    const strokeBoost = 0.65;
    for (final offset in _signatureStrokeOffsets(strokeBoost)) {
      page.graphics.drawImage(image, drawRect.shift(offset));
    }
  }

  List<Offset> _signatureStrokeOffsets(double amount) {
    return [
      Offset.zero,
      Offset(amount, 0),
      Offset(-amount, 0),
      Offset(0, amount),
      Offset(0, -amount),
      Offset(amount, amount),
      Offset(-amount, -amount),
    ];
  }

  Uint8List _cropSignatureWhitespace(Uint8List imageBytes) {
    final decodedImage = img.decodePng(imageBytes);
    if (decodedImage == null) {
      return imageBytes;
    }

    var left = decodedImage.width;
    var top = decodedImage.height;
    var right = -1;
    var bottom = -1;

    for (var y = 0; y < decodedImage.height; y++) {
      for (var x = 0; x < decodedImage.width; x++) {
        if (_isSignatureInk(decodedImage.getPixel(x, y))) {
          left = math.min(left, x);
          top = math.min(top, y);
          right = math.max(right, x);
          bottom = math.max(bottom, y);
        }
      }
    }

    if (right < left || bottom < top) {
      return imageBytes;
    }

    // The signature pad stores the full canvas. Cropping the blank margin lets
    // the handwriting fill more of the official cell without overflowing it.
    const margin = 4;
    final cropLeft = math.max(0, left - margin);
    final cropTop = math.max(0, top - margin);
    final cropRight = math.min(decodedImage.width - 1, right + margin);
    final cropBottom = math.min(decodedImage.height - 1, bottom + margin);
    final croppedImage = img.copyCrop(
      decodedImage,
      x: cropLeft,
      y: cropTop,
      width: cropRight - cropLeft + 1,
      height: cropBottom - cropTop + 1,
    );

    return Uint8List.fromList(img.encodePng(croppedImage));
  }

  bool _isSignatureInk(img.Pixel pixel) {
    final alpha = pixel.a.toDouble();
    final luminance = pixel.r.toDouble() * 0.299 +
        pixel.g.toDouble() * 0.587 +
        pixel.b.toDouble() * 0.114;

    return alpha > 12 && luminance < 245;
  }

  void setTextField(PdfDocument document, String fieldName, String value) {
    if (value.isEmpty) return;

    final field = _fieldByName(document, fieldName);
    if (field is PdfTextBoxField) {
      field.text = value;
    } else if (field == null) {
      _warnMissingField(fieldName);
    } else {
      _warnWrongFieldType(fieldName, field);
    }
  }

  void setCheckbox(PdfDocument document, String fieldName, bool value) {
    final field = _fieldByName(document, fieldName);
    if (field is PdfCheckBoxField) {
      field.isChecked = value;
    } else if (field == null) {
      _warnMissingField(fieldName);
    } else {
      _warnWrongFieldType(fieldName, field);
    }
  }

  PdfField? _fieldByName(PdfDocument document, String fieldName) {
    // TODO: inspect actual PDF field names and update Of297PdfFieldMap if the
    // official template changes between revisions.
    for (var i = 0; i < document.form.fields.count; i++) {
      final field = document.form.fields[i];
      final actualName = field.name ?? '';
      if (_fieldNameMatches(actualName, fieldName)) {
        return field;
      }
    }
    return null;
  }

  bool _fieldNameMatches(String actualName, String expectedName) {
    final actual = _normalizeFieldName(actualName);
    final expected = _normalizeFieldName(expectedName);
    return actual == expected ||
        actual.endsWith('.$expected') ||
        actual.endsWith(expected);
  }

  String _normalizeFieldName(String name) {
    return name.replaceAll(RegExp(r'\[\d+\]'), '');
  }

  void _warnMissingField(String fieldName) {
    developer.log(
      'OF-297 PDF field missing: $fieldName. '
      'If values still do not appear, inspect actual fields/bounds from OF297-24.pdf.',
      name: 'Of297PdfGenerator',
    );
  }

  void _warnWrongFieldType(String fieldName, PdfField field) {
    developer.log(
      'OF-297 PDF field "$fieldName" was ${field.runtimeType}, not the expected type.',
      name: 'Of297PdfGenerator',
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '';
    return DateFormat('MM/dd/yyyy').format(value);
  }

  String _time(DateTime? value) {
    if (value == null) return '';
    return DateFormat('HHmm').format(value);
  }

  String _number(double value) {
    if (value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _nullableNumber(double? value) {
    if (value == null || value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}
