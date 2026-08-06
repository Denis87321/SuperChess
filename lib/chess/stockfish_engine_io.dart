import 'stockfish_engine.dart';

/// Native mobile Stockfish was removed to keep the APK small.
/// Vs-computer uses [createRemoteStockfishEngine] on the SuperChess server.
Future<StockfishEngine?> createStockfishEngineImpl() async => null;
