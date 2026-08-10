import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/chess/move.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/puzzles/puzzle_engine.dart';
import 'package:super_chess/puzzles/puzzle_models.dart';

void main() {
  late List<PuzzleDefinition> pack;

  setUpAll(() {
    final raw = File('assets/puzzles/puzzles.json').readAsStringSync();
    pack = parsePuzzlePack(raw);
  });

  PuzzleDefinition byId(String id) => pack.firstWhere((p) => p.id == id);

  test('puzzle pack loads', () {
    expect(pack.length, greaterThanOrEqualTo(8));
  });

  test('tour-de-france solution wins via center', () {
    final puzzle = byId('tour-de-france-1');
    final game = gameFromPuzzle(puzzle);
    expect(game.kingCenterActive, isTrue);
    expect(applySolutionMove(game, puzzle.solution.first), isTrue);
    expect(
      puzzleGoalMet(puzzle, game, plyCount: 1),
      isTrue,
    );
    expect(game.endReason, GameEndReason.alternativeVictory);
  });

  test('atomic blast destroys king', () {
    final puzzle = byId('atomic-knight-1');
    final game = gameFromPuzzle(puzzle);
    expect(game.atomicActive, isTrue);
    expect(applySolutionMove(game, puzzle.solution.first), isTrue);
    expect(puzzleGoalMet(puzzle, game, plyCount: 1), isTrue);
    expect(game.endReason, GameEndReason.kingDestroyed);
  });

  test('back-rank mate is checkmate', () {
    final puzzle = byId('back-rank-mate');
    final game = gameFromPuzzle(puzzle);
    expect(applySolutionMove(game, puzzle.solution.first), isTrue);
    expect(puzzleGoalMet(puzzle, game, plyCount: 1), isTrue);
    expect(game.endReason, GameEndReason.checkmate);
  });

  test('airborne jump is a legal promotion move', () {
    final puzzle = byId('airborne-1');
    final game = gameFromPuzzle(puzzle);
    final legal = game.getLegalMoves(from: puzzle.solution.first.from);
    expect(
      legal.any(
        (m) =>
            m.to == puzzle.solution.first.to &&
            m.promotion == PieceType.queen,
      ),
      isTrue,
    );
  });

  test('queen mate puzzle solves', () {
    final puzzle = byId('queen-mate-1');
    final game = gameFromPuzzle(puzzle);
    expect(applySolutionMove(game, puzzle.solution.first), isTrue);
    expect(puzzleGoalMet(puzzle, game, plyCount: 1), isTrue);
  });
}
