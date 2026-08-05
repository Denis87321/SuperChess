import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AuthTokens {
  AuthTokens(this.secret);

  final String secret;
  static const ttlDays = 90;

  String issue({required String userId, required String username}) {
    final jwt = JWT(
      {
        'sub': userId,
        'username': username,
      },
      issuer: 'superchess',
    );
    return jwt.sign(
      SecretKey(secret),
      expiresIn: const Duration(days: ttlDays),
    );
  }

  /// Returns payload map or null if invalid/expired.
  Map<String, dynamic>? verify(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      final payload = jwt.payload;
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return null;
    } catch (_) {
      return null;
    }
  }
}

final _usernameRe = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

String? validateUsername(String raw) {
  final username = raw.trim();
  if (!_usernameRe.hasMatch(username)) {
    return null;
  }
  return username;
}

String? validatePassword(String password) {
  if (password.length < 6 || password.length > 128) return null;
  return password;
}
