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
    // Geometry-breaking start mods may return null — only assert when 8×8.
    if (game.fileCount == 8 && game.rankCount == 8) {
      expect(fen, isNotNull);
      expect(fen!.contains(' w '), isTrue);
    }
  });

  test('StockfishPlayer returns null when engine factory yields null', () async {
    final game = ChessGame(
      abilityChoosingColors: const {PieceColor.white},
    );
    final offer = game.startOffersFor(PieceColor.white).first;
    game.applyStartAbility(PieceColor.white, offer.ability, remoteOffer: offer);
    final white = game.getLegalMoves().first;
    expect(game.makeMove(white), isNotNull);

    final player = StockfishPlayer(
      movetimeMs: 50,
      engineFactory: () async => null,
    );
    await player.ensureReady();
    expect(player.isStockfishActive, isFalse);
    expect(player.issue, StockfishIssue.engineUnavailable);
    final move = await player.chooseMove(game, forColor: PieceColor.black);
    expect(move, isNull);
    expect(player.issue, StockfishIssue.engineUnavailable);
    player.dispose();
  });
}
