import '../l10n/models/piece.dart';

/// Peer-synced chess clock.
///
/// Frozen remaining times live in [whiteMs]/[blackMs]. While a side is
/// running, its displayed time is derived from an absolute [deadline] so both
/// clients that share the same remaining snapshot countdown identically
/// between syncs (no double-debit from independent elapsed subtraction).
class GameClock {
  GameClock({
    this.initialMs = 5 * 60 * 1000,
  })  : whiteMs = initialMs,
        blackMs = initialMs;

  final int initialMs;
  int whiteMs;
  int blackMs;

  PieceColor? _running;
  DateTime? _deadline;

  void reset() {
    whiteMs = initialMs;
    blackMs = initialMs;
    _running = null;
    _deadline = null;
  }

  /// Whether a side currently has an active countdown deadline.
  bool get isRunning => _running != null && _deadline != null;

  PieceColor? get runningColor => _running;

  /// Apply an authoritative remaining-time snapshot.
  ///
  /// If [active] is set, that side starts counting down from [DateTime.now].
  /// Otherwise both sides stay frozen until [resume] / next sync with active.
  void applySync({
    required int whiteMs,
    required int blackMs,
    PieceColor? active,
  }) {
    this.whiteMs = whiteMs.clamp(0, initialMs * 2);
    this.blackMs = blackMs.clamp(0, initialMs * 2);
    _running = null;
    _deadline = null;
    if (active != null) {
      resume(active);
    }
  }

  int msFor(PieceColor color) {
    final deadline = _deadline;
    if (_running == color && deadline != null) {
      final left = deadline.difference(DateTime.now()).inMilliseconds;
      return left.clamp(0, initialMs * 2);
    }
    return color == PieceColor.white ? whiteMs : blackMs;
  }

  /// Ensure [active] is counting down from its frozen remaining time.
  void resume(PieceColor active) {
    final remaining = active == PieceColor.white ? whiteMs : blackMs;
    _running = active;
    _deadline = DateTime.now().add(Duration(milliseconds: remaining));
  }

  /// Freeze the running side's remaining time from its deadline.
  void pause() {
    final running = _running;
    final deadline = _deadline;
    if (running != null && deadline != null) {
      final left = deadline.difference(DateTime.now()).inMilliseconds.clamp(
        0,
        initialMs * 2,
      );
      if (running == PieceColor.white) {
        whiteMs = left;
      } else {
        blackMs = left;
      }
    }
    _running = null;
    _deadline = null;
  }

  /// Check whether [active] has flagged. Starts/switches the deadline if needed.
  ///
  /// Does not subtract wall time into storage each tick — display uses the
  /// deadline; storage is updated on [pause] / flag.
  bool tick(PieceColor active) {
    if (_running != active || _deadline == null) {
      // Switching sides or resuming after pause: freeze previous, start new.
      if (_running != null && _running != active) {
        pause();
      }
      if (_running != active) {
        resume(active);
      }
    }
    final left = msFor(active);
    if (left <= 0) {
      if (active == PieceColor.white) {
        whiteMs = 0;
      } else {
        blackMs = 0;
      }
      _running = null;
      _deadline = null;
      return true;
    }
    return false;
  }

  static String formatMs(int ms) {
    final totalSec = (ms / 1000).ceil().clamp(0, 99 * 60);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
