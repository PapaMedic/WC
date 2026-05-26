/// Persistent metadata for a finalized OF-297 PDF export.
///
/// The generated PDF file lives on disk. This record lets the app remember
/// which finalized ticket produced it, where it was saved, and when it was
/// exported without making the PDF itself the source of truth.
class OF297PdfRecord {
  final String id;
  final String ticketId;
  final String incidentId;
  final String incidentName;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime generatedAt;

  const OF297PdfRecord({
    required this.id,
    required this.ticketId,
    required this.incidentId,
    required this.incidentName,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'incidentId': incidentId,
        'incidentName': incidentName,
        'fileName': fileName,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory OF297PdfRecord.fromJson(Map<String, dynamic> json) {
    return OF297PdfRecord(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      incidentId: json['incidentId'] ?? '',
      incidentName: json['incidentName'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
