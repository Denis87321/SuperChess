import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late Process server;
  late int port;

  setUpAll(() async {
    port = await _freePort();
    server = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      workingDirectory: Directory.current.path,
      environment: {...Platform.environment, 'PORT': '$port'},
    );
    // Drain logs so the process does not block on a full pipe.
    server.stdout.transform(utf8.decoder).listen((_) {});
    server.stderr.transform(utf8.decoder).listen((_) {});
    await _waitForHealth(port);
  });

  tearDownAll(() async {
    server.kill(ProcessSignal.sigterm);
    await server.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        server.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  });

  test('health endpoint responds', () async {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/health'),
    );
    final response = await request.close();
    expect(response.statusCode, 200);
    final body = await response.transform(utf8.decoder).join();
    expect(jsonDecode(body)['ok'], isTrue);
    client.close(force: true);
  });

  test('two players are matched and can relay a move', () async {
    final white = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:$port/ws'),
    );
    final black = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:$port/ws'),
    );

    final whiteMatched = Completer<Map<String, dynamic>>();
    final blackMatched = Completer<Map<String, dynamic>>();
    final blackGotMove = Completer<Map<String, dynamic>>();

    white.stream.listen((raw) {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'matched' && !whiteMatched.isCompleted) {
        whiteMatched.complete(data);
      }
    });
    black.stream.listen((raw) {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'matched' && !blackMatched.isCompleted) {
        blackMatched.complete(data);
      }
      if (data['type'] == 'move' && !blackGotMove.isCompleted) {
        blackGotMove.complete(data);
      }
    });

    white.sink.add(jsonEncode({'type': 'find_game', 'name': 'Alice'}));
    // Small delay so Alice is waiting before Bob joins.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    black.sink.add(jsonEncode({'type': 'find_game', 'name': 'Bob'}));

    final w = await whiteMatched.future.timeout(const Duration(seconds: 5));
    final b = await blackMatched.future.timeout(const Duration(seconds: 5));
    expect(w['color'], 'white');
    expect(b['color'], 'black');
    expect(w['gameId'], b['gameId']);
    expect(w['opponentName'], 'Bob');
    expect(b['opponentName'], 'Alice');

    final gameId = w['gameId'];
    white.sink.add(
      jsonEncode({
        'type': 'move',
        'gameId': gameId,
        'move': {
          'from': {'f': 4, 'r': 1},
          'to': {'f': 4, 'r': 3},
        },
      }),
    );

    final relayed = await blackGotMove.future.timeout(
      const Duration(seconds: 5),
    );
    expect(relayed['gameId'], gameId);
    expect(relayed['move'], isA<Map>());

    await white.sink.close();
    await black.sink.close();
  });
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _waitForHealth(int port) async {
  final client = HttpClient();
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final request = await client
          .getUrl(Uri.parse('http://127.0.0.1:$port/health'))
          .timeout(const Duration(milliseconds: 500));
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode == 200) {
        client.close(force: true);
        return;
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  client.close(force: true);
  fail('Server did not become healthy on port $port');
}
