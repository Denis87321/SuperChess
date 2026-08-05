import 'stockfish_engine_stub.dart'
    if (dart.library.html) 'stockfish_engine_web.dart'
    if (dart.library.io) 'stockfish_engine_io.dart' as stockfish_impl;

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

Future<StockfishEngine?> createStockfishEngine() {
  return stockfish_impl.createStockfishEngineImpl();
}
