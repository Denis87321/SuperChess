import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'redis_bus.dart';

class _LocalSeat {
  _LocalSeat({
    required this.channel,
    this.color,
    this.resumeToken,
    this.spectator = false,
  });
  final WebSocketChannel channel;
  String? color;
  String? resumeToken;
  bool spectator;
}

/// Bridges local WebSocket seats with Redis pub/sub for multi-instance deploy.
///
/// - Owns games register `sc:game:{id}:owner` = instanceId
/// - Local fanout also publishes to `sc:game:{id}`
/// - Remote instances deliver to locally attached channels for that game
/// - Ingress: client on non-owner instance → `sc:game:{id}:ingress` → owner
class ClusterBridge {
  ClusterBridge._();
  static final ClusterBridge instance = ClusterBridge._();

  final _gameSeats = <String, Set<_LocalSeat>>{};
  final _ingressHandlers =
      <String, FutureOr<void> Function(Map<String, dynamic>)>{};
  final _channelIndex = <WebSocketChannel, String>{};
  final _seatByChannel = <WebSocketChannel, _LocalSeat>{};

  void start() {
    RedisBus.instance.onMessage(_onRedis);
  }

  void attachLocal(
    String gameId,
    WebSocketChannel channel, {
    String? color,
    String? resumeToken,
    bool spectator = false,
  }) {
    final set = _gameSeats.putIfAbsent(gameId, () => {});
    set.removeWhere((s) => identical(s.channel, channel));
    final seat = _LocalSeat(
      channel: channel,
      color: color,
      resumeToken: resumeToken,
      spectator: spectator,
    );
    set.add(seat);
    _channelIndex[channel] = gameId;
    _seatByChannel[channel] = seat;
  }

  void detachLocal(String gameId, WebSocketChannel channel) {
    _gameSeats[gameId]?.removeWhere((s) => identical(s.channel, channel));
    if (_gameSeats[gameId]?.isEmpty ?? false) {
      _gameSeats.remove(gameId);
    }
    if (_channelIndex[channel] == gameId) {
      _channelIndex.remove(channel);
    }
    _seatByChannel.remove(channel);
  }

  void detachChannel(WebSocketChannel channel) {
    final gameId = _channelIndex.remove(channel);
    _seatByChannel.remove(channel);
    if (gameId != null) {
      detachLocal(gameId, channel);
    }
  }

  ({String? color, String? resumeToken})? seatMeta(WebSocketChannel channel) {
    final s = _seatByChannel[channel];
    if (s == null) return null;
    return (color: s.color, resumeToken: s.resumeToken);
  }

  Future<void> claimGameOwnership(String gameId) async {
    await RedisBus.instance.setex(
      'sc:game:$gameId:owner',
      3600 * 6,
      RedisBus.instance.instanceId,
    );
  }

  Future<void> releaseGameOwnership(String gameId) async {
    final owner = await ownerOf(gameId);
    if (owner == RedisBus.instance.instanceId) {
      await RedisBus.instance.del('sc:game:$gameId:owner');
    }
  }

  Future<String?> ownerOf(String gameId) =>
      RedisBus.instance.get('sc:game:$gameId:owner');

  Future<bool> isLocalOwner(String gameId) async {
    if (!RedisBus.instance.enabled) return true;
    final owner = await ownerOf(gameId);
    return owner == null || owner == RedisBus.instance.instanceId;
  }

  void setIngressHandler(
    String gameId,
    FutureOr<void> Function(Map<String, dynamic>) handler,
  ) {
    _ingressHandlers[gameId] = handler;
  }

  void clearIngressHandler(String gameId) {
    _ingressHandlers.remove(gameId);
  }

  /// Publish a game event to other instances (local echo filtered by RedisBus).
  Future<void> publishGameEvent(
    String gameId,
    Map<String, dynamic> message, {
    String? toColor,
    String? toResumeToken,
  }) async {
    await RedisBus.instance.publish('sc:game:$gameId', {
      'kind': 'fanout',
      'gameId': gameId,
      'payload': message,
      if (toColor != null) 'toColor': toColor,
      if (toResumeToken != null) 'toResumeToken': toResumeToken,
    });
  }

  /// Forward a client message to the owning instance.
  Future<void> publishIngress(
    String gameId,
    Map<String, dynamic> message,
  ) async {
    await RedisBus.instance.publish('sc:game:$gameId:ingress', {
      'kind': 'ingress',
      'gameId': gameId,
      'payload': message,
    });
  }

  Future<void> setPresence(String userId, {bool online = true}) async {
    if (online) {
      await RedisBus.instance.setex('sc:presence:$userId', 90, '1');
    } else {
      await RedisBus.instance.del('sc:presence:$userId');
    }
  }

  Future<bool> isOnlineRemote(String userId) async {
    final v = await RedisBus.instance.get('sc:presence:$userId');
    return v != null;
  }

  /// Publish lobby seek list hint so other instances can refresh snapshots.
  Future<void> publishLobbyHint(Map<String, dynamic> hint) async {
    await RedisBus.instance.publish('sc:lobby', {
      'kind': 'lobby',
      'payload': hint,
    });
  }

  void deliverLocal(
    String gameId,
    Map<String, dynamic> payload, {
    String? toColor,
    String? toResumeToken,
  }) {
    final set = _gameSeats[gameId];
    if (set == null) return;
    final raw = jsonEncode(payload);
    for (final seat in set.toList()) {
      if (toResumeToken != null &&
          seat.resumeToken != null &&
          seat.resumeToken != toResumeToken) {
        continue;
      }
      if (toColor != null &&
          !seat.spectator &&
          seat.color != null &&
          seat.color != toColor) {
        continue;
      }
      try {
        seat.channel.sink.add(raw);
      } catch (_) {
        set.remove(seat);
      }
    }
  }

  void _onRedis(String channel, Map<String, dynamic> msg) {
    if (channel == 'sc:lobby' || msg['kind'] == 'lobby') {
      // Hint only — each instance keeps its own local lobby; clients refresh
      // via their own lobby_subscribe. No-op delivery.
      return;
    }

    final kind = msg['kind'] as String?;
    final gameId = msg['gameId'] as String? ?? _gameIdFromChannel(channel);
    if (gameId == null) return;

    if (channel.endsWith(':ingress') || kind == 'ingress') {
      final handler = _ingressHandlers[gameId];
      final payload = msg['payload'];
      if (handler != null && payload is Map) {
        unawaited(
          Future.sync(() => handler(Map<String, dynamic>.from(payload))),
        );
      }
      return;
    }

    if (kind == 'fanout' || channel.startsWith('sc:game:')) {
      final payload = msg['payload'];
      if (payload is Map) {
        deliverLocal(
          gameId,
          Map<String, dynamic>.from(payload),
          toColor: msg['toColor'] as String?,
          toResumeToken: msg['toResumeToken'] as String?,
        );
      }
    }
  }

  String? _gameIdFromChannel(String channel) {
    final parts = channel.split(':');
    if (parts.length >= 3 && parts[0] == 'sc' && parts[1] == 'game') {
      return parts[2];
    }
    return null;
  }
}
