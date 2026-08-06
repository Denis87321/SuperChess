import 'stockfish_engine_remote.dart';
import 'stockfish_engine_stub.dart'
    if (dart.library.html) 'stockfish_engine_web.dart'
    if (dart.library.io) 'stockfish_engine_io.dart' as stockfish_local;

/// Thin UCI engine handle used by [StockfishPlayer].
abstract class StockfishEngine {
  Future<bool> ready();

  /// Returns UCI move like `e2e4` / `e7e8q`, or null on failure.
  Future<String?> goBestMove({
    required String fen,
    int movetimeMs = 800,
  });

  void dispose();
}

Future<StockfishEngine?> createStockfishEngine({
  Duration remoteTimeout = const Duration(seconds: 45),
}) async {
  final remote = await createRemoteStockfishEngine(timeout: remoteTimeout);
  if (remote != null) return remote;
  return stockfish_local.createStockfishEngineImpl();
}
