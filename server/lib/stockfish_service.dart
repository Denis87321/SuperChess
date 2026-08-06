import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Shared Stockfish UCI process for vs-computer games.
///
/// Requests are serialized (one `go` at a time) so a free-tier host stays stable.
class StockfishService {
  StockfishService._();
  static final StockfishService instance = StockfishService._();

  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  final _lines = StreamController<String>.broadcast();
  Future<void> _lock = Future<void>.value();
  bool _starting = false;
  bool _unavailable = false;
  String? _lastError;

  bool get isAvailable => !_unavailable && _process != null;

  String? get lastError => _lastError;

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final gate = Completer<void>();
    final previous = _lock;
    _lock = gate.future;
    return previous.then((_) => action()).whenComplete(gate.complete);
  }

  static Future<Process> _spawn() async {
    final env = Platform.environment['STOCKFISH_PATH']?.trim();
    final tried = <String>[
      if (env != null && env.isNotEmpty) env,
      if (Platform.isWindows) 'stockfish.exe',
      if (!Platform.isWindows) ...[
        'stockfish',
        '/usr/games/stockfish',
        '/usr/bin/stockfish',
      ],
    ];
    Object? lastError;
    for (final path in tried) {
      try {
        return await Process.start(path, const []);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError('stockfish not found');
  }

  Future<bool> ensureStarted() => _synchronized(_ensureStartedImpl);

  Future<bool> _ensureStartedImpl() async {
    if (_unavailable) return false;
    if (_process != null) return true;
    if (_starting) return false;
    _starting = true;
    try {
      final proc = await _spawn();
      _process = proc;
      _stdoutSub = proc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final t = line.trim();
        if (t.isNotEmpty) _lines.add(t);
      });
      proc.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        // ignore: avoid_print
        print('stockfish stderr: $line');
      });
      unawaited(proc.exitCode.then((code) {
        // ignore: avoid_print
        print('stockfish exited: $code');
        _process = null;
        unawaited(_stdoutSub?.cancel());
        _stdoutSub = null;
      }));

      final ok = await _uciHandshake();
      if (!ok) {
        await _kill();
        _unavailable = true;
        _lastError = 'uci handshake failed';
        return false;
      }
      // ignore: avoid_print
      print('Stockfish ready');
      return true;
    } catch (e) {
      _unavailable = true;
      _lastError = '$e';
      // ignore: avoid_print
      print('Stockfish unavailable: $e');
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<bool> _uciHandshake() async {
    final proc = _process;
    if (proc == null) return false;
    final ready = Completer<bool>();
    late final StreamSubscription<String> sub;
    sub = _lines.stream.listen((line) {
      if (line.startsWith('uciok') && !ready.isCompleted) {
        ready.complete(true);
      }
    });
    proc.stdin.writeln('uci');
    final ok = await ready.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    await sub.cancel();
    if (!ok) return false;
    proc.stdin.writeln('setoption name Skill Level value 20');
    proc.stdin.writeln('setoption name UCI_LimitStrength value false');
    proc.stdin.writeln('setoption name Threads value 1');
    proc.stdin.writeln('setoption name Hash value 64');
    proc.stdin.writeln('ucinewgame');
    proc.stdin.writeln('isready');
    final readyOk = Completer<bool>();
    late final StreamSubscription<String> sub2;
    sub2 = _lines.stream.listen((line) {
      if (line.startsWith('readyok') && !readyOk.isCompleted) {
        readyOk.complete(true);
      }
    });
    await readyOk.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => true,
    );
    await sub2.cancel();
    return true;
  }

  /// Returns UCI move (`e2e4`) or null.
  Future<String?> goBestMove({
    required String fen,
    int movetimeMs = 2000,
  }) {
    final clamped = movetimeMs.clamp(200, 8000);
    return _synchronized(() => _goImpl(fen, clamped));
  }

  Future<String?> _goImpl(String fen, int movetimeMs) async {
    final started = await _ensureStartedImpl();
    final proc = _process;
    if (!started || proc == null) return null;

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
    });

    try {
      proc.stdin.writeln('position fen $fen');
      proc.stdin.writeln('go movetime $movetimeMs');
      return await completer.future.timeout(
        Duration(milliseconds: movetimeMs + 5000),
        onTimeout: () {
          try {
            proc.stdin.writeln('stop');
          } catch (_) {}
          return null;
        },
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _kill() async {
    final proc = _process;
    _process = null;
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    if (proc == null) return;
    try {
      proc.stdin.writeln('quit');
    } catch (_) {}
    try {
      proc.kill();
    } catch (_) {}
  }
}
