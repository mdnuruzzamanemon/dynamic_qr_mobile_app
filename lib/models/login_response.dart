class LoginResponse {
  final String token;
  final String role;
  final String bankPublicKeyPem;
  final String encryptedEncKey;
  final String signature;

  LoginResponse({
    required this.token,
    required this.role,
    required this.bankPublicKeyPem,
    required this.encryptedEncKey,
    required this.signature,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      role: json['role'] as String,
      bankPublicKeyPem: json['bank_public_key_pem'] as String,
      encryptedEncKey: json['encrypted_enc_key'] as String,
      signature: json['signature'] as String,
    );
  }
}
