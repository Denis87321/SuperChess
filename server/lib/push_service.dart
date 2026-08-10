import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'db.dart';

/// Optional FCM HTTP legacy send. Enable with FCM_SERVER_KEY.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  AuthDatabase? _db;
  String? get _serverKey =>
      Platform.environment['FCM_SERVER_KEY']?.trim();

  bool get enabled =>
      _serverKey != null && _serverKey!.isNotEmpty && _db != null;

  void bind(AuthDatabase? db) => _db = db;

  Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    final db = _db;
    final key = _serverKey;
    if (db == null || key == null || key.isEmpty) return;
    List<Map<String, dynamic>> devices;
    try {
      devices = await db.devicesForUser(userId);
    } catch (_) {
      return;
    }
    for (final d in devices) {
      final token = d['token'] as String?;
      if (token == null || token.isEmpty) continue;
      try {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$key',
          },
          body: jsonEncode({
            'to': token,
            'notification': {'title': title, 'body': body},
            'data': data,
            'priority': 'high',
          }),
        );
      } catch (_) {}
    }
  }
}
