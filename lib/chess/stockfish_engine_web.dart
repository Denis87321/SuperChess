import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'stockfish_engine.dart';

/// Stockfish 18 NNUE workers (strongest first).
///
/// Full single-thread (~108MB wasm) needs no COOP/COEP.
/// Lite single is a smaller offline fallback.
const _engineScripts = <String>[
  'stockfish/stockfish-18-single.js',
  'stockfish/stockfish-18-lite-single.js',
];

Future<StockfishEngine?> createStockfishEngineImpl() async {
  for (final script in _engineScripts) {
    try {
      final engine = _WebStockfishEngine(script);
      final ok = await engine.ready().timeout(const Duration(seconds: 90));
      if (ok) return engine;
      engine.dispose();
    } catch (_) {
      // Try next candidate.
    }
  }
  return null;
}

class _WebStockfishEngine implements StockfishEngine {
  _WebStockfishEngine(this._scriptUrl) {
    _worker = web.Worker(_scriptUrl.toJS);
    _worker.onmessage = _onMessage.toJS;
    _worker.onerror = _onError.toJS;
  }

  final String _scriptUrl;
  late final web.Worker _worker;
  final _lines = StreamController<String>.broadcast();
  Completer<bool>? _uciReady;
  bool _disposed = false;
  bool _configured = false;

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
    if (_configured) return true;
    if (_uciReady != null) return _uciReady!.future;
    _uciReady = Completer<bool>();
    _send('uci');
    final ok = await _uciReady!.future.timeout(
      const Duration(seconds: 75),
      onTimeout: () => false,
    );
    if (!ok) return false;

    // Max classical strength (Stockfish 18 NNUE).
    _send('setoption name Skill Level value 20');
    _send('setoption name UCI_LimitStrength value false');
    _send('setoption name Hash value 256');
    _send('setoption name Move Overhead value 20');
    _send('ucinewgame');
    _send('isready');
    _configured = true;
    return true;
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
        Duration(milliseconds: movetimeMs + 8000),
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
    try {
      _send('quit');
    } catch (_) {}
    _worker.terminate();
    unawaited(_lines.close());
  }
}
