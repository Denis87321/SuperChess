import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/chess/computer_player.dart';
import 'package:super_chess/models/piece.dart';

void main() {
  test('vs-computer game skips black start abilities', () {
    final game = ChessGame(
      abilityChoosingColors: const {PieceColor.white},
    );
    expect(game.isAwaitingStartChoice(PieceColor.black), isFalse);
    expect(game.isAwaitingStartChoice(PieceColor.white), isTrue);
    expect(game.isReadyToPlay, isFalse);

    final offer = game.startOffersFor(PieceColor.white).first;
    game.applyStartAbility(PieceColor.white, offer.ability, remoteOffer: offer);
    expect(game.isReadyToPlay, isTrue);
  });

  test('computer player returns a legal move', () {
    final game = ChessGame(
      abilityChoosingColors: const {PieceColor.white},
    );
    final offer = game.startOffersFor(PieceColor.white).first;
    game.applyStartAbility(PieceColor.white, offer.ability, remoteOffer: offer);

    // Human (white) plays a simple pawn move, then bot (black) replies.
    final whiteMoves = game.getLegalMoves();
    expect(whiteMoves, isNotEmpty);
    final whiteMove = whiteMoves.firstWhere(
      (m) => m.from.file == 4 && m.from.rank == 1,
      orElse: () => whiteMoves.first,
    );
    expect(game.makeMove(whiteMove), isNotNull);

    final bot = ComputerPlayer(searchDepth: 1);
    final reply = bot.chooseMove(game, forColor: PieceColor.black);
    expect(reply, isNotNull);
    expect(game.getLegalMoves(), contains(reply));
  });
}
