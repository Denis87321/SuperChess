import 'dart:async';
import 'dart:convert';

import 'package:super_chess_engine/super_chess_engine.dart';

import 'db.dart';
import 'stockfish_service.dart';

/// Cloud Stockfish fair-play sampler during live games.
///
/// Compares each rated move to the engine best move (short movetime).
/// High match streaks → soft flag persisted for review (no auto-ban).
class FairPlayMonitor {
  FairPlayMonitor(this._db);

  final AuthDatabase? _db;
  static FairPlayMonitor? _instance;
  static FairPlayMonitor get instance =>
      _instance ??= FairPlayMonitor(null);

  static void bind(AuthDatabase? db) {
    _instance = FairPlayMonitor(db);
  }

  final _sessions = <String, _FairSession>{};
  final _queue = <_SampleJob>[];
  bool _pumping = false;

  /// Called when a soft flag trips (for live WS soft-alert).
  void Function(String gameId, String color, double matchRate, int samples)?
      onSoftFlag;

  void onGameStart(String gameId, {required bool rated}) {
    if (!rated) return;
    _sessions[gameId] = _FairSession();
  }

  void onGameEnd(String gameId) {
    final s = _sessions.remove(gameId);
    if (s == null) return;
    unawaited(_persistSummary(gameId, s));
  }

  /// Schedule async engine compare. [fenBefore] must be position before the move.
  void sampleMove({
    required String gameId,
    required String? userId,
    required String color,
    required String? fenBefore,
    required String moveUci,
    required bool rated,
  }) {
    if (!rated || fenBefore == null || fenBefore.isEmpty) return;
    _sessions.putIfAbsent(gameId, _FairSession.new);
    _queue.add(
      _SampleJob(
        gameId: gameId,
        userId: userId,
        color: color,
        fenBefore: fenBefore,
        moveUci: moveUci.toLowerCase(),
      ),
    );
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        await _runSample(job);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runSample(_SampleJob job) async {
    final session = _sessions[job.gameId];
    if (session == null) return;
    final ok = await StockfishService.instance.ensureStarted();
    if (!ok) return;

    final best = await StockfishService.instance.goBestMove(
      fen: job.fenBefore,
      movetimeMs: 120,
    );
    if (best == null) return;

    final matched = _uciEqual(job.moveUci, best);
    session.record(
      color: job.color,
      userId: job.userId,
      matched: matched,
      best: best,
      played: job.moveUci,
    );

    final db = _db;
    if (db != null) {
      try {
        await db.insertFairPlaySample(
          gameId: job.gameId,
          userId: job.userId,
          color: job.color,
          fen: job.fenBefore,
          playedUci: job.moveUci,
          bestUci: best,
          matched: matched,
        );
      } catch (_) {}
    }

    // Soft alert threshold: 12+ samples and ≥92% match for a side.
    final side = session.side(job.color);
    if (side.samples >= 12 && side.matchRate >= 0.92 && !side.flagged) {
      side.flagged = true;
      if (db != null) {
        try {
          await db.upsertFairPlayFlag(
            gameId: job.gameId,
            userId: job.userId,
            color: job.color,
            matchRate: side.matchRate,
            samples: side.samples,
            detail: 'High cloud-engine match rate during live game',
          );
        } catch (_) {}
      }
      onSoftFlag?.call(
        job.gameId,
        job.color,
        side.matchRate,
        side.samples,
      );
    }
  }

  Future<void> _persistSummary(String gameId, _FairSession s) async {
    final db = _db;
    if (db == null) return;
    for (final color in ['white', 'black']) {
      final side = s.side(color);
      if (side.samples == 0) continue;
      try {
        await db.upsertFairPlayFlag(
          gameId: gameId,
          userId: side.userId,
          color: color,
          matchRate: side.matchRate,
          samples: side.samples,
          detail: side.flagged ? 'flagged' : 'summary',
          flagged: side.flagged,
        );
      } catch (_) {}
    }
  }

  static bool _uciEqual(String a, String b) {
    String norm(String u) {
      final t = u.toLowerCase().trim();
      if (t.length >= 5 && 'qrbn'.contains(t[4])) {
        return t.substring(0, 5);
      }
      return t.length >= 4 ? t.substring(0, 4) : t;
    }

    return norm(a) == norm(b);
  }

  static String moveJsonToUci(Map<String, dynamic> move) {
    final n = MoveCodec.normalizeJson(move);
    final from = Square(n['fromF'] as int, n['fromR'] as int);
    final to = Square(n['toF'] as int, n['toR'] as int);
    var uci = '${from.algebraic}${to.algebraic}';
    final promo = n['promotion'] as String?;
    if (promo != null && promo.isNotEmpty) {
      uci += promo[0].toLowerCase();
    }
    return uci;
  }
}

class _SampleJob {
  _SampleJob({
    required this.gameId,
    required this.userId,
    required this.color,
    required this.fenBefore,
    required this.moveUci,
  });
  final String gameId;
  final String? userId;
  final String color;
  final String fenBefore;
  final String moveUci;
}

class _FairSession {
  final white = _SideStats();
  final black = _SideStats();

  _SideStats side(String color) => color == 'white' ? white : black;

  void record({
    required String color,
    required String? userId,
    required bool matched,
    required String best,
    required String played,
  }) {
    final s = side(color);
    s.userId ??= userId;
    s.samples++;
    if (matched) s.matches++;
    s.lastBest = best;
    s.lastPlayed = played;
  }
}

class _SideStats {
  String? userId;
  int samples = 0;
  int matches = 0;
  bool flagged = false;
  String? lastBest;
  String? lastPlayed;

  double get matchRate => samples == 0 ? 0 : matches / samples;
}

/// Debug helper for logs.
String fairPlayDebugEncode(_SideStats s) => jsonEncode({
      'samples': s.samples,
      'matches': s.matches,
      'rate': s.matchRate,
      'flagged': s.flagged,
    });
