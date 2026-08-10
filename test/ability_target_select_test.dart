import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/l10n/models/ability_catalog.dart';
import 'package:super_chess/l10n/models/game_ability.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';

ChessGame _readyPlain() {
  final game = ChessGame(catalog: AbilityCatalog(random: Random(1)));
  // Skip random start mods so piece-type targeting stays predictable.
  game.skipStartAbility(PieceColor.white);
  game.skipStartAbility(PieceColor.black);
  return game;
}

void main() {
  test('selecting piece for Gallop clears target phase and allows moves', () {
    final game = _readyPlain();
    const offer = AbilityOffer(
      ability: GameAbility.knightGallop,
      applyMode: AbilityApplyMode.selectFriendlyPiece,
      forColor: PieceColor.white,
    );
    game.debugApplyOffer(PieceColor.white, offer);

    expect(game.isAwaitingAbilityTarget, isTrue);
    final ids = game.legalAbilityTargetPieceIds;
    // Two white knights on the starting board.
    expect(ids, hasLength(2));

    expect(game.chooseAbilityTarget(pieceId: ids.first), isTrue);

    // Bug was: stayed in ability-target mode highlighting all friendly pieces.
    expect(game.isAwaitingAbilityTarget, isFalse);
    expect(game.legalAbilityTargetPieceIds, isEmpty);
    expect(game.enginePhase, GameEnginePhase.play);

    final knight = game.pieceAt(const Square(1, 0));
    final other = game.pieceAt(const Square(6, 0));
    final granted =
        (knight?.hasAbility(GameAbility.knightGallop) ?? false) ||
        (other?.hasAbility(GameAbility.knightGallop) ?? false);
    expect(granted, isTrue);

    final moves = game.getLegalMoves();
    expect(moves, isNotEmpty);
    expect(game.makeMove(moves.first), isNotNull);
  });

  test('selecting piece for Dust clears target phase', () {
    final game = _readyPlain();
    const offer = AbilityOffer(
      ability: GameAbility.knightDust,
      applyMode: AbilityApplyMode.selectFriendlyPiece,
      forColor: PieceColor.white,
    );
    game.debugApplyOffer(PieceColor.white, offer);
    expect(game.isAwaitingAbilityTarget, isTrue);
    final id = game.legalAbilityTargetPieceIds.first;
    expect(game.chooseAbilityTarget(pieceId: id), isTrue);
    expect(game.isAwaitingAbilityTarget, isFalse);
    expect(game.enginePhase, GameEnginePhase.play);
  });
}
