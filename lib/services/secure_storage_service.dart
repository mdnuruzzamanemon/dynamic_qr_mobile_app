import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/device_registration.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._();
  factory SecureStorageService() => _instance;
  SecureStorageService._();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _deviceKeysKey = 'device_keys';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveDeviceKeys(DeviceKeys keys) async {
    await _storage.write(
      key: _deviceKeysKey,
      value: jsonEncode(keys.toJson()),
    );
  }

  Future<DeviceKeys?> getDeviceKeys() async {
    final value = await _storage.read(key: _deviceKeysKey);
    if (value == null) return null;
    return DeviceKeys.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> deleteDeviceKeys() async {
    await _storage.delete(key: _deviceKeysKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
