import 'dart:async';
import 'dart:io' show Platform;

import 'package:stockfish/stockfish.dart';

import 'stockfish_engine.dart';

Future<StockfishEngine?> createStockfishEngineImpl() async {
  // Official plugin ships Android / iOS binaries only.
  if (!(Platform.isAndroid || Platform.isIOS)) return null;
  try {
    final engine = _IoStockfishEngine();
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

class _IoStockfishEngine implements StockfishEngine {
  _IoStockfishEngine() : _engine = Stockfish();

  final Stockfish _engine;
  StreamSubscription<String>? _sub;
  Completer<bool>? _uciReady;
  final _lines = StreamController<String>.broadcast();
  bool _disposed = false;

  @override
  Future<bool> ready() async {
    if (_uciReady != null) return _uciReady!.future;
    _uciReady = Completer<bool>();
    _sub = _engine.stdout.listen((line) {
      _lines.add(line);
      if (line.startsWith('uciok') &&
          _uciReady != null &&
          !_uciReady!.isCompleted) {
        _uciReady!.complete(true);
      }
    });

    // Wait until state is ready.
    final started = Completer<void>();
    void listener() {
      if (_engine.state.value == StockfishState.ready && !started.isCompleted) {
        started.complete();
      }
      if (_engine.state.value == StockfishState.error && !started.isCompleted) {
        started.completeError(StateError('stockfish error'));
      }
    }

    _engine.state.addListener(listener);
    try {
      if (_engine.state.value != StockfishState.ready) {
        await started.future.timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      _uciReady?.complete(false);
      return false;
    } finally {
      _engine.state.removeListener(listener);
    }

    _engine.stdin = 'uci';
    final ok = await _uciReady!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    if (ok) {
      _engine.stdin = 'setoption name Skill Level value 20';
      _engine.stdin = 'ucinewgame';
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
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'go movetime $movetimeMs';
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
    unawaited(_sub?.cancel());
    _engine.dispose();
    unawaited(_lines.close());
  }
}
