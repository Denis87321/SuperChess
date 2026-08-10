import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:super_chess_engine/super_chess_engine.dart';
import 'package:super_chess_server/analysis_worker.dart';
import 'package:super_chess_server/anticheat.dart';
import 'package:super_chess_server/auth.dart';
import 'package:super_chess_server/cluster_bridge.dart';
import 'package:super_chess_server/db.dart';
import 'package:super_chess_server/game_authority.dart';
import 'package:super_chess_server/lobby.dart';
import 'package:super_chess_server/password.dart';
import 'package:super_chess_server/platform_routes.dart';
import 'package:super_chess_server/push_service.dart';
import 'package:super_chess_server/redis_bus.dart';
import 'package:super_chess_server/redis_lobby.dart';
import 'package:super_chess_server/stockfish_service.dart';

AuthDatabase? _authDb;
AuthTokens? _authTokens;
final Lobby _lobby = Lobby();
final Set<String> _onlineUserIds = {};
final Map<WebSocketChannel, String> _channelUserIds = {};
final Map<WebSocketChannel, String> _seekIdByChannel = {};
final Map<String, _QueuedPlayer> _seekPlayerById = {};

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final jwtSecret = Platform.environment['JWT_SECRET'] ??
      'dev-only-change-me-superchess-jwt-secret';
  _authTokens = AuthTokens(jwtSecret);

  try {
    _authDb = await AuthDatabase.connect();
    // ignore: avoid_print
    print(_authDb == null
        ? 'Auth DB: disabled (no DATABASE_URL)'
        : 'Auth DB: connected');
  } catch (e) {
    // ignore: avoid_print
    print('Auth DB: failed to connect ($e) — auth endpoints return 503');
    _authDb = null;
  }

  FairPlayMonitor.bind(_authDb);
  PushService.instance.bind(_authDb);
  FairPlayMonitor.instance.onSoftFlag = (gameId, color, rate, samples) {
    final room = _games[gameId];
    if (room == null) return;
    room.broadcast({
      'type': 'fairplay_alert',
      'gameId': gameId,
      'color': color,
      'matchRate': rate,
      'samples': samples,
      'soft': true,
    });
  };

  await RedisBus.instance.connect();
  ClusterBridge.instance.start();
  RedisLobby.instance.start();
  RedisLobby.instance.onRemoteMatch = _onRedisLobbyMatch;

  final ws = webSocketHandler((WebSocketChannel client, String? _) {
    _ClientConnection(client).listen();
  });

  // Warm Stockfish in background (optional; fails soft if binary missing).
  unawaited(StockfishService.instance.ensureStarted());

  final router = Router();
  mountPlatformRoutes(
    router,
    db: () => _authDb,
    tokens: () => _authTokens,
    onlineUserIds: () => _onlineUserIds,
  );

  router.get('/health', (Request request) async {
    final sf = StockfishService.instance;
    // Don't block health on a cold start forever.
    final available = sf.isAvailable ||
        await sf.ensureStarted().timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            );
    return _json({
      'ok': true,
      'service': 'superchess',
      'auth': _authDb != null,
      'stockfish': available,
      if (sf.lastError != null) 'stockfishError': sf.lastError,
      'redis': RedisBus.instance.enabled,
      'instanceId': RedisBus.instance.instanceId,
      'anticheat': true,
    });
  });

  router.get('/', (Request request) {
    return _json({
      'ok': true,
      'service': 'superchess',
      'auth': _authDb != null,
    });
  });

  router.post('/auth/register', (Request request) async {
    final db = _authDb;
    if (db == null) {
      return _json({'error': 'Auth unavailable'}, status: 503);
    }
    final body = await _readJson(request);
    if (body == null) {
      return _json({'error': 'Invalid JSON'}, status: 400);
    }
    final username = validateUsername('${body['username'] ?? ''}');
    final password = validatePassword('${body['password'] ?? ''}');
    if (username == null) {
      return _json(
        {
          'error':
              'Username must be 3–20 chars: letters, digits, underscore',
        },
        status: 400,
      );
    }
    if (password == null) {
      return _json(
        {'error': 'Password must be at least 6 characters'},
        status: 400,
      );
    }
    final user = await db.createUser(username: username, password: password);
    if (user == null) {
      return _json({'error': 'Username already taken'}, status: 409);
    }
    final token =
        _authTokens!.issue(userId: user.id, username: user.username);
    final profile = await db.profileJson(user);
    return _json({...profile, 'token': token});
  });

  router.post('/auth/login', (Request request) async {
    final db = _authDb;
    if (db == null) {
      return _json({'error': 'Auth unavailable'}, status: 503);
    }
    final body = await _readJson(request);
    if (body == null) {
      return _json({'error': 'Invalid JSON'}, status: 400);
    }
    final username = validateUsername('${body['username'] ?? ''}');
    final password = '${body['password'] ?? ''}';
    if (username == null || password.isEmpty) {
      return _json({'error': 'Invalid credentials'}, status: 400);
    }
    final user = await db.findByUsername(username);
    if (user == null || !PasswordHasher.verify(password, user.passwordHash)) {
      return _json({'error': 'Invalid credentials'}, status: 401);
    }
    final token =
        _authTokens!.issue(userId: user.id, username: user.username);
    final profile = await db.profileJson(user);
    return _json({...profile, 'token': token});
  });

  router.get('/auth/me', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    return _json(await _authDb!.profileJson(user));
  });

  router.get('/user/history', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 30;
    final entries =
        await _authDb!.historyFor(user.id, limit: limit.clamp(1, 100));
    return _json({
      'games': [
        for (final e in entries)
          {
            'gameId': e.gameId,
            'opponentName': e.opponentName,
            'color': e.color,
            'result': e.result,
            'rated': e.rated,
            'ratingBefore': e.ratingBefore,
            'ratingAfter': e.ratingAfter,
            'reason': e.reason,
            'reasonDetail': e.reasonDetail,
            'hasReplay': e.hasReplay,
            'createdAt': e.createdAt.toUtc().toIso8601String(),
          },
      ],
    });
  });

  router.get('/user/rivalries', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final entries = await _authDb!.rivalriesFor(user.id);
    return _json({
      'rivalries': [
        for (final e in entries)
          {
            'opponentId': e.opponentId,
            'opponentName': e.opponentName,
            'wins': e.wins,
            'losses': e.losses,
            'draws': e.draws,
            'lastPlayed': e.lastPlayed.toUtc().toIso8601String(),
          },
      ],
    });
  });

  router.get('/user/matches/<gameId>', (Request request, String gameId) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final replay =
        await _authDb!.matchReplayFor(userId: user.id, gameId: gameId);
    if (replay == null) {
      return _json({'error': 'Not found'}, status: 404);
    }
    return _json(replay);
  });

  router.get('/user/abilities', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final abilities = await _authDb!.listAbilitiesUsed(user.id);
    return _json({'abilities': abilities});
  });

  router.get('/user/search', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final q = request.url.queryParameters['q'] ?? '';
    final users = await _authDb!.searchUsers(q, user.id);
    return _json({'users': users});
  });

  router.get('/user/friends', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final db = _authDb!;
    final friends = await db.listFriends(user.id);
    final incoming = await db.listPendingIncoming(user.id);
    final outgoing = await db.listPendingOutgoing(user.id);
    return _json({
      'friends': friends,
      'incoming': incoming,
      'outgoing': outgoing,
    });
  });

  router.post('/user/friends/request', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final body = await _readJson(request);
    if (body == null) {
      return _json({'error': 'Invalid JSON'}, status: 400);
    }
    final username = (body['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) {
      return _json({'error': 'Username required'}, status: 400);
    }
    final result = await _authDb!.requestFriend(user.id, username);
    if (result['error'] is String) {
      return _json(
        {'error': result['error']},
        status: result['status'] as int? ?? 400,
      );
    }
    return _json(result);
  });

  router.post('/user/friends/respond', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final body = await _readJson(request);
    if (body == null) {
      return _json({'error': 'Invalid JSON'}, status: 400);
    }
    final otherUserId = (body['userId'] as String?)?.trim() ?? '';
    final accept = body['accept'];
    if (otherUserId.isEmpty) {
      return _json({'error': 'userId required'}, status: 400);
    }
    if (accept is! bool) {
      return _json({'error': 'accept must be a boolean'}, status: 400);
    }
    final result = await _authDb!.respondFriend(
      user.id,
      otherUserId,
      accept: accept,
    );
    if (result['error'] is String) {
      return _json(
        {'error': result['error']},
        status: result['status'] as int? ?? 400,
      );
    }
    return _json(result);
  });

  router.post('/games/result', (Request request) async {
    final user = await _userFromAuthHeader(request);
    if (user == null) {
      return _json({'error': 'Unauthorized'}, status: 401);
    }
    final body = await _readJson(request);
    if (body == null) {
      return _json({'error': 'Invalid JSON'}, status: 400);
    }
    final gameId = body['gameId'] as String?;
    final color = body['color'] as String?;
    if (gameId == null || gameId.isEmpty || (color != 'white' && color != 'black')) {
      return _json({'error': 'Invalid game result'}, status: 400);
    }
    final winnerRaw = body['winner'];
    String? winner;
    if (winnerRaw == 'white' || winnerRaw == 'black') {
      winner = winnerRaw as String;
    } else {
      winner = null; // draw
    }
    final abilities = <String>[];
    final rawAbilities = body['abilities'];
    if (rawAbilities is List) {
      for (final a in rawAbilities) {
        if (a is String) abilities.add(a);
      }
    }
    final opponentAbilities = <String>[];
    final rawOppAbs = body['opponentAbilities'];
    if (rawOppAbs is List) {
      for (final a in rawOppAbs) {
        if (a is String) opponentAbilities.add(a);
      }
    }
    final plies = <Map<String, dynamic>>[];
    final rawPlies = body['plies'];
    if (rawPlies is List) {
      for (final p in rawPlies) {
        if (p is Map<String, dynamic>) {
          plies.add(p);
        } else if (p is Map) {
          plies.add(Map<String, dynamic>.from(p));
        }
      }
    }

    final room = _games[gameId];
    String? opponentUserId;
    var opponentName = 'Anonymous';
    var effectiveWinner = winner;
    var reason = body['reason'] as String?;
    if (room != null) {
      final opponent =
          color == 'white' ? room.black : room.white;
      opponentUserId = opponent.userId;
      opponentName = opponent.name;
      // Rated: prefer server-authoritative outcome if already known.
      if (room.rated && room.authority.game.isGameOver) {
        effectiveWinner = room.authority.winnerColorName;
        reason = room.authority.endReasonName ?? reason;
      }
    } else if (body['opponentName'] is String) {
      opponentName = body['opponentName'] as String;
    }

    final profile = await _authDb!.submitGameResult(
      gameId: gameId,
      userId: user.id,
      color: color!,
      winner: effectiveWinner,
      reason: reason,
      reasonDetail: body['reasonDetail'] as String?,
      opponentUserId: opponentUserId,
      opponentName: opponentName,
      abilities: abilities,
      opponentAbilities: opponentAbilities,
      plies: plies,
    );
    return _json({'ok': true, 'profile': profile});
  });

  router.all('/ws', (Request request) => ws(request));

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print(
    'SuperChess server listening on '
    'http://${server.address.host}:${server.port} '
    '(ws /ws, auth /auth/*, health /health)',
  );
}

Future<UserRecord?> _userFromAuthHeader(Request request) async {
  final db = _authDb;
  final tokens = _authTokens;
  if (db == null || tokens == null) return null;
  final header = request.headers['authorization'] ?? '';
  if (!header.toLowerCase().startsWith('bearer ')) return null;
  final token = header.substring(7).trim();
  final payload = tokens.verify(token);
  if (payload == null) return null;
  final userId = payload['sub'] as String?;
  if (userId == null) return null;
  return db.findById(userId);
}

Response _json(Map<String, dynamic> body, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Future<Map<String, dynamic>?> _readJson(Request request) async {
  try {
    final raw = await request.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  } catch (_) {
    return null;
  }
}

Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}

final _games = <String, _GameRoom>{};
final _privateLobbies = <String, _PrivateLobby>{};
final _gameIdByCode = <String, String>{};

class _PrivateLobby {
  _PrivateLobby({
    required this.code,
    required this.host,
  });

  final String code;
  final _QueuedPlayer host;
}

String _newRoomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final now = DateTime.now().microsecondsSinceEpoch;
  var x = now ^ Object().hashCode;
  final buf = StringBuffer();
  for (var i = 0; i < 6; i++) {
    x = 1103515245 * x + 12345;
    buf.write(alphabet[x.abs() % alphabet.length]);
  }
  var code = buf.toString();
  while (_privateLobbies.containsKey(code) || _gameIdByCode.containsKey(code)) {
    x = 1103515245 * x + 12345;
    code = List.generate(
      6,
      (i) => alphabet[(x + i * 17).abs() % alphabet.length],
    ).join();
  }
  return code;
}

void _broadcastLobbySnapshot(WebSocketChannel channel) {
  try {
    channel.sink.add(jsonEncode({
      'type': 'lobby_snapshot',
      'seeks': _lobby.snapshot(exclude: channel),
      'count': _lobby.totalSeekers,
    }));
  } catch (_) {}
}

Future<void> _startCrossInstanceMatch({
  required _QueuedPlayer local,
  required Map<String, dynamic> peer,
  required TimeControl tc,
  required bool rated,
  required String localSeekId,
}) async {
  _lobby.cancel(local.channel);
  await RedisLobby.instance.dequeue(localSeekId, tcId: tc.id, rated: rated);
  _seekIdByChannel.remove(local.channel);
  _seekPlayerById.remove(localSeekId);

  final remote = _QueuedPlayer(
    channel: local.channel, // placeholder; remote=true → cluster-only
    name: peer['name'] as String? ?? 'Player',
    userId: peer['userId'] as String?,
    rating: (peer['rating'] as num?)?.toInt(),
    remote: true,
  );
  final isRated =
      rated && local.userId != null && remote.userId != null;
  final gameId = DateTime.now().millisecondsSinceEpoch.toString();
  // Local is white, remote black (claiming instance hosts).
  final room = _GameRoom(
    id: gameId,
    white: local,
    black: remote,
    resumeTokenWhite: _newResumeToken(),
    resumeTokenBlack: _newResumeToken(),
    timeControl: tc,
    rated: isRated,
  );
  room.blackConnected = false;
  _games[gameId] = room;
  _registerOwnedRoom(room);

  local.channel.sink.add(jsonEncode({
    'type': 'matched',
    'gameId': gameId,
    'color': 'white',
    'resumeToken': room.resumeTokenWhite,
    'opponentName': remote.name,
    'rated': isRated,
    'yourRating': local.rating,
    'opponentRating': remote.rating,
    'opponentLoggedIn': remote.userId != null,
    'tc': tc.id,
    'initialMs': tc.initialMs,
    'incrementMs': tc.incrementMs,
    'bucket': tc.bucket.name,
  }));

  await RedisLobby.instance.publishMatch({
    'targetSeekId': peer['seekId'],
    'targetInstance': peer['instanceId'],
    'gameId': gameId,
    'color': 'black',
    'resumeToken': room.resumeTokenBlack,
    'opponentName': local.name,
    'rated': isRated,
    'yourRating': remote.rating,
    'opponentRating': local.rating,
    'opponentLoggedIn': local.userId != null,
    'tc': tc.id,
    'initialMs': tc.initialMs,
    'incrementMs': tc.incrementMs,
    'bucket': tc.bucket.name,
  });
}

void _onRedisLobbyMatch(Map<String, dynamic> match) {
  final seekId = match['targetSeekId'] as String?;
  if (seekId == null) return;
  final player = _seekPlayerById.remove(seekId);
  if (player == null) return;
  final channel = player.channel;
  _seekIdByChannel.remove(channel);
  _lobby.cancel(channel);
  unawaited(
    RedisLobby.instance.dequeue(
      seekId,
      tcId: match['tc'] as String?,
      rated: match['rated'] as bool?,
    ),
  );
  final gameId = match['gameId'] as String?;
  final resume = match['resumeToken'] as String?;
  if (gameId != null && resume != null) {
    ClusterBridge.instance.attachLocal(
      gameId,
      channel,
      color: match['color'] as String?,
      resumeToken: resume,
    );
  }
  try {
    channel.sink.add(jsonEncode({
      'type': 'matched',
      ...match,
    }));
  } catch (_) {}
}

/// Disconnect grace before forfeit (override with GRACE_MS for tests).
final int _graceMs =
    int.tryParse(Platform.environment['GRACE_MS'] ?? '') ?? 90000;

String _newResumeToken() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final rnd = now.hashCode.abs() ^ Object().hashCode;
  return '${now.toRadixString(36)}_${rnd.toRadixString(36)}';
}

class _QueuedPlayer {
  _QueuedPlayer({
    required this.channel,
    required this.name,
    this.userId,
    this.rating,
    this.remote = false,
  });

  WebSocketChannel channel;
  final String name;
  final String? userId;
  final int? rating;
  final bool remote;
}

class _GameRoom {
  _GameRoom({
    required this.id,
    required this.white,
    required this.black,
    required this.resumeTokenWhite,
    required this.resumeTokenBlack,
    this.roomCode,
    this.rated = false,
    TimeControl? timeControl,
  }) : tc = timeControl ?? defaultTimeControl {
    authority = GameAuthority(tc: tc);
  }

  final String id;
  final _QueuedPlayer white;
  final _QueuedPlayer black;
  final String resumeTokenWhite;
  final String resumeTokenBlack;
  final String? roomCode;
  final bool rated;
  final TimeControl tc;
  late final GameAuthority authority;
  final List<Map<String, dynamic>> eventLog = [];
  final List<WebSocketChannel> spectators = [];

  bool whiteConnected = true;
  bool blackConnected = true;
  Timer? graceTimer;
  String? disconnectedSide; // 'white' | 'black'
  bool closed = false;

  bool get bothConnected => whiteConnected && blackConnected;

  bool ownsChannel(WebSocketChannel channel) =>
      white.channel == channel || black.channel == channel;

  bool isSpectator(WebSocketChannel channel) => spectators.contains(channel);

  String? colorOf(WebSocketChannel channel) {
    if (white.channel == channel) return 'white';
    if (black.channel == channel) return 'black';
    return null;
  }

  _QueuedPlayer playerOf(String color) =>
      color == 'white' ? white : black;

  String resumeTokenOf(String color) =>
      color == 'white' ? resumeTokenWhite : resumeTokenBlack;

  void relay(WebSocketChannel from, Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final enriched = Map<String, dynamic>.from(message);
    final fromColor = colorOf(from);
    if (fromColor != null) {
      enriched['fromColor'] = fromColor;
    }
    _relayEnriched(fromColor: fromColor, enriched: enriched, type: type);
  }

  void relayAsColor(String fromColor, Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final enriched = Map<String, dynamic>.from(message);
    enriched['fromColor'] = fromColor;
    _relayEnriched(fromColor: fromColor, enriched: enriched, type: type);
  }

  void _relayEnriched({
    required String? fromColor,
    required Map<String, dynamic> enriched,
    required String? type,
  }) {
    // Persist gameplay messages for resume replay (not chat / rematch).
    if (type != null &&
        type != 'chat' &&
        type != 'rematch_offer' &&
        type != 'rematch_accept' &&
        type != 'ping' &&
        type != 'pong') {
      eventLog.add(Map<String, dynamic>.from(enriched));
    }

    if (fromColor != null) {
      final peer = fromColor == 'white' ? 'black' : 'white';
      sendTo(peer, enriched, cluster: false);
    }
    _fanoutSpectators(enriched);
    unawaited(ClusterBridge.instance.publishGameEvent(id, enriched));
  }

  void sendTo(
    String color,
    Map<String, dynamic> message, {
    bool cluster = true,
  }) {
    final seat = playerOf(color);
    final connected = color == 'white' ? whiteConnected : blackConnected;
    if (connected && !seat.remote) {
      try {
        seat.channel.sink.add(jsonEncode(message));
      } catch (_) {}
    }
    if (cluster) {
      unawaited(
        ClusterBridge.instance.publishGameEvent(
          id,
          message,
          toColor: color,
        ),
      );
    }
  }

  void _fanoutSpectators(Map<String, dynamic> message) {
    final raw = jsonEncode(message);
    for (final s in spectators.toList()) {
      try {
        s.sink.add(raw);
      } catch (_) {
        spectators.remove(s);
      }
    }
  }

  void broadcast(Map<String, dynamic> message) {
    for (final color in ['white', 'black']) {
      sendTo(color, message, cluster: false);
    }
    _fanoutSpectators(message);
    unawaited(ClusterBridge.instance.publishGameEvent(id, message));
  }

  void addSpectator(WebSocketChannel channel) {
    if (!spectators.contains(channel)) spectators.add(channel);
  }

  void removeSpectator(WebSocketChannel channel) {
    spectators.remove(channel);
  }

  void onSeatDisconnected(WebSocketChannel channel) {
    if (closed) return;
    if (isSpectator(channel)) {
      removeSpectator(channel);
      return;
    }
    final color = colorOf(channel);
    if (color == null) return;

    if (color == 'white') {
      whiteConnected = false;
    } else {
      blackConnected = false;
    }
    disconnectedSide = color;

    if (!whiteConnected && !blackConnected) {
      close(notifyOpponentLeft: false);
      return;
    }

    final peerColor = color == 'white' ? 'black' : 'white';
    sendTo(peerColor, {
      'type': 'opponent_disconnected',
      'graceMs': _graceMs,
      'gameId': id,
    });

    graceTimer?.cancel();
    graceTimer = Timer(Duration(milliseconds: _graceMs), forfeitDisconnect);
  }

  void forfeitDisconnect() {
    if (closed) return;
    final side = disconnectedSide;
    if (side == null) return;
    final stillDown = side == 'white' ? !whiteConnected : !blackConnected;
    if (!stillDown) return;

    final end = authority.applyDisconnectForfeit(
      disconnectedColor: side,
    );
    final msg = <String, dynamic>{
      ...?end.broadcast,
      'gameId': id,
    };
    eventLog.add(Map<String, dynamic>.from(msg));
    broadcast(msg);
    unawaited(_finalizeGameRoom(this, {
      'winner': end.winner,
      'reason': end.reason,
      'detail': end.detail,
    }));
    close(notifyOpponentLeft: false);
  }

  /// Intentional leave: peer wins immediately (no grace).
  void leaveBy(WebSocketChannel channel) {
    if (closed) return;
    final color = colorOf(channel);
    if (color == null) return;
    final winner = color == 'white' ? 'black' : 'white';
    final msg = <String, dynamic>{
      'type': 'game_over',
      'gameId': id,
      'winner': winner,
      'reason': 'disconnect',
      'detail': 'leave',
      'fromColor': color,
    };
    eventLog.add(Map<String, dynamic>.from(msg));
    final peer = color == 'white' ? 'black' : 'white';
    sendTo(peer, msg);
    close(notifyOpponentLeft: false);
  }

  Map<String, dynamic>? tryResume({
    required WebSocketChannel channel,
    required String resumeToken,
  }) {
    if (closed) return null;
    String? color;
    if (resumeToken == resumeTokenWhite && !whiteConnected) {
      color = 'white';
      white.channel = channel;
      whiteConnected = true;
    } else if (resumeToken == resumeTokenBlack && !blackConnected) {
      color = 'black';
      black.channel = channel;
      blackConnected = true;
    } else {
      return null;
    }
    ClusterBridge.instance.attachLocal(
      id,
      channel,
      color: color,
      resumeToken: resumeToken,
    );
    return _resumePayload(color);
  }

  /// Resume from another instance: mark seat online without rebinding channel.
  Map<String, dynamic>? tryResumeRemote({required String resumeToken}) {
    if (closed) return null;
    String? color;
    if (resumeToken == resumeTokenWhite && !whiteConnected) {
      color = 'white';
      whiteConnected = true;
    } else if (resumeToken == resumeTokenBlack && !blackConnected) {
      color = 'black';
      blackConnected = true;
    } else if (resumeToken == resumeTokenWhite) {
      color = 'white';
      whiteConnected = true;
    } else if (resumeToken == resumeTokenBlack) {
      color = 'black';
      blackConnected = true;
    } else {
      return null;
    }
    return _resumePayload(color);
  }

  Map<String, dynamic> _resumePayload(String seatColor) {
    if (disconnectedSide == seatColor) {
      disconnectedSide = null;
      graceTimer?.cancel();
      graceTimer = null;
    }

    final peerColor = seatColor == 'white' ? 'black' : 'white';
    final peer = playerOf(peerColor);
    sendTo(peerColor, {
      'type': 'opponent_reconnected',
      'gameId': id,
    });

    return {
      'type': 'resume_ok',
      'gameId': id,
      'color': seatColor,
      'resumeToken': resumeTokenOf(seatColor),
      'opponentName': peer.name,
      'rated': rated,
      'yourRating': playerOf(seatColor).rating,
      'opponentRating': peer.rating,
      'opponentLoggedIn': peer.userId != null,
      'eventLog': eventLog,
    };
  }

  void close({bool notifyOpponentLeft = true}) {
    if (closed) return;
    closed = true;
    graceTimer?.cancel();
    graceTimer = null;
    FairPlayMonitor.instance.onGameEnd(id);
    ClusterBridge.instance.clearIngressHandler(id);
    unawaited(ClusterBridge.instance.releaseGameOwnership(id));
    if (notifyOpponentLeft) {
      for (final color in ['white', 'black']) {
        final connected = color == 'white' ? whiteConnected : blackConnected;
        if (!connected) continue;
        try {
          playerOf(color).channel.sink.add(
            jsonEncode({'type': 'opponent_left', 'gameId': id}),
          );
        } catch (_) {}
      }
      unawaited(
        ClusterBridge.instance.publishGameEvent(
          id,
          {'type': 'opponent_left', 'gameId': id},
        ),
      );
    }
    if (roomCode != null) {
      _gameIdByCode.remove(roomCode);
    }
    _games.remove(id);
  }
}

void _registerOwnedRoom(_GameRoom room) {
  ClusterBridge.instance.setIngressHandler(
    room.id,
    (msg) => _handleClusterIngress(room.id, msg),
  );
  unawaited(ClusterBridge.instance.claimGameOwnership(room.id));
  ClusterBridge.instance.attachLocal(
    room.id,
    room.white.channel,
    color: 'white',
    resumeToken: room.resumeTokenWhite,
  );
  ClusterBridge.instance.attachLocal(
    room.id,
    room.black.channel,
    color: 'black',
    resumeToken: room.resumeTokenBlack,
  );
  FairPlayMonitor.instance.onGameStart(room.id, rated: room.rated);
}

Future<void> _handleClusterIngress(
  String gameId,
  Map<String, dynamic> data,
) async {
  final room = _games[gameId];
  if (room == null || room.closed) return;

  final type = data['type'] as String?;
  final resume = data['_resumeToken'] as String? ??
      data['resumeToken'] as String?;
  String? color = data['_seatColor'] as String?;
  if (color == null && resume != null) {
    if (resume == room.resumeTokenWhite) color = 'white';
    if (resume == room.resumeTokenBlack) color = 'black';
  }

  if (type == 'resume_game') {
    if (resume == null) return;
    final ok = room.tryResumeRemote(resumeToken: resume);
    if (ok == null) {
      await ClusterBridge.instance.publishGameEvent(
        gameId,
        {'type': 'resume_failed', 'message': 'Не удалось переподключиться'},
        toResumeToken: resume,
      );
      return;
    }
    await ClusterBridge.instance.publishGameEvent(
      gameId,
      ok,
      toResumeToken: resume,
    );
    return;
  }

  if (color == null) return;

  if (type == 'move') {
    await _applyAuthoritativeMove(room, fromColor: color, data: data);
    return;
  }

  const authoritative = {
    'ability',
    'start_ability',
    'ability_target',
    'reaction',
    'reroll',
    'skip_turn',
    'resign',
    'game_over',
    'draw_response',
  };
  if (authoritative.contains(type)) {
    await _handleAuthoritativeAction(room, fromColor: color, data: data);
    return;
  }
  room.relayAsColor(color, data);
}

void _startRematch(_GameRoom room, {required WebSocketChannel accepter}) {
  if (!room.bothConnected) {
    try {
      accepter.sink.add(jsonEncode({
        'type': 'error',
        'message': 'Соперник не в сети — реванш недоступен',
      }));
    } catch (_) {}
    return;
  }
  room.close(notifyOpponentLeft: false);
  final newId = '${DateTime.now().millisecondsSinceEpoch}_r';
  // Swap colors for rematch.
  final white = room.black;
  final black = room.white;
  final rated = room.rated &&
      white.userId != null &&
      black.userId != null;
  final next = _GameRoom(
    id: newId,
    white: white,
    black: black,
    resumeTokenWhite: _newResumeToken(),
    resumeTokenBlack: _newResumeToken(),
    roomCode: room.roomCode,
    rated: rated,
    timeControl: room.tc,
  );
  _games[newId] = next;
  _registerOwnedRoom(next);
  if (room.roomCode != null) {
    _gameIdByCode[room.roomCode!] = newId;
  }

  void sendMatched(_QueuedPlayer player, String color, _QueuedPlayer opp) {
    final token = color == 'white'
        ? next.resumeTokenWhite
        : next.resumeTokenBlack;
    player.channel.sink.add(jsonEncode({
      'type': 'rematch_start',
      'gameId': newId,
      'color': color,
      'resumeToken': token,
      'roomCode': next.roomCode,
      'opponentName': opp.name,
      'rated': rated,
      'yourRating': player.rating,
      'opponentRating': opp.rating,
      'opponentLoggedIn': opp.userId != null,
    }));
  }

  sendMatched(white, 'white', black);
  sendMatched(black, 'black', white);
}

Future<void> _applyAuthoritativeMove(
  _GameRoom room, {
  required String fromColor,
  required Map<String, dynamic> data,
  void Function(Map<String, dynamic>)? reply,
}) async {
  final gameId = room.id;
  final move = data['move'];
  if (move is! Map) {
    reply?.call({'type': 'illegal_move', 'message': 'bad_payload'});
    return;
  }
  final fenBefore = room.authority.fenBeforeMove();
  final err = room.authority.applyMove(
    fromColor: fromColor,
    moveJson: Map<String, dynamic>.from(move),
  );
  if (err != null) {
    reply?.call({
      'type': 'illegal_move',
      'message': err,
      'gameId': gameId,
    });
    if (reply == null) {
      await ClusterBridge.instance.publishGameEvent(
        gameId,
        {
          'type': 'illegal_move',
          'message': err,
          'gameId': gameId,
        },
        toColor: fromColor,
      );
    }
    return;
  }

  final moveUci = FairPlayMonitor.moveJsonToUci(
    Map<String, dynamic>.from(move),
  );
  FairPlayMonitor.instance.sampleMove(
    gameId: gameId,
    userId: room.playerOf(fromColor).userId,
    color: fromColor,
    fenBefore: fenBefore,
    moveUci: moveUci,
    rated: room.rated,
  );

  final clock = room.authority.clock.snapshot();
  room.relayAsColor(fromColor, {
    ...data,
    'whiteMs': clock['whiteMs'],
    'blackMs': clock['blackMs'],
    'stateHash': room.authority.currentStateHash(),
  });
  room.broadcast({
    'type': 'clock_sync',
    'gameId': gameId,
    'whiteMs': clock['whiteMs'],
    'blackMs': clock['blackMs'],
    'active': clock['active'],
  });

  if (room.authority.game.isGameOver) {
    await _broadcastAuthority(
      room,
      'server',
      AuthorityResult(
        broadcast: {
          'type': 'game_over',
          'winner': room.authority.winnerColorName,
          'reason': room.authority.endReasonName ?? 'ended',
          'fromColor': 'server',
          'stateHash': room.authority.currentStateHash(),
        },
        gameOver: true,
        winner: room.authority.winnerColorName,
        reason: room.authority.endReasonName ?? 'ended',
      ),
    );
    return;
  }

  final flagged = room.authority.clock.flaggedColor;
  if (flagged != null) {
    final timeout = room.authority.applyTimeout(flaggedColor: flagged);
    await _broadcastAuthority(room, 'server', timeout);
  }
}

Future<void> _finalizeGameRoom(
  _GameRoom room,
  Map<String, dynamic> data,
) async {
  if (room.authority.finalized) return;
  room.authority.finalized = true;
  FairPlayMonitor.instance.onGameEnd(room.id);
  final db = _authDb;
  final winner = data['winner'] as String? ?? room.authority.winnerColorName;
  final reason = data['reason'] as String? ?? room.authority.endReasonName;
  final result = winner == 'white'
      ? '1-0'
      : winner == 'black'
          ? '0-1'
          : '1/2-1/2';
  final pgn = room.authority.toPgn(
    white: room.white.name,
    black: room.black.name,
    whiteElo: '${room.white.rating ?? ''}',
    blackElo: '${room.black.rating ?? ''}',
    result: result,
  );
  if (db == null) return;
  try {
    await db.saveGamePgn(room.id, pgn);
    // Authoritative rated result (Elo) — do not wait for clients.
    if (room.rated &&
        room.white.userId != null &&
        room.black.userId != null) {
      await db.submitGameResult(
        gameId: room.id,
        userId: room.white.userId!,
        color: 'white',
        winner: winner,
        reason: reason,
        reasonDetail: data['detail'] as String?,
        opponentUserId: room.black.userId,
        opponentName: room.black.name,
        abilities: const [],
      );
      await db.submitGameResult(
        gameId: room.id,
        userId: room.black.userId!,
        color: 'black',
        winner: winner,
        reason: reason,
        reasonDetail: data['detail'] as String?,
        opponentUserId: room.white.userId,
        opponentName: room.white.name,
        abilities: const [],
      );
    }
    final jobId = await db.enqueueAnalysis(room.id);
    unawaited(runAnalysisJob(db: db, jobId: jobId, gameId: room.id));
  } catch (_) {}
}

Future<void> _broadcastAuthority(
  _GameRoom room,
  String fromColor,
  AuthorityResult result,
) async {
  if (!result.ok) return;
  final raw = result.broadcast;
  if (raw != null) {
    final payload = Map<String, dynamic>.from(raw);
    payload['gameId'] = room.id;
    payload.putIfAbsent('fromColor', () => fromColor);
    room.eventLog.add(Map<String, dynamic>.from(payload));
    room.broadcast(payload);
  }
  if (result.gameOver) {
    await _finalizeGameRoom(room, {
      'winner': result.winner,
      'reason': result.reason,
      'detail': result.detail,
    });
    if (!room.closed) room.close(notifyOpponentLeft: false);
  }
}

Future<void> _handleAuthoritativeAction(
  _GameRoom room, {
  required String fromColor,
  required Map<String, dynamic> data,
  void Function(Map<String, dynamic>)? reply,
}) async {
  final type = data['type'] as String?;
  AuthorityResult result;
  switch (type) {
    case 'start_ability':
      final offerRaw = data['offer'];
      result = room.authority.applyStartAbility(
        fromColor: fromColor,
        color: data['color'] as String? ?? fromColor,
        abilityName: '${data['ability'] ?? ''}',
        lavaRank: (data['lavaRank'] as num?)?.toInt(),
        offerJson: offerRaw is Map
            ? Map<String, dynamic>.from(offerRaw)
            : null,
      );
    case 'ability':
      final offerRaw = data['offer'];
      result = room.authority.applyAbility(
        fromColor: fromColor,
        abilityName: '${data['ability'] ?? ''}',
        offerJson: offerRaw is Map
            ? Map<String, dynamic>.from(offerRaw)
            : null,
      );
    case 'ability_target':
      final sq = data['square'];
      result = room.authority.applyAbilityTarget(
        fromColor: fromColor,
        pieceId: data['pieceId'] as String?,
        squareJson: sq is Map ? Map<String, dynamic>.from(sq) : null,
        index: (data['index'] as num?)?.toInt() ?? 0,
        removeAbilityName: data['removeAbility'] as String?,
      );
    case 'reaction':
      result = room.authority.applyReaction(
        fromColor: fromColor,
        accepted: data['accepted'] as bool? ?? false,
        abilityName: data['ability'] as String?,
      );
    case 'reroll':
      result = room.authority.applyReroll(
        fromColor: fromColor,
        color: data['color'] as String? ?? fromColor,
      );
    case 'skip_turn':
      result = room.authority.applySkipTurn(fromColor: fromColor);
    case 'resign':
      result = room.authority.applyResign(fromColor: fromColor);
    case 'draw_response':
      if (data['accepted'] == true) {
        result = room.authority.applyDrawAgreed();
      } else {
        room.relayAsColor(fromColor, data);
        return;
      }
    case 'game_over':
      result = room.authority.confirmClientGameOver(
        winner: data['winner'] as String?,
        reason: data['reason'] as String?,
        detail: data['detail'] as String?,
      );
    default:
      return;
  }
  if (!result.ok) {
    final err = {
      'type': 'illegal_action',
      'message': result.error,
      'gameId': room.id,
      'action': type,
    };
    reply?.call(err);
    return;
  }
  await _broadcastAuthority(room, fromColor, result);
}

class _ClientConnection {
  _ClientConnection(this._channel);

  final WebSocketChannel _channel;

  void listen() {
    _channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          unawaited(_handle(data));
        } catch (_) {
          _send({'type': 'error', 'message': 'Неверное сообщение'});
        }
      },
      onDone: _onDisconnect,
    );
  }

  Future<void> _handle(Map<String, dynamic> data) async {
    switch (data['type'] as String?) {
      case 'find_game':
      case 'seek':
      case 'requeue':
        await _enqueue(
          name: data['name'] as String? ?? 'Player',
          token: data['token'] as String?,
          tcId: data['tc'] as String? ?? data['timeControl'] as String?,
          rated: data['rated'] as bool?,
        );
      case 'cancel_seek':
        _lobby.cancel(_channel);
        _broadcastLobbySnapshot(_channel);
      case 'lobby_subscribe':
        _broadcastLobbySnapshot(_channel);
      case 'presence_ping':
        await _presencePing(data['token'] as String?);
      case 'dm':
        await _handleDm(data);
      case 'ping':
        _send({'type': 'pong', 't': data['t']});
      case 'resume_game':
        await _handleResume(data);
      case 'leave_game':
        _handleLeave(data);
      case 'create_private':
        await _createPrivate(
          name: data['name'] as String? ?? 'Player',
          token: data['token'] as String?,
        );
      case 'join_private':
        await _joinPrivate(
          code: '${data['code'] ?? ''}'.toUpperCase().trim(),
          name: data['name'] as String? ?? 'Player',
          token: data['token'] as String?,
        );
      case 'cancel_private':
        _cancelPrivate();
      case 'spectate_private':
        _spectatePrivate('${data['code'] ?? ''}'.toUpperCase().trim());
      case 'leave_spectate':
        _leaveSpectate(data['gameId'] as String?);
      case 'stockfish_ping':
        final ok = await StockfishService.instance.ensureStarted();
        _send({
          'type': 'stockfish_pong',
          'available': ok,
          if (!ok && StockfishService.instance.lastError != null)
            'error': StockfishService.instance.lastError,
        });
      case 'stockfish_go':
        await _handleStockfishGo(data);
      case 'move':
        await _handleAuthoritativeMove(data);
      case 'ability':
      case 'start_ability':
      case 'ability_target':
      case 'reaction':
      case 'reroll':
      case 'skip_turn':
      case 'resign':
      case 'game_over':
      case 'draw_response':
        final gameId = data['gameId'] as String?;
        final room = gameId != null ? _games[gameId] : null;
        if (room == null) {
          await _forwardIfRemote(gameId, data);
          return;
        }
        if (!room.ownsChannel(_channel)) return;
        final fromColor = room.colorOf(_channel);
        if (fromColor == null) return;
        // draw_response declines still relay; accepts go through authority.
        if (data['type'] == 'draw_response' && data['accepted'] != true) {
          room.relay(_channel, data);
          return;
        }
        await _handleAuthoritativeAction(
          room,
          fromColor: fromColor,
          data: data,
          reply: _send,
        );
      case 'state_resync':
      case 'chat':
      case 'draw_offer':
      case 'takeback_offer':
      case 'takeback_response':
      case 'clock_sync':
      case 'rematch_offer':
      case 'rematch_accept':
        final gameId = data['gameId'] as String?;
        final room = gameId != null ? _games[gameId] : null;
        if (room == null) {
          await _forwardIfRemote(gameId, data);
          return;
        }
        if (!room.ownsChannel(_channel)) return;
        if (data['type'] == 'rematch_accept') {
          _startRematch(room, accepter: _channel);
          return;
        }
        room.relay(_channel, data);
      default:
        _send({'type': 'error', 'message': 'Unknown message type'});
    }
  }

  Future<bool> _forwardIfRemote(
    String? gameId,
    Map<String, dynamic> data, {
    String? resumeToken,
    String? seatColor,
  }) async {
    if (gameId == null || !RedisBus.instance.enabled) return false;
    final owner = await ClusterBridge.instance.ownerOf(gameId);
    if (owner == null || owner == RedisBus.instance.instanceId) return false;
    final meta = ClusterBridge.instance.seatMeta(_channel);
    final color = seatColor ?? meta?.color;
    final token = resumeToken ??
        data['resumeToken'] as String? ??
        meta?.resumeToken;
    ClusterBridge.instance.attachLocal(
      gameId,
      _channel,
      color: color,
      resumeToken: token,
    );
    await ClusterBridge.instance.publishIngress(gameId, {
      ...data,
      if (token != null) '_resumeToken': token,
      if (color != null) '_seatColor': color,
    });
    return true;
  }

  Future<void> _handleResume(Map<String, dynamic> data) async {
    final gameId = data['gameId'] as String?;
    final token = data['resumeToken'] as String?;
    if (gameId == null || token == null || token.isEmpty) {
      _send({'type': 'resume_failed', 'message': 'Нет данных для восстановления'});
      return;
    }
    final room = _games[gameId];
    if (room == null) {
      final forwarded = await _forwardIfRemote(
        gameId,
        data,
        resumeToken: token,
      );
      if (!forwarded) {
        _send({'type': 'resume_failed', 'message': 'Партия не найдена'});
      }
      return;
    }
    final ok = room.tryResume(channel: _channel, resumeToken: token);
    if (ok == null) {
      _send({'type': 'resume_failed', 'message': 'Не удалось переподключиться'});
      return;
    }
    _send(ok);
  }

  void _handleLeave(Map<String, dynamic> data) {
    final gameId = data['gameId'] as String?;
    final room = gameId != null ? _games[gameId] : null;
    if (room == null) return;
    if (!room.ownsChannel(_channel)) return;
    room.leaveBy(_channel);
  }

  Future<void> _handleStockfishGo(Map<String, dynamic> data) async {
    final id = data['id']?.toString() ?? '';
    final fen = data['fen'] as String?;
    final movetime = (data['movetime'] as num?)?.toInt() ?? 2000;
    if (fen == null || fen.isEmpty) {
      _send({
        'type': 'stockfish_bestmove',
        'id': id,
        'move': null,
        'error': 'missing fen',
      });
      return;
    }
    final move = await StockfishService.instance.goBestMove(
      fen: fen,
      movetimeMs: movetime,
    );
    _send({
      'type': 'stockfish_bestmove',
      'id': id,
      'move': move,
      if (move == null) 'error': StockfishService.instance.lastError ?? 'no move',
    });
  }

  Future<_QueuedPlayer> _resolvePlayer({
    required String name,
    String? token,
  }) async {
    var displayName = name;
    String? userId;
    int? rating;
    if (token != null &&
        token.isNotEmpty &&
        _authDb != null &&
        _authTokens != null) {
      final payload = _authTokens!.verify(token);
      final sub = payload?['sub'] as String?;
      if (sub != null) {
        final user = await _authDb!.findById(sub);
        if (user != null) {
          displayName = user.username;
          userId = user.id;
          rating = user.rating;
        }
      }
    }
    return _QueuedPlayer(
      channel: _channel,
      name: displayName,
      userId: userId,
      rating: rating,
    );
  }

  Future<void> _createPrivate({required String name, String? token}) async {
    _cancelPrivate();
    final host = await _resolvePlayer(name: name, token: token);
    final code = _newRoomCode();
    _privateLobbies[code] = _PrivateLobby(code: code, host: host);
    _send({
      'type': 'private_waiting',
      'code': code,
    });
  }

  void _cancelPrivate() {
    final codes = _privateLobbies.entries
        .where((e) => e.value.host.channel == _channel)
        .map((e) => e.key)
        .toList();
    for (final c in codes) {
      _privateLobbies.remove(c);
    }
  }

  Future<void> _joinPrivate({
    required String code,
    required String name,
    String? token,
  }) async {
    final lobby = _privateLobbies.remove(code);
    if (lobby == null) {
      // Maybe already a running game — allow join only via spectate.
      _send({'type': 'error', 'message': 'Комната не найдена'});
      return;
    }
    if (lobby.host.channel == _channel) {
      _privateLobbies[code] = lobby;
      _send({'type': 'error', 'message': 'Нельзя войти в свою комнату'});
      return;
    }
    final joiner = await _resolvePlayer(name: name, token: token);
    final gameId = DateTime.now().millisecondsSinceEpoch.toString();
    final room = _GameRoom(
      id: gameId,
      white: lobby.host,
      black: joiner,
      resumeTokenWhite: _newResumeToken(),
      resumeTokenBlack: _newResumeToken(),
      roomCode: code,
      rated: false,
    );
    _games[gameId] = room;
    _registerOwnedRoom(room);
    _gameIdByCode[code] = gameId;

    void sendMatched(_QueuedPlayer player, String color, _QueuedPlayer opp) {
      final token = color == 'white'
          ? room.resumeTokenWhite
          : room.resumeTokenBlack;
      player.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': color,
        'resumeToken': token,
        'roomCode': code,
        'opponentName': opp.name,
        'rated': false,
        'yourRating': player.rating,
        'opponentRating': opp.rating,
        'opponentLoggedIn': opp.userId != null,
      }));
    }

    sendMatched(lobby.host, 'white', joiner);
    sendMatched(joiner, 'black', lobby.host);
  }

  void _spectatePrivate(String code) {
    final gameId = _gameIdByCode[code];
    final room = gameId != null ? _games[gameId] : null;
    if (room == null || room.closed) {
      _send({'type': 'error', 'message': 'Партия для просмотра не найдена'});
      return;
    }
    if (room.ownsChannel(_channel)) {
      _send({'type': 'error', 'message': 'Вы уже в этой партии'});
      return;
    }
    room.addSpectator(_channel);
    _send({
      'type': 'spectate_ok',
      'gameId': room.id,
      'roomCode': room.roomCode,
      'whiteName': room.white.name,
      'blackName': room.black.name,
      'eventLog': room.eventLog,
    });
  }

  void _leaveSpectate(String? gameId) {
    final room = gameId != null ? _games[gameId] : null;
    if (room == null) {
      for (final r in _games.values) {
        r.removeSpectator(_channel);
      }
      return;
    }
    room.removeSpectator(_channel);
  }

  Future<void> _enqueue({
    required String name,
    String? token,
    String? tcId,
    bool? rated,
  }) async {
    final player = await _resolvePlayer(name: name, token: token);
    final tc = TimeControl.byId(tcId ?? '5+0') ?? defaultTimeControl;
    var wantRated = rated ?? (player.userId != null);
    if (player.userId == null) wantRated = false;

    int? bucketRating = player.rating;
    final db = _authDb;
    if (db != null && player.userId != null) {
      await db.ensureUserRatings(player.userId!);
      bucketRating = await db.ratingForBucket(player.userId!, tc.bucket.name);
      await db.touchPresence(player.userId!);
      _onlineUserIds.add(player.userId!);
      _channelUserIds[_channel] = player.userId!;
    }

    final lobbyPlayer = LobbyPlayer(
      channel: player.channel,
      name: player.name,
      userId: player.userId,
      rating: bucketRating,
    );
    final seek = LobbySeek(player: lobbyPlayer, tc: tc, rated: wantRated);
    final match = _lobby.place(seek);
    if (match == null) {
      final seekId =
          '${RedisBus.instance.instanceId}_${tc.id}_${wantRated}_${player.userId ?? player.name}_${DateTime.now().microsecondsSinceEpoch}';
      _seekIdByChannel[_channel] = seekId;
      _seekPlayerById[seekId] = player;
      final peer = await RedisLobby.instance.tryClaimPeer(
        tcId: tc.id,
        rated: wantRated,
        localSeekId: seekId,
      );
      if (peer != null) {
        await _startCrossInstanceMatch(
          local: player,
          peer: peer,
          tc: tc,
          rated: wantRated,
          localSeekId: seekId,
        );
        return;
      }
      await RedisLobby.instance.enqueue({
        'seekId': seekId,
        'tc': tc.id,
        'rated': wantRated,
        'name': player.name,
        'userId': player.userId,
        'rating': bucketRating,
        'instanceId': RedisBus.instance.instanceId,
      });
      _send({
        'type': 'searching',
        'count': _lobby.totalSeekers,
        'tc': tc.id,
        'rated': wantRated,
      });
      _broadcastLobbySnapshot(_channel);
      return;
    }
    final localSeekId = _seekIdByChannel.remove(_channel);
    if (localSeekId != null) {
      _seekPlayerById.remove(localSeekId);
      unawaited(
        RedisLobby.instance.dequeue(
          localSeekId,
          tcId: tc.id,
          rated: wantRated,
        ),
      );
    }

    final whiteLp = match.a.player;
    final blackLp = match.b.player;
    final white = _QueuedPlayer(
      channel: whiteLp.channel,
      name: whiteLp.name,
      userId: whiteLp.userId,
      rating: whiteLp.rating,
    );
    final black = _QueuedPlayer(
      channel: blackLp.channel,
      name: blackLp.name,
      userId: blackLp.userId,
      rating: blackLp.rating,
    );
    final gameId = DateTime.now().millisecondsSinceEpoch.toString();
    final isRated = wantRated &&
        white.userId != null &&
        black.userId != null;
    final room = _GameRoom(
      id: gameId,
      white: white,
      black: black,
      resumeTokenWhite: _newResumeToken(),
      resumeTokenBlack: _newResumeToken(),
      timeControl: tc,
      rated: isRated,
    );
    _games[gameId] = room;
    _registerOwnedRoom(room);
    unawaited(
      ClusterBridge.instance.publishLobbyHint({
        'event': 'matched',
        'tc': tc.id,
        'rated': isRated,
      }),
    );

    void sendMatched(_QueuedPlayer seat, String color, _QueuedPlayer opp) {
      seat.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': color,
        'resumeToken': room.resumeTokenOf(color),
        'opponentName': opp.name,
        'rated': isRated,
        'yourRating': seat.rating,
        'opponentRating': opp.rating,
        'opponentLoggedIn': opp.userId != null,
        'tc': tc.id,
        'initialMs': tc.initialMs,
        'incrementMs': tc.incrementMs,
        'bucket': tc.bucket.name,
      }));
    }

    sendMatched(white, 'white', black);
    sendMatched(black, 'black', white);
  }

  Future<void> _presencePing(String? token) async {
    final db = _authDb;
    final tokens = _authTokens;
    if (db == null || tokens == null || token == null) return;
    final payload = tokens.verify(token);
    final id = payload?['sub'] as String?;
    if (id == null) return;
    await db.touchPresence(id);
    _onlineUserIds.add(id);
    _channelUserIds[_channel] = id;
    unawaited(ClusterBridge.instance.setPresence(id, online: true));
    _send({'type': 'presence_ok', 'online': true});
  }

  Future<void> _handleDm(Map<String, dynamic> data) async {
    final db = _authDb;
    final fromId = _channelUserIds[_channel];
    final toId = data['toUserId'] as String?;
    final body = '${data['body'] ?? ''}'.trim();
    if (db == null || fromId == null || toId == null || body.isEmpty) {
      _send({'type': 'error', 'message': 'dm_failed'});
      return;
    }
    final msg = await db.sendFriendMessage(
      fromId: fromId,
      toId: toId,
      body: body,
    );
    _send({'type': 'dm_ok', 'message': msg});
    var delivered = false;
    for (final e in _channelUserIds.entries) {
      if (e.value == toId) {
        try {
          e.key.sink.add(jsonEncode({'type': 'dm', 'message': msg}));
          delivered = true;
        } catch (_) {}
      }
    }
    if (!delivered) {
      unawaited(
        PushService.instance.notifyUser(
          userId: toId,
          title: 'SuperChess',
          body: 'New message',
          data: {'type': 'dm', 'fromUserId': fromId},
        ),
      );
    }
  }

  Future<void> _handleAuthoritativeMove(Map<String, dynamic> data) async {
    final gameId = data['gameId'] as String?;
    final room = gameId != null ? _games[gameId] : null;
    if (room == null) {
      await _forwardIfRemote(gameId, data);
      return;
    }
    if (!room.ownsChannel(_channel)) return;
    final fromColor = room.colorOf(_channel);
    if (fromColor == null) return;
    await _applyAuthoritativeMove(
      room,
      fromColor: fromColor,
      data: data,
      reply: _send,
    );
  }

  void _onDisconnect() {
    _lobby.cancel(_channel);
    final seekId = _seekIdByChannel.remove(_channel);
    if (seekId != null) {
      _seekPlayerById.remove(seekId);
      unawaited(RedisLobby.instance.dequeue(seekId));
    }
    ClusterBridge.instance.detachChannel(_channel);
    final uid = _channelUserIds.remove(_channel);
    if (uid != null) {
      final still = _channelUserIds.values.contains(uid);
      if (!still) {
        _onlineUserIds.remove(uid);
        unawaited(ClusterBridge.instance.setPresence(uid, online: false));
      }
    }
    _cancelPrivate();
    for (final room in _games.values.toList()) {
      if (room.isSpectator(_channel)) {
        room.removeSpectator(_channel);
      } else if (room.ownsChannel(_channel)) {
        room.onSeatDisconnected(_channel);
      }
    }
  }

  void _send(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }
}
