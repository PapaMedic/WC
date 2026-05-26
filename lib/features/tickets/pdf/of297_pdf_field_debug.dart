import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:wildland_companion_v2/features/tickets/pdf/of297_pdf_field_map.dart';

/// Debug helper for inspecting the official OF-297 template fields.
///
/// PDF mapping depends on exact AcroForm field names. If exported values do not
/// appear, the first debugging step is to print fields and bounds from the
/// official `OF297-24.pdf` template and update [Of297PdfFieldMap].
class Of297PdfFieldDebug {
  Future<void> logTemplateFieldsFromAsset() async {
    final assetData = await rootBundle.load(Of297PdfFieldMap.templateAssetPath);
    logFieldsFromBytes(assetData.buffer.asUint8List());
  }

  void logFieldsFromFile(String path) {
    logFieldsFromBytes(File(path).readAsBytesSync());
  }

  void logFieldsFromBytes(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    try {
      developer.log('OF-297 field count: ${document.form.fields.count}');
      for (var i = 0; i < document.form.fields.count; i++) {
        final field = document.form.fields[i];
        final pageIndex =
            field.page == null ? -1 : document.pages.indexOf(field.page!);
        developer.log(
          'OF-297 field[$i] '
          'name="${field.name}" '
          'type="${field.runtimeType}" '
          'page="$pageIndex" '
          'bounds="${field.bounds}" '
          'value="${_fieldValue(field)}"',
        );
      }
    } finally {
      document.dispose();
    }
  }

  String _fieldValue(PdfField field) {
    if (field is PdfTextBoxField) return field.text;
    if (field is PdfCheckBoxField) return field.isChecked.toString();
    if (field is PdfComboBoxField) return field.selectedValue;
    if (field is PdfListBoxField) return field.selectedIndexes.toString();
    return '';
  }
}
