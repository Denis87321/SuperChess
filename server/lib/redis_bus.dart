import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:redis/redis.dart';

/// Multi-instance fanout. No-op when [REDIS_URL] is unset.
class RedisBus {
  RedisBus._();
  static final RedisBus instance = RedisBus._();

  final String instanceId =
      Platform.environment['INSTANCE_ID'] ??
      'inst_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_'
          '${Random().nextInt(1 << 20).toRadixString(36)}';

  Command? _cmd;
  PubSub? _pubsub;
  final _handlers = <void Function(String channel, Map<String, dynamic> msg)>[];
  bool get enabled => _cmd != null;

  Future<void> connect() async {
    final url = Platform.environment['REDIS_URL']?.trim();
    if (url == null || url.isEmpty) {
      // ignore: avoid_print
      print('Redis: disabled (no REDIS_URL)');
      return;
    }
    try {
      final parsed = _parseRedisUrl(url);
      final conn = RedisConnection();
      _cmd = await conn.connect(parsed.host, parsed.port);
      if (parsed.password != null) {
        await _cmd!.send_object(['AUTH', parsed.password]);
      }
      if (parsed.db != 0) {
        await _cmd!.send_object(['SELECT', parsed.db]);
      }

      final subConn = RedisConnection();
      final subCmd = await subConn.connect(parsed.host, parsed.port);
      if (parsed.password != null) {
        await subCmd.send_object(['AUTH', parsed.password]);
      }
      _pubsub = PubSub(subCmd);
      _pubsub!.psubscribe(['sc:*']);
      _pubsub!.getStream().listen(_onRaw, onError: (_) {});
      // ignore: avoid_print
      print('Redis: connected as $instanceId');
    } catch (e) {
      _cmd = null;
      _pubsub = null;
      // ignore: avoid_print
      print('Redis: failed ($e) — single-instance mode');
    }
  }

  void onMessage(void Function(String channel, Map<String, dynamic> msg) h) {
    _handlers.add(h);
  }

  Future<void> publish(String channel, Map<String, dynamic> message) async {
    final cmd = _cmd;
    if (cmd == null) return;
    final payload = jsonEncode({
      ...message,
      '_fromInstance': instanceId,
    });
    try {
      await cmd.send_object(['PUBLISH', channel, payload]);
    } catch (_) {}
  }

  Future<void> setex(String key, int seconds, String value) async {
    final cmd = _cmd;
    if (cmd == null) return;
    try {
      await cmd.send_object(['SETEX', key, '$seconds', value]);
    } catch (_) {}
  }

  Future<String?> get(String key) async {
    final cmd = _cmd;
    if (cmd == null) return null;
    try {
      final r = await cmd.send_object(['GET', key]);
      return r?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> del(String key) async {
    final cmd = _cmd;
    if (cmd == null) return;
    try {
      await cmd.send_object(['DEL', key]);
    } catch (_) {}
  }

  Future<void> sadd(String key, String member) async {
    final cmd = _cmd;
    if (cmd == null) return;
    try {
      await cmd.send_object(['SADD', key, member]);
    } catch (_) {}
  }

  Future<void> srem(String key, String member) async {
    final cmd = _cmd;
    if (cmd == null) return;
    try {
      await cmd.send_object(['SREM', key, member]);
    } catch (_) {}
  }

  Future<List<String>> smembers(String key) async {
    final cmd = _cmd;
    if (cmd == null) return const [];
    try {
      final r = await cmd.send_object(['SMEMBERS', key]);
      if (r is! List) return const [];
      return [for (final e in r) '$e'];
    } catch (_) {
      return const [];
    }
  }

  void _onRaw(dynamic msg) {
    // pmessage: ['pmessage', pattern, channel, payload]
    if (msg is! List || msg.length < 4) return;
    if ('${msg[0]}' != 'pmessage' && '${msg[0]}' != 'message') return;
    final channel = '${msg[msg.length - 2]}';
    final raw = '${msg[msg.length - 1]}';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      if (map['_fromInstance'] == instanceId) return; // echo
      for (final h in _handlers) {
        h(channel, map);
      }
    } catch (_) {}
  }
}

class _RedisEndpoint {
  _RedisEndpoint({
    required this.host,
    required this.port,
    this.password,
    this.db = 0,
  });
  final String host;
  final int port;
  final String? password;
  final int db;
}

_RedisEndpoint _parseRedisUrl(String url) {
  final uri = Uri.parse(url);
  final host = uri.host.isEmpty ? 'localhost' : uri.host;
  final port = uri.hasPort ? uri.port : 6379;
  String? password = uri.userInfo.isEmpty
      ? null
      : (uri.userInfo.contains(':')
          ? uri.userInfo.split(':').last
          : uri.userInfo);
  if (password != null && password.isEmpty) password = null;
  final db = int.tryParse(uri.path.replaceFirst('/', '')) ?? 0;
  return _RedisEndpoint(host: host, port: port, password: password, db: db);
}
