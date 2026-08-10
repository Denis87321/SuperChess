import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/move.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';
import 'package:super_chess/online/online_game_service.dart';
import 'package:super_chess/online/websocket_online_service.dart';

/// Simulates two independent clients (e.g. web + phone) against one server.
void main() {
  late Process server;
  late int port;
  late String wsUrl;

  setUpAll(() async {
    port = await _freePort();
    wsUrl = 'ws://127.0.0.1:$port/ws';
    final serverDir = Directory('server').absolute.path;
    server = await Process.start(
      _dartExecutable(),
      ['run', 'bin/server.dart'],
      workingDirectory: serverDir,
      environment: {...Platform.environment, 'PORT': '$port'},
    );
    server.stdout.transform(utf8.decoder).listen((_) {});
    server.stderr.transform(utf8.decoder).listen((_) {});
    await _waitForHealth(port);
  });

  tearDownAll(() async {
    try {
      server.kill(ProcessSignal.sigterm);
      await server.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          server.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    } catch (_) {}
  });

  test('web-like and phone-like clients match and exchange a move', () async {
    final web = WebSocketOnlineService(serverUrl: wsUrl);
    final phone = WebSocketOnlineService(serverUrl: wsUrl);

    final webMatched = Completer<OnlineMatched>();
    final phoneMatched = Completer<OnlineMatched>();
    final webGotMove = Completer<OnlineOpponentMove>();
    final phoneGotMove = Completer<OnlineOpponentMove>();

    web.events.listen((event) {
      if (event is OnlineMatched && !webMatched.isCompleted) {
        webMatched.complete(event);
      }
      if (event is OnlineOpponentMove && !webGotMove.isCompleted) {
        webGotMove.complete(event);
      }
    });
    phone.events.listen((event) {
      if (event is OnlineMatched && !phoneMatched.isCompleted) {
        phoneMatched.complete(event);
      }
      if (event is OnlineOpponentMove && !phoneGotMove.isCompleted) {
        phoneGotMove.complete(event);
      }
    });

    await web.connect();
    await phone.connect();
    await web.findGame(playerName: 'WebPlayer', timeControlId: '5+0');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await phone.findGame(playerName: 'PhonePlayer', timeControlId: '5+0');

    final w = await webMatched.future.timeout(const Duration(seconds: 5));
    final p = await phoneMatched.future.timeout(const Duration(seconds: 5));
    expect(w.match.gameId, p.match.gameId);
    expect({w.match.localColor, p.match.localColor}, {
      PieceColor.white,
      PieceColor.black,
    });

    final whiteIsWeb = w.match.localColor == PieceColor.white;
    final whiteClient = whiteIsWeb ? web : phone;
    final blackMoveFuture = whiteIsWeb ? phoneGotMove.future : webGotMove.future;

    whiteClient.sendMove(
      const Move(from: Square(4, 1), to: Square(4, 3)),
      whiteMs: 299_000,
      blackMs: 300_000,
    );
    final relayed = await blackMoveFuture.timeout(const Duration(seconds: 5));
    expect(relayed.move.from, const Square(4, 1));
    expect(relayed.move.to, const Square(4, 3));
    // Server clock is authoritative (client whiteMs/blackMs are hints only).
    expect(relayed.whiteMs, isNotNull);
    expect(relayed.blackMs, isNotNull);
    expect(relayed.whiteMs!, greaterThan(290_000));
    expect(relayed.blackMs!, greaterThan(290_000));

    web.dispose();
    phone.dispose();
  });
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final candidate = Platform.isWindows
        ? '$flutterRoot\\bin\\cache\\dart-sdk\\bin\\dart.exe'
        : '$flutterRoot/bin/cache/dart-sdk/bin/dart';
    if (File(candidate).existsSync()) return candidate;
  }
  final fromPath = Platform.isWindows ? 'dart.bat' : 'dart';
  return fromPath;
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
