class QrScanResponse {
  final String documentToken;
  final String portalUrl;
  final String qrType;
  final String rawEncryptedPayload;

  QrScanResponse({
    required this.documentToken,
    required this.portalUrl,
    required this.qrType,
    required this.rawEncryptedPayload,
  });

  factory QrScanResponse.fromJson(Map<String, dynamic> json) {
    return QrScanResponse(
      documentToken: json['document_token'] as String? ?? '',
      portalUrl: json['portal_url'] as String? ?? '',
      qrType: json['qr_type'] as String? ?? 'standard',
      rawEncryptedPayload: json['raw_encrypted_payload'] as String? ?? '',
    );
  }

  bool get isEncrypted => qrType == 'encrypted';
}

class StandardQrResponse {
  final String qrType;
  final Map<String, dynamic>? document;
  final String hmacSig;
  final String? message;

  StandardQrResponse({
    required this.qrType,
    this.document,
    required this.hmacSig,
    this.message,
  });

  factory StandardQrResponse.fromJson(Map<String, dynamic> json) {
    return StandardQrResponse(
      qrType: json['qr_type'] as String? ?? 'standard',
      document: json['document'] as Map<String, dynamic>?,
      hmacSig: json['hmac_sig'] as String? ?? '',
      message: json['message'] as String?,
    );
  }

  bool get isEncrypted => qrType == 'encrypted';
}
