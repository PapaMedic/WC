import 'dart:typed_data';

import 'package:flutter/services.dart';

Uint8List pdfBytesFromByteData(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void validatePdfBytes(Uint8List bytes, {required String label}) {
  if (bytes.isEmpty) {
    throw StateError('$label produced an empty PDF.');
  }

  final header = pdfHeader(bytes);
  if (!header.startsWith('%PDF')) {
    throw StateError('$label produced invalid PDF bytes. Header: $header');
  }
}

String pdfHeader(Uint8List bytes) {
  final headerLength = bytes.length < 5 ? bytes.length : 5;
  return String.fromCharCodes(bytes.take(headerLength).toList());
}
