import 'time_control.dart';

/// Authoritative deadline-based clock for online games.
class ServerClock {
  ServerClock(TimeControl tc)
      : whiteMs = tc.initialMs,
        blackMs = tc.initialMs,
        incrementMs = tc.incrementMs;

  int whiteMs;
  int blackMs;
  final int incrementMs;
  String? _active; // 'white' | 'black'
  DateTime? _startedAt;

  void start(String color) {
    _flush();
    _active = color;
    _startedAt = DateTime.now();
  }

  void pause() {
    _flush();
    _active = null;
    _startedAt = null;
  }

  void afterMove(String moverColor) {
    _flush();
    if (moverColor == 'white') {
      whiteMs += incrementMs;
      _active = 'black';
    } else {
      blackMs += incrementMs;
      _active = 'white';
    }
    _startedAt = DateTime.now();
  }

  void _flush() {
    if (_active == null || _startedAt == null) return;
    final elapsed = DateTime.now().difference(_startedAt!).inMilliseconds;
    if (_active == 'white') {
      whiteMs = (whiteMs - elapsed).clamp(0, 1 << 31);
    } else {
      blackMs = (blackMs - elapsed).clamp(0, 1 << 31);
    }
    _startedAt = DateTime.now();
  }

  bool get flagged => whiteMs <= 0 || blackMs <= 0;

  String? get flaggedColor {
    _flush();
    if (whiteMs <= 0) return 'white';
    if (blackMs <= 0) return 'black';
    return null;
  }

  Map<String, dynamic> snapshot() {
    _flush();
    return {
      'whiteMs': whiteMs,
      'blackMs': blackMs,
      'active': _active,
    };
  }
}
