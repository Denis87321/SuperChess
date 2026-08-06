import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../online/server_config.dart';
import 'stockfish_engine.dart';

/// Stockfish over the SuperChess WebSocket API (`stockfish_ping` / `stockfish_go`).
class RemoteStockfishEngine implements StockfishEngine {
  RemoteStockfishEngine._(this._channel);

  final WebSocketChannel _channel;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _sub;
  bool _disposed = false;
  bool _ready = false;
  int _reqId = 0;

  static Future<RemoteStockfishEngine?> connect({
    String? wsUrl,
    Duration timeout = const Duration(seconds: 75),
  }) async {
    final url = wsUrl ?? defaultServerUrl();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      final engine = RemoteStockfishEngine._(channel);
      engine._sub = channel.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            engine._messages.add(data);
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );

      try {
        await channel.ready.timeout(timeout);
      } catch (_) {
        // Some platforms omit [ready]; continue to ping.
      }
      final pong = Completer<bool>();
      late final StreamSubscription sub;
      sub = engine._messages.stream.listen((data) {
        if (data['type'] == 'stockfish_pong' && !pong.isCompleted) {
          pong.complete(data['available'] == true);
        }
      });
      channel.sink.add(jsonEncode({'type': 'stockfish_ping'}));
      final ok = await pong.future.timeout(timeout, onTimeout: () => false);
      await sub.cancel();
      if (!ok) {
        engine.dispose();
        return null;
      }
      engine._ready = true;
      return engine;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> ready() async => _ready && !_disposed;

  @override
  Future<String?> goBestMove({
    required String fen,
    int movetimeMs = 800,
  }) async {
    if (_disposed || !_ready) return null;
    final id = '${++_reqId}';
    final completer = Completer<String?>();
    late final StreamSubscription sub;
    sub = _messages.stream.listen((data) {
      if (data['type'] != 'stockfish_bestmove') return;
      if (data['id']?.toString() != id) return;
      final move = data['move'];
      if (!completer.isCompleted) {
        completer.complete(move is String && move.isNotEmpty ? move : null);
      }
    });
    try {
      _channel.sink.add(jsonEncode({
        'type': 'stockfish_go',
        'id': id,
        'fen': fen,
        'movetime': movetimeMs,
      }));
      return await completer.future.timeout(
        Duration(milliseconds: movetimeMs + 15000),
        onTimeout: () => null,
      );
    } finally {
      await sub.cancel();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ready = false;
    unawaited(_sub?.cancel());
    unawaited(_messages.close());
    try {
      _channel.sink.close();
    } catch (_) {}
  }
}

Future<StockfishEngine?> createRemoteStockfishEngine({
  String? wsUrl,
  Duration timeout = const Duration(seconds: 45),
}) {
  return RemoteStockfishEngine.connect(wsUrl: wsUrl, timeout: timeout);
}
