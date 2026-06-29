class DeviceRegistrationResponse {
  final String deviceId;
  final String status;
  final String? expiresAt;

  DeviceRegistrationResponse({
    required this.deviceId,
    required this.status,
    this.expiresAt,
  });

  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      deviceId: json['device_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: json['expires_at'] as String?,
    );
  }
}

class DeviceKeys {
  final String deviceId;
  final String publicKey;
  final String privateKey;

  DeviceKeys({
    required this.deviceId,
    required this.publicKey,
    required this.privateKey,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'public_key': publicKey,
    'private_key': privateKey,
  };

  factory DeviceKeys.fromJson(Map<String, dynamic> json) {
    return DeviceKeys(
      deviceId: json['device_id'] as String,
      publicKey: json['public_key'] as String,
      privateKey: json['private_key'] as String,
    );
  }
}
