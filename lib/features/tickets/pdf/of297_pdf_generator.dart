import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_signature.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_export_document.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_field_map.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/pdf_byte_utils.dart';

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

    return _generatePdf(ticket,
        exportDocument: buildOf297ExportDocuments(ticket).first);
  }

  Future<Uint8List> generatePreviewPdf(OF297ShiftTicket ticket) async {
    return _generatePdf(ticket,
        exportDocument: buildOf297ExportDocuments(ticket).first);
  }

  Future<Uint8List> generateFinalizedPdfForDocument(
    OF297ShiftTicket ticket,
    Of297ExportDocument exportDocument,
  ) async {
    if (!ticket.isFinalized) {
      throw StateError('Only finalized OF-297 tickets can be exported to PDF.');
    }

    return _generatePdf(ticket, exportDocument: exportDocument);
  }

  Future<Uint8List> generatePreviewPdfForDocument(
    OF297ShiftTicket ticket,
    Of297ExportDocument exportDocument,
  ) {
    return _generatePdf(ticket, exportDocument: exportDocument);
  }

  Future<Uint8List> _generatePdf(
    OF297ShiftTicket ticket, {
    required Of297ExportDocument exportDocument,
  }) async {
    final templateData =
        await rootBundle.load(Of297PdfFieldMap.templateAssetPath);
    final templateBytes = pdfBytesFromByteData(templateData);
    final document = PdfDocument(
      inputBytes: templateBytes,
    );

    try {
      _fillTopSection(document, ticket);
      _fillEquipmentRows(document, ticket, exportDocument);
      _fillPersonnelRows(document, exportDocument);
      _fillBottomSection(document, ticket);
      final signatureBoxes = _signatureBoxes();

      // Flattening makes the exported billing record stable/read-only.
      // TODO: verify flattened output formatting with real agency billing workflows.
      document.form.flattenAllFields();

      _drawSignatures(document, ticket, signatureBoxes);

      final outputBytes = Uint8List.fromList(await document.save());
      validatePdfBytes(
        outputBytes,
        label: 'OF-297 ${exportDocument.fileName}',
      );
      return outputBytes;
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

  void _fillEquipmentRows(
    PdfDocument document,
    OF297ShiftTicket ticket,
    Of297ExportDocument exportDocument,
  ) {
    for (var i = 0; i < exportDocument.equipmentRows.length && i < 4; i++) {
      final row = i + 1;
      final exportRow = exportDocument.equipmentRows[i];
      final entry = exportRow.source;

      setCompactTextField(
        document,
        Of297PdfFieldMap.equipmentDate(row),
        exportRow.date,
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentStart(row),
        ticket.rateIsMiles
            ? _nullableNumber(entry.mileageStart)
            : exportRow.start,
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentStop(row),
        ticket.rateIsMiles ? _nullableNumber(entry.mileageEnd) : exportRow.stop,
      );
      setTextField(
        document,
        Of297PdfFieldMap.equipmentTotal(row),
        ticket.rateIsMiles
            ? _number(entry.totalMiles)
            : _number(exportRow.totalHours),
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

  void _fillPersonnelRows(
    PdfDocument document,
    Of297ExportDocument exportDocument,
  ) {
    for (var i = 0; i < exportDocument.personnelRows.length && i < 4; i++) {
      final row = i + 1;
      final exportRow = exportDocument.personnelRows[i];
      final entry = exportRow.source;

      setCompactTextField(
        document,
        Of297PdfFieldMap.personnelDate(row),
        exportRow.date,
      );
      setTextField(document, Of297PdfFieldMap.personnelName(row), entry.name);
      setTextField(
        document,
        Of297PdfFieldMap.personnelStartOne(row),
        exportRow.block1Start,
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStopOne(row),
        exportRow.block1Stop,
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStartTwo(row),
        exportRow.block2Start,
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelStopTwo(row),
        exportRow.block2Stop,
      );
      setTextField(
        document,
        Of297PdfFieldMap.personnelTotal(row),
        _number(exportRow.totalHours),
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

  Map<String, Rect> _signatureBoxes() {
    return {
      Of297PdfFieldMap.contractorSignature:
          Of297SignatureBoxes.contractorRepresentative,
      Of297PdfFieldMap.supervisorSignature:
          Of297SignatureBoxes.incidentSupervisor,
    };
  }

  void _drawSignatures(
    PdfDocument document,
    OF297ShiftTicket ticket,
    Map<String, Rect> signatureBoxes,
  ) {
    final page = document.pages[0];

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

    final imageBytes = _prepareSignatureImage(
      base64Decode(signature.signatureBytesBase64),
    );
    final image = PdfBitmap(imageBytes);
    const padding = 3.0;
    final target = Rect.fromLTWH(
      box.left + padding,
      box.top + padding,
      math.max(1, box.width - padding * 2),
      math.max(1, box.height - padding * 2),
    );
    final imageRatio = image.width / image.height;
    final targetRatio = target.width / target.height;
    final fittedWidth =
        imageRatio > targetRatio ? target.width : target.height * imageRatio;
    final fittedHeight =
        imageRatio > targetRatio ? target.width / imageRatio : target.height;
    const maxFill = 0.94;
    final drawWidth = fittedWidth * maxFill;
    final drawHeight = fittedHeight * maxFill;
    final drawRect = Rect.fromLTWH(
      target.left + (target.width - drawWidth) / 2,
      target.top + (target.height - drawHeight) / 2,
      drawWidth,
      drawHeight,
    );

    page.graphics.drawImage(image, drawRect);
  }

  Uint8List _prepareSignatureImage(Uint8List imageBytes) {
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

    for (var y = 0; y < croppedImage.height; y++) {
      for (var x = 0; x < croppedImage.width; x++) {
        final pixel = croppedImage.getPixel(x, y);
        if (_isSignatureInk(pixel)) {
          croppedImage.setPixelRgba(x, y, 0, 0, 0, pixel.a.toInt());
        } else {
          croppedImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

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

  void setCompactTextField(
    PdfDocument document,
    String fieldName,
    String value,
  ) {
    if (value.isEmpty) return;

    final field = _fieldByName(document, fieldName);
    if (field is PdfTextBoxField) {
      field.font = PdfStandardFont(
        PdfFontFamily.helvetica,
        value.contains('-') ? 6.4 : 7.5,
      );
      field.textAlignment = PdfTextAlignment.center;
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

  String _number(double value) {
    if (value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _nullableNumber(double? value) {
    if (value == null || value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }
}

class Of297SignatureBoxes {
  static const contractorRepresentative = Rect.fromLTWH(318, 338, 244, 32);
  static const incidentSupervisor = Rect.fromLTWH(318, 365, 244, 32);
}
