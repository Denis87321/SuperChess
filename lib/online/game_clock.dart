import '../models/piece.dart';

class GameClock {
  GameClock({
    this.initialMs = 5 * 60 * 1000,
  })  : whiteMs = initialMs,
        blackMs = initialMs;

  final int initialMs;
  int whiteMs;
  int blackMs;
  DateTime? _lastTick;

  void reset() {
    whiteMs = initialMs;
    blackMs = initialMs;
    _lastTick = null;
  }

  void applySync({required int whiteMs, required int blackMs}) {
    this.whiteMs = whiteMs.clamp(0, initialMs * 2);
    this.blackMs = blackMs.clamp(0, initialMs * 2);
    _lastTick = DateTime.now();
  }

  int msFor(PieceColor color) =>
      color == PieceColor.white ? whiteMs : blackMs;

  /// Deduct elapsed time from [active]. Returns true if that side flagged.
  bool tick(PieceColor active) {
    final now = DateTime.now();
    final last = _lastTick;
    _lastTick = now;
    if (last == null) return false;
    final elapsed = now.difference(last).inMilliseconds;
    if (elapsed <= 0) return false;
    if (active == PieceColor.white) {
      whiteMs = (whiteMs - elapsed).clamp(0, whiteMs);
      return whiteMs <= 0;
    }
    blackMs = (blackMs - elapsed).clamp(0, blackMs);
    return blackMs <= 0;
  }

  void pause() {
    _lastTick = null;
  }

  static String formatMs(int ms) {
    final totalSec = (ms / 1000).ceil().clamp(0, 99 * 60);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
