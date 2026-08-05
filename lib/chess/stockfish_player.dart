import '../models/piece.dart';
import '../models/square.dart';
import 'chess_game.dart';
import 'fen_export.dart';
import 'move.dart';
import 'stockfish_engine.dart';

/// Opponent that uses Stockfish only (no ComputerPlayer fallback).
///
/// Experimental: if the position is not classical 8×8 FEN, or Stockfish has no
/// legal SuperChess mapping, [chooseMove] returns null and the bot skips.
///
/// To restore fallback: re-add `ComputerPlayer` and
/// `return _fallback.chooseMove(...)` when Stockfish cannot move.
class StockfishPlayer {
  StockfishPlayer({this.movetimeMs = 900});

  final int movetimeMs;
  StockfishEngine? _engine;
  Future<void>? _init;

  bool get isStockfishActive => _engine != null;

  Future<void> ensureReady() {
    return _init ??= () async {
      _engine = await createStockfishEngine();
    }();
  }

  Future<Move?> chooseMove(
    ChessGame game, {
    required PieceColor forColor,
  }) async {
    await ensureReady();
    if (game.isGameOver || !game.isReadyToPlay) return null;
    if (game.turn != forColor || game.enginePhase != GameEnginePhase.play) {
      return null;
    }

    final legal = game.getLegalMoves();
    if (legal.isEmpty) return null;

    final engine = _engine;
    if (engine == null) return null;

    final fen = tryBuildFen(game);
    // Non-8×8 / non-classical geometry: Stockfish cannot see the board.
    if (fen == null) return null;

    final uci = await engine.goBestMove(fen: fen, movetimeMs: movetimeMs);
    final mapped = _mapUci(uci, legal);
    if (mapped != null) return mapped;

    // Stockfish move illegal under mods — score a few legal candidates.
    return _pickByStockfishEval(game, engine, legal, forColor);
  }

  Future<Move?> _pickByStockfishEval(
    ChessGame game,
    StockfishEngine engine,
    List<Move> legal,
    PieceColor forColor,
  ) async {
    // Cap work: evaluate up to 12 capture-first candidates.
    final ordered = List<Move>.from(legal);
    ordered.sort((a, b) {
      final ca = game.piecesAt(a.to).isEmpty ? 0 : 1;
      final cb = game.piecesAt(b.to).isEmpty ? 0 : 1;
      return cb.compareTo(ca);
    });
    final candidates = ordered.take(12).toList();
    final root = game.createSnapshot();
    Move? best;
    var bestScore = -0x3fffffff;

    for (final move in candidates) {
      final captureBonus = game.piecesAt(move.to).isEmpty ? 0 : 50;
      game.restoreSnapshot(root);
      if (game.makeMove(_preferQueen(move)) == null) continue;
      while (game.isAwaitingSkillChoice) {
        game.skipPendingAbility();
      }
      if (game.isAwaitingGallop) game.skipGallop();
      if (game.isAwaitingReaction) game.declineRansom();
      if (game.isAwaitingAbilityTarget) game.autoResolveAbilityTarget();

      var score = captureBonus + _materialDelta(game, forColor) * 100;
      if (game.isInCheck(
        forColor == PieceColor.white ? PieceColor.black : PieceColor.white,
      )) {
        score += 80;
      }
      final fen = tryBuildFen(game);
      if (fen != null) {
        final reply = await engine.goBestMove(fen: fen, movetimeMs: 80);
        if (reply != null) score += 5;
      }
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    game.restoreSnapshot(root);
    return best == null ? null : _preferQueen(best);
  }

  int _materialDelta(ChessGame game, PieceColor forColor) {
    var white = 0;
    var black = 0;
    const values = {
      PieceType.pawn: 1,
      PieceType.knight: 3,
      PieceType.bishop: 3,
      PieceType.rook: 5,
      PieceType.queen: 9,
      PieceType.king: 0,
    };
    for (var r = 0; r < game.rankCount; r++) {
      for (var f = 0; f < game.fileCount; f++) {
        for (final p in game.piecesAt(Square(f, r))) {
          final v = values[p.type] ?? 0;
          if (p.color == PieceColor.white) {
            white += v;
          } else {
            black += v;
          }
        }
      }
    }
    final diff = white - black;
    return forColor == PieceColor.white ? diff : -diff;
  }

  Move? _mapUci(String? uci, List<Move> legal) {
    if (uci == null || uci.length < 4) return null;
    final from = _sq(uci.substring(0, 2));
    final to = _sq(uci.substring(2, 4));
    if (from == null || to == null) return null;
    PieceType? promo;
    if (uci.length >= 5) {
      promo = switch (uci[4].toLowerCase()) {
        'q' => PieceType.queen,
        'r' => PieceType.rook,
        'b' => PieceType.bishop,
        'n' => PieceType.knight,
        _ => PieceType.queen,
      };
    }
    for (final m in legal) {
      if (m.from != from || m.to != to) continue;
      if (promo != null) {
        if (m.promotion == promo) return m;
        if (m.promotion == null) continue;
      } else if (m.promotion != null) {
        // Prefer queen promo if Stockfish omitted letter (rare).
        continue;
      }
      return m;
    }
    // Promo mismatch: take any matching from-to with queen promo.
    if (promo != null) {
      for (final m in legal) {
        if (m.from == from && m.to == to && m.promotion == PieceType.queen) {
          return m;
        }
      }
    }
    return null;
  }

  Square? _sq(String alg) {
    if (alg.length < 2) return null;
    final file = alg.codeUnitAt(0) - 97;
    final rank = alg.codeUnitAt(1) - 49;
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return null;
    return Square(file, rank);
  }

  Move _preferQueen(Move move) {
    if (move.promotion == null || move.promotion == PieceType.queen) {
      return move;
    }
    return Move(
      from: move.from,
      to: move.to,
      promotion: PieceType.queen,
      isEnPassant: move.isEnPassant,
      isCastle: move.isCastle,
      isCastleSwap: move.isCastleSwap,
      isKnightRearSwap: move.isKnightRearSwap,
      isRookPush: move.isRookPush,
      isColorChaos: move.isColorChaos,
      isAirborne: move.isAirborne,
      isInquisitorStrip: move.isInquisitorStrip,
      pieceIndex: move.pieceIndex,
    );
  }

  void dispose() {
    _engine?.dispose();
    _engine = null;
  }
}
