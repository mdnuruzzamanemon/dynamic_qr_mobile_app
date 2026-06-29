import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/device_registration.dart';
import '../models/login_response.dart';
import '../models/qr_scan_response.dart';
import 'crypto_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final _crypto = CryptoService();
  final _client = http.Client();

  Map<String, String> _headers({String? token, String? origin}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';
    headers['Origin'] = origin ?? ApiConfig.origin;
    return headers;
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginPath}'),
          headers: _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
          body['error'] as String? ?? body['message'] as String? ?? 'Login failed');
    }

    return LoginResponse.fromJson(jsonDecode(response.body));
  }

  Future<DeviceRegistrationResponse> registerDevice({
    required String token,
    required String deviceId,
    required String publicKeyPem,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerDevicePath}'),
          headers: _headers(token: token),
          body: jsonEncode({
            'device_id': deviceId,
            'public_key_pem': publicKeyPem,
            'device_name': 'Mobile QR Scanner',
            'platform': 'android',
            'app_version': '1.0.0',
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw ApiException(
          body['error'] as String? ?? 'Device registration failed');
    }

    return DeviceRegistrationResponse.fromJson(jsonDecode(response.body));
  }

  Future<StandardQrResponse> scanStandardQr(String qrToken) async {
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.portalPath}/$qrToken'),
          headers: _headers(),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Failed to scan QR code');
    }

    return StandardQrResponse.fromJson(jsonDecode(response.body));
  }

  Future<QrScanResponse> scanEncryptedQr({
    required String token,
    required String qrToken,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.scanQrPath}/$qrToken')
        .replace(queryParameters: {'client_decrypt': 'true'});

    final response = await _client
        .get(
          uri,
          headers: _headers(token: token),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
          body['error'] as String? ?? 'Failed to scan encrypted QR');
    }

    return QrScanResponse.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> decryptHash({
    required String token,
    required String deviceId,
    required String privateKeyPem,
    required String encryptedHash,
  }) async {
    final method = 'POST';
    final path = ApiConfig.decryptHashPath;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final requestBody = jsonEncode({
      'encrypted_payload': encryptedHash,
    });

    final signedData = '$method|$path|$timestamp|$requestBody';
    final signature = _crypto.signWithRsaPssBase64(
      data: signedData,
      privateKeyPem: privateKeyPem,
    );

    final headers = _headers(token: token);
    headers['X-Signature'] = signature;
    headers['X-Device-ID'] = deviceId;
    headers['X-Timestamp'] = timestamp;

    final response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: headers,
          body: requestBody,
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw ApiException(
          body['error'] as String? ?? 'Failed to decrypt hash');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
