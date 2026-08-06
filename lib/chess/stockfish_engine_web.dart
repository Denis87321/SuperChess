import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'stockfish_engine.dart';

Future<StockfishEngine?> createStockfishEngineImpl() async {
  try {
    final engine = _WebStockfishEngine();
    final ok = await engine.ready().timeout(const Duration(seconds: 12));
    if (!ok) {
      engine.dispose();
      return null;
    }
    return engine;
  } catch (_) {
    return null;
  }
}

class _WebStockfishEngine implements StockfishEngine {
  _WebStockfishEngine() {
    _worker = web.Worker('stockfish/stockfish.js'.toJS);
    _worker.onmessage = _onMessage.toJS;
    _worker.onerror = _onError.toJS;
  }

  late final web.Worker _worker;
  final _lines = StreamController<String>.broadcast();
  Completer<bool>? _uciReady;
  bool _disposed = false;

  void _onMessage(web.MessageEvent event) {
    final data = event.data;
    final text = data?.dartify()?.toString() ?? '';
    if (text.isEmpty) return;
    _lines.add(text);
    if ((text.startsWith('uciok') || text.startsWith('readyok')) &&
        _uciReady != null &&
        !_uciReady!.isCompleted) {
      _uciReady!.complete(true);
    }
  }

  void _onError(web.Event _) {
    if (_uciReady != null && !_uciReady!.isCompleted) {
      _uciReady!.complete(false);
    }
  }

  void _send(String cmd) {
    if (_disposed) return;
    _worker.postMessage(cmd.toJS);
  }

  @override
  Future<bool> ready() async {
    if (_uciReady != null) return _uciReady!.future;
    _uciReady = Completer<bool>();
    _send('uci');
    _send('isready');
    // Wait for uciok; also accept readyok as soft success after timeout path.
    final ok = await _uciReady!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => false,
    );
    if (ok) {
      // Max classical skill; do not limit Elo.
      _send('setoption name Skill Level value 20');
      _send('setoption name UCI_LimitStrength value false');
      _send('setoption name Threads value 2');
      _send('setoption name Hash value 128');
      _send('ucinewgame');
    }
    return ok;
  }

  @override
  Future<String?> goBestMove({
    required String fen,
    int movetimeMs = 800,
  }) async {
    if (_disposed) return null;
    final completer = Completer<String?>();
    late final StreamSubscription<String> sub;
    sub = _lines.stream.listen((line) {
      if (!line.startsWith('bestmove')) return;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2 || parts[1] == '(none)') {
        if (!completer.isCompleted) completer.complete(null);
      } else {
        if (!completer.isCompleted) completer.complete(parts[1]);
      }
      unawaited(sub.cancel());
    });
    _send('position fen $fen');
    _send('go movetime $movetimeMs');
    try {
      return await completer.future.timeout(
        Duration(milliseconds: movetimeMs + 2500),
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
    _worker.terminate();
    unawaited(_lines.close());
  }
}
