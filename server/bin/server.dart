import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:super_chess_server/auth.dart';
import 'package:super_chess_server/db.dart';
import 'package:super_chess_server/password.dart';
import 'package:super_chess_server/stockfish_service.dart';

AuthDatabase? _authDb;
AuthTokens? _authTokens;

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

  final ws = webSocketHandler((WebSocketChannel client, String? _) {
    _ClientConnection(client).listen();
  });

  // Warm Stockfish in background (optional; fails soft if binary missing).
  unawaited(StockfishService.instance.ensureStarted());

  final router = Router();

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
    if (room != null) {
      final opponent =
          color == 'white' ? room.black : room.white;
      opponentUserId = opponent.userId;
      opponentName = opponent.name;
    } else if (body['opponentName'] is String) {
      opponentName = body['opponentName'] as String;
    }

    final profile = await _authDb!.submitGameResult(
      gameId: gameId,
      userId: user.id,
      color: color!,
      winner: winner,
      reason: body['reason'] as String?,
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

final _waiting = <_QueuedPlayer>[];
final _games = <String, _GameRoom>{};

void _broadcastQueueSize() {
  final payload = jsonEncode({
    'type': 'queue_size',
    'count': _waiting.length,
  });
  for (final player in _waiting) {
    try {
      player.channel.sink.add(payload);
    } catch (_) {}
  }
}

class _QueuedPlayer {
  _QueuedPlayer({
    required this.channel,
    required this.name,
    this.userId,
    this.rating,
  });

  final WebSocketChannel channel;
  final String name;
  final String? userId;
  final int? rating;
}

class _GameRoom {
  _GameRoom({
    required this.id,
    required this.white,
    required this.black,
  });

  final String id;
  final _QueuedPlayer white;
  final _QueuedPlayer black;

  void relay(WebSocketChannel from, Map<String, dynamic> message) {
    final target = from == white.channel ? black.channel : white.channel;
    target.sink.add(jsonEncode(message));
  }

  void close() {
    for (final player in [white, black]) {
      try {
        player.channel.sink.add(jsonEncode({'type': 'opponent_left'}));
      } catch (_) {}
    }
    _games.remove(id);
  }
}

void _startRematch(_GameRoom room, {required WebSocketChannel accepter}) {
  _games.remove(room.id);
  final newId = '${DateTime.now().millisecondsSinceEpoch}_r';
  // Swap colors for rematch.
  final white = room.black;
  final black = room.white;
  final next = _GameRoom(id: newId, white: white, black: black);
  _games[newId] = next;
  final rated = white.userId != null && black.userId != null;

  void sendMatched(_QueuedPlayer player, String color, _QueuedPlayer opp) {
    player.channel.sink.add(jsonEncode({
      'type': 'rematch_start',
      'gameId': newId,
      'color': color,
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
        await _enqueue(
          name: data['name'] as String? ?? 'Player',
          token: data['token'] as String?,
        );
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
      case 'ability':
      case 'start_ability':
      case 'ability_target':
      case 'reaction':
      case 'reroll':
      case 'skip_turn':
      case 'game_over':
      case 'state_resync':
      case 'chat':
      case 'resign':
      case 'draw_offer':
      case 'draw_response':
      case 'takeback_offer':
      case 'takeback_response':
      case 'clock_sync':
      case 'rematch_offer':
      case 'rematch_accept':
        final gameId = data['gameId'] as String?;
        final room = gameId != null ? _games[gameId] : null;
        if (room == null) return;
        if (data['type'] == 'rematch_accept') {
          _startRematch(room, accepter: _channel);
          return;
        }
        room.relay(_channel, data);
      default:
        _send({'type': 'error', 'message': 'Неизвестный тип сообщения'});
    }
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

  Future<void> _enqueue({required String name, String? token}) async {
    String displayName = name;
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

    final player = _QueuedPlayer(
      channel: _channel,
      name: displayName,
      userId: userId,
      rating: rating,
    );

    if (_waiting.isNotEmpty) {
      final opponent = _waiting.removeAt(0);
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      final room = _GameRoom(id: gameId, white: opponent, black: player);
      _games[gameId] = room;

      final rated =
          opponent.userId != null && player.userId != null;

      opponent.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': 'white',
        'opponentName': player.name,
        'rated': rated,
        'yourRating': opponent.rating,
        'opponentRating': player.rating,
        'opponentLoggedIn': player.userId != null,
      }));

      player.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': 'black',
        'opponentName': opponent.name,
        'rated': rated,
        'yourRating': player.rating,
        'opponentRating': opponent.rating,
        'opponentLoggedIn': opponent.userId != null,
      }));

      _broadcastQueueSize();
    } else {
      _waiting.add(player);
      _broadcastQueueSize();
    }
  }

  void _onDisconnect() {
    final wasWaiting = _waiting.any((p) => p.channel == _channel);
    _waiting.removeWhere((p) => p.channel == _channel);
    if (wasWaiting) {
      _broadcastQueueSize();
    }
    for (final room in _games.values.toList()) {
      if (room.white.channel == _channel || room.black.channel == _channel) {
        room.close();
      }
    }
  }

  void _send(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }
}
