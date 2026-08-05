import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final ws = webSocketHandler((WebSocketChannel client, String? _) {
    _ClientConnection(client).listen();
  });

  FutureOr<Response> router(Request request) {
    final path = request.url.path;
    if (request.method == 'GET' && (path == 'health' || path.isEmpty)) {
      return Response.ok(
        jsonEncode({'ok': true, 'service': 'superchess'}),
        headers: {'content-type': 'application/json'},
      );
    }
    if (path == 'ws') {
      return ws(request);
    }
    return Response.notFound('Not Found');
  }

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print(
    'SuperChess server listening on '
    'http://${server.address.host}:${server.port} '
    '(ws path /ws, health /health)',
  );
}

final _waiting = <_QueuedPlayer>[];
final _games = <String, _GameRoom>{};

class _QueuedPlayer {
  _QueuedPlayer({
    required this.channel,
    required this.name,
  });

  final WebSocketChannel channel;
  final String name;
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

class _ClientConnection {
  _ClientConnection(this._channel);

  final WebSocketChannel _channel;

  void listen() {
    _channel.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          _handle(data);
        } catch (_) {
          _send({'type': 'error', 'message': 'Неверное сообщение'});
        }
      },
      onDone: _onDisconnect,
    );
  }

  void _handle(Map<String, dynamic> data) {
    switch (data['type'] as String?) {
      case 'find_game':
        _enqueue(name: data['name'] as String? ?? 'Player');
      case 'move':
      case 'ability':
      case 'start_ability':
      case 'ability_target':
      case 'reaction':
      case 'reroll':
      case 'skip_turn':
      case 'game_over':
      case 'state_resync':
        final gameId = data['gameId'] as String?;
        final room = gameId != null ? _games[gameId] : null;
        if (room == null) return;
        room.relay(_channel, data);
      default:
        _send({'type': 'error', 'message': 'Неизвестный тип сообщения'});
    }
  }

  void _enqueue({required String name}) {
    final player = _QueuedPlayer(
      channel: _channel,
      name: name,
    );

    if (_waiting.isNotEmpty) {
      final opponent = _waiting.removeAt(0);
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      final room = _GameRoom(id: gameId, white: opponent, black: player);
      _games[gameId] = room;

      opponent.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': 'white',
        'opponentName': player.name,
      }));

      player.channel.sink.add(jsonEncode({
        'type': 'matched',
        'gameId': gameId,
        'color': 'black',
        'opponentName': opponent.name,
      }));
    } else {
      _waiting.add(player);
    }
  }

  void _onDisconnect() {
    _waiting.removeWhere((p) => p.channel == _channel);
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
