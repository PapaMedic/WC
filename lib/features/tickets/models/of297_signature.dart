/// Captured OF-297 signature data stored directly with the draft ticket.
///
/// The signature pad exports a PNG and stores it as base64 so the draft ticket
/// remains self-contained. PDF export will later read this data but is not part
/// of the signature workflow yet.
class OF297Signature {
  final String signerName;
  final String signerTitle;
  final String signatureBytesBase64;
  final DateTime signedAt;

  const OF297Signature({
    required this.signerName,
    this.signerTitle = '',
    required this.signatureBytesBase64,
    required this.signedAt,
  });

  Map<String, dynamic> toJson() => {
        'signerName': signerName,
        'signerTitle': signerTitle,
        'signatureBytesBase64': signatureBytesBase64,
        'signedAt': signedAt.toIso8601String(),
      };

  factory OF297Signature.fromJson(Map<String, dynamic> json) {
    return OF297Signature(
      signerName: json['signerName'] ?? '',
      signerTitle: json['signerTitle'] ?? '',
      signatureBytesBase64: json['signatureBytesBase64'] ?? '',
      signedAt: DateTime.tryParse(json['signedAt'] ?? '') ?? DateTime.now(),
    );
  }

  OF297Signature copyWith({
    String? signerName,
    String? signerTitle,
    String? signatureBytesBase64,
    DateTime? signedAt,
  }) {
    return OF297Signature(
      signerName: signerName ?? this.signerName,
      signerTitle: signerTitle ?? this.signerTitle,
      signatureBytesBase64: signatureBytesBase64 ?? this.signatureBytesBase64,
      signedAt: signedAt ?? this.signedAt,
    );
  }
}
