import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/chess/fen_export.dart';
import 'package:super_chess/chess/stockfish_player.dart';
import 'package:super_chess/l10n/models/piece.dart';

void main() {
  test('tryBuildFen returns starting-style fen after white start only', () {
    final game = ChessGame(
      abilityChoosingColors: const {PieceColor.white},
    );
    final offer = game.startOffersFor(PieceColor.white).first;
    game.applyStartAbility(PieceColor.white, offer.ability, remoteOffer: offer);
    final fen = tryBuildFen(game);
    expect(fen, isNotNull);
    expect(fen!.startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR'), isTrue);
    expect(fen.contains(' w '), isTrue);
  });

  test('StockfishPlayer returns null without a native engine on desktop', () async {
    final game = ChessGame(
      abilityChoosingColors: const {PieceColor.white},
    );
    final offer = game.startOffersFor(PieceColor.white).first;
    game.applyStartAbility(PieceColor.white, offer.ability, remoteOffer: offer);
    final white = game.getLegalMoves().first;
    expect(game.makeMove(white), isNotNull);

    final player = StockfishPlayer(movetimeMs: 50);
    await player.ensureReady();
    // Desktop has no stockfish plugin binary; no ComputerPlayer fallback.
    expect(player.isStockfishActive, isFalse);
    expect(player.issue, StockfishIssue.engineUnavailable);
    final move = await player.chooseMove(game, forColor: PieceColor.black);
    expect(move, isNull);
    expect(player.issue, StockfishIssue.engineUnavailable);
    player.dispose();
  });
}
