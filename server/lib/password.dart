import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hashing (pure Dart, no native deps).
class PasswordHasher {
  static const _iterations = 100000;
  static const _keyLength = 32;
  static const _saltLength = 16;

  static String hash(String password) {
    final salt = _randomBytes(_saltLength);
    final derived = _pbkdf2(password, salt);
    return 'pbkdf2\$$_iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  static bool verify(String password, String encoded) {
    final parts = encoded.split('\$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    late List<int> salt;
    late List<int> expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } catch (_) {
      return false;
    }
    final actual = _pbkdf2(password, salt, iterations: iterations);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _pbkdf2(
    String password,
    List<int> salt, {
    int iterations = _iterations,
    int keyLength = _keyLength,
  }) {
    final passwordBytes = utf8.encode(password);
    final hmacLength = sha256.convert([]).bytes.length;
    final blocks = (keyLength + hmacLength - 1) ~/ hmacLength;
    final result = BytesBuilder(copy: false);

    for (var block = 1; block <= blocks; block++) {
      final blockBytes = ByteData(4)..setUint32(0, block, Endian.big);
      var u = _hmac(passwordBytes, [...salt, ...blockBytes.buffer.asUint8List()]);
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = _hmac(passwordBytes, u);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.add(t);
    }

    return Uint8List.fromList(result.takeBytes().sublist(0, keyLength));
  }

  static List<int> _hmac(List<int> key, List<int> message) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).bytes;
  }
}
