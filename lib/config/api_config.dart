class ApiConfig {
  static const String baseUrl = 'https://neoorthodox-nonemendable-rogelio.ngrok-free.dev';
  static const String loginPath = '/api/v1/auth/login';
  static const String registerDevicePath = '/api/v1/app/register-certificate';
  static const String scanQrPath = '/api/v1/app/scan';
  static const String publicKeyPath = '/api/v1/bank/public-key';
  static const String decryptHashPath = '/api/v1/app/decrypt-hash';
  static const String profilePath = '/api/v1/user/profile';
  static const String portalPath = '/portal';
  static const String origin = 'http://localhost:3000';
  static const Duration requestTimeout = Duration(seconds: 30);
}
