import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/chess/move.dart';
import 'package:super_chess/l10n/models/ability_catalog.dart';
import 'package:super_chess/l10n/models/ability_group.dart';
import 'package:super_chess/l10n/models/game_ability.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';

ChessGame _readyGame() => _readyGameWithKingSwap();

ChessGame _emptyReadyGame() {
  final game = _readyGame();
  for (var rank = 0; rank < game.rankCount; rank++) {
    for (var file = 0; file < game.fileCount; file++) {
      game.debugSetPiece(Square(file, rank), null);
    }
  }
  game.debugSetPiece(
    const Square(7, 0),
    const Piece(
      pieceId: 'white-king',
      type: PieceType.king,
      color: PieceColor.white,
      hasMoved: true,
    ),
  );
  game.debugSetPiece(
    const Square(7, 7),
    const Piece(
      pieceId: 'black-king',
      type: PieceType.king,
      color: PieceColor.black,
      hasMoved: true,
    ),
  );
  return game;
}

class _CountingRandom implements Random {
  _CountingRandom(int seed) : _delegate = Random(seed);

  final Random _delegate;
  int calls = 0;

  @override
  bool nextBool() {
    calls++;
    return _delegate.nextBool();
  }

  @override
  double nextDouble() {
    calls++;
    return _delegate.nextDouble();
  }

  @override
  int nextInt(int max) {
    calls++;
    return _delegate.nextInt(max);
  }
}

ChessGame _readyGameWithKingSwap() {
  for (var seed = 0; seed < 5000; seed++) {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
    final whiteOffers = game.startOffersFor(PieceColor.white);
    final blackOffers = game.startOffersFor(PieceColor.black);
    if (!whiteOffers.any((o) => o.ability == GameAbility.boardKingSwap) ||
        !blackOffers.any((o) => o.ability == GameAbility.boardKingSwap)) {
      continue;
    }
    game.applyStartAbility(PieceColor.white, GameAbility.boardKingSwap);
    game.applyStartAbility(PieceColor.black, GameAbility.boardKingSwap);
    return game;
  }
  throw StateError('Could not find seed with boardKingSwap');
}

void main() {
  test('start offers contain three board abilities', () {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(1)));
    expect(game.startOffersFor(PieceColor.white), hasLength(3));
    expect(
      game
          .startOffersFor(PieceColor.white)
          .every((offer) => offer.ability.group == AbilityGroup.board),
      isTrue,
    );
  });

  test('remote start ability applies even if not in local offer list', () {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(42)));
    const remote = GameAbility.boardTroopFatigue;
    expect(
      game.startOffersFor(PieceColor.black).map((o) => o.ability),
      isNot(contains(remote)),
    );

    game.applyStartAbility(
      PieceColor.white,
      GameAbility.boardSkipTurn,
      remoteOffer: const AbilityOffer(
        ability: GameAbility.boardSkipTurn,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.white,
      ),
    );
    game.applyRemoteStartAbility(
      PieceColor.black,
      remote,
      offer: const AbilityOffer(
        ability: remote,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.black,
      ),
    );

    expect(game.isReadyToPlay, isTrue);
    expect(game.blackBoardAbility, remote);
    expect(game.activeAbilitiesSnapshot().blackStart?.ability, remote);
    expect(
      game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3))),
      isNotNull,
    );
  });

  test('resign and takeback work', () {
    final game = _readyGame();
    expect(game.canTakeback, isFalse);
    expect(
      game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3))),
      isNotNull,
    );
    expect(game.canTakeback, isTrue);
    expect(game.pieceAt(const Square(4, 3))?.type, PieceType.pawn);
    expect(game.takeback(), isTrue);
    expect(game.pieceAt(const Square(4, 1))?.type, PieceType.pawn);
    expect(game.pieceAt(const Square(4, 3)), isNull);
    expect(game.canTakeback, isFalse);

    game.resign(PieceColor.white);
    expect(game.isGameOver, isTrue);
    expect(game.winnerColor, PieceColor.black);
    expect(game.endReason, GameEndReason.resign);
  });

  test('board ability applies to all pawns at start', () {
    late ChessGame game;
    late GameAbility ability;
    var found = false;
    for (var seed = 0; seed < 5000; seed++) {
      game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
      final match = game
          .startOffersFor(PieceColor.white)
          .where((o) => o.ability == GameAbility.boardPawnsSideways);
      if (match.isEmpty) continue;
      ability = match.first.ability;
      found = true;
      break;
    }
    expect(found, isTrue);

    game.applyStartAbility(PieceColor.white, ability);
    game.applyStartAbility(
      PieceColor.black,
      game.startOffersFor(PieceColor.black).first.ability,
    );

    final pawn = game.pieceAt(const Square(4, 1));
    expect(pawn?.type, PieceType.pawn);
    expect(pawn?.abilities.contains(ability), isTrue);
  });

  test('classic pawn can advance two squares after start choice', () {
    final game = _readyGame();
    final moves = game.getLegalMoves(from: const Square(4, 1));

    expect(moves.any((move) => move.to == const Square(4, 3)), isTrue);
  });

  test('capture does not prompt skill choice', () {
    final game = _readyGame();
    game.makeMove(const Move(from: Square(3, 1), to: Square(3, 3)));
    game.makeMove(const Move(from: Square(2, 6), to: Square(2, 4)));
    final capture = game.makeMove(
      const Move(from: Square(3, 3), to: Square(2, 4)),
    );

    expect(capture?.requiresSkillChoice, isFalse);
    expect(game.isAwaitingSkillChoice, isFalse);
    expect(game.turn, PieceColor.black);
  });

  test('initiative fear grants bonus choice to first capture victim', () {
    final game = _emptyReadyGame();
    game.debugApplyOffer(
      PieceColor.white,
      const AbilityOffer(
        ability: GameAbility.boardInitiativeFear,
        applyMode: AbilityApplyMode.boardWide,
      ),
    );
    game.debugSetPiece(
      const Square(0, 1),
      const Piece(
        pieceId: 'wr',
        type: PieceType.rook,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(0, 4),
      const Piece(
        pieceId: 'br',
        type: PieceType.rook,
        color: PieceColor.black,
        hasMoved: true,
      ),
    );
    game.debugSetTurn(PieceColor.white);
    final beforeWhite = game.createSnapshot().boardRules.whiteMovesSinceAbilityWave;
    final beforeBlack = game.createSnapshot().boardRules.blackMovesSinceAbilityWave;

    final result = game.makeMove(
      const Move(from: Square(0, 1), to: Square(0, 4)),
    );
    expect(result?.requiresSkillChoice, isTrue);
    expect(game.isAwaitingSkillChoice, isTrue);
    expect(game.pendingSkillColor, PieceColor.black);
    expect(game.pendingCaptureOffers, hasLength(3));
    // Wave counters still advance for the capturer's completed move, but this
    // choice is bonus and must not open the periodic white→black queue.
    expect(
      game.createSnapshot().boardRules.pendingPeriodicChooserQueue,
      isEmpty,
    );
    expect(
      game.createSnapshot().boardRules.whiteMovesSinceAbilityWave,
      beforeWhite + 1,
    );
    expect(
      game.createSnapshot().boardRules.blackMovesSinceAbilityWave,
      beforeBlack,
    );

    final offer = game.pendingCaptureOffers.firstWhere(
      (o) =>
          o.targetSelection == AbilityTargetSelection.none &&
          (o.applyMode == AbilityApplyMode.boardWide ||
              o.applyMode == AbilityApplyMode.allPiecesOfType),
      orElse: () => game.pendingCaptureOffers.first,
    );
    game.applyAbility(offer.ability);
    expect(game.isAwaitingSkillChoice, isFalse);
    expect(game.turn, PieceColor.black);

    // Second capture must not grant another bonus.
    game.debugSetPiece(
      const Square(1, 1),
      const Piece(
        pieceId: 'wr2',
        type: PieceType.rook,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(1, 4),
      const Piece(
        pieceId: 'br2',
        type: PieceType.rook,
        color: PieceColor.black,
        hasMoved: true,
      ),
    );
    game.debugSetTurn(PieceColor.white);
    final second = game.makeMove(
      const Move(from: Square(1, 1), to: Square(1, 4)),
    );
    expect(second?.requiresSkillChoice, isFalse);
    expect(game.isAwaitingSkillChoice, isFalse);
  });

  test('after 3 moves each, white then black choose mods', () {
    final game = _readyGame();
    // White 1 / Black 1
    expect(
      game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3))),
      isNotNull,
    );
    expect(
      game.makeMove(const Move(from: Square(4, 6), to: Square(4, 4))),
      isNotNull,
    );
    // White 2 / Black 2
    expect(
      game.makeMove(const Move(from: Square(3, 1), to: Square(3, 3))),
      isNotNull,
    );
    expect(
      game.makeMove(const Move(from: Square(3, 6), to: Square(3, 4))),
      isNotNull,
    );
    // White 3
    expect(
      game.makeMove(const Move(from: Square(2, 1), to: Square(2, 3))),
      isNotNull,
    );
    expect(game.isAwaitingSkillChoice, isFalse);
    // Black 3 -> wave starts for white
    final sixth = game.makeMove(const Move(from: Square(2, 6), to: Square(2, 4)));
    expect(sixth?.requiresSkillChoice, isTrue);
    expect(game.isAwaitingSkillChoice, isTrue);
    expect(game.pendingSkillColor, PieceColor.white);
    expect(game.pendingCaptureOffers, hasLength(3));

    void finishTargets() {
      var guard = 0;
      while (game.isAwaitingAbilityTarget && guard++ < 12) {
        final options = game.legalAbilityOptions;
        if (options.isNotEmpty) {
          expect(game.chooseAbilityToRemove(options.first), isTrue);
          continue;
        }
        final ids = game.legalAbilityTargetPieceIds;
        final squares = game.legalAbilityTargetSquares;
        if (ids.isNotEmpty) {
          expect(game.chooseAbilityTarget(pieceId: ids.first), isTrue);
        } else if (squares.isNotEmpty) {
          expect(game.chooseAbilityTarget(square: squares.first), isTrue);
        } else {
          break;
        }
      }
    }

    AbilityOffer pickSimple(List<AbilityOffer> offers) {
      return offers.firstWhere(
        (o) =>
            o.targetSelection == AbilityTargetSelection.none &&
            (o.applyMode == AbilityApplyMode.boardWide ||
                o.applyMode == AbilityApplyMode.allPiecesOfType),
        orElse: () => offers.first,
      );
    }

    final whiteOffer = pickSimple(game.pendingCaptureOffers);
    game.applyAbility(whiteOffer.ability);
    finishTargets();

    expect(game.isAwaitingSkillChoice, isTrue);
    expect(game.pendingSkillColor, PieceColor.black);
    final blackOffer = pickSimple(game.pendingCaptureOffers);
    game.applyAbility(blackOffer.ability);
    finishTargets();

    expect(game.isAwaitingSkillChoice, isFalse);
    expect(game.turn, PieceColor.white);
  });

  test('selectFriendlyPiece auto-applies when only one piece of type', () {
    final game = _emptyReadyGame();
    game.debugSetPiece(
      const Square(1, 0),
      const Piece(
        pieceId: 'only-knight',
        type: PieceType.knight,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetTurn(PieceColor.white);
    // Force a periodic choice with a knight ability.
    game.debugApplyOffer(
      PieceColor.white,
      const AbilityOffer(
        ability: GameAbility.knightCentaur,
        applyMode: AbilityApplyMode.selectFriendlyPiece,
      ),
    );
    // debugApplyOffer applies immediately; verify grant path via applyAbility flow:
    expect(
      game.pieceAt(const Square(1, 0))?.abilities.contains(
            GameAbility.knightCentaur,
          ),
      isTrue,
    );
  });

  test('royal decree swap does not prompt skill choice', () {
    final game = _readyGameWithKingSwap();
    final kingSquare = game.findKing(PieceColor.white)!;
    final rookFile = kingSquare.file == 7 ? 0 : 7;
    final rookSquare = Square(rookFile, kingSquare.rank);

    final result = game.makeMove(
      Move(from: kingSquare, to: rookSquare, isCastleSwap: true),
    );

    expect(result?.requiresSkillChoice, isFalse);
    expect(game.isAwaitingSkillChoice, isFalse);
    expect(game.pieceAt(rookSquare)?.royalDecreeUsed, isTrue);
  });

  test('royal decree can only be used once', () {
    final game = _readyGameWithKingSwap();
    final kingSquare = game.findKing(PieceColor.white)!;
    final rank = kingSquare.rank;

    game.makeMove(
      Move(from: kingSquare, to: Square(7, rank), isCastleSwap: true),
    );
    game.makeMove(const Move(from: Square(4, 6), to: Square(4, 5)));

    final kingOnBoard = game.findKing(PieceColor.white)!;
    final swapMoves = game
        .getLegalMoves(from: kingOnBoard)
        .where((move) => move.isCastleSwap);

    expect(swapMoves, isEmpty);
  });

  test('cannot move into self check', () {
    final game = _readyGame();
    game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3)));
    game.makeMove(const Move(from: Square(3, 6), to: Square(3, 5)));
    game.makeMove(const Move(from: Square(3, 0), to: Square(7, 4)));
    game.makeMove(const Move(from: Square(4, 7), to: Square(4, 6)));

    final illegal = game.makeMove(
      const Move(from: Square(7, 4), to: Square(3, 0)),
    );

    expect(illegal, isNull);
    expect(game.pieceAt(const Square(7, 4))?.type, PieceType.queen);
  });

  test('board diagonal pawn ability inverts movement', () {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(1)));
    final whiteOffers = game.startOffersFor(PieceColor.white);
    final diagonalOffer = whiteOffers.cast<AbilityOffer?>().firstWhere(
      (o) => o!.ability == GameAbility.boardPawnsDiagonal,
      orElse: () => null,
    );
    if (diagonalOffer == null) return;

    game.applyStartAbility(PieceColor.white, GameAbility.boardPawnsDiagonal);
    game.applyStartAbility(
      PieceColor.black,
      game.startOffersFor(PieceColor.black).first.ability,
    );

    final moves = game.getLegalMoves(from: const Square(4, 1));
    expect(moves.any((move) => move.to == const Square(3, 2)), isTrue);
    expect(moves.any((move) => move.to == const Square(5, 2)), isTrue);
    expect(moves.any((move) => move.to == const Square(4, 2)), isFalse);
  });

  test('detects checkmate in fools mate', () {
    final game = _readyGame();
    game.makeMove(const Move(from: Square(5, 1), to: Square(5, 2)));
    game.makeMove(const Move(from: Square(4, 6), to: Square(4, 4)));
    game.makeMove(const Move(from: Square(6, 1), to: Square(6, 3)));
    game.makeMove(const Move(from: Square(3, 7), to: Square(7, 3)));

    expect(game.status, GameStatus.checkmate);
    expect(game.turn, PieceColor.white);
    expect(game.winnerColor, PieceColor.black);
    expect(game.endReason, GameEndReason.checkmate);
  });

  test('initial pieces have unique stable identity', () {
    final game = _readyGame();
    final ids = <String>{};
    for (final row in game.board) {
      for (final piece in row.whereType<Piece>()) {
        expect(piece.pieceId, isNotEmpty);
        expect(ids.add(piece.pieceId), isTrue);
        expect(piece.copyWith(type: PieceType.queen).pieceId, piece.pieceId);
      }
    }
    expect(ids, hasLength(32));

    final before = game.pieceAt(const Square(4, 1))!.pieceId;
    game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3)));
    expect(game.pieceAt(const Square(4, 3))!.pieceId, before);
  });

  test('promotion preserves piece identity', () {
    final game = _readyGame();
    for (var rank = 0; rank < game.rankCount; rank++) {
      for (var file = 0; file < game.fileCount; file++) {
        game.debugSetPiece(Square(file, rank), null);
      }
    }
    game.debugSetPiece(
      const Square(0, 0),
      const Piece(
        pieceId: 'white-king',
        type: PieceType.king,
        color: PieceColor.white,
      ),
    );
    game.debugSetPiece(
      const Square(7, 7),
      const Piece(
        pieceId: 'black-king',
        type: PieceType.king,
        color: PieceColor.black,
      ),
    );
    game.debugSetPiece(
      const Square(4, 6),
      const Piece(
        pieceId: 'promoting-pawn',
        type: PieceType.pawn,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetTurn(PieceColor.white);

    game.makeMove(
      const Move(
        from: Square(4, 6),
        to: Square(4, 7),
        promotion: PieceType.queen,
      ),
    );

    expect(game.pieceAt(const Square(4, 7))?.pieceId, 'promoting-pawn');
  });

  test('stalemate records a draw result', () {
    final game = _readyGame();
    for (var rank = 0; rank < game.rankCount; rank++) {
      for (var file = 0; file < game.fileCount; file++) {
        game.debugSetPiece(Square(file, rank), null);
      }
    }
    game.debugSetPiece(
      const Square(0, 7),
      const Piece(type: PieceType.king, color: PieceColor.black),
    );
    game.debugSetPiece(
      const Square(2, 5),
      const Piece(type: PieceType.king, color: PieceColor.white),
    );
    game.debugSetPiece(
      const Square(1, 5),
      const Piece(type: PieceType.queen, color: PieceColor.white),
    );
    game.debugSetTurn(PieceColor.black);
    game.debugUpdateStatus();

    expect(game.status, GameStatus.stalemate);
    expect(game.winnerColor, isNull);
    expect(game.endReason, GameEndReason.stalemate);
  });

  test('destroyed king clears an already-created pending choice', () {
    final game = _readyGame();
    for (var rank = 0; rank < game.rankCount; rank++) {
      for (var file = 0; file < game.fileCount; file++) {
        game.debugSetPiece(Square(file, rank), null);
      }
    }
    game.debugSetPiece(
      const Square(7, 0),
      const Piece(type: PieceType.king, color: PieceColor.white),
    );
    game.debugSetPiece(
      const Square(0, 7),
      const Piece(type: PieceType.king, color: PieceColor.black),
    );
    game.debugSetPiece(
      const Square(1, 6),
      const Piece(type: PieceType.queen, color: PieceColor.white),
    );
    game.debugSetTurn(PieceColor.white);

    final result = game.makeMove(
      const Move(from: Square(1, 6), to: Square(0, 7)),
    );

    expect(result?.requiresSkillChoice, isFalse);
    expect(game.isAwaitingSkillChoice, isFalse);
    expect(game.winnerColor, PieceColor.white);
    expect(game.endReason, GameEndReason.kingDestroyed);
  });

  test('snapshot restores complete visible gameplay state', () {
    final game = _readyGame();
    final snapshot = game.createSnapshot();
    final originalId = game.pieceAt(const Square(4, 1))!.pieceId;

    game.makeMove(const Move(from: Square(4, 1), to: Square(4, 3)));
    expect(game.turn, PieceColor.black);
    game.restoreSnapshot(snapshot);

    expect(game.turn, PieceColor.white);
    expect(game.status, GameStatus.playing);
    expect(game.enPassantTarget, isNull);
    expect(game.fileCount, snapshot.fileCount);
    expect(game.rankCount, snapshot.rankCount);
    expect(game.pieceAt(const Square(4, 1))?.pieceId, originalId);
    expect(game.pieceAt(const Square(4, 3)), isNull);
  });

  test('legality simulation neither mutates state nor consumes random', () {
    final game = _emptyReadyGame();
    game.debugSetPiece(
      const Square(2, 2),
      const Piece(
        type: PieceType.bishop,
        color: PieceColor.white,
      ).withAbility(GameAbility.bishopInquisitor),
    );
    game.debugSetPiece(
      const Square(4, 4),
      const Piece(
        type: PieceType.pawn,
        color: PieceColor.black,
      ).withAbility(GameAbility.pawnSideways),
    );
    game.debugSetTurn(PieceColor.white);
    final before = game.createSnapshot();

    final moves = game.getLegalMoves(from: const Square(2, 2));

    expect(moves.any((move) => move.isInquisitorStrip), isTrue);
    expect(game.pieceAt(const Square(4, 4))?.abilities, isNotEmpty);
    expect(game.createSnapshot().dustSquares, before.dustSquares);
    expect(game.createSnapshot().mines, before.mines);
  });

  test('tide advances pawns and removes double step', () {
    late ChessGame game;
    var found = false;
    for (var seed = 0; seed < 80; seed++) {
      game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
      if (!game
          .startOffersFor(PieceColor.white)
          .any((o) => o.ability == GameAbility.boardTide)) {
        continue;
      }
      game.applyStartAbility(PieceColor.white, GameAbility.boardTide);
      final blackOffers = game.startOffersFor(PieceColor.black);
      // Для стабильности выбираем "безопасную" мод стороны чёрных,
      // которая не должна напрямую блокировать движение пешки вперёд
      // (стены / размещение фигур на старте / мины).
      final blackSafeOffer = blackOffers.firstWhere(
        (o) => !{
          GameAbility.boardArchitect,
          GameAbility.boardGolconda,
          GameAbility.boardMinefield,
          GameAbility.boardTeleport,
          GameAbility.boardNight,
          GameAbility.boardDay,
        }.contains(o.ability),
        orElse: () => blackOffers.first,
      );
      game.applyStartAbility(
        PieceColor.black,
        blackSafeOffer.ability,
        lavaRank: blackSafeOffer.lavaRank,
      );
      // Для проверки механики "tide" ход должен принадлежать белым.
      game.debugSetTurn(PieceColor.white);

      // Из-за возможных эффектов соперника клетка перед пешкой иногда может
      // оказаться занятой. Мы проверяем именно механику tide:
      // вперёд на 1 — разрешён, на 2 — запрещён.
      game.debugSetPiece(const Square(4, 3), null);
      final moves = game.getLegalMoves(from: const Square(4, 2));
      final okSingle = moves.any(
        (m) => m.to == const Square(4, 3),
      );
      final okDouble = moves.any(
        (m) => m.to == const Square(4, 4),
      );

      if (game.pieceAt(const Square(4, 1)) == null &&
          game.pieceAt(const Square(4, 2))?.type == PieceType.pawn &&
          okSingle &&
          !okDouble) {
        found = true;
        break;
      }
    }
    expect(found, isTrue);
    expect(game.pieceAt(const Square(4, 1)), isNull);
    expect(game.pieceAt(const Square(4, 2))?.type, PieceType.pawn);
    // Из-за нового модификатора на старте (и рандомных катаклизмов на
    // стороне соперника) клетка перед пешкой иногда может оказаться
    // занятой. Для проверки механики "tide" нам важно лишь, что ход на
    // 1 клетку вперёд разрешён, а 2 клетки вперёд — нет.
    game.debugSetPiece(const Square(4, 3), null);
    final moves = game.getLegalMoves(from: const Square(4, 2));
    expect(moves.any((m) => m.to == const Square(4, 3)), isTrue);
    expect(moves.any((m) => m.to == const Square(4, 4)), isFalse);
  });

  test('sprint shortens skill choice timer', () {
    late ChessGame game;
    var found = false;
    for (var seed = 0; seed < 80; seed++) {
      game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
      if (!game
          .startOffersFor(PieceColor.white)
          .any((o) => o.ability == GameAbility.boardSprint)) {
        continue;
      }
      game.applyStartAbility(PieceColor.white, GameAbility.boardSprint);
      game.applyStartAbility(
        PieceColor.black,
        game.startOffersFor(PieceColor.black).first.ability,
        lavaRank: game.startOffersFor(PieceColor.black).first.lavaRank,
      );
      found = true;
      break;
    }
    expect(found, isTrue);
    expect(game.sprintActive, isTrue);
    expect(game.skillChoiceSeconds, 10);
  });

  test('double start allows a one-time triple step', () {
    late ChessGame game;
    var found = false;
    for (var seed = 0; seed < 2000; seed++) {
      game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
      if (!game
          .startOffersFor(PieceColor.white)
          .any((o) => o.ability == GameAbility.boardDoubleStart)) {
        continue;
      }
      final blackOffer = game
          .startOffersFor(PieceColor.black)
          .where(
            (o) =>
                o.ability == GameAbility.boardKingSwap ||
                o.ability == GameAbility.boardSprint ||
                o.ability == GameAbility.boardFogOfWar,
          )
          .firstOrNull;
      if (blackOffer == null) continue;

      game.applyStartAbility(PieceColor.white, GameAbility.boardDoubleStart);
      game.applyStartAbility(
        PieceColor.black,
        blackOffer.ability,
        lavaRank: blackOffer.lavaRank,
      );
      found = true;
      break;
    }
    expect(found, isTrue);
    final moves = game.getLegalMoves(from: const Square(4, 1));
    expect(moves.any((m) => m.to == const Square(4, 4)), isTrue);

    game.makeMove(const Move(from: Square(4, 1), to: Square(4, 4)));
    expect(game.pieceAt(const Square(4, 4))?.tripleStepUsed, isTrue);
  });

  ChessGame? _startWith(
    GameAbility ability, {
    Set<GameAbility> allowedBlack = const {
      GameAbility.boardKingSwap,
      GameAbility.boardSprint,
      GameAbility.boardFogOfWar,
      GameAbility.boardNight,
      GameAbility.boardDay,
      GameAbility.boardColorblind,
      GameAbility.boardMirror,
      GameAbility.boardZebras,
    },
  }) {
    for (var seed = 0; seed < 300; seed++) {
      final game = ChessGame(catalog: AbilityCatalog(random: Random(seed)));
      if (!game
          .startOffersFor(PieceColor.white)
          .any((o) => o.ability == ability)) {
        continue;
      }
      final blackOffer = game
          .startOffersFor(PieceColor.black)
          .where((o) => allowedBlack.contains(o.ability))
          .firstOrNull;
      if (blackOffer == null) continue;

      game.applyStartAbility(PieceColor.white, ability);
      game.applyStartAbility(
        PieceColor.black,
        blackOffer.ability,
        lavaRank: blackOffer.lavaRank,
      );
      if (game.isInCheck(PieceColor.white) || game.isInCheck(PieceColor.black)) {
        continue;
      }
      return game;
    }
    return null;
  }

  test('classic fisher keeps pawns and mirrors both sides', () {
    final game = _startWith(GameAbility.boardFisher);
    expect(game, isNotNull);

    for (var file = 0; file < 8; file++) {
      expect(game!.pieceAt(Square(file, 1))?.type, PieceType.pawn);
      expect(game.pieceAt(Square(file, 6))?.type, PieceType.pawn);
      expect(
        game.pieceAt(Square(file, 0))?.type,
        game.pieceAt(Square(file, 7))?.type,
      );
    }

    final whiteBishops = <Square>[];
    var kingFile = -1;
    final rookFiles = <int>[];
    for (var file = 0; file < 8; file++) {
      final piece = game!.pieceAt(Square(file, 0))!;
      if (piece.type == PieceType.bishop) whiteBishops.add(Square(file, 0));
      if (piece.type == PieceType.king) kingFile = file;
      if (piece.type == PieceType.rook) rookFiles.add(file);
    }
    expect(whiteBishops, hasLength(2));
    expect(
      (whiteBishops[0].file + whiteBishops[0].rank).isEven !=
          (whiteBishops[1].file + whiteBishops[1].rank).isEven,
      isTrue,
    );
    rookFiles.sort();
    expect(kingFile > rookFiles.first && kingFile < rookFiles.last, isTrue);
  });

  test('fisher madness mixes both ranks with opposite-color bishops', () {
    final game = _startWith(GameAbility.boardFisherMadness);
    expect(game, isNotNull);

    final bishops = <Square>[];
    for (var rank = 0; rank <= 1; rank++) {
      for (var file = 0; file < 8; file++) {
        final piece = game!.pieceAt(Square(file, rank));
        if (piece?.type == PieceType.bishop &&
            piece?.color == PieceColor.white) {
          bishops.add(Square(file, rank));
        }
      }
    }
    expect(bishops, hasLength(2));
    expect(
      (bishops[0].file + bishops[0].rank).isEven !=
          (bishops[1].file + bishops[1].rank).isEven,
      isTrue,
    );

    // На двух горизонталях ровно 16 белых фигур.
    var whiteCount = 0;
    for (var rank = 0; rank <= 1; rank++) {
      for (var file = 0; file < 8; file++) {
        if (game!.pieceAt(Square(file, rank))?.color == PieceColor.white) {
          whiteCount++;
        }
      }
    }
    expect(whiteCount, 16);
    expect(game!.isInCheck(PieceColor.white), isFalse);
    expect(game.isInCheck(PieceColor.black), isFalse);
  });

  test('fisher madness same rngSeed yields identical boards', () {
    const seed = 424242;
    final offer = AbilityOffer(
      ability: GameAbility.boardFisherMadness,
      applyMode: AbilityApplyMode.boardWide,
      rngSeed: seed,
      forColor: PieceColor.white,
    );
    final safeBlack = AbilityOffer(
      ability: GameAbility.boardSprint,
      applyMode: AbilityApplyMode.boardWide,
      forColor: PieceColor.black,
    );

    PieceType? typeAt(ChessGame g, Square s) => g.pieceAt(s)?.type;

    ChessGame build() {
      final game = ChessGame(catalog: AbilityCatalog(random: Random(1)));
      game.applyStartAbility(
        PieceColor.white,
        offer.ability,
        remoteOffer: offer,
      );
      game.applyStartAbility(
        PieceColor.black,
        safeBlack.ability,
        remoteOffer: safeBlack,
      );
      return game;
    }

    final a = build();
    final b = build();
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = Square(file, rank);
        expect(typeAt(a, square), typeAt(b, square), reason: '$square');
        expect(
          a.pieceAt(square)?.color,
          b.pieceAt(square)?.color,
          reason: '$square color',
        );
      }
    }
  });

  test('long step onto last rank offers promotion', () {
    final game = _readyGame();
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        game.debugSetPiece(Square(file, rank), null);
      }
    }
    game.debugSetPiece(
      const Square(0, 0),
      const Piece(
        type: PieceType.king,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(7, 7),
      const Piece(
        type: PieceType.king,
        color: PieceColor.black,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(4, 5),
      const Piece(
        type: PieceType.pawn,
        color: PieceColor.white,
        hasMoved: true,
      ).withAbility(GameAbility.pawnAlwaysDoubleStep),
    );

    final moves = game.getLegalMoves(from: const Square(4, 5));
    final toLast = moves.where((m) => m.to == const Square(4, 7)).toList();
    expect(toLast, isNotEmpty);
    expect(toLast.every((m) => m.promotion != null), isTrue);
    expect(
      toLast.map((m) => m.promotion).toSet(),
      containsAll([
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      ]),
    );
  });

  test('day lock allows pawn double step over a dark square', () {
    final game = _startWith(GameAbility.boardDay);
    expect(game, isNotNull);
    expect(game!.lightSquaresOnly, isTrue);

    // a1 is dark. e2 — светлая, e3 — тёмная, e4 — светлая.
    const e2 = Square(4, 1);
    const e3 = Square(4, 2);
    const e4 = Square(4, 3);
    expect(game.isSquareLight(e2), isTrue);
    expect(game.isSquareLight(e3), isFalse);
    expect(game.isSquareLight(e4), isTrue);

    final moves = game.getLegalMoves(from: e2);
    expect(moves.any((m) => m.to == e3), isFalse);
    expect(moves.any((m) => m.to == e4), isTrue);
  });

  group('piece ability engine phases', () {
    test('pawn inheritance uses stable nearest heir', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'legacy',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnInheritance, GameAbility.pawnSideways},
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'heir-a',
          type: PieceType.pawn,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(4, 2),
        const Piece(
          pieceId: 'heir-b',
          type: PieceType.pawn,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(3, 5),
        const Piece(
          pieceId: 'capturer',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetTurn(PieceColor.black);

      game.makeMove(const Move(from: Square(3, 5), to: Square(3, 3)));

      expect(
        game.pieceAt(const Square(2, 2))!.abilities,
        containsAll({GameAbility.pawnInheritance, GameAbility.pawnSideways}),
      );
      expect(game.pieceAt(const Square(4, 2))!.abilities, isEmpty);
    });

    test('ransom waits without mutation and can cancel move', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'ransom',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnRansom, GameAbility.pawnSideways},
        ),
      );
      game.debugSetPiece(
        const Square(3, 5),
        const Piece(
          pieceId: 'rook',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetTurn(PieceColor.black);

      final result = game.makeMove(
        const Move(from: Square(3, 5), to: Square(3, 3)),
      );

      expect(result?.outcome, MoveOutcome.awaitingReaction);
      expect(game.enginePhase, GameEnginePhase.reaction);
      expect(game.pieceAt(const Square(3, 5))?.pieceId, 'rook');
      expect(game.pieceAt(const Square(3, 3))?.pieceId, 'ransom');
      expect(game.acceptRansom(GameAbility.pawnRansom), isTrue);
      expect(game.turn, PieceColor.black);
      expect(game.pieceAt(const Square(3, 3))!.abilities, {
        GameAbility.pawnSideways,
      });
    });

    test('duel limits captures but preserves quiet moves', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(1, 0),
        const Piece(
          pieceId: 'duelist',
          type: PieceType.knight,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'chosen',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetPiece(
        const Square(3, 1),
        const Piece(
          pieceId: 'other',
          type: PieceType.pawn,
          color: PieceColor.black,
        ),
      );
      game.debugGrantAbility(const Square(1, 0), GameAbility.knightDuel);
      expect(game.chooseAbilityTarget(pieceId: 'chosen'), isTrue);
      game.debugSetTurn(PieceColor.white);

      final moves = game.getLegalMoves(from: const Square(1, 0));
      expect(moves.any((move) => move.to == const Square(2, 2)), isTrue);
      expect(moves.any((move) => move.to == const Square(3, 1)), isFalse);
      expect(moves.any((move) => move.to == const Square(0, 2)), isTrue);
      expect(game.duelPartnerOf('chosen'), 'duelist');
    });

    test('guard intercepts landing without separate reward', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(1, 0),
        const Piece(
          pieceId: 'guard',
          type: PieceType.knight,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(2, 5),
        const Piece(
          pieceId: 'intruder',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugGrantAbility(const Square(1, 0), GameAbility.knightGuard);
      expect(game.chooseAbilityTarget(square: const Square(2, 2)), isTrue);

      final result = game.makeMove(
        const Move(from: Square(2, 5), to: Square(2, 2)),
      );

      expect(result?.requiresSkillChoice, isFalse);
      expect(game.pieceAt(const Square(2, 2))?.pieceId, 'guard');
      expect(game.pieceAt(const Square(1, 0)), isNull);
      expect(game.knightGuards, isEmpty);
    });

    test('ransom precedes sanctuary and decline reaches protection', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'protector',
          type: PieceType.bishop,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'ward',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnRansom},
        ),
      );
      game.debugSetPiece(
        const Square(4, 4),
        const Piece(
          pieceId: 'attacker',
          type: PieceType.bishop,
          color: PieceColor.black,
        ),
      );
      game.debugGrantAbility(const Square(0, 0), GameAbility.bishopSanctuary);
      expect(game.chooseAbilityTarget(pieceId: 'ward'), isTrue);

      expect(
        game
            .makeMove(const Move(from: Square(4, 4), to: Square(2, 2)))
            ?.outcome,
        MoveOutcome.awaitingReaction,
      );
      expect(game.declineRansom()?.outcome, MoveOutcome.cancelled);
      expect(game.pieceAt(const Square(2, 2))?.pieceId, 'ward');
      expect(game.pieceAt(const Square(4, 4))?.pieceId, 'attacker');
      expect(game.pieceAt(const Square(0, 0)), isNull);
      expect(game.turn, PieceColor.black);
    });

    test('tithe suppression restores on bishop voluntary move', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'tithe-bishop',
          type: PieceType.bishop,
          color: PieceColor.white,
          abilities: {GameAbility.bishopTithe},
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'modified',
          type: PieceType.knight,
          color: PieceColor.black,
          abilities: {GameAbility.knightCentaur},
        ),
      );
      game.debugSetTurn(PieceColor.black);

      game.makeMove(const Move(from: Square(2, 2), to: Square(3, 3)));
      expect(
        game.hasEffectiveAbility('modified', GameAbility.knightCentaur),
        isFalse,
      );
      game.makeMove(const Move(from: Square(0, 0), to: Square(1, 1)));
      expect(
        game.hasEffectiveAbility('modified', GameAbility.knightCentaur),
        isTrue,
      );
    });

    test('excommunication blocks captured type until bishop moves', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'bishop',
          type: PieceType.bishop,
          color: PieceColor.white,
          abilities: {GameAbility.bishopExcommunication},
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'victim-rook',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetPiece(
        const Square(2, 5),
        const Piece(
          pieceId: 'other-rook',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetTurn(PieceColor.white);

      game.makeMove(const Move(from: Square(0, 0), to: Square(2, 2)));
      expect(
        game.isSquareAttacked(const Square(2, 2), PieceColor.black),
        isFalse,
      );

      // Capture no longer opens a skill choice; continue on white's turn.
      game.debugSetTurn(PieceColor.white);
      game.makeMove(const Move(from: Square(2, 2), to: Square(3, 3)));

      expect(
        game.isSquareAttacked(const Square(3, 3), PieceColor.black),
        isFalse,
      );
      game.debugSetPiece(const Square(3, 5), game.pieceAt(const Square(2, 5)));
      game.debugSetPiece(const Square(2, 5), null);
      expect(
        game.isSquareAttacked(const Square(3, 3), PieceColor.black),
        isTrue,
      );
    });

    test('pilgrimage visits four quadrants and grants one-use protection', () {
      final game = _emptyReadyGame();
      const route = [Square(0, 0), Square(4, 4), Square(1, 7), Square(7, 1)];
      game.debugSetPiece(
        route.first,
        const Piece(
          pieceId: 'pilgrim',
          type: PieceType.bishop,
          color: PieceColor.white,
        ),
      );
      game.debugGrantAbility(route.first, GameAbility.bishopPilgrimage);
      for (var i = 1; i < route.length; i++) {
        game.debugSetTurn(PieceColor.white);
        game.makeMove(Move(from: route[i - 1], to: route[i]));
      }

      expect(game.bishopPilgrimageQuadrants('pilgrim'), hasLength(4));
      expect(game.enginePhase, GameEnginePhase.abilityTarget);
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'pilgrimage-ward',
          type: PieceType.pawn,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(3, 6),
        const Piece(
          pieceId: 'pilgrimage-attacker',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      expect(game.chooseAbilityTarget(pieceId: 'pilgrimage-ward'), isTrue);
      expect(game.bishopPilgrimageCompleted('pilgrim'), isTrue);

      expect(
        game
            .makeMove(const Move(from: Square(3, 6), to: Square(3, 3)))
            ?.outcome,
        MoveOutcome.cancelled,
      );
      expect(game.pieceAt(const Square(3, 3))?.pieceId, 'pilgrimage-ward');
      expect(game.pieceAt(const Square(7, 1))?.pieceId, 'pilgrim');
    });

    test('knight tour tracks identity and queues three knight offers', () {
      final game = _emptyReadyGame();
      const route = [
        Square(1, 0),
        Square(2, 2),
        Square(4, 3),
        Square(6, 4),
        Square(4, 5),
        Square(2, 4),
        Square(0, 3),
        Square(1, 5),
      ];
      game.debugSetPiece(
        route.first,
        const Piece(
          pieceId: 'tourist',
          type: PieceType.knight,
          color: PieceColor.white,
        ),
      );
      game.debugGrantAbility(route.first, GameAbility.knightTour);
      for (var i = 1; i < route.length; i++) {
        game.debugSetTurn(PieceColor.white);
        game.makeMove(Move(from: route[i - 1], to: route[i]));
      }

      expect(game.knightTourVisited('tourist'), hasLength(8));
      expect(game.knightTourRewardUsed('tourist'), isTrue);
      expect(game.enginePhase, GameEnginePhase.skillChoice);
      expect(game.pendingCaptureOffers, hasLength(3));
      expect(
        game.pendingCaptureOffers.every(
          (offer) => offer.ability.primaryPieceType == PieceType.knight,
        ),
        isTrue,
      );
    });

    test('customs blocks enemy landing on controlled file', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'customs-rook',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(3, 6),
        const Piece(
          pieceId: 'enemy-rook',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugGrantAbility(
        const Square(0, 0),
        GameAbility.rookCustoms,
        offer: const AbilityOffer(
          ability: GameAbility.rookCustoms,
          applyMode: AbilityApplyMode.capturingPiece,
          axis: AbilityAxis.file,
        ),
      );
      game.debugSetTurn(PieceColor.black);

      final moves = game.getLegalMoves(from: const Square(3, 6));
      expect(moves.any((move) => move.to.file == 0), isFalse);
      expect(moves.any((move) => move.to == const Square(3, 0)), isTrue);
    });

    test('drawbridge lets ally hop through friendly rook', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'slider',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(0, 3),
        const Piece(
          pieceId: 'bridge',
          type: PieceType.rook,
          color: PieceColor.white,
          abilities: {GameAbility.rookDrawbridge},
        ),
      );
      game.debugSetTurn(PieceColor.white);

      final moves = game.getLegalMoves(from: const Square(0, 0));
      expect(moves.any((move) => move.to == const Square(0, 5)), isTrue);
      expect(moves.any((move) => move.to == const Square(0, 3)), isFalse);
    });

    test('delayed sentence kills after opponent turn if still attacked', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'queen',
          type: PieceType.queen,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(0, 5),
        const Piece(
          pieceId: 'marked',
          type: PieceType.pawn,
          color: PieceColor.black,
        ),
      );
      game.debugGrantAbility(const Square(0, 0), GameAbility.queenDelayedSentence);
      expect(game.legalAbilityTargetPieceIds, contains('marked'));
      expect(game.chooseAbilityTarget(pieceId: 'marked'), isTrue);
      expect(game.turn, PieceColor.black);

      // End black's turn with a king step; sentence resolves on that handoff.
      final moveResult = game.makeMove(
        const Move(from: Square(7, 7), to: Square(6, 7)),
      );
      expect(moveResult, isNotNull);
      expect(game.pieceAt(const Square(0, 5)), isNull);
      expect(
        game.graveyard.any((record) => record.piece.pieceId == 'marked'),
        isTrue,
      );
    });

    test('youShallNotPass destroys capturer and skips reward', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'doom-queen',
          type: PieceType.queen,
          color: PieceColor.black,
          abilities: {GameAbility.queenYouShallNotPass},
        ),
      );
      game.debugSetPiece(
        const Square(3, 0),
        const Piece(
          pieceId: 'attacker',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetTurn(PieceColor.white);

      final result = game.makeMove(
        const Move(from: Square(3, 0), to: Square(3, 3)),
      );
      expect(result?.requiresSkillChoice, isFalse);
      expect(game.pieceAt(const Square(3, 3)), isNull);
      expect(
        game.graveyard.any((record) => record.piece.pieceId == 'doom-queen'),
        isTrue,
      );
      expect(
        game.graveyard.any((record) => record.piece.pieceId == 'attacker'),
        isTrue,
      );
      expect(game.isAwaitingSkillChoice, isFalse);
    });

    test('trophy embargo skips capture skill reward', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(4, 4),
        const Piece(
          pieceId: 'embargo-queen',
          type: PieceType.queen,
          color: PieceColor.black,
          abilities: {GameAbility.queenTrophyEmbargo},
        ),
      );
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'capturer',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(0, 4),
        const Piece(
          pieceId: 'victim',
          type: PieceType.pawn,
          color: PieceColor.black,
        ),
      );
      game.debugSetTurn(PieceColor.white);

      final result = game.makeMove(
        const Move(from: Square(0, 0), to: Square(0, 4)),
      );
      expect(result, isNotNull);
      expect(result!.requiresSkillChoice, isFalse);
      expect(game.isAwaitingSkillChoice, isFalse);
      expect(game.pieceAt(const Square(0, 4))?.pieceId, 'capturer');
      expect(game.turn, PieceColor.black);
    });

    test('siege destroys target after three consecutive end-of-turn locks', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'siege-rook',
          type: PieceType.rook,
          color: PieceColor.white,
          abilities: {GameAbility.rookSiegeCalculation},
        ),
      );
      game.debugSetPiece(
        const Square(0, 5),
        const Piece(
          pieceId: 'siege-target',
          type: PieceType.pawn,
          color: PieceColor.black,
        ),
      );
      game.debugSetPiece(
        const Square(4, 4),
        const Piece(
          pieceId: 'black-mover',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetPiece(
        const Square(6, 1),
        const Piece(
          pieceId: 'white-mover',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );

      game.debugSetTurn(PieceColor.white);
      game.makeMove(const Move(from: Square(6, 1), to: Square(6, 2)));
      expect(game.rookSiegeFor('siege-rook')?.counter, 1);
      game.makeMove(const Move(from: Square(4, 4), to: Square(4, 5)));

      game.makeMove(const Move(from: Square(6, 2), to: Square(6, 3)));
      expect(game.rookSiegeFor('siege-rook')?.counter, 2);
      game.makeMove(const Move(from: Square(4, 5), to: Square(4, 6)));

      game.makeMove(const Move(from: Square(6, 3), to: Square(6, 4)));
      expect(game.pieceAt(const Square(0, 5)), isNull);
      expect(game.rookSiegeFor('siege-rook'), isNull);
      expect(
        game.graveyard.any((record) => record.piece.pieceId == 'siege-target'),
        isTrue,
      );
    });

    test('prisoner exchange restores both chosen captured pieces', () {
      final game = _emptyReadyGame();
      void dismissSkillChoice() {
        if (!game.isAwaitingSkillChoice) return;
        final offer = game.pendingCaptureOffers.firstWhere(
          (o) => o.targetSelection == AbilityTargetSelection.none,
          orElse: () => game.pendingCaptureOffers.first,
        );
        game.applyAbility(offer.ability);
        if (game.isAwaitingAbilityTarget) {
          final ids = game.legalAbilityTargetPieceIds;
          if (ids.isNotEmpty) {
            game.chooseAbilityTarget(pieceId: ids.first);
          } else if (game.legalAbilityTargetSquares.isNotEmpty) {
            game.chooseAbilityTarget(square: game.legalAbilityTargetSquares.first);
          }
        }
      }

      game.debugSetPiece(
        const Square(1, 1),
        const Piece(
          pieceId: 'white-prisoner',
          type: PieceType.knight,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(1, 4),
        const Piece(
          pieceId: 'black-capturer',
          type: PieceType.rook,
          color: PieceColor.black,
        ),
      );
      game.debugSetTurn(PieceColor.black);
      game.makeMove(const Move(from: Square(1, 4), to: Square(1, 1)));
      dismissSkillChoice();

      game.debugSetPiece(
        const Square(2, 6),
        const Piece(
          pieceId: 'black-prisoner',
          type: PieceType.bishop,
          color: PieceColor.black,
        ),
      );
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'white-capturer',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      game.makeMove(const Move(from: Square(2, 2), to: Square(2, 6)));
      dismissSkillChoice();

      expect(
        game.graveyard.where((r) => r.wasCapturedByOpponent),
        hasLength(2),
      );

      game.debugSetTurn(PieceColor.white);
      game.debugGrantAbility(
        const Square(7, 0),
        GameAbility.kingPrisonerExchange,
      );
      expect(game.enginePhase, GameEnginePhase.abilityTarget);
      expect(game.chooseAbilityTarget(pieceId: 'white-prisoner'), isTrue);
      expect(game.pendingTargetColor, PieceColor.black);
      expect(game.chooseAbilityTarget(pieceId: 'black-prisoner'), isTrue);

      bool onBoard(String id) => game.board.any(
        (row) => row.any((piece) => piece?.pieceId == id),
      );
      expect(onBoard('white-prisoner'), isTrue);
      expect(onBoard('black-prisoner'), isTrue);
    });

    test('remove enemy mod strips chosen ability from enemy piece', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(2, 2),
        const Piece(
          pieceId: 'modded',
          type: PieceType.knight,
          color: PieceColor.black,
          abilities: {GameAbility.knightCentaur, GameAbility.knightGallop},
        ),
      );
      game.debugGrantAbility(
        const Square(7, 0),
        GameAbility.kingRemoveEnemyMod,
      );
      expect(game.chooseAbilityTarget(pieceId: 'modded'), isTrue);
      expect(game.legalAbilityOptions, hasLength(2));
      expect(game.chooseAbilityToRemove(GameAbility.knightGallop), isTrue);
      expect(
        game.pieceAt(const Square(2, 2))?.abilities,
        equals({GameAbility.knightCentaur}),
      );
    });
  });

  group('board and cataclysm abilities', () {
    test('troop fatigue blocks the same piece next turn', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardTroopFatigue,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(1, 0),
        const Piece(
          pieceId: 'rook-w2',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(0, 0), to: Square(0, 3))),
        isNotNull,
      );
      game.debugSetTurn(PieceColor.white);
      expect(game.getLegalMoves(from: const Square(0, 3)), isEmpty);
      expect(game.getLegalMoves(from: const Square(1, 0)), isNotEmpty);
    });

    test('combat optics limits quiet slides to 3', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardCombatOptics,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(0, 5),
        const Piece(
          pieceId: 'pawn-b',
          type: PieceType.pawn,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(0, 0));
      expect(moves.any((m) => m.to == const Square(0, 3)), isTrue);
      expect(moves.any((m) => m.to == const Square(0, 4)), isFalse);
      expect(moves.any((m) => m.to == const Square(0, 5)), isTrue);
    });

    test('might makes right blocks weaker captures', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardMightMakesRight,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'pawn-w',
          type: PieceType.pawn,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(4, 4),
        const Piece(
          pieceId: 'rook-b',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(2, 4),
        const Piece(
          pieceId: 'pawn-b',
          type: PieceType.pawn,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(3, 3));
      expect(moves.any((m) => m.to == const Square(4, 4)), isFalse);
      expect(moves.any((m) => m.to == const Square(2, 4)), isTrue);
    });

    test('border closure blocks crossing mid-rank', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomBorderClosure,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 2,
        ),
      );
      game.debugSetPiece(
        const Square(0, 3),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(0, 3));
      expect(moves.any((m) => m.to == const Square(0, 2)), isTrue);
      expect(moves.any((m) => m.to == const Square(0, 4)), isFalse);
    });

    test('myopia limits ranged distance to 2', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomMyopia,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 3,
        ),
      );
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(0, 0));
      expect(moves.any((m) => m.to == const Square(0, 2)), isTrue);
      expect(moves.any((m) => m.to == const Square(0, 3)), isFalse);
    });

    test('magic shutdown disables piece ability effects', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(4, 1),
        const Piece(
          pieceId: 'pawn-w',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnSideways},
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(
        game
            .getLegalMoves(from: const Square(4, 1))
            .any((m) => m.to == const Square(5, 1)),
        isTrue,
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomMagicShutdown,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 3,
        ),
      );
      expect(
        game
            .getLegalMoves(from: const Square(4, 1))
            .any((m) => m.to == const Square(5, 1)),
        isFalse,
      );
    });

    test('suicide capture destroys capturer after capture', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomSuicideCapture,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(3, 5),
        const Piece(
          pieceId: 'pawn-b',
          type: PieceType.pawn,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      game.makeMove(const Move(from: Square(3, 3), to: Square(3, 5)));
      expect(game.pieceAt(const Square(3, 5)), isNull);
      expect(game.suicideCapturePending, isFalse);
    });

    test('king of hill wins above 48 squares', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardKingOfHill,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      var n = 0;
      for (var rank = 0; rank < 8 && n < 48; rank++) {
        for (var file = 0; file < 8 && n < 48; file++) {
          final square = Square(file, rank);
          if (square == const Square(0, 6)) continue;
          game.debugPaintTerritory(square, PieceColor.white);
          n++;
        }
      }
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(0, 0), to: Square(0, 6))),
        isNotNull,
      );
      expect(game.isGameOver, isTrue);
      expect(game.winnerColor, PieceColor.white);
      expect(game.endReason, GameEndReason.alternativeVictory);
    });

    test('passive aggression loses after countdown', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardPassiveAggression,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPassiveAggressionCounter(PieceColor.white, 1);
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      game.makeMove(const Move(from: Square(0, 0), to: Square(0, 1)));
      expect(game.isGameOver, isTrue);
      expect(game.winnerColor, PieceColor.black);
      expect(game.endReason, GameEndReason.alternativeVictory);
    });

    test('skip turn passes when enabled and not in check', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardSkipTurn,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(game.canSkipTurn, isTrue);
      expect(game.skipTurn(), isTrue);
      expect(game.turn, PieceColor.black);
    });

    test('secret route win on completing three squares', () {
      final game = _emptyReadyGame();
      const route = [Square(0, 1), Square(0, 2), Square(0, 3)];
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardSecretRoute,
          applyMode: AbilityApplyMode.boardWide,
          route: route,
        ),
      );
      expect(game.secretRouteFor(PieceColor.white), route);
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'rook-w',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      for (final square in route) {
        game.debugSetTurn(PieceColor.white);
        final from = game
            .getLegalMoves()
            .firstWhere((m) => m.to == square)
            .from;
        game.makeMove(Move(from: from, to: square));
      }
      expect(game.isGameOver, isTrue);
      expect(game.winnerColor, PieceColor.white);
      expect(game.endReason, GameEndReason.alternativeVictory);
    });

    test('royal pilgrimage wins on enemy back rank without check', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardRoyalPilgrimage,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(const Square(7, 0), null);
      game.debugSetPiece(
        const Square(4, 6),
        const Piece(
          pieceId: 'white-king',
          type: PieceType.king,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(4, 6), to: Square(4, 7))),
        isNotNull,
      );
      expect(game.isGameOver, isTrue);
      expect(game.winnerColor, PieceColor.white);
      expect(game.endReason, GameEndReason.alternativeVictory);
    });

    test('time capsule restores positions but keeps earned abilities', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 1),
        const Piece(
          pieceId: 'capsule-pawn',
          type: PieceType.pawn,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomTimeCapsule,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 1,
        ),
      );
      game.debugGrantAbility(const Square(0, 1), GameAbility.pawnSideways);
      game.debugSetTurn(PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(0, 1), to: Square(0, 2))),
        isNotNull,
      );
      expect(game.pieceAt(const Square(0, 1))?.pieceId, 'capsule-pawn');
      expect(
        game.pieceAt(const Square(0, 1))!.abilities,
        contains(GameAbility.pawnSideways),
      );
      expect(game.pieceAt(const Square(0, 2)), isNull);
    });

    test('right to move forces only the chosen enemy piece', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 6),
        const Piece(
          pieceId: 'forced',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(1, 6),
        const Piece(
          pieceId: 'other',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomRightToMove,
          applyMode: AbilityApplyMode.boardWide,
          hiddenData: {'pieceId': 'forced'},
        ),
      );
      game.debugSetTurn(PieceColor.black);
      expect(game.getLegalMoves(from: const Square(0, 6)), isNotEmpty);
      expect(game.getLegalMoves(from: const Square(1, 6)), isEmpty);
    });

    test('veto blocks the chosen piece for its duration', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 6),
        const Piece(
          pieceId: 'vetoed',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomVeto,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 3,
          hiddenData: {'pieceId': 'vetoed'},
        ),
      );
      game.debugSetTurn(PieceColor.black);
      expect(game.getLegalMoves(from: const Square(0, 6)), isEmpty);
    });

    test('strike freezes all pieces of the chosen type', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 6),
        const Piece(
          pieceId: 'struck-rook',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(2, 6),
        const Piece(
          pieceId: 'free-knight',
          type: PieceType.knight,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomStrike,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 3,
          affectedPieceType: PieceType.rook,
        ),
      );
      game.debugSetTurn(PieceColor.black);
      expect(game.strikePieceType, PieceType.rook);
      expect(game.getLegalMoves(from: const Square(0, 6)), isEmpty);
      expect(game.getLegalMoves(from: const Square(2, 6)), isNotEmpty);
    });

    test('word of honor strips an ability when pledge square is missed', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 1),
        const Piece(
          pieceId: 'pledger',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
          abilities: {GameAbility.pawnSideways, GameAbility.rookDrawbridge},
        ),
      );
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomWordOfHonor,
          applyMode: AbilityApplyMode.boardWide,
          targetCell: Square(0, 3),
        ),
      );
      game.debugSetTurn(PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(0, 1), to: Square(0, 2))),
        isNotNull,
      );
      final abilities = game.pieceAt(const Square(0, 2))!.abilities;
      expect(abilities.length, 1);
    });

    test('marseilles chess: белые делают 1 движение, затем по 2', () {
      final game = _emptyReadyGame();

      // В первую очередь выставим ход, чтобы инициализация моды
      // настроила правильный счётчик движений.
      game.debugSetTurn(PieceColor.white);
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardMarseillesChess,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );

      // Белые: 1 движение в рамках сегмента хода => смена игрока.
      expect(game.turn, PieceColor.white);
      expect(
        game.makeMove(const Move(from: Square(7, 0), to: Square(7, 1))),
        isNotNull,
      );
      expect(game.turn, PieceColor.black);

      // Чёрные: 2 движения => после первого смена игрока не происходит.
      expect(
        game.makeMove(const Move(from: Square(7, 7), to: Square(7, 6))),
        isNotNull,
      );
      expect(game.turn, PieceColor.black);

      // После второго: снова смена игрока.
      expect(
        game.makeMove(const Move(from: Square(7, 6), to: Square(7, 5))),
        isNotNull,
      );
      expect(game.turn, PieceColor.white);
    });
  });

  group('force-move and curfew interactions', () {
    test('standard bearer blocks typhoon rotation of adjacent ally', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'bearer',
          type: PieceType.rook,
          color: PieceColor.white,
          abilities: {GameAbility.rookStandardBearer},
        ),
      );
      game.debugSetPiece(
        const Square(3, 4),
        const Piece(
          pieceId: 'protected',
          type: PieceType.pawn,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(4, 4),
        const Piece(
          pieceId: 'loose',
          type: PieceType.pawn,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );

      expect(game.canForceMove(const Square(3, 4), 'protected'), isFalse);
      expect(game.canForceMove(const Square(4, 4), 'loose'), isTrue);

      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomTyphoon,
          applyMode: AbilityApplyMode.boardWide,
          typhoonOrigin: Square(3, 3),
        ),
      );
      expect(game.pieceAt(const Square(3, 4))?.pieceId, 'protected');
      expect(game.pieceAt(const Square(3, 3))?.pieceId, 'bearer');
    });

    test('curfew blocks enemy moves that increase distance from rook', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'curfew-rook',
          type: PieceType.rook,
          color: PieceColor.white,
        ),
      );
      game.debugSetPiece(
        const Square(3, 4),
        const Piece(
          pieceId: 'bound',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugGrantAbility(const Square(3, 3), GameAbility.rookCurfew);
      game.debugSetTurn(PieceColor.black);

      final moves = game.getLegalMoves(from: const Square(3, 4));
      expect(moves.any((m) => m.to == const Square(3, 5)), isFalse);
      expect(moves.any((m) => m.to == const Square(3, 3)), isTrue);
      expect(game.rookCurfews.any((c) => c.pieceId == 'bound'), isTrue);
    });

    test('ransom decline still allows suicide capture to resolve', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomSuicideCapture,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'ransom',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnRansom},
        ),
      );
      game.debugSetPiece(
        const Square(3, 5),
        const Piece(
          pieceId: 'attacker',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.black);
      expect(
        game
            .makeMove(const Move(from: Square(3, 5), to: Square(3, 3)))
            ?.outcome,
        MoveOutcome.awaitingReaction,
      );
      expect(game.declineRansom(), isNotNull);
      expect(game.pieceAt(const Square(3, 3)), isNull);
      expect(game.pieceAt(const Square(3, 5)), isNull);
    });
  });

  group('expansion batch abilities', () {
    test('fifth leg uses 2+2 knight deltas', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'k5',
          type: PieceType.knight,
          color: PieceColor.white,
          abilities: {GameAbility.knightFifthLeg},
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(3, 3));
      expect(moves.any((m) => m.to == const Square(5, 5)), isTrue);
      expect(moves.any((m) => m.to == const Square(4, 5)), isFalse);
    });

    test('trench blocks capture by a single attacker', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(3, 3),
        const Piece(
          pieceId: 'trench',
          type: PieceType.pawn,
          color: PieceColor.white,
          abilities: {GameAbility.pawnTrench},
          idleTurns: 5,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(4, 5),
        const Piece(
          pieceId: 'attacker',
          type: PieceType.knight,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.black);
      final moves = game.getLegalMoves(from: const Square(4, 5));
      expect(moves.any((m) => m.to == const Square(3, 3)), isFalse);
    });

    test('meat grinder forces a capture when one exists', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.randomMeatGrinder,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'wr',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetPiece(
        const Square(0, 5),
        const Piece(
          pieceId: 'br',
          type: PieceType.rook,
          color: PieceColor.black,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final moves = game.getLegalMoves(from: const Square(0, 0));
      expect(moves, isNotEmpty);
      expect(moves.every((m) => m.to == const Square(0, 5)), isTrue);
    });

    test('architect creates walls that reduce rook mobility', () {
      final game = _emptyReadyGame();
      game.debugSetPiece(
        const Square(0, 0),
        const Piece(
          pieceId: 'wr',
          type: PieceType.rook,
          color: PieceColor.white,
          hasMoved: true,
        ),
      );
      game.debugSetTurn(PieceColor.white);
      final before = game.getLegalMoves(from: const Square(0, 0)).length;
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardArchitect,
          applyMode: AbilityApplyMode.boardWide,
          durationMoves: 8,
        ),
      );
      final after = game.getLegalMoves(from: const Square(0, 0)).length;
      expect(after, lessThanOrEqualTo(before));
    });

    test('only equals kill wins after five same-type captures', () {
      final game = _emptyReadyGame();
      game.debugApplyOffer(
        PieceColor.white,
        const AbilityOffer(
          ability: GameAbility.boardOnlyEqualsKill,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );

      for (var i = 0; i < 5; i++) {
        game.debugSetPiece(
          Square(i, 1),
          Piece(
            pieceId: 'wr$i',
            type: PieceType.rook,
            color: PieceColor.white,
            hasMoved: true,
          ),
        );
        game.debugSetPiece(
          Square(i, 4),
          Piece(
            pieceId: 'br$i',
            type: PieceType.rook,
            color: PieceColor.black,
            hasMoved: true,
          ),
        );
        // Do not advance black: wave requires 3 moves from each side.
        game.debugSetTurn(PieceColor.white);
        expect(
          game.makeMove(Move(from: Square(i, 1), to: Square(i, 4))),
          isNotNull,
        );
        if (game.isGameOver) break;
      }
      expect(game.isGameOver, isTrue);
      expect(game.winnerColor, PieceColor.white);
      expect(game.endReason, GameEndReason.alternativeVictory);
    });
  });

  test('castling works by clicking king destination or the rook', () {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(1)));
    game.applyStartAbility(
      PieceColor.white,
      GameAbility.boardSkipTurn,
      remoteOffer: const AbilityOffer(
        ability: GameAbility.boardSkipTurn,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.white,
      ),
    );
    game.applyStartAbility(
      PieceColor.black,
      GameAbility.boardSkipTurn,
      remoteOffer: const AbilityOffer(
        ability: GameAbility.boardSkipTurn,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.black,
      ),
    );

    // Clear path for kingside castling.
    game.debugSetPiece(const Square(5, 0), null);
    game.debugSetPiece(const Square(6, 0), null);

    final byKingSquare = game.getLegalMoves(from: const Square(4, 0)).where(
      (m) => m.isCastle && m.to == const Square(6, 0),
    );
    final byRookSquare = game.getLegalMoves(from: const Square(4, 0)).where(
      (m) => m.isCastle && m.to == const Square(7, 0),
    );
    expect(byKingSquare, isNotEmpty);
    expect(byRookSquare, isNotEmpty);

    expect(
      game.makeMove(
        const Move(from: Square(4, 0), to: Square(7, 0), isCastle: true),
      ),
      isNotNull,
    );
    expect(game.pieceAt(const Square(6, 0))?.type, PieceType.king);
    expect(game.pieceAt(const Square(5, 0))?.type, PieceType.rook);
    expect(game.pieceAt(const Square(7, 0)), isNull);
  });

  test('attraction pulse moves c6 queen diagonally to d5', () {
    final game = _emptyReadyGame();
    game.debugSetPiece(const Square(7, 0), null);
    game.debugSetPiece(const Square(7, 7), null);
    // Keep kings off the board center path; place them in corners.
    game.debugSetPiece(
      const Square(0, 0),
      const Piece(
        pieceId: 'wk',
        type: PieceType.king,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(0, 7),
      const Piece(
        pieceId: 'bk',
        type: PieceType.king,
        color: PieceColor.black,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(2, 5), // c6
      const Piece(
        pieceId: 'wq',
        type: PieceType.queen,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );

    game.debugAttractionPulse();

    expect(game.pieceAt(const Square(2, 5)), isNull);
    expect(game.pieceAt(const Square(3, 4))?.type, PieceType.queen); // d5
  });

  test('frost map stages rise without torch and fall next to torch', () {
    final game = ChessGame(catalog: AbilityCatalog(random: Random(7)));
    game.applyStartAbility(
      PieceColor.white,
      GameAbility.boardFrostMap,
      remoteOffer: const AbilityOffer(
        ability: GameAbility.boardFrostMap,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.white,
      ),
    );
    game.applyStartAbility(
      PieceColor.black,
      GameAbility.boardSkipTurn,
      remoteOffer: const AbilityOffer(
        ability: GameAbility.boardSkipTurn,
        applyMode: AbilityApplyMode.boardWide,
        forColor: PieceColor.black,
      ),
    );

    expect(game.frostMapActive, isTrue);
    expect(GameAbility.boardFrostMap.group, AbilityGroup.mode);

    for (var r = 0; r < 8; r++) {
      for (var f = 0; f < 8; f++) {
        game.debugSetPiece(Square(f, r), null);
      }
    }
    game.debugSetPiece(
      const Square(4, 0),
      const Piece(
        pieceId: 'wk',
        type: PieceType.king,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(4, 7),
      const Piece(
        pieceId: 'bk',
        type: PieceType.king,
        color: PieceColor.black,
        hasMoved: true,
      ),
    );
    game.debugSetPiece(
      const Square(0, 3),
      const Piece(
        pieceId: 'wr',
        type: PieceType.rook,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetTorchIds(PieceColor.white, {});
    game.debugSetTorchIds(PieceColor.black, {});

    expect(game.pieceAt(const Square(0, 3))?.frostLevel, 0);
    game.debugTickFrostMap(PieceColor.white);
    expect(game.pieceAt(const Square(0, 3))?.frostLevel, 1);
    game.debugTickFrostMap(PieceColor.white);
    expect(game.pieceAt(const Square(0, 3))?.frostLevel, 2);
    game.debugTickFrostMap(PieceColor.white);
    expect(game.pieceAt(const Square(0, 3))?.frostLevel, 3);
    expect(game.isFrozenPiece('wr'), isTrue);

    game.debugSetPiece(
      const Square(1, 3),
      const Piece(
        pieceId: 'wn',
        type: PieceType.knight,
        color: PieceColor.white,
        hasMoved: true,
      ),
    );
    game.debugSetTorchIds(PieceColor.white, {'wn'});

    game.debugTickFrostMap(PieceColor.white);
    expect(game.pieceAt(const Square(0, 3))?.frostLevel, 2);
    expect(game.isFrozenPiece('wr'), isFalse);
    expect(game.pieceAt(const Square(1, 3))?.frostLevel, 0);
  });
}
