import 'dart:math';

import '../models/piece.dart';
import '../models/square.dart';
import 'chess_game.dart';
import 'move.dart';

/// Lightweight classical-style move picker (material + shallow alpha-beta).
///
/// Works on the live [ChessGame] rules (including board mods the human chose),
/// but never selects abilities itself — pending skill/target phases are skipped.
class ComputerPlayer {
  ComputerPlayer({Random? random, this.searchDepth = 2})
    : _random = random ?? Random();

  final Random _random;
  final int searchDepth;

  static const _pieceValue = <PieceType, int>{
    PieceType.pawn: 100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook: 500,
    PieceType.queen: 900,
    PieceType.king: 20000,
  };

  Move? chooseMove(ChessGame game, {required PieceColor forColor}) {
    if (game.isGameOver || !game.isReadyToPlay) return null;
    _resolveNonPlayPhases(game);
    if (game.isGameOver || game.enginePhase != GameEnginePhase.play) {
      return null;
    }
    if (game.turn != forColor) return null;

    final root = game.createSnapshot();
    final moves = _orderedMoves(game);
    if (moves.isEmpty) {
      game.restoreSnapshot(root);
      return null;
    }

    var bestScore = forColor == PieceColor.white ? -0x3fffffff : 0x3fffffff;
    final best = <Move>[];

    for (final move in moves) {
      game.restoreSnapshot(root);
      final result = game.makeMove(_preferQueenPromo(move));
      if (result == null) continue;
      _resolveNonPlayPhases(game);
      final score = _search(
        game,
        depth: searchDepth - 1,
        alpha: -0x3fffffff,
        beta: 0x3fffffff,
        maximizingWhite: forColor == PieceColor.black,
      );
      if (forColor == PieceColor.white) {
        if (score > bestScore) {
          bestScore = score;
          best
            ..clear()
            ..add(move);
        } else if (score == bestScore) {
          best.add(move);
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          best
            ..clear()
            ..add(move);
        } else if (score == bestScore) {
          best.add(move);
        }
      }
    }

    game.restoreSnapshot(root);
    if (best.isEmpty) return null;
    return _preferQueenPromo(best[_random.nextInt(best.length)]);
  }

  int _search(
    ChessGame game, {
    required int depth,
    required int alpha,
    required int beta,
    required bool maximizingWhite,
  }) {
    _resolveNonPlayPhases(game);
    if (game.isGameOver || depth <= 0) {
      return _evaluate(game);
    }
    if (game.enginePhase != GameEnginePhase.play) {
      return _evaluate(game);
    }

    final snap = game.createSnapshot();
    final moves = _orderedMoves(game);
    if (moves.isEmpty) {
      game.restoreSnapshot(snap);
      return _evaluate(game);
    }

    if (maximizingWhite) {
      var value = -0x3fffffff;
      for (final move in moves) {
        game.restoreSnapshot(snap);
        if (game.makeMove(_preferQueenPromo(move)) == null) continue;
        value = max(
          value,
          _search(
            game,
            depth: depth - 1,
            alpha: alpha,
            beta: beta,
            maximizingWhite: false,
          ),
        );
        alpha = max(alpha, value);
        if (alpha >= beta) break;
      }
      game.restoreSnapshot(snap);
      return value;
    }

    var value = 0x3fffffff;
    for (final move in moves) {
      game.restoreSnapshot(snap);
      if (game.makeMove(_preferQueenPromo(move)) == null) continue;
      value = min(
        value,
        _search(
          game,
          depth: depth - 1,
          alpha: alpha,
          beta: beta,
          maximizingWhite: true,
        ),
      );
      beta = min(beta, value);
      if (alpha >= beta) break;
    }
    game.restoreSnapshot(snap);
    return value;
  }

  List<Move> _orderedMoves(ChessGame game) {
    final moves = List<Move>.from(game.getLegalMoves());
    moves.sort((a, b) {
      final capA = _captureScore(game, a);
      final capB = _captureScore(game, b);
      if (capA != capB) return capB.compareTo(capA);
      return 0;
    });
    return moves;
  }

  int _captureScore(ChessGame game, Move move) {
    final victims = game.piecesAt(move.to);
    if (victims.isEmpty) return 0;
    var score = 0;
    for (final p in victims) {
      score += _pieceValue[p.type] ?? 0;
    }
    return score;
  }

  int _evaluate(ChessGame game) {
    if (game.isGameOver) {
      if (game.winnerColor == PieceColor.white) return 100000;
      if (game.winnerColor == PieceColor.black) return -100000;
      return 0;
    }
    var score = 0;
    for (var rank = 0; rank < game.rankCount; rank++) {
      for (var file = 0; file < game.fileCount; file++) {
        final square = Square(file, rank);
        for (final piece in game.piecesAt(square)) {
          final base = _pieceValue[piece.type] ?? 0;
          final pst = _pstBonus(piece, square, game.rankCount);
          final signed = piece.color == PieceColor.white
              ? base + pst
              : -(base + pst);
          score += signed;
        }
      }
    }
    if (game.isInCheck(PieceColor.white)) score -= 40;
    if (game.isInCheck(PieceColor.black)) score += 40;
    return score;
  }

  int _pstBonus(Piece piece, Square square, int rankCount) {
    // Encourage centralisation; flip ranks for black.
    final rank = piece.color == PieceColor.white
        ? square.rank
        : (rankCount - 1 - square.rank);
    final file = square.file;
    final centerFile = (file - 3.5).abs();
    final centerRank = (rank - 3.5).abs();
    switch (piece.type) {
      case PieceType.pawn:
        return rank * 6 - (centerFile * 2).round();
      case PieceType.knight:
        return 20 - ((centerFile + centerRank) * 4).round();
      case PieceType.bishop:
        return 12 - ((centerFile + centerRank) * 2).round();
      case PieceType.king:
        return rank < 2 ? 10 : -rank;
      default:
        return 0;
    }
  }

  Move _preferQueenPromo(Move move) {
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

  void _resolveNonPlayPhases(ChessGame game) {
    var guard = 0;
    while (!game.isGameOver && guard++ < 48) {
      if (game.isAwaitingSkillChoice) {
        game.skipPendingAbility();
        continue;
      }
      if (game.isAwaitingReaction) {
        game.declineRansom();
        continue;
      }
      if (game.isAwaitingGallop) {
        game.skipGallop();
        continue;
      }
      if (game.isAwaitingAbilityTarget) {
        if (!game.autoResolveAbilityTarget()) break;
        continue;
      }
      if (game.enginePhase == GameEnginePhase.play) break;
      break;
    }
  }
}
