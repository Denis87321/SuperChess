import 'dart:async';
import 'dart:convert';

import 'redis_bus.dart';

/// Cross-instance lobby queue on Redis sets + match fanout.
class RedisLobby {
  RedisLobby._();
  static final RedisLobby instance = RedisLobby._();

  void Function(Map<String, dynamic> match)? onRemoteMatch;
  void Function(Map<String, dynamic> seek)? onRemoteSeekHint;

  void start() {
    RedisBus.instance.onMessage(_onRedis);
  }

  String _queueKey(String tcId, bool rated) => 'sc:lobby:q:$tcId|$rated';

  Future<void> enqueue(Map<String, dynamic> seek) async {
    if (!RedisBus.instance.enabled) return;
    final tc = '${seek['tc']}';
    final rated = seek['rated'] == true;
    final seekId = '${seek['seekId']}';
    await RedisBus.instance.setex(
      'sc:lobby:seek:$seekId',
      180,
      jsonEncode(seek),
    );
    await RedisBus.instance.sadd(_queueKey(tc, rated), seekId);
    await RedisBus.instance.publish('sc:lobby', {
      'kind': 'lobby_seek',
      'payload': seek,
    });
  }

  Future<void> dequeue(String seekId, {String? tcId, bool? rated}) async {
    if (!RedisBus.instance.enabled) return;
    await RedisBus.instance.del('sc:lobby:seek:$seekId');
    if (tcId != null && rated != null) {
      await RedisBus.instance.srem(_queueKey(tcId, rated), seekId);
    }
  }

  /// Try to claim another instance's seek from the shared queue.
  Future<Map<String, dynamic>?> tryClaimPeer({
    required String tcId,
    required bool rated,
    required String localSeekId,
  }) async {
    if (!RedisBus.instance.enabled) return null;
    final members = await RedisBus.instance.smembers(_queueKey(tcId, rated));
    for (final seekId in members) {
      if (seekId == localSeekId) continue;
      final raw = await RedisBus.instance.get('sc:lobby:seek:$seekId');
      if (raw == null) {
        await RedisBus.instance.srem(_queueKey(tcId, rated), seekId);
        continue;
      }
      Map<String, dynamic> peer;
      try {
        peer = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        continue;
      }
      if (peer['instanceId'] == RedisBus.instance.instanceId) continue;
      // Claim: delete key first (best-effort lock).
      await RedisBus.instance.del('sc:lobby:seek:$seekId');
      await RedisBus.instance.srem(_queueKey(tcId, rated), seekId);
      return peer;
    }
    return null;
  }

  Future<void> publishMatch(Map<String, dynamic> match) async {
    await RedisBus.instance.publish('sc:lobby:match', {
      'kind': 'lobby_match',
      'payload': match,
    });
  }

  void _onRedis(String channel, Map<String, dynamic> msg) {
    final kind = msg['kind'] as String?;
    if (channel == 'sc:lobby:match' || kind == 'lobby_match') {
      final payload = msg['payload'];
      if (payload is Map) {
        onRemoteMatch?.call(Map<String, dynamic>.from(payload));
      }
      return;
    }
    if (kind == 'lobby_seek') {
      final payload = msg['payload'];
      if (payload is Map) {
        onRemoteSeekHint?.call(Map<String, dynamic>.from(payload));
      }
    }
  }
}
