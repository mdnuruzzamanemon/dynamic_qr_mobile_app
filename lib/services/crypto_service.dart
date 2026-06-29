import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:pointycastle/export.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._();
  factory CryptoService() => _instance;
  CryptoService._();

  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = dart_crypto.sha256
        .convert(utf8.encode(DateTime.now().microsecondsSinceEpoch.toString()))
        .bytes;
    random.seed(KeyParameter(Uint8List.fromList(seed)));
    return random;
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRsaKeyPair() {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _secureRandom(),
      ));
    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  String rsaPublicKeyToPem(RSAPublicKey key) {
    final algoId = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1'))
      ..add(ASN1Null());

    final pubKeySeq = ASN1Sequence()
      ..add(ASN1Integer(key.modulus!))
      ..add(ASN1Integer(key.exponent!));

    final pubKeyBitString = ASN1BitString(
      pubKeySeq.encodedBytes.toList(),
      unusedbits: 0,
    );

    final topSeq = ASN1Sequence()
      ..add(algoId)
      ..add(pubKeyBitString);

    return _toPem(topSeq.encodedBytes, 'PUBLIC KEY');
  }

  RSAPublicKey rsaPublicKeyFromPem(String pem) {
    final der = _fromPem(pem, 'PUBLIC KEY');
    final parser = ASN1Parser(Uint8List.fromList(der));
    final topLevel = parser.nextObject() as ASN1Sequence;
    final bitString = topLevel.elements[1] as ASN1BitString;
    final keyDer = bitString.contentBytes();
    final keyParser = ASN1Parser(keyDer);
    final keySeq = keyParser.nextObject() as ASN1Sequence;
    return RSAPublicKey(
      (keySeq.elements[0] as ASN1Integer).valueAsBigInteger,
      (keySeq.elements[1] as ASN1Integer).valueAsBigInteger,
    );
  }

  RSAPrivateKey rsaPrivateKeyFromPem(String pem) {
    final der = _fromPem(pem, 'PRIVATE KEY');
    final parser = ASN1Parser(Uint8List.fromList(der));
    final topLevel = parser.nextObject() as ASN1Sequence;
    final octetString = topLevel.elements[2] as ASN1OctetString;
    final keyDer = octetString.valueBytes();
    final keyParser = ASN1Parser(keyDer);
    final keySeq = keyParser.nextObject() as ASN1Sequence;
    return RSAPrivateKey(
      (keySeq.elements[1] as ASN1Integer).valueAsBigInteger,
      (keySeq.elements[3] as ASN1Integer).valueAsBigInteger,
      (keySeq.elements[4] as ASN1Integer).valueAsBigInteger,
      (keySeq.elements[5] as ASN1Integer).valueAsBigInteger,
      // ignore: deprecated_member_use
      (keySeq.elements[2] as ASN1Integer).valueAsBigInteger,
    );
  }

  String rsaPrivateKeyToPem(RSAPrivateKey key) {
    final rsaKeySeq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero))
      ..add(ASN1Integer(key.modulus!))
      // ignore: deprecated_member_use
      ..add(ASN1Integer(key.publicExponent!))
      ..add(ASN1Integer(key.privateExponent!))
      ..add(ASN1Integer(key.p!))
      ..add(ASN1Integer(key.q!))
      ..add(ASN1Integer(key.privateExponent! % (key.p! - BigInt.one)))
      ..add(ASN1Integer(key.privateExponent! % (key.q! - BigInt.one)))
      ..add(ASN1Integer(key.q!.modInverse(key.p!)));

    final algoId = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1'))
      ..add(ASN1Null());

    final privateKeyOctet = ASN1OctetString(rsaKeySeq.encodedBytes);

    final topSeq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero))
      ..add(algoId)
      ..add(privateKeyOctet);

    return _toPem(topSeq.encodedBytes, 'PRIVATE KEY');
  }

  bool verifyRsaPssSignature({
    required String data,
    required String signatureHex,
    required String publicKeyPem,
  }) {
    try {
      final publicKey = rsaPublicKeyFromPem(publicKeyPem);
      final message = utf8.encode(data);
      final sigBytes = _hexDecode(signatureHex);

      final signer = PSSSigner(
        RSAEngine(),
        SHA256Digest(),
        SHA256Digest(),
      );
      signer.init(
        false,
        ParametersWithSaltConfiguration(
          PublicKeyParameter<RSAPublicKey>(publicKey),
          _secureRandom(),
          32,
        ),
      );
      return signer.verifySignature(
        Uint8List.fromList(message),
        PSSSignature(Uint8List.fromList(sigBytes)),
      );
    } catch (e) {
      return false;
    }
  }

  String signWithRsaPssBase64({
    required String data,
    required String privateKeyPem,
  }) {
    final privateKey = rsaPrivateKeyFromPem(privateKeyPem);
    final message = utf8.encode(data);

    final signer = PSSSigner(
      RSAEngine(),
      SHA256Digest(),
      SHA256Digest(),
    );
    signer.init(
      true,
      ParametersWithSaltConfiguration(
        PrivateKeyParameter<RSAPrivateKey>(privateKey),
        _secureRandom(),
        32,
      ),
    );
    final signature = signer.generateSignature(Uint8List.fromList(message));
    return base64Encode(signature.bytes);
  }

  Uint8List sha256Hash(Uint8List data) {
    return Uint8List.fromList(dart_crypto.sha256.convert(data).bytes);
  }

  String decryptMasterKey({
    required String encryptedEncKey,
    required String password,
  }) {
    final passwordHash =
        sha256Hash(Uint8List.fromList(utf8.encode(password)));
    final encryptedBytes = _base64UrlDecode(encryptedEncKey);
    final decrypted = _decryptAes256Gcm(passwordHash, encryptedBytes);
    return utf8.decode(decrypted);
  }

  String decryptQrPayload({
    required String encryptedPayload,
    required String masterKey,
    required String portalUrl,
  }) {
    final perQrKeyMaterial = masterKey + portalUrl;
    final perQrKey =
        sha256Hash(Uint8List.fromList(utf8.encode(perQrKeyMaterial)));
    final encryptedBytes = _base64UrlDecode(encryptedPayload);
    final decrypted = _decryptAes256Gcm(perQrKey, encryptedBytes);
    return utf8.decode(decrypted);
  }

  Uint8List _decryptAes256Gcm(Uint8List key, Uint8List encryptedData) {
    final nonce = encryptedData.sublist(0, 12);
    final ciphertext = encryptedData.sublist(12);
    final tag = ciphertext.sublist(ciphertext.length - 16);
    final actual = ciphertext.sublist(0, ciphertext.length - 16);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(
        KeyParameter(key),
        128,
        nonce,
        Uint8List(0),
      ));

    final input = Uint8List.fromList(actual + tag);
    final output = Uint8List(cipher.getOutputSize(input.length));
    final len1 = cipher.processBytes(input, 0, input.length, output, 0);
    final len2 = cipher.doFinal(output, len1);
    return output.sublist(0, len1 + len2);
  }

  Uint8List _hexDecode(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Uint8List _base64UrlDecode(String str) {
    var s = str.replaceAll('-', '+').replaceAll('_', '/');
    while (s.length % 4 != 0) { s += '='; }
    return base64Decode(s);
  }

  String _toPem(Uint8List der, String label) {
    final b64 = base64Encode(der);
    final buf = StringBuffer()..writeln('-----BEGIN $label-----');
    for (var i = 0; i < b64.length; i += 64) {
      buf.writeln(
          b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    buf.write('-----END $label-----');
    return buf.toString();
  }

  Uint8List _fromPem(String pem, String label) {
    final s = pem
        .replaceAll('-----BEGIN $label-----', '')
        .replaceAll('-----END $label-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
    return base64Decode(s);
  }
}
