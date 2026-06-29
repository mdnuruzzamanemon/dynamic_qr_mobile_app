import 'package:flutter/foundation.dart';

import '../models/device_registration.dart';
import '../services/api_service.dart';
import '../services/crypto_service.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus { uninitialized, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();
  final _crypto = CryptoService();
  final _storage = SecureStorageService();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _token;
  String? _role;
  String? _masterKey;
  DeviceKeys? _deviceKeys;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get role => _role;
  String? get masterKey => _masterKey;
  DeviceKeys? get deviceKeys => _deviceKeys;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    final token = await _storage.getToken();
    final deviceKeys = await _storage.getDeviceKeys();

    if (token != null) {
      _token = token;
      _deviceKeys = deviceKeys;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final loginResponse = await _api.login(email: email, password: password);

    final signatureValid = _crypto.verifyRsaPssSignature(
      data: loginResponse.encryptedEncKey,
      signatureHex: loginResponse.signature,
      publicKeyPem: loginResponse.bankPublicKeyPem,
    );

    if (!signatureValid) {
      throw Exception('Bank signature verification failed. Possible tampering detected.');
    }

    final masterKey = _crypto.decryptMasterKey(
      encryptedEncKey: loginResponse.encryptedEncKey,
      password: password,
    );

    _token = loginResponse.token;
    _role = loginResponse.role;
    _masterKey = masterKey;
    _status = AuthStatus.authenticated;

    await _storage.saveToken(_token!);
    await _registerDevice();
    notifyListeners();
  }

  Future<void> _registerDevice() async {
    if (_deviceKeys != null) return;

    final pair = _crypto.generateRsaKeyPair();
    final publicKeyPem = _crypto.rsaPublicKeyToPem(pair.publicKey);
    final privateKeyPem = _crypto.rsaPrivateKeyToPem(pair.privateKey);

    final deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';

    await _api.registerDevice(
      token: _token!,
      deviceId: deviceId,
      publicKeyPem: publicKeyPem,
    );

    _deviceKeys = DeviceKeys(
      deviceId: deviceId,
      publicKey: publicKeyPem,
      privateKey: privateKeyPem,
    );

    await _storage.saveDeviceKeys(_deviceKeys!);
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _masterKey = null;
    _deviceKeys = null;
    _status = AuthStatus.unauthenticated;
    await _storage.clearAll();
    notifyListeners();
  }
}
