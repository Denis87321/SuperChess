import '../chess/chess_game.dart';
import '../chess/move.dart';
import '../l10n/models/piece.dart';
import 'puzzle_models.dart';

ChessGame gameFromPuzzle(PuzzleDefinition puzzle) {
  return ChessGame.setupPuzzle(
    pieces: [
      for (final p in puzzle.pieces) (square: p.square, piece: p.toPiece()),
    ],
    turn: puzzle.turn,
    boardAbilities: puzzle.boardAbilities,
  );
}

/// Whether [game] currently satisfies the puzzle goal for the side to solve.
bool puzzleGoalMet(PuzzleDefinition puzzle, ChessGame game, {required int plyCount}) {
  switch (puzzle.goal) {
    case PuzzleGoal.checkmate:
      return game.isGameOver &&
          game.endReason == GameEndReason.checkmate &&
          game.winnerColor == puzzle.turn;
    case PuzzleGoal.captureKing:
      return game.isGameOver &&
          game.endReason == GameEndReason.kingDestroyed &&
          game.winnerColor == puzzle.turn;
    case PuzzleGoal.alternativeWin:
      return game.isGameOver &&
          game.endReason == GameEndReason.alternativeVictory &&
          game.winnerColor == puzzle.turn;
    case PuzzleGoal.surviveNMoves:
      final n = puzzle.surviveMoves ?? 1;
      return !game.isGameOver && plyCount >= n;
  }
}

/// Apply the first legal solution move (with promotion=queen if needed).
bool applySolutionMove(ChessGame game, PuzzleMove step) {
  final legal = game.getLegalMoves(from: step.from);
  Move? match;
  for (final m in legal) {
    if (m.to == step.to) {
      match = m;
      if (m.promotion == PieceType.queen || m.promotion == null) break;
    }
  }
  if (match == null) {
    // Prefer queen promotion if several promo choices share the same squares.
    for (final m in legal) {
      if (m.to == step.to && m.promotion == PieceType.queen) {
        match = m;
        break;
      }
    }
  }
  if (match == null) return false;
  return game.makeMove(match) != null;
}
